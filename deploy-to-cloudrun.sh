#!/bin/bash
# Deploy Prisma AIRS Red Teaming streaming app to Google Cloud Run

set -e

echo "🚀 Deploying Streaming App to Google Cloud Run"
echo "=================================================="
echo ""

# Configuration
#
# Images go to Artifact Registry, not Container Registry. Google shut off
# gcr.io writes on 2025-03-18, so pushing to gcr.io/PROJECT/... fails on any
# project that did not have legacy GCR grandfathered in.
#
# Create the Artifact Registry repo once, before the first deploy:
#   gcloud artifacts repositories create prisma-airs \
#     --repository-format=docker --location=us-central1
#
# We build explicitly (rather than `gcloud run deploy --source .`) because the
# Cloud Run image is built from Dockerfile.cloudrun, while the Dockerfile at
# the repo root is the ngrok/local variant that listens on port 5000.
PROJECT_ID=${GCP_PROJECT_ID:-""}
REGION=${GCP_REGION:-"us-central1"}
SERVICE_NAME="prisma-airs-streaming"
AR_REPO=${GCP_AR_REPO:-"prisma-airs"}
IMAGE_NAME="${REGION}-docker.pkg.dev/${PROJECT_ID}/${AR_REPO}/${SERVICE_NAME}:latest"

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

# Make sure the Artifact Registry repo exists. Creating it is idempotent enough
# here: we only create when the describe fails.
if ! gcloud artifacts repositories describe "${AR_REPO}" \
        --location "${REGION}" --project "${PROJECT_ID}" &> /dev/null; then
    echo "Artifact Registry repo '${AR_REPO}' not found in ${REGION}, creating it..."
    gcloud artifacts repositories create "${AR_REPO}" \
        --repository-format=docker \
        --location "${REGION}" \
        --project "${PROJECT_ID}" \
        --description "Prisma AIRS red teaming target images"
fi

# Build and push using Cloud Build (recommended) or Docker.
# Both paths target Artifact Registry; gcr.io no longer accepts writes.
if command -v docker &> /dev/null; then
    echo "Using Docker to build locally..."
    gcloud auth configure-docker "${REGION}-docker.pkg.dev" --quiet
    docker build -f Dockerfile.cloudrun -t ${IMAGE_NAME} .
    docker push ${IMAGE_NAME}
else
    echo "Using Cloud Build..."
    gcloud builds submit --config cloudbuild.yaml \
        --project "${PROJECT_ID}" \
        --substitutions "_REGION=${REGION},_AR_REPO=${AR_REPO},_IMAGE=${SERVICE_NAME},_TAG=latest" \
        .
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
echo "curl -X POST ${SERVICE_URL}/v1/chat/completions -H \"Content-Type: application/json\" -d '{\"messages\":[{\"role\":\"user\",\"content\":\"{INPUT}\"}],\"model\":\"gpt-4o-mini\",\"stream\":true}'"
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
