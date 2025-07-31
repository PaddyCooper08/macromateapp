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
} from "./supabaseClient.js";
import { calculateMacros, testService, calculateImageMacros } from "./geminiService.js";

// Validate required environment variables
if (!process.env.GEMINI_API_KEY) {
  throw new Error("Missing GEMINI_API_KEY environment variable");
}

if (!process.env.SUPABASE_URL || !process.env.SUPABASE_ANON_KEY) {
  throw new Error("Missing Supabase environment variables");
}

const app = express();
const PORT = process.env.PORT || 3000;

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
        'ionic://localhost', // Ionic apps
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

    // Additional file validation
    const imageBuffer = req.file.buffer;
    console.log('Image buffer size:', imageBuffer.length);
    
    // Check if the file is actually an image by examining the buffer
    const isValidImage = imageBuffer.length > 0 && (
      // Check for common image file signatures
      imageBuffer[0] === 0xFF && imageBuffer[1] === 0xD8 || // JPEG
      imageBuffer[0] === 0x89 && imageBuffer[1] === 0x50 || // PNG
      imageBuffer[0] === 0x47 && imageBuffer[1] === 0x49 || // GIF
      imageBuffer[0] === 0x42 && imageBuffer[1] === 0x4D    // BMP
    );
    
    if (!isValidImage && req.file.mimetype && !req.file.mimetype.startsWith('image/')) {
      console.log('File validation failed - not a valid image file');
      return res.status(400).json({
        success: false,
        error: 'Invalid file type',
        message: 'Please upload a valid image file (JPG, PNG, GIF, BMP)'
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
          mimeType: req.file.mimetype,
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
    const { userId } = req.body;

    if (!userId) {
      return res.status(400).json({
        success: false,
        error: 'Missing userId in request body'
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

// Error handling middleware
app.use((error, req, res, next) => {
  console.error('Unhandled error:', error);
  console.error('Error details:', {
    name: error.name,
    message: error.message,
    code: error.code,
    stack: error.stack
  });
  
  if (error instanceof multer.MulterError) {
    if (error.code === 'LIMIT_FILE_SIZE') {
      return res.status(400).json({
        success: false,
        error: 'File too large',
        message: 'Image file must be smaller than 10MB'
      });
    }
  }
  
  // Handle file filter errors
  if (error.message === 'Only image files are allowed') {
    return res.status(400).json({
      success: false,
      error: 'Invalid file type',
      message: 'Please upload a valid image file (JPG, PNG, GIF, etc.)'
    });
  }
  
  res.status(500).json({
    success: false,
    error: 'Internal server error',
    message: process.env.NODE_ENV === 'development' ? error.message : 'Something went wrong'
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    error: 'Not found',
    message: 'The requested endpoint does not exist'
  });
});

// Start the server
async function startServer() {
  try {
    console.log("🤖 Starting MacroMate Express Server...");

    // Test connections
    console.log("🧪 Testing Gemini service...");
    await testService();
    console.log("✅ Gemini service working");

    app.listen(PORT, () => {
      console.log(`🚀 MacroMate Express Server is running on port ${PORT}!`);
      console.log(`📱 Ready to serve Flutter app requests`);
      console.log(`🌐 Health check: http://localhost:${PORT}/health`);
    });
  } catch (error) {
    console.error("❌ Failed to start server:", error);
    process.exit(1);
  }
}

startServer();
