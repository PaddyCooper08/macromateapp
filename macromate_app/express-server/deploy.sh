#!/bin/bash

# MacroMate Server - Google Cloud Run Deployment Script
# Make sure you have gcloud CLI installed and authenticated

echo "🚀 Deploying MacroMate Server to Google Cloud Run..."

# Set your project ID here
PROJECT_ID="macromate-468121"
SUPABASE_URL=https://oabuwijptyrmnhzwekgo.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9hYnV3aWpwdHlybW5oendla2dvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMxMzQzOTQsImV4cCI6MjA2ODcxMDM5NH0.Eu5L2OJ8rxMebj1dAJGoFzheisOWJjna-w98hTeJywM
GEMINI_API_KEY=AIzaSyDnh4h4J2qvvf34aR_wQwEj_x-MQQg6-s4
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9hYnV3aWpwdHlybW5oendla2dvIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MzEzNDM5NCwiZXhwIjoyMDY4NzEwMzk0fQ.g7gME_3rDwKvNO1QcUra7upE5XSreslLz-PzDK6GM-s
# Set region
REGION="europe-west1"

# Service name
SERVICE_NAME="macromate-server"

echo "📋 Project ID: $PROJECT_ID"
echo "🌍 Region: $REGION"
echo "🔧 Service: $SERVICE_NAME"

# Build and deploy in one command
echo "🔨 Building and deploying..."
gcloud run deploy $SERVICE_NAME \
  --source . \
  --region $REGION \
  --platform managed \
  --allow-unauthenticated \
  --memory 1Gi \
  --cpu 1 \
  --concurrency 80 \
  --max-instances 10 \
  --timeout 300 \
  --port 8080 \
  --set-env-vars "NODE_ENV=production,GEMINI_API_KEY=${GEMINI_API_KEY},SUPABASE_URL=${SUPABASE_URL},SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY},SUPABASE_SERVICE_ROLE_KEY=${SUPABASE_SERVICE_ROLE_KEY}" \
  --project $PROJECT_ID

echo "✅ Deployment complete!"
echo "🌐 Your service URL will be displayed above"
echo ""
echo "📝 Don't forget to:"
echo "   1. Set your environment variables in Cloud Run console"
echo "   2. Update your Flutter app with the new URL"
