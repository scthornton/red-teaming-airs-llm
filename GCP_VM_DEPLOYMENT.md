# Deploying to GCP VM

If Cloud Run's authentication restrictions are blocking Red Teaming access, a simple GCP VM works great. Takes about 5 minutes to set up.

## Setup

Create the VM:

```bash
gcloud compute instances create prisma-airs-streaming-vm \
  --project=YOUR-PROJECT-ID \
  --zone=us-central1-a \
  --machine-type=e2-micro \
  --image-family=debian-12 \
  --image-project=debian-cloud \
  --boot-disk-size=10GB \
  --tags=http-server,https-server
```

Note the external IP from the output (you'll need it later).

Open the firewall for port 5000:

```bash
gcloud compute firewall-rules create allow-prisma-airs-app \
  --project=YOUR-PROJECT-ID \
  --allow=tcp:5000 \
  --source-ranges=0.0.0.0/0 \
  --target-tags=http-server,https-server
```

Copy the app files:

```bash
gcloud compute scp requirements.txt runtime_test_app_streaming.py prisma-airs-streaming-vm:~ \
  --zone=us-central1-a \
  --project=YOUR-PROJECT-ID
```

Install Python and dependencies:

```bash
gcloud compute ssh prisma-airs-streaming-vm --zone=us-central1-a --project=YOUR-PROJECT-ID --command="
  sudo apt-get update && \
  sudo apt-get install -y python3 python3-pip && \
  pip3 install -r requirements.txt --break-system-packages
"
```

Start the app (replace with your actual API key):

```bash
gcloud compute ssh prisma-airs-streaming-vm --zone=us-central1-a --project=YOUR-PROJECT-ID --command="
  export PANW_AI_SEC_API_KEY='your-key-here' && \
  export PRISMA_AIRS_PROFILE='chatbot' && \
  nohup python3 runtime_test_app_streaming.py > app.log 2>&1 &
"
```

Test it:

```bash
curl http://YOUR-EXTERNAL-IP:5000/health
```

## Red Teaming Configuration

Use the cURL import method in Red Teaming with this command:

```bash
curl -X POST http://YOUR-EXTERNAL-IP:5000/v1/chat/completions -H "Content-Type: application/json" -d '{"messages":[{"role":"user","content":"{INPUT}"}],"model":"gpt-3.5-turbo","stream":true}'
```

Replace `YOUR-EXTERNAL-IP` with your VM's external IP.

## Monitoring

Watch requests in real-time:

```bash
gcloud compute ssh prisma-airs-streaming-vm --zone=us-central1-a --project=YOUR-PROJECT-ID --command="tail -f app.log"
```

Check recent activity:

```bash
gcloud compute ssh prisma-airs-streaming-vm --zone=us-central1-a --project=YOUR-PROJECT-ID --command="tail -50 app.log"
```

Restart if needed:

```bash
gcloud compute ssh prisma-airs-streaming-vm --zone=us-central1-a --project=YOUR-PROJECT-ID --command="
  pkill -f runtime_test_app_streaming.py && \
  export PANW_AI_SEC_API_KEY='your-key-here' && \
  export PRISMA_AIRS_PROFILE='chatbot' && \
  nohup python3 runtime_test_app_streaming.py > app.log 2>&1 &
"
```

## Cleanup

Stop the VM when you're done testing to avoid charges:

```bash
gcloud compute instances stop prisma-airs-streaming-vm --zone=us-central1-a --project=YOUR-PROJECT-ID
```

Start it back up when needed:

```bash
gcloud compute instances start prisma-airs-streaming-vm --zone=us-central1-a --project=YOUR-PROJECT-ID
```

Delete everything when you're completely done:

```bash
gcloud compute instances delete prisma-airs-streaming-vm --zone=us-central1-a --project=YOUR-PROJECT-ID
gcloud compute firewall-rules delete allow-prisma-airs-app --project=YOUR-PROJECT-ID
```

## Notes

The e2-micro instance is free tier eligible in us-central1, us-west1, and us-east1 (one instance per month). After that it's about $7/month if you leave it running 24/7.

This VM is publicly accessible, so use test API keys only. Don't run this with production credentials.

For actual production use, Cloud Run with authentication is the better choice. This VM approach is specifically for Red Teaming tests where you need unauthenticated public access.
