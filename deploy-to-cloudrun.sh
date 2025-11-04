#!/bin/bash
# Deploy Prisma AIRS Red Teaming streaming app to Google Cloud Run

set -e

echo "🚀 Deploying Streaming App to Google Cloud Run"
echo "=================================================="
echo ""

# Configuration
PROJECT_ID=${GCP_PROJECT_ID:-""}
REGION=${GCP_REGION:-"us-central1"}
SERVICE_NAME="prisma-airs-streaming"
IMAGE_NAME="gcr.io/${PROJECT_ID}/${SERVICE_NAME}"

# Check prerequisites
if [ -z "$PROJECT_ID" ]; then
    echo "❌ ERROR: GCP_PROJECT_ID not set"
    echo ""
    echo "Set your GCP project ID:"
    echo "  export GCP_PROJECT_ID='your-project-id'"
    echo ""
    echo "Or find it with: gcloud config get-value project"
    exit 1
fi

if [ -z "$PANW_AI_SEC_API_KEY" ]; then
    echo "❌ ERROR: PANW_AI_SEC_API_KEY not set"
    echo ""
    echo "Set your Prisma AIRS API key:"
    echo "  export PANW_AI_SEC_API_KEY='your-api-key'"
    exit 1
fi

if ! command -v gcloud &> /dev/null; then
    echo "❌ ERROR: gcloud CLI not installed"
    echo ""
    echo "Install from: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Optional: Check if Docker is installed (for local build testing)
if ! command -v docker &> /dev/null; then
    echo "⚠️  WARNING: Docker not installed - will use Cloud Build"
fi

echo "✅ Prerequisites check passed"
echo ""
echo "Configuration:"
echo "  Project ID: $PROJECT_ID"
echo "  Region: $REGION"
echo "  Service Name: $SERVICE_NAME"
echo "  Image: $IMAGE_NAME"
echo ""

# Confirm deployment
read -p "Deploy to GCP? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Deployment cancelled"
    exit 0
fi

echo ""
echo "🔧 Step 1: Building container image..."
echo "=================================================="

# Build and push using Cloud Build (recommended) or Docker
if command -v docker &> /dev/null; then
    echo "Using Docker to build locally..."
    docker build -f Dockerfile.cloudrun -t ${IMAGE_NAME} .
    docker push ${IMAGE_NAME}
else
    echo "Using Cloud Build..."
    gcloud builds submit --tag ${IMAGE_NAME} -f Dockerfile.cloudrun .
fi

echo ""
echo "✅ Image built and pushed: ${IMAGE_NAME}"
echo ""

echo "🚀 Step 2: Deploying to Cloud Run..."
echo "=================================================="

# Deploy to Cloud Run
gcloud run deploy ${SERVICE_NAME} \
    --image ${IMAGE_NAME} \
    --platform managed \
    --region ${REGION} \
    --allow-unauthenticated \
    --set-env-vars PANW_AI_SEC_API_KEY=${PANW_AI_SEC_API_KEY} \
    --set-env-vars PRISMA_AIRS_PROFILE=${PRISMA_AIRS_PROFILE:-chatbot} \
    --set-env-vars OPENAI_API_KEY=${OPENAI_API_KEY:-} \
    --memory 512Mi \
    --cpu 1 \
    --timeout 300 \
    --max-instances 10 \
    --port 8080

echo ""
echo "✅ Deployment complete!"
echo ""

# Get service URL
SERVICE_URL=$(gcloud run services describe ${SERVICE_NAME} \
    --platform managed \
    --region ${REGION} \
    --format 'value(status.url)')

echo "=================================================="
echo "🎉 Streaming App Deployed Successfully!"
echo "=================================================="
echo ""
echo "Service URL: ${SERVICE_URL}"
echo ""
echo "📋 Test endpoints:"
echo "  Health check:    ${SERVICE_URL}/health"
echo "  Chat endpoint:   ${SERVICE_URL}/v1/chat/completions"
echo ""
echo "🧪 Test it:"
echo "  curl ${SERVICE_URL}/health"
echo ""
echo "📡 Streaming formats available:"
echo "  • OpenAI:    ${SERVICE_URL}/v1/chat/completions (default)"
echo "  • Text-delta: ${SERVICE_URL}/v1/chat/completions?format=textdelta"
echo "  • NDJSON:    ${SERVICE_URL}/v1/chat/completions?format=ndjson"
echo "  • Simple:    ${SERVICE_URL}/v1/chat/completions?format=simple"
echo ""
echo "🎯 Add to Red Teaming:"
echo ""
echo "Use this cURL command in SCM:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "curl -X POST ${SERVICE_URL}/v1/chat/completions -H \"Content-Type: application/json\" -d '{\"messages\":[{\"role\":\"user\",\"content\":\"{INPUT}\"}],\"model\":\"gpt-3.5-turbo\",\"stream\":true}'"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📊 View logs:"
echo "  gcloud run logs read ${SERVICE_NAME} --region ${REGION} --limit 100"
echo ""
echo "🔄 Update deployment:"
echo "  Run this script again after making code changes"
echo ""
echo "🗑️  Delete service:"
echo "  gcloud run services delete ${SERVICE_NAME} --region ${REGION}"
echo ""
