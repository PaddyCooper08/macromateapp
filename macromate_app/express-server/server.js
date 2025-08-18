import dotenv from "dotenv";
dotenv.config();

import express from "express";
import cors from "cors";
import helmet from "helmet";
import rateLimit from "express-rate-limit";
import multer from "multer";
import {
  saveMacrosToDb,
  getDailyMacros,
  getPreviousDaysMacros,
  deleteMacroLog,
  saveFavoriteItem,
  getFavoriteItems,
  deleteFavoriteItem,
  updateFavoriteItem,
} from "./supabaseClient.js";
import { calculateMacros, testService, calculateImageMacros } from "./geminiService.js";
import { createClient } from '@supabase/supabase-js';

// Validate required environment variables
if (!process.env.GEMINI_API_KEY) {
  console.warn("⚠️ Missing GEMINI_API_KEY environment variable - some features may not work");
}

if (!process.env.SUPABASE_URL || !process.env.SUPABASE_ANON_KEY) {
  console.warn("⚠️ Missing Supabase environment variables - database features may not work");
}

const app = express();
const PORT = process.env.PORT || 8080;

// Configure multer for image uploads
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB limit
  },
  fileFilter: (req, file, cb) => {
    console.log('File filter - checking file:', {
      originalname: file.originalname,
      mimetype: file.mimetype,
      fieldname: file.fieldname
    });
    
    // Be more permissive - accept all files and validate in the endpoint
    // This helps avoid issues with mobile apps sending files with incorrect MIME types
    if (!file.mimetype || file.mimetype === 'application/octet-stream') {
      console.log('File has no/generic MIME type, checking extension');
      const hasImageExtension = /\.(jpg|jpeg|png|gif|bmp|webp)$/i.test(file.originalname || '');
      if (hasImageExtension) {
        console.log('File accepted based on extension');
        cb(null, true);
      } else {
        console.log('File rejected - no image extension');
        cb(new Error('Only image files are allowed'), false);
      }
    } else if (file.mimetype.startsWith('image/')) {
      console.log('File accepted as image by MIME type');
      cb(null, true);
    } else {
      console.log('File rejected - not an image MIME type');
      cb(new Error('Only image files are allowed'), false);
    }
  }
});

// Security middleware
app.use(helmet());
app.use(cors({
  origin: process.env.NODE_ENV === 'production' 
    ? [
        'https://macromateapi.onrender.com', // Your production server
        'http://localhost:3000', // Allow local Flutter web development
        'http://10.0.2.2:3000', // Android emulator
        'capacitor://localhost', // Capacitor apps
        'ionic://localhost',
        'https://macromate-server-290899070829.europe-west1.run.app', // Ionic apps
        '*' // Allow all origins for mobile apps (since they don't have a fixed origin)
      ]
    : ['http://localhost:3000', 'http://localhost:8080', 'http://10.0.2.2:3000'], // Local development
  credentials: true
}));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP, please try again later.'
});
app.use(limiter);

// Body parsing middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

// Test Gemini service endpoint
app.get('/api/test-service', async (req, res) => {
  try {
    const result = await testService();
    res.json({ success: true, data: result });
  } catch (error) {
    console.error('Test service error:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Service test failed',
      message: error.message 
    });
  }
});

// Calculate macros from food description
app.post('/api/calculate-macros', async (req, res) => {
  try {
    const { foodDescription, userId } = req.body;

    if (!foodDescription || !userId) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields: foodDescription and userId'
      });
    }

    // Calculate macros using Gemini
    const macroData = await calculateMacros(foodDescription);

    // Check if macros were successfully calculated
    if (
      macroData.protein_g === 0 &&
      macroData.carbs_g === 0 &&
      macroData.fats_g === 0
    ) {
      return res.status(400).json({
        success: false,
        error: 'Could not calculate macros',
        message: `I couldn't calculate macros for "${foodDescription}". Please try being more specific about the food items and quantities.`,
        suggestion: 'Example: "100g chicken breast" or "1 medium apple"'
      });
    }

    // Save to database
    const now = new Date();
    const date = now.toISOString().split("T")[0]; // YYYY-MM-DD
    const mealTime = now.toISOString();

    const savedData = await saveMacrosToDb(
      userId,
      date,
      mealTime,
      macroData.parsed_food_item,
      macroData.protein_g,
      macroData.carbs_g,
      macroData.fats_g,
      macroData.calories
    );

    res.json({
      success: true,
      data: {
        ...macroData,
        id: savedData.id,
        date,
        mealTime
      }
    });
  } catch (error) {
    console.error('Error calculating macros:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to calculate macros',
      message: error.message
    });
  }
});

// Calculate macros from image
app.post('/api/calculate-image-macros', upload.single('image'), async (req, res) => {
  try {
    console.log('Received image upload request');
    console.log('Request body:', { weight: req.body.weight, userId: req.body.userId });
    console.log('File info:', req.file ? { 
      mimetype: req.file.mimetype, 
      size: req.file.size,
      filename: req.file.originalname 
    } : 'No file');

    const { weight, userId } = req.body;

    if (!req.file || !userId) {
      console.log('Missing required fields:', { hasFile: !!req.file, userId });
      return res.status(400).json({
        success: false,
        error: 'Missing required fields: image file and userId'
      });
    }

    // Additional file validation and MIME type detection
    const imageBuffer = req.file.buffer;
    console.log('Image buffer size:', imageBuffer.length);
    console.log('Original MIME type:', req.file.mimetype);
    
    // Detect correct MIME type based on file signature
    let mimeType = req.file.mimetype;
    if (imageBuffer.length > 2) {
      if (imageBuffer[0] === 0xFF && imageBuffer[1] === 0xD8) {
        mimeType = 'image/jpeg';
      } else if (imageBuffer[0] === 0x89 && imageBuffer[1] === 0x50 && imageBuffer[2] === 0x4E) {
        mimeType = 'image/png';
      } else if (imageBuffer[0] === 0x47 && imageBuffer[1] === 0x49 && imageBuffer[2] === 0x46) {
        mimeType = 'image/gif';
      } else if (imageBuffer[0] === 0x52 && imageBuffer[1] === 0x49 && imageBuffer[2] === 0x46) {
        mimeType = 'image/webp';
      } else if (req.file.mimetype === 'application/octet-stream') {
        // Fallback to jpeg if we can't detect and original was octet-stream
        mimeType = 'image/jpeg';
      }
    }
    
    console.log('Detected MIME type:', mimeType);
    
    // Check if the file is actually an image
    const validMimeTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp'];
    if (!validMimeTypes.includes(mimeType)) {
      console.log('File validation failed - not a valid image file');
      return res.status(400).json({
        success: false,
        error: 'Invalid file type',
        message: 'Please upload a valid image file (JPG, PNG, GIF, WebP)'
      });
    }

    const prompt = `You are a nutrition expert. Analyze the following image of a food nutrition label and then calculate the macronutrients for the weight specified in the prompt.

IMPORTANT: Respond ONLY with a valid JSON object in the exact format specified below. Do not include any additional text, markdown formatting, or explanations.

Weight : "${weight || ''}"

Analyze this nutrition label and the weight provided and provide the macronutrient breakdown. If quantities are not specified, assume reasonable serving sizes. If you cannot identify the food or calculate macros, return zeros.
All food is from the uk and when a brand is mentioned you need to use google search to locate the nutritional information online if possible. If exact information is not avaialble, use reasonable estimates based on common nutritional values, use the lower bound of protein content ensuring you do not overshoot protein values.

Required JSON format (respond with this format only):
{
  "protein_g": <number>,
  "carbs_g": <number>,
  "fats_g": <number>,
  "calories": <number>,
  "parsed_food_item": "<string describing the food as you understood it>"
}

Examples:
Input: "An image of a frozen pizza food nutrition label stating that 100g has 20g protein, 30g carbs, 10g fats, 500kcal and the weight provided is 50g"
Output: {"protein_g": 10, "carbs_g": 15, "fats_g": 5, "calories": 250, "parsed_food_item": "A frozen pizza"}

Now analyze the image with weight: "${weight || ''}"`;

    const contents = [
      {
        inlineData: {
          mimeType: mimeType,
          data: imageBuffer.toString("base64"),
        },
      },
      { text: prompt },
    ];

    console.log('Calling Gemini API with image...');
    // Calculate macros using Gemini
    const macroData = await calculateImageMacros(contents);
    console.log('Gemini response:', macroData);

    // Check if macros were successfully calculated
    if (
      macroData.protein_g === 0 &&
      macroData.carbs_g === 0 &&
      macroData.fats_g === 0
    ) {
      console.log('Zero macros detected, returning error');
      return res.status(400).json({
        success: false,
        error: 'Could not calculate macros from image',
        message: 'I couldn\'t calculate macros from this image. Please try again with a clearer nutrition label or include the weight.',
        suggestion: 'Example: Upload a clear nutrition label image with weight "100g"'
      });
    }

    console.log('Saving macro data to database...');
    // Save to database
    const now = new Date();
    const date = now.toISOString().split("T")[0]; // YYYY-MM-DD
    const mealTime = now.toISOString();

    const savedData = await saveMacrosToDb(
      userId,
      date,
      mealTime,
      macroData.parsed_food_item,
      macroData.protein_g,
      macroData.carbs_g,
      macroData.fats_g,
      macroData.calories
    );

    console.log('Successfully saved to database:', savedData.id);

    res.json({
      success: true,
      data: {
        ...macroData,
        id: savedData.id,
        date,
        mealTime
      }
    });
  } catch (error) {
    console.error('Error processing image macros:', error);
    console.error('Error stack:', error.stack);
    res.status(500).json({
      success: false,
      error: 'Failed to process image',
      message: error.message
    });
  }
});

// Calculate macros from barcode (Open Food Facts)
app.post('/api/barcode-macros', async (req, res) => {
  try {
    const { barcode, userId, weight } = req.body;

    if (!barcode || !userId) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields: barcode and userId'
      });
    }

    const trimmedBarcode = String(barcode).trim();
    if (!/^\d{6,14}$/.test(trimmedBarcode)) {
      return res.status(400).json({
        success: false,
        error: 'Invalid barcode format'
      });
    }

    // Normalise weight (extract number of grams) default 100g
    let weightGrams = 100;
    if (weight && typeof weight === 'string') {
      const match = weight.replace(',', '.').match(/([0-9]*\.?[0-9]+)/);
      if (match) {
        const val = parseFloat(match[1]);
        if (!isNaN(val) && val > 0) weightGrams = val;
      }
    } else if (typeof weight === 'number' && weight > 0) {
      weightGrams = weight;
    }

    const url = `https://world.openfoodfacts.org/api/v2/product/${trimmedBarcode}.json?cc=gb&lc=en`;

    let response;
    try {
      response = await fetch(url, {
        headers: {
          'User-Agent': 'MacroMateApp/1.0',
          'Accept': 'application/json'
        }
      });
    } catch (err) {
      return res.status(502).json({ success: false, error: 'Failed to reach Open Food Facts API' });
    }

    if (!response.ok) {
      return res.status(502).json({ success: false, error: 'Open Food Facts API error' });
    }
    const data = await response.json();

    if (data.status !== 1 || !data.product) {
      return res.status(404).json({ success: false, error: 'Product not found' });
    }

    const product = data.product;
    const nutriments = product.nutriments || {};

    // Prefer *_100g entries (already per 100g). Fallback to *_serving if 100g missing and serving size ~100g assumption.
    const protein100 = parseFloat(nutriments.proteins_100g ?? nutriments.proteins_serving ?? 0) || 0;
    const carbs100 = parseFloat(nutriments.carbohydrates_100g ?? nutriments.carbohydrates_serving ?? 0) || 0;
    const fats100 = parseFloat(nutriments.fat_100g ?? nutriments.fat_serving ?? 0) || 0;

    // Energy may be in kcal or only kJ
    let calories100 = parseFloat(
      nutriments['energy-kcal_100g'] ?? nutriments['energy-kcal_serving'] ?? nutriments.energy_kcal ?? 0
    );
    if (!calories100 || calories100 === 0) {
      const kj = parseFloat(
        nutriments['energy-kj_100g'] ?? nutriments['energy-kj_serving'] ?? nutriments.energy_kj ?? 0
      );
      if (kj && kj > 0) calories100 = kj / 4.184;
    }

    const scale = weightGrams / 100.0;
    const protein = parseFloat((protein100 * scale).toFixed(1));
    const carbs = parseFloat((carbs100 * scale).toFixed(1));
    const fats = parseFloat((fats100 * scale).toFixed(1));
    const calories = parseFloat((calories100 * scale).toFixed(0));

    // Reject if all zero (insufficient data)
    if (protein === 0 && carbs === 0 && fats === 0 && calories === 0) {
      return res.status(422).json({
        success: false,
        error: 'Insufficient nutrient data for this product'
      });
    }

    const now = new Date();
    const date = now.toISOString().split('T')[0];
    const mealTime = now.toISOString();

    const nameParts = [
      product.brand_owner || product.brands,
      product.product_name || product.generic_name
    ].filter(Boolean);
    const foodName = nameParts.join(' - ') || `Barcode ${trimmedBarcode}`;

    const savedData = await saveMacrosToDb(
      userId,
      date,
      mealTime,
      foodName,
      protein,
      carbs,
      fats,
      calories
    );

    res.json({
      success: true,
      data: {
        id: savedData.id,
        foodItem: foodName,
        protein,
        carbs,
        fats,
        calories,
        date,
        mealTime
      }
    });
  } catch (error) {
    console.error('Error processing barcode macros:', error);
    res.status(500).json({ success: false, error: 'Failed to process barcode', message: error.message });
  }
});

// Get today's macros for a user
app.get('/api/today-macros/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    const today = new Date().toISOString().split("T")[0];

    const dailyMacros = await getDailyMacros(userId, today);

    if (dailyMacros.length === 0) {
      return res.json({
        success: true,
        data: {
          date: today,
          totalMacros: {
            protein: 0,
            carbs: 0,
            fats: 0,
            calories: 0
          },
          meals: [],
          message: 'No food entries logged for today yet!'
        }
      });
    }

    // Calculate totals
    let totalProtein = 0;
    let totalCarbs = 0;
    let totalFats = 0;
    let totalCalories = 0;

    dailyMacros.forEach((entry) => {
      totalProtein += parseFloat(entry.protein_g || 0);
      totalCarbs += parseFloat(entry.carbs_g || 0);
      totalFats += parseFloat(entry.fats_g || 0);
      totalCalories += parseFloat(entry.calories || 0);
    });

    // Format meals data
    const meals = dailyMacros.map((entry) => ({
      id: entry.id,
      foodItem: entry.food_item,
      protein: parseFloat(entry.protein_g || 0),
      carbs: parseFloat(entry.carbs_g || 0),
      fats: parseFloat(entry.fats_g || 0),
      calories: parseFloat(entry.calories || 0),
      mealTime: entry.meal_time,
      date: entry.log_date
    }));

    res.json({
      success: true,
      data: {
        date: today,
        totalMacros: {
          protein: parseFloat(totalProtein.toFixed(1)),
          carbs: parseFloat(totalCarbs.toFixed(1)),
          fats: parseFloat(totalFats.toFixed(1)),
          calories: parseFloat(totalCalories.toFixed(1))
        },
        meals
      }
    });
  } catch (error) {
    console.error('Error getting today\'s macros:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to retrieve today\'s macros',
      message: error.message
    });
  }
});

// NEW: Get macros for a specific day for a user
app.get('/api/day-macros/:userId/:date', async (req, res) => {
  try {
    const { userId, date } = req.params;

    // Basic date validation (YYYY-MM-DD)
    if (!/^\d{4}-\d{2}-\d{2}$/.test(date)) {
      return res.status(400).json({
        success: false,
        error: 'Invalid date format',
        message: 'Date must be in YYYY-MM-DD format'
      });
    }

    const dailyMacros = await getDailyMacros(userId, date);

    if (dailyMacros.length === 0) {
      return res.json({
        success: true,
        data: {
          date,
          totalMacros: {
            protein: 0,
            carbs: 0,
            fats: 0,
            calories: 0
          },
          meals: [],
          message: 'No food entries logged for this day.'
        }
      });
    }

    // Calculate totals
    let totalProtein = 0;
    let totalCarbs = 0;
    let totalFats = 0;
    let totalCalories = 0;

    dailyMacros.forEach((entry) => {
      totalProtein += parseFloat(entry.protein_g || 0);
      totalCarbs += parseFloat(entry.carbs_g || 0);
      totalFats += parseFloat(entry.fats_g || 0);
      totalCalories += parseFloat(entry.calories || 0);
    });

    // Format meals data
    const meals = dailyMacros.map((entry) => ({
      id: entry.id,
      foodItem: entry.food_item,
      protein: parseFloat(entry.protein_g || 0),
      carbs: parseFloat(entry.carbs_g || 0),
      fats: parseFloat(entry.fats_g || 0),
      calories: parseFloat(entry.calories || 0),
      mealTime: entry.meal_time,
      date: entry.log_date
    }));

    res.json({
      success: true,
      data: {
        date,
        totalMacros: {
          protein: parseFloat(totalProtein.toFixed(1)),
          carbs: parseFloat(totalCarbs.toFixed(1)),
          fats: parseFloat(totalFats.toFixed(1)),
          calories: parseFloat(totalCalories.toFixed(1))
        },
        meals
      }
    });
  } catch (error) {
    console.error('Error getting day\'s macros:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to retrieve day\'s macros',
      message: error.message
    });
  }
});

// Get past macros for a user
app.get('/api/past-macros/:userId/:days?', async (req, res) => {
  try {
    const { userId, days = 3 } = req.params;
    const numberOfDays = parseInt(days, 10);

    if (numberOfDays > 30) {
      return res.status(400).json({
        success: false,
        error: 'Invalid days parameter',
        message: 'Please choose a number between 1 and 30 days.'
      });
    }

    const pastMacros = await getPreviousDaysMacros(userId, numberOfDays);

    if (pastMacros.length === 0) {
      return res.json({
        success: true,
        data: {
          days: numberOfDays,
          dailySummaries: [],
          message: `No macro data found for the past ${numberOfDays} days.`
        }
      });
    }

    // Format the data for Flutter
    const dailySummaries = pastMacros.map((day) => ({
      date: day.date,
      totalProtein: parseFloat(day.total_protein.toFixed(1)),
      totalCarbs: parseFloat(day.total_carbs.toFixed(1)),
      totalFats: parseFloat(day.total_fats.toFixed(1)),
      totalCalories: parseFloat(day.total_calories.toFixed(1))
    }));

    res.json({
      success: true,
      data: {
        days: numberOfDays,
        dailySummaries
      }
    });
  } catch (error) {
    console.error('Error getting past macros:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to retrieve past macros',
      message: error.message
    });
  }
});

// Delete a macro log entry
app.delete('/api/macro-log/:logId', async (req, res) => {
  try {
    const { logId } = req.params;
    const { userId } = req.query;

    if (!userId) {
      return res.status(400).json({
        success: false,
        error: 'Missing userId in query parameters'
      });
    }

    const deletedData = await deleteMacroLog(logId, userId);

    res.json({
      success: true,
      data: deletedData,
      message: 'Meal removed successfully!'
    });
  } catch (error) {
    console.error('Error deleting macro log:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to delete meal',
      message: error.message
    });
  }
});

// Get user's favorite foods
app.get('/api/favorites/:userId', async (req, res) => {
  try {
    const { userId } = req.params;

    const favorites = await getFavoriteItems(userId);

    if (favorites.length === 0) {
      return res.json({
        success: true,
        data: {
          favorites: [],
          message: 'You don\'t have any favourite foods yet!'
        }
      });
    }

    // Format favorites data
    const formattedFavorites = favorites.map((favorite) => ({
      id: favorite.id,
      foodItem: favorite.food_item,
      protein: parseFloat(favorite.protein_g || 0),
      carbs: parseFloat(favorite.carbs_g || 0),
      fats: parseFloat(favorite.fats_g || 0),
      calories: parseFloat(favorite.calories || 0),
      createdAt: favorite.created_at
    }));

    res.json({
      success: true,
      data: {
        favorites: formattedFavorites
      }
    });
  } catch (error) {
    console.error('Error getting favorites:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to retrieve favorites',
      message: error.message
    });
  }
});

// Add food item to favorites
app.post('/api/favorites/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    const { foodItem, protein, carbs, fats, calories } = req.body;

    if (!foodItem || protein === undefined || carbs === undefined || fats === undefined || calories === undefined) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields: foodItem, protein, carbs, fats, calories'
      });
    }

    const savedFavorite = await saveFavoriteItem(
      userId,
      foodItem,
      protein,
      carbs,
      fats,
      calories
    );

    res.json({
      success: true,
      data: {
        id: savedFavorite.id,
        foodItem: savedFavorite.food_item,
        protein: parseFloat(savedFavorite.protein_g),
        carbs: parseFloat(savedFavorite.carbs_g),
        fats: parseFloat(savedFavorite.fats_g),
        calories: parseFloat(savedFavorite.calories),
        createdAt: savedFavorite.created_at
      },
      message: 'Added to favourites!'
    });
  } catch (error) {
    console.error('Error saving favorite:', error);
    const isAlreadyExists = error.message.includes('already in');
    res.status(isAlreadyExists ? 409 : 500).json({
      success: false,
      error: isAlreadyExists ? 'Already in favourites!' : 'Failed to save favorite',
      message: error.message
    });
  }
});

// Add favorite to today's meals
app.post('/api/favorites/:userId/add-to-meals', async (req, res) => {
  try {
    const { userId } = req.params;
    const { favoriteId } = req.body;

    if (!favoriteId) {
      return res.status(400).json({
        success: false,
        error: 'Missing favoriteId in request body'
      });
    }

    const favorites = await getFavoriteItems(userId);
    const favorite = favorites.find(f => f.id === favoriteId);

    if (!favorite) {
      return res.status(404).json({
        success: false,
        error: 'Favourite item not found'
      });
    }

    // Save to macro log
    const now = new Date();
    const date = now.toISOString().split("T")[0];
    const mealTime = now.toISOString();

    const savedData = await saveMacrosToDb(
      userId,
      date,
      mealTime,
      favorite.food_item,
      favorite.protein_g,
      favorite.carbs_g,
      favorite.fats_g,
      favorite.calories
    );

    res.json({
      success: true,
      data: {
        id: savedData.id,
        foodItem: savedData.food_item,
        protein: parseFloat(savedData.protein_g),
        carbs: parseFloat(savedData.carbs_g),
        fats: parseFloat(savedData.fats_g),
        calories: parseFloat(savedData.calories),
        date: savedData.log_date,
        mealTime: savedData.meal_time
      },
      message: 'Added to today\'s meals!'
    });
  } catch (error) {
    console.error('Error adding favorite to meals:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to add favorite to meals',
      message: error.message
    });
  }
});

// Delete a favorite food item
app.delete('/api/favorites/:userId/:favoriteId', async (req, res) => {
  try {
    const { userId, favoriteId } = req.params;

    const deletedData = await deleteFavoriteItem(favoriteId, userId);

    res.json({
      success: true,
      data: deletedData,
      message: 'Removed from favourites!'
    });
  } catch (error) {
    console.error('Error deleting favorite:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to remove from favourites',
      message: error.message
    });
  }
});

// Edit a favorite food item name
app.put('/api/favorites/:userId/:favoriteId', async (req, res) => {
  try {
    const { userId, favoriteId } = req.params;
    const { foodItem } = req.body;

    if (!foodItem || foodItem.trim() === '') {
      return res.status(400).json({
        success: false,
        error: 'Food item name is required'
      });
    }

    const updatedData = await updateFavoriteItem(favoriteId, userId, foodItem.trim());

    res.json({
      success: true,
      data: {
        id: updatedData.id,
        foodItem: updatedData.food_item,
        protein: parseFloat(updatedData.protein_g),
        carbs: parseFloat(updatedData.carbs_g),
        fats: parseFloat(updatedData.fats_g),
        calories: parseFloat(updatedData.calories),
        createdAt: updatedData.created_at
      },
      message: 'Favorite updated successfully!'
    });
  } catch (error) {
    console.error('Error updating favorite:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to update favorite',
      message: error.message
    });
  }
});

// Migration endpoint: move data from Telegram ID to Supabase auth user.id
app.post('/api/migrate-user', async (req, res) => {
  try {
    const { telegramId, supabaseUserId } = req.body;
    if (!telegramId || !supabaseUserId) {
      return res.status(400).json({ success: false, error: 'telegramId and supabaseUserId are required' });
    }

    const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_ANON_KEY);

    // Update macro_logs
    const { error: macroErr } = await supabase
      .from('macro_logs')
      .update({ user_id: supabaseUserId })
      .eq('user_id', telegramId.toString());
    if (macroErr) throw macroErr;

    // Update favorite_foods
    const { error: favErr } = await supabase
      .from('favorite_foods')
      .update({ user_id: supabaseUserId })
      .eq('user_id', telegramId.toString());
    if (favErr) throw favErr;

    res.json({ success: true, message: 'Migration completed' });
  } catch (error) {
    console.error('Migration error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Re-log (duplicate) a past macro entry into today
app.post('/api/relog-macro', async (req, res) => {
  try {
    const { userId, foodItem, protein, carbs, fats, calories } = req.body;
    if (!userId || !foodItem || protein == null || carbs == null || fats == null || calories == null) {
      return res.status(400).json({ success: false, error: 'Missing required fields' });
    }

    const now = new Date();
    const date = now.toISOString().split('T')[0];
    const mealTime = now.toISOString();

    const savedData = await saveMacrosToDb(
      userId,
      date,
      mealTime,
      String(foodItem),
      parseFloat(protein),
      parseFloat(carbs),
      parseFloat(fats),
      parseFloat(calories)
    );

    res.json({
      success: true,
      data: {
        id: savedData.id,
        foodItem: savedData.food_item,
        protein: parseFloat(savedData.protein_g),
        carbs: parseFloat(savedData.carbs_g),
        fats: parseFloat(savedData.fats_g),
        calories: parseFloat(savedData.calories),
        date: savedData.log_date,
        mealTime: savedData.meal_time
      },
      message: 'Meal added to today'
    });
  } catch (error) {
    console.error('Error re-logging macro:', error);
    res.status(500).json({ success: false, error: 'Failed to re-log macro', message: error.message });
  }
});

app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
