# Deploying to Azure VM

If Cloud Run's auth blocks Red Teaming, or you prefer Azure, this works great. Takes about 5 minutes.

## Setup

Create the VM:

```bash
az vm create \
  --resource-group YOUR-RESOURCE-GROUP \
  --name prisma-airs-streaming-vm \
  --image Debian11 \
  --size Standard_B1s \
  --admin-username azureuser \
  --generate-ssh-keys \
  --public-ip-sku Standard
```

Note the public IP from the output.

Open the firewall for port 5000:

```bash
az vm open-port \
  --resource-group YOUR-RESOURCE-GROUP \
  --name prisma-airs-streaming-vm \
  --port 5000 \
  --priority 1001
```

Copy the app files:

```bash
az vm run-command invoke \
  --resource-group YOUR-RESOURCE-GROUP \
  --name prisma-airs-streaming-vm \
  --command-id RunShellScript \
  --scripts "mkdir -p /home/azureuser/app"

scp -i ~/.ssh/id_rsa \
  requirements.txt runtime_test_app_streaming.py \
  azureuser@YOUR-PUBLIC-IP:/home/azureuser/app/
```

Install Python and dependencies:

```bash
az vm run-command invoke \
  --resource-group YOUR-RESOURCE-GROUP \
  --name prisma-airs-streaming-vm \
  --command-id RunShellScript \
  --scripts "
    sudo apt-get update && \
    sudo apt-get install -y python3 python3-pip && \
    cd /home/azureuser/app && \
    pip3 install -r requirements.txt --break-system-packages
  "
```

Start the app:

```bash
ssh azureuser@YOUR-PUBLIC-IP << 'EOF'
cd /home/azureuser/app
export PANW_AI_SEC_API_KEY='your-key-here'
export PRISMA_AIRS_PROFILE='chatbot'
nohup python3 runtime_test_app_streaming.py > app.log 2>&1 &
exit
EOF
```

Test it:

```bash
curl http://YOUR-PUBLIC-IP:5000/health
```

## Red Teaming Configuration

Use the cURL import method with this command:

```bash
curl -X POST http://YOUR-PUBLIC-IP:5000/v1/chat/completions -H "Content-Type: application/json" -d '{"messages":[{"role":"user","content":"{INPUT}"}],"model":"gpt-3.5-turbo","stream":true}'
```

## Monitoring

Watch requests:

```bash
ssh azureuser@YOUR-PUBLIC-IP "tail -f /home/azureuser/app/app.log"
```

Check recent activity:

```bash
ssh azureuser@YOUR-PUBLIC-IP "tail -50 /home/azureuser/app/app.log"
```

Restart if needed:

```bash
ssh azureuser@YOUR-PUBLIC-IP << 'EOF'
pkill -f runtime_test_app_streaming.py
cd /home/azureuser/app
export PANW_AI_SEC_API_KEY='your-key-here'
export PRISMA_AIRS_PROFILE='chatbot'
nohup python3 runtime_test_app_streaming.py > app.log 2>&1 &
EOF
```

## Cleanup

Stop the VM:

```bash
az vm deallocate \
  --resource-group YOUR-RESOURCE-GROUP \
  --name prisma-airs-streaming-vm
```

Start it back up:

```bash
az vm start \
  --resource-group YOUR-RESOURCE-GROUP \
  --name prisma-airs-streaming-vm
```

Delete everything:

```bash
az vm delete \
  --resource-group YOUR-RESOURCE-GROUP \
  --name prisma-airs-streaming-vm \
  --yes
```

## Notes

The Standard_B1s instance costs about $8/month if left running 24/7.

This VM is publicly accessible, so use test API keys only. Don't run with production credentials.

For production use, add proper authentication and network security groups. This VM approach is for Red Teaming tests where you need unauthenticated public access.
