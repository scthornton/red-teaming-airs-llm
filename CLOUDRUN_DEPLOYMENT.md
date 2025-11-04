# Deploy to Google Cloud Run

Deploy the streaming test app to Google Cloud Run for persistent, production-like testing.

## Why Cloud Run?

✅ **No ngrok needed** - Get a permanent HTTPS URL
✅ **Better for streaming** - Production-grade infrastructure
✅ **Auto-scaling** - Handles multiple concurrent scans
✅ **Free tier** - 2 million requests/month free
✅ **Real-world testing** - Tests in cloud environment like production

---

## Prerequisites

### 1. Google Cloud Account

Sign up at: https://cloud.google.com (free tier available)

### 2. Install gcloud CLI

**macOS:**
```bash
curl https://sdk.cloud.google.com | bash
exec -l $SHELL
gcloud init
```

**Or download from:** https://cloud.google.com/sdk/docs/install

### 3. Create GCP Project

```bash
# List existing projects
gcloud projects list

# Or create new project
gcloud projects create prisma-airs-test --name="Prisma AIRS Testing"

# Set as active project
gcloud config set project prisma-airs-test
```

### 4. Enable Required APIs

```bash
# Enable Cloud Run and Container Registry
gcloud services enable run.googleapis.com
gcloud services enable containerregistry.googleapis.com
```

### 5. Set Up Authentication

```bash
# Login to GCP
gcloud auth login

# Configure Docker (if using local Docker build)
gcloud auth configure-docker
```

---

## Quick Deployment

### 1. Configure Environment

```bash
# Copy environment template
cp .env.cloudrun.example .env.cloudrun

# Edit with your values
nano .env.cloudrun
```

**Required values:**
```bash
GCP_PROJECT_ID=your-project-id
PANW_AI_SEC_API_KEY=your-airs-api-key
PRISMA_AIRS_PROFILE=chatbot
```

### 2. Load Environment

```bash
# Load variables
export $(cat .env.cloudrun | xargs)

# Verify
echo $GCP_PROJECT_ID
echo $PANW_AI_SEC_API_KEY
```

### 3. Deploy

```bash
./deploy-to-cloudrun.sh
```

**What happens:**
1. Builds Docker container
2. Pushes to Google Container Registry
3. Deploys to Cloud Run
4. Returns public HTTPS URL

**Output:**
```
🎉 Streaming App Deployed Successfully!
Service URL: https://prisma-airs-streaming-abc123-uc.a.run.app

📋 Test endpoints:
  Health check: https://prisma-airs-streaming-abc123-uc.a.run.app/health
```

---

## Testing Your Deployment

### 1. Health Check

```bash
curl https://YOUR-URL.run.app/health
```

**Expected:**
```json
{
  "status": "healthy",
  "runtime_security": "enabled (direct API)",
  "profile": "chatbot",
  "streaming": "supported (openai, textdelta, ndjson, simple)",
  "environment": "Google Cloud Run"
}
```

### 2. Test Non-Streaming

```bash
curl -X POST https://YOUR-URL.run.app/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"messages":[{"role":"user","content":"Hello"}],"model":"gpt-3.5-turbo"}'
```

### 3. Test Streaming (OpenAI format)

```bash
curl -N -X POST https://YOUR-URL.run.app/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"messages":[{"role":"user","content":"Hello"}],"model":"gpt-3.5-turbo","stream":true}'
```

**Expected (streaming chunks):**
```
data: {"id":"chatcmpl-...","choices":[{"delta":{"content":"This is a"},...}]}

data: {"id":"chatcmpl-...","choices":[{"delta":{"content":"safe streaming"},...}]}

data: [DONE]
```

### 4. Test Other Formats

**Text-delta:**
```bash
curl -N -X POST "https://YOUR-URL.run.app/v1/chat/completions?format=textdelta" \
  -H "Content-Type: application/json" \
  -d '{"messages":[{"role":"user","content":"Test"}],"stream":true}'
```

**NDJSON:**
```bash
curl -N -X POST "https://YOUR-URL.run.app/v1/chat/completions?format=ndjson" \
  -H "Content-Type: application/json" \
  -d '{"messages":[{"role":"user","content":"Test"}],"stream":true}'
```

---

## Add to Red Teaming

### 1. Log into SCM

https://strata.paloaltonetworks.com

### 2. Add Target

**Navigate to:** Insights → Prisma AIRS → Red Teaming → Targets

**Click:** + New Target

### 3. Choose Connection Method

**For Streaming Testing:**
- **Target Type:** Model
- **Connection Method:** Streaming

**Use this cURL (replace YOUR-URL):**
```bash
curl -X POST https://YOUR-URL.run.app/v1/chat/completions -H "Content-Type: application/json" -d '{"messages":[{"role":"user","content":"{INPUT}"}],"model":"gpt-3.5-turbo","stream":true}'
```

**For REST API (more reliable):**
- **Connection Method:** REST API

```bash
curl -X POST https://YOUR-URL.run.app/v1/chat/completions -H "Content-Type: application/json" -d '{"messages":[{"role":"user","content":"{INPUT}"}],"model":"gpt-3.5-turbo"}'
```

### 4. Run Scan

1. Navigate to: **Red Teaming → Scans**
2. Click **+ New Scan**
3. Select your Cloud Run target
4. Scan Type: **Attack Library**
5. Select categories
6. **Start Scan**

---

## Monitoring

### View Logs

**Real-time logs:**
```bash
gcloud run logs tail prisma-airs-streaming --region us-central1
```

**Recent logs:**
```bash
gcloud run logs read prisma-airs-streaming --region us-central1 --limit 100
```

**Watch for attack attempts:**
```
📨 Received prompt: Ignore all previous instructions...
🔄 Streaming: True (format: openai)
🔍 Scan result: malicious / block
🚫 BLOCKED - Returning security error
📡 Starting openai stream...
```

### Cloud Run Console

View in browser: https://console.cloud.google.com/run

Shows:
- Request count
- Latency
- Errors
- Resource usage
- Logs

---

## Updating Your Deployment

### After Code Changes

```bash
# Just run deployment script again
./deploy-to-cloudrun.sh
```

Cloud Run will:
1. Build new container
2. Deploy with zero downtime
3. Keep same URL

### Update Environment Variables

```bash
gcloud run services update prisma-airs-streaming \
  --region us-central1 \
  --set-env-vars PRISMA_AIRS_PROFILE=new-profile-name
```

---

## Cost Management

### Free Tier Limits

Cloud Run free tier (per month):
- **2 million requests** free
- **360,000 GB-seconds** compute time free
- **180,000 vCPU-seconds** free

**Estimate for Red Teaming:**
- Average scan: 100-500 requests
- Cost: ~$0 (within free tier)
- 1000 scans/month: Still free

### Monitor Costs

```bash
# Check current usage
gcloud run services describe prisma-airs-streaming \
  --region us-central1 \
  --format="value(status.traffic)"
```

**View billing:** https://console.cloud.google.com/billing

---

## Troubleshooting

### Deployment Fails

**Error:** "Permission denied"
```bash
# Ensure you're authenticated
gcloud auth login

# Ensure project is set
gcloud config set project YOUR_PROJECT_ID
```

**Error:** "API not enabled"
```bash
# Enable required APIs
gcloud services enable run.googleapis.com
gcloud services enable containerregistry.googleapis.com
```

### Service Won't Start

**Check logs:**
```bash
gcloud run logs read prisma-airs-streaming --region us-central1 --limit 50
```

**Common issues:**
- Missing PANW_AI_SEC_API_KEY
- Invalid API key
- Profile doesn't exist in SCM

### Streaming Doesn't Work

**Test locally first:**
```bash
curl -N -X POST https://YOUR-URL.run.app/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"messages":[{"role":"user","content":"test"}],"stream":true}'
```

**If local streaming works but Red Teaming fails:**
- This is a known Red Teaming limitation
- Use REST API mode instead
- See STREAMING_GUIDE.md for details

### High Latency

**Cloud Run cold starts:**
- First request after idle: 1-3 seconds
- Subsequent requests: <100ms

**Keep warm (costs money):**
```bash
gcloud run services update prisma-airs-streaming \
  --region us-central1 \
  --min-instances 1
```

---

## Cleanup

### Delete Service

```bash
gcloud run services delete prisma-airs-streaming --region us-central1
```

### Delete Container Images

```bash
# List images
gcloud container images list

# Delete specific image
gcloud container images delete gcr.io/YOUR_PROJECT/prisma-airs-streaming
```

---

## Advanced Configuration

### Custom Domain

```bash
# Map custom domain
gcloud run domain-mappings create \
  --service prisma-airs-streaming \
  --domain test.yourdomain.com \
  --region us-central1
```

### Increase Resources

```bash
gcloud run services update prisma-airs-streaming \
  --region us-central1 \
  --memory 1Gi \
  --cpu 2 \
  --timeout 600
```

### Authentication

**Require authentication:**
```bash
gcloud run services update prisma-airs-streaming \
  --region us-central1 \
  --no-allow-unauthenticated
```

Then use service account credentials for Red Teaming.

### Multiple Regions

Deploy to multiple regions for redundancy:

```bash
# US
./deploy-to-cloudrun.sh  # us-central1

# Europe
export GCP_REGION=europe-west1
./deploy-to-cloudrun.sh

# Asia
export GCP_REGION=asia-east1
./deploy-to-cloudrun.sh
```

---

## Comparison: Cloud Run vs. ngrok

| Feature | Cloud Run | ngrok |
|---------|-----------|-------|
| **URL** | Permanent HTTPS | Changes on restart (free) |
| **Uptime** | 24/7 | Only while running |
| **Performance** | Production-grade | Development proxy |
| **Scaling** | Auto-scales | Single instance |
| **Cost** | Free tier generous | Free tier limited |
| **Setup** | One-time deployment | Manual each time |
| **Monitoring** | Full GCP logs | Web interface |
| **Best For** | Production testing | Quick local testing |

---

## Security Considerations

**⚠️ Current Deployment:**
- Service is publicly accessible (--allow-unauthenticated)
- Runtime Security scans all requests
- API keys in environment variables (secure)

**For Production:**
1. Enable authentication:
   ```bash
   gcloud run services update prisma-airs-streaming \
     --no-allow-unauthenticated
   ```
2. Use Secret Manager for API keys:
   ```bash
   echo -n "your-api-key" | gcloud secrets create panw-api-key --data-file=-
   ```
3. Implement rate limiting
4. Use Cloud Armor for DDoS protection

---

## Next Steps

1. ✅ Deploy to Cloud Run
2. ✅ Test all endpoints
3. ✅ Add to Red Teaming
4. ✅ Run streaming scan
5. ✅ Compare results with ngrok/local testing
6. ✅ Monitor logs during scan
7. ✅ Document streaming behavior

---

**Ready to deploy?**

```bash
# 1. Configure
export $(cat .env.cloudrun | xargs)

# 2. Deploy
./deploy-to-cloudrun.sh

# 3. Test
curl https://YOUR-URL.run.app/health

# 4. Add to Red Teaming!
```

See you in the cloud! ☁️
