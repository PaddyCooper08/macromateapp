# MacroMate Express API Server

Express.js API server for the MacroMate Flutter application. This server wraps the existing Telegram bot functionality into RESTful API endpoints.

## Features

- 🔐 **Secure API**: CORS, Helmet, and rate limiting
- 📸 **Image Processing**: Upload nutrition label images for macro calculation
- 🤖 **AI Integration**: Uses Gemini AI for food analysis (same as Telegram bot)
- 💾 **Database**: Supabase integration for data persistence
- 🍽️ **Favorites**: Manage favorite foods
- 📊 **Analytics**: Daily and historical macro tracking

## API Endpoints

### Health & Testing

- `GET /health` - Health check
- `GET /api/test-service` - Test Gemini AI service

### Macro Calculation

- `POST /api/calculate-macros` - Calculate macros from food description
- `POST /api/calculate-image-macros` - Calculate macros from nutrition label image

### Daily Tracking

- `GET /api/today-macros/:userId` - Get today's macro summary and meals
- `GET /api/past-macros/:userId/:days?` - Get past daily macro summaries
- `DELETE /api/macro-log/:logId` - Delete a specific meal entry

### Favorites Management

- `GET /api/favorites/:userId` - Get user's favorite foods
- `POST /api/favorites/:userId` - Add food to favorites
- `POST /api/favorites/:userId/add-to-meals` - Add favorite food to today's meals
- `DELETE /api/favorites/:userId/:favoriteId` - Delete favorite food

## Installation

1. **Install dependencies:**

```bash
cd express-server
npm install
```

2. **Configure environment variables:**

```bash
cp .env.example .env
```

Edit `.env` with your credentials:

```env
GEMINI_API_KEY=your_gemini_api_key
SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_supabase_anon_key
PORT=3000
NODE_ENV=development
```

3. **Start the server:**

```bash
# Development
npm run dev

# Production
npm start
```

## API Usage Examples

### Calculate Macros from Text

```bash
curl -X POST http://localhost:3000/api/calculate-macros \
  -H "Content-Type: application/json" \
  -d '{
    "foodDescription": "100g chicken breast with 150g rice",
    "userId": "user123"
  }'
```

Response:

```json
{
  "success": true,
  "data": {
    "protein_g": 31.0,
    "carbs_g": 45.2,
    "fats_g": 3.6,
    "calories": 340,
    "parsed_food_item": "100g chicken breast with 150g rice",
    "id": "uuid",
    "date": "2025-07-30",
    "mealTime": "2025-07-30T12:30:00.000Z"
  }
}
```

### Get Today's Macros

```bash
curl http://localhost:3000/api/today-macros/user123
```

Response:

```json
{
  "success": true,
  "data": {
    "date": "2025-07-30",
    "totalMacros": {
      "protein": 75.2,
      "carbs": 120.5,
      "fats": 45.3,
      "calories": 1250.0
    },
    "meals": [
      {
        "id": "uuid",
        "foodItem": "Oatmeal with banana",
        "protein": 12.0,
        "carbs": 35.0,
        "fats": 3.5,
        "calories": 220,
        "mealTime": "2025-07-30T08:30:00.000Z",
        "date": "2025-07-30"
      }
    ]
  }
}
```

### Upload Image for Macro Calculation

```bash
curl -X POST http://localhost:3000/api/calculate-image-macros \
  -H "Content-Type: multipart/form-data" \
  -F "image=@nutrition_label.jpg" \
  -F "weight=100g" \
  -F "userId=user123"
```

### Get Favorites

```bash
curl http://localhost:3000/api/favorites/user123
```

### Add to Favorites

```bash
curl -X POST http://localhost:3000/api/favorites/user123 \
  -H "Content-Type: application/json" \
  -d '{
    "foodItem": "Protein shake",
    "protein": 25.0,
    "carbs": 5.0,
    "fats": 2.0,
    "calories": 140
  }'
```

## Error Handling

All endpoints return consistent error responses:

```json
{
  "success": false,
  "error": "Error type",
  "message": "Detailed error message"
}
```

HTTP Status Codes:

- `200` - Success
- `400` - Bad Request (missing/invalid parameters)
- `404` - Not Found
- `409` - Conflict (e.g., already exists)
- `429` - Too Many Requests (rate limited)
- `500` - Internal Server Error

## Security Features

- **CORS**: Configured for Flutter app origins
- **Rate Limiting**: 100 requests per 15 minutes per IP
- **Helmet**: Security headers
- **File Upload**: 10MB limit, image files only
- **Input Validation**: All endpoints validate required parameters

## Flutter Integration

This API is designed to work seamlessly with Flutter using `http` package:

```dart
// Example Flutter HTTP call
final response = await http.post(
  Uri.parse('http://your-server:3000/api/calculate-macros'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
    'foodDescription': 'chicken breast 200g',
    'userId': 'user123'
  }),
);

if (response.statusCode == 200) {
  final data = jsonDecode(response.body);
  if (data['success']) {
    // Handle success
    print(data['data']);
  }
}
```

## Migration from Telegram Bot

This server maintains the exact same functionality as the original Telegram bot:

- ✅ Same Gemini AI prompts and logic
- ✅ Same Supabase database operations
- ✅ Same macro calculation accuracy
- ✅ Same favorites system
- ✅ Same data validation

## Production Deployment

1. Set `NODE_ENV=production`
2. Configure proper CORS origins
3. Use a reverse proxy (nginx)
4. Set up SSL/TLS
5. Monitor with PM2 or similar

```bash
# PM2 deployment
pm2 start server.js --name macromate-api
pm2 startup
pm2 save
```

## Development

```bash
# Install dependencies
npm install

# Start development server with auto-reload
npm run dev

# Test the service
curl http://localhost:3000/health
```

The server will automatically reload when you make changes to the code during development.
