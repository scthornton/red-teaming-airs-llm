# Cloud Run Quick Deploy - 5 Minutes

Deploy streaming app to Google Cloud Run in 5 minutes.

## Step 1: Prerequisites Check (1 minute)

```bash
# Check if gcloud is installed
which gcloud

# If not, install:
# macOS: curl https://sdk.cloud.google.com | bash
# Then: exec -l $SHELL
```

## Step 2: GCP Setup (2 minutes)

```bash
# Login
gcloud auth login

# Get your project ID (or create new project)
gcloud projects list

# Set project
export GCP_PROJECT_ID="your-project-id"
gcloud config set project $GCP_PROJECT_ID

# Enable APIs
gcloud services enable run.googleapis.com containerregistry.googleapis.com
```

## Step 3: Configure Environment (1 minute)

```bash
# Set your credentials
export PANW_AI_SEC_API_KEY="your-airs-api-key"
export PRISMA_AIRS_PROFILE="chatbot"
export OPENAI_API_KEY="sk-proj-your-key"  # Optional
```

## Step 4: Deploy! (1 minute)

```bash
./deploy-to-cloudrun.sh
```

**That's it!** The script will:
- Build Docker container
- Push to Google Container Registry
- Deploy to Cloud Run
- Give you a public HTTPS URL

## Step 5: Test

```bash
# Your URL will be shown in output, something like:
# https://prisma-airs-streaming-abc123-uc.a.run.app

curl https://YOUR-URL.run.app/health
```

## Add to Red Teaming

**For streaming testing:**
```bash
curl -X POST https://YOUR-URL.run.app/v1/chat/completions -H "Content-Type: application/json" -d '{"messages":[{"role":"user","content":"{INPUT}"}],"model":"gpt-3.5-turbo","stream":true}'
```

**For REST API (more reliable):**
```bash
curl -X POST https://YOUR-URL.run.app/v1/chat/completions -H "Content-Type: application/json" -d '{"messages":[{"role":"user","content":"{INPUT}"}],"model":"gpt-3.5-turbo"}'
```

Paste into SCM Red Teaming target cURL field.

## Monitor

```bash
# Watch logs during scan
gcloud run logs tail prisma-airs-streaming --region us-central1
```

## Done!

You now have:
- ✅ Permanent HTTPS URL
- ✅ No ngrok needed
- ✅ Production-grade infrastructure
- ✅ Auto-scaling
- ✅ Free tier (2M requests/month)

See CLOUDRUN_DEPLOYMENT.md for full guide.
