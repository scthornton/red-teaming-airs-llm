# Docker Without ngrok

Simple Docker setup that runs the app without ngrok. Use this for:
- Local development and testing
- Running on GCP VM with direct port exposure
- Any environment where you have direct network access

## Local Usage (No Red Teaming Access)

**Quick start:**
```bash
# 1. Configure environment
cp .env.example .env
# Edit .env with your API key

# 2. Start container
./docker-simple-start.sh
```

**Access locally:**
```bash
curl http://localhost:5000/health
```

**Stop container:**
```bash
docker-compose -f docker-compose.simple.yml down
```

**View logs:**
```bash
docker-compose -f docker-compose.simple.yml logs -f
```

## Deploy Docker to GCP VM (For Red Teaming)

Run the Docker container on a GCP VM to get public access without ngrok or Cloud Run auth restrictions.

**1. Create VM with Docker pre-installed:**
```bash
gcloud compute instances create prisma-airs-docker-vm \
  --project=YOUR-PROJECT-ID \
  --zone=us-central1-a \
  --machine-type=e2-small \
  --image-family=cos-stable \
  --image-project=cos-cloud \
  --boot-disk-size=10GB \
  --tags=http-server,https-server
```

**2. Open firewall:**
```bash
gcloud compute firewall-rules create allow-prisma-airs-docker \
  --project=YOUR-PROJECT-ID \
  --allow=tcp:5000 \
  --source-ranges=0.0.0.0/0 \
  --target-tags=http-server,https-server
```

**3. Copy files to VM:**
```bash
gcloud compute scp \
  requirements.txt \
  runtime_test_app_streaming.py \
  Dockerfile.simple \
  docker-compose.simple.yml \
  prisma-airs-docker-vm:~ \
  --zone=us-central1-a \
  --project=YOUR-PROJECT-ID
```

**4. SSH and start container:**
```bash
gcloud compute ssh prisma-airs-docker-vm --zone=us-central1-a --project=YOUR-PROJECT-ID
```

Once on the VM:
```bash
# Create .env file
cat > .env << 'EOF'
PANW_AI_SEC_API_KEY=your-key-here
PRISMA_AIRS_PROFILE=chatbot
OPENAI_API_KEY=
EOF

# Start container (Container OS has docker-compose)
docker-compose -f docker-compose.simple.yml up -d

# Verify it's running
curl http://localhost:5000/health
```

**5. Get external IP:**
```bash
gcloud compute instances describe prisma-airs-docker-vm \
  --zone=us-central1-a \
  --project=YOUR-PROJECT-ID \
  --format='get(networkInterfaces[0].accessConfigs[0].natIP)'
```

**6. Test from your machine:**
```bash
curl http://EXTERNAL-IP:5000/health
```

**Red Teaming cURL:**
```bash
curl -X POST http://EXTERNAL-IP:5000/v1/chat/completions -H "Content-Type: application/json" -d '{"messages":[{"role":"user","content":"{INPUT}"}],"model":"gpt-3.5-turbo","stream":true}'
```

## Managing Docker Container on VM

**View logs:**
```bash
gcloud compute ssh prisma-airs-docker-vm --zone=us-central1-a --project=YOUR-PROJECT-ID --command="docker-compose -f docker-compose.simple.yml logs -f"
```

**Restart container:**
```bash
gcloud compute ssh prisma-airs-docker-vm --zone=us-central1-a --project=YOUR-PROJECT-ID --command="docker-compose -f docker-compose.simple.yml restart"
```

**Stop container:**
```bash
gcloud compute ssh prisma-airs-docker-vm --zone=us-central1-a --project=YOUR-PROJECT-ID --command="docker-compose -f docker-compose.simple.yml down"
```

**Update app code:**
```bash
# Copy new version
gcloud compute scp runtime_test_app_streaming.py prisma-airs-docker-vm:~ \
  --zone=us-central1-a --project=YOUR-PROJECT-ID

# Restart container
gcloud compute ssh prisma-airs-docker-vm --zone=us-central1-a --project=YOUR-PROJECT-ID --command="docker-compose -f docker-compose.simple.yml restart"
```

## Cleanup

**Stop VM:**
```bash
gcloud compute instances stop prisma-airs-docker-vm \
  --zone=us-central1-a \
  --project=YOUR-PROJECT-ID
```

**Delete everything:**
```bash
gcloud compute instances delete prisma-airs-docker-vm \
  --zone=us-central1-a \
  --project=YOUR-PROJECT-ID

gcloud compute firewall-rules delete allow-prisma-airs-docker \
  --project=YOUR-PROJECT-ID
```

## Files Included

- **Dockerfile.simple** - Docker image without ngrok
- **docker-compose.simple.yml** - Compose config without ngrok
- **docker-simple-start.sh** - Quick start script for local use

## Differences from Main Docker Setup

| Feature | Main Docker | Simple Docker |
|---------|-------------|---------------|
| ngrok included | ✅ Yes | ❌ No |
| Local development | ✅ Yes | ✅ Yes |
| Auto public URL | ✅ Yes | ❌ No |
| Red Teaming access | ✅ Direct | ⚠️ Requires VM/Cloud |
| Image size | Larger | Smaller |
| Setup complexity | More | Less |

## When to Use What

**Use Main Docker (with ngrok):**
- Testing from your laptop
- Don't want to set up cloud infrastructure
- Need quick public URL

**Use Simple Docker:**
- Local development without public access
- Deploying to VM with public IP
- Want minimal Docker image
- Don't need ngrok overhead

**Use GCP VM (no Docker):**
- Simplest cloud deployment
- Don't need containerization
- See GCP_VM_DEPLOYMENT.md

**Use Cloud Run:**
- Production deployment
- Need auto-scaling
- Can handle authentication requirements
- See CLOUDRUN_QUICKSTART.md
