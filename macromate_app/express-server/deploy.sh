#!/bin/bash

# MacroMate Server - Google Cloud Run Deployment Script
# Make sure you have gcloud CLI installed and authenticated

echo "🚀 Deploying MacroMate Server to Google Cloud Run..."

# Set your project ID here
PROJECT_ID="macromate-468121"

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
  --set-env-vars "NODE_ENV=production,GEMINI_API_KEY=${GEMINI_API_KEY:-},SUPABASE_URL=${SUPABASE_URL:-},SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY:-}" \
  --project $PROJECT_ID

echo "✅ Deployment complete!"
echo "🌐 Your service URL will be displayed above"
echo ""
echo "📝 Don't forget to:"
echo "   1. Set your environment variables in Cloud Run console"
echo "   2. Update your Flutter app with the new URL"
