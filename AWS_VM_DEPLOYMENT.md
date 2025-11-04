# Deploying to AWS EC2

If Cloud Run's auth blocks Red Teaming, or you prefer AWS, this works great. Takes about 5 minutes.

## Setup

Create a security group for port 5000:

```bash
aws ec2 create-security-group \
  --group-name prisma-airs-app \
  --description "Allow port 5000 for Prisma AIRS test app"

# Note the GroupId from the output
```

Open the firewall:

```bash
aws ec2 authorize-security-group-ingress \
  --group-name prisma-airs-app \
  --protocol tcp \
  --port 5000 \
  --cidr 0.0.0.0/0

# Also allow SSH
aws ec2 authorize-security-group-ingress \
  --group-name prisma-airs-app \
  --protocol tcp \
  --port 22 \
  --cidr 0.0.0.0/0
```

Launch the instance:

```bash
aws ec2 run-instances \
  --image-id ami-06db4d78cb1d3c39c \
  --instance-type t3.micro \
  --key-name YOUR-KEY-PAIR-NAME \
  --security-groups prisma-airs-app \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=prisma-airs-streaming-vm}]'
```

Get the public IP:

```bash
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=prisma-airs-streaming-vm" \
  --query "Reservations[0].Instances[0].PublicIpAddress" \
  --output text
```

Copy the app files:

```bash
scp -i ~/.ssh/YOUR-KEY.pem \
  requirements.txt runtime_test_app_streaming.py \
  ubuntu@YOUR-PUBLIC-IP:~/
```

Install Python and dependencies:

```bash
ssh -i ~/.ssh/YOUR-KEY.pem ubuntu@YOUR-PUBLIC-IP << 'EOF'
sudo apt-get update
sudo apt-get install -y python3 python3-pip
pip3 install -r requirements.txt --break-system-packages
exit
EOF
```

Start the app:

```bash
ssh -i ~/.ssh/YOUR-KEY.pem ubuntu@YOUR-PUBLIC-IP << 'EOF'
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
ssh -i ~/.ssh/YOUR-KEY.pem ubuntu@YOUR-PUBLIC-IP "tail -f app.log"
```

Check recent activity:

```bash
ssh -i ~/.ssh/YOUR-KEY.pem ubuntu@YOUR-PUBLIC-IP "tail -50 app.log"
```

Restart if needed:

```bash
ssh -i ~/.ssh/YOUR-KEY.pem ubuntu@YOUR-PUBLIC-IP << 'EOF'
pkill -f runtime_test_app_streaming.py
export PANW_AI_SEC_API_KEY='your-key-here'
export PRISMA_AIRS_PROFILE='chatbot'
nohup python3 runtime_test_app_streaming.py > app.log 2>&1 &
EOF
```

## Cleanup

Stop the instance:

```bash
aws ec2 stop-instances \
  --instance-ids $(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=prisma-airs-streaming-vm" \
    --query "Reservations[0].Instances[0].InstanceId" \
    --output text)
```

Start it back up:

```bash
aws ec2 start-instances \
  --instance-ids $(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=prisma-airs-streaming-vm" \
    --query "Reservations[0].Instances[0].InstanceId" \
    --output text)
```

Delete everything:

```bash
# Terminate instance
aws ec2 terminate-instances \
  --instance-ids $(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=prisma-airs-streaming-vm" \
    --query "Reservations[0].Instances[0].InstanceId" \
    --output text)

# Delete security group (wait until instance is terminated)
aws ec2 delete-security-group --group-name prisma-airs-app
```

## Notes

The t3.micro instance is free tier eligible for the first 12 months (750 hours/month). After that it's about $8/month if left running 24/7.

The AMI ID shown (ami-06db4d78cb1d3c39c) is Ubuntu 22.04 LTS in us-east-1. For other regions, find the Ubuntu AMI ID here: https://cloud-images.ubuntu.com/locator/ec2/

This VM is publicly accessible, so use test API keys only. Don't run with production credentials.

For production use, add proper IAM roles and VPC security groups. This VM approach is for Red Teaming tests where you need unauthenticated public access.
