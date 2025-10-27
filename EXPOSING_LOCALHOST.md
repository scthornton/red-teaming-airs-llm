# Exposing Localhost for Red Teaming

## The Problem

Red Teaming runs in Palo Alto's cloud infrastructure and cannot reach `http://localhost:5000` on your machine. You need to expose your local test application to the internet.

## Solutions

### Option 1: ngrok (Recommended for Testing)

**What is ngrok?**
ngrok creates a secure tunnel from a public URL to your localhost, allowing Red Teaming to reach your test application. The free version has some limitations, just beware.

**Install ngrok:**
```bash
# macOS
brew install ngrok

# Or download from https://ngrok.com/download
```

**Setup:**
```bash
# 1. Sign up for free account at https://ngrok.com
# 2. Get your authtoken from dashboard
# 3. Configure ngrok
ngrok config add-authtoken YOUR_AUTHTOKEN
```

**Start tunnel:**
```bash
# In a new terminal (keep the app running in another terminal)
ngrok http 5000
```

**You'll see output like:**
```
Session Status                online
Account                       your-email@example.com
Version                       3.5.0
Region                        United States (us)
Latency                       -
Web Interface                 http://127.0.0.1:4040
Forwarding                    https://abc123def456.ngrok-free.app -> http://localhost:5000
```

**Use in Red Teaming:**
- Copy the `https://` URL (e.g., `https://abc123def456.ngrok-free.app`)
- Add as target in SCM: `https://abc123def456.ngrok-free.app/v1/chat/completions`

**Pros:**
- ✅ Free tier available
- ✅ HTTPS automatically
- ✅ No server setup required
- ✅ Works immediately
- ✅ Can inspect all requests at http://localhost:4040

**Cons:**
- ⚠️ URL changes each time you restart (unless you pay for static domain)
- ⚠️ Free tier has request limits
- ⚠️ Requires ngrok to be running

### Option 2: Cloudflare Tunnel (Free, Persistent)

**Install cloudflared:**
```bash
brew install cloudflare/cloudflare/cloudflared
```

**Setup:**
```bash
# Login to Cloudflare
cloudflared tunnel login

# Create a tunnel
cloudflared tunnel create red-teaming-test

# Configure tunnel
cat > ~/.cloudflared/config.yml <<EOF
tunnel: YOUR_TUNNEL_ID
credentials-file: /Users/scott/.cloudflared/YOUR_TUNNEL_ID.json

ingress:
  - hostname: red-team-test.yourdomain.com
    service: http://localhost:5000
  - service: http_status:404
EOF

# Run tunnel
cloudflared tunnel run red-teaming-test
```

**Pros:**
- ✅ Completely free
- ✅ Persistent URL
- ✅ HTTPS automatically
- ✅ Better performance than ngrok

**Cons:**
- ⚠️ Requires a domain name
- ⚠️ More complex setup

### Option 3: Deploy to Cloud (Production-Ready)

Deploy the test application to a real server for persistent testing.

**AWS EC2:**
```bash
# 1. Create EC2 instance (t2.micro free tier)
# 2. SSH to instance
# 3. Install Python and dependencies
# 4. Run application
# 5. Configure security group to allow port 5000
# 6. Use public IP or domain
```

**Pros:**
- ✅ Production-like environment
- ✅ Persistent
- ✅ No tunneling required
- ✅ Can run 24/7

**Cons:**
- ⚠️ Costs money (unless free tier)
- ⚠️ Requires server management
- ⚠️ More complex setup

## Recommended Workflow

### For Quick Testing (Use ngrok)

**Terminal 1 - Run Application:**
```bash
cd /Users/scott/perfecxion/prisma-airs/red-teaming
source .venv/bin/activate
python runtime_test_app_direct_api.py
```

**Terminal 2 - Start ngrok:**
```bash
ngrok http 5000
```

**Terminal 3 - Test Locally First:**
```bash
# Get the ngrok URL from Terminal 2
NGROK_URL="https://abc123def456.ngrok-free.app"

# Test it works
curl $NGROK_URL/health
```

**Expected:**
```json
{
  "api_url": "https://service.api.aisecurity.paloaltonetworks.com/v1/scan/sync/request",
  "llm": "openai",
  "profile": "advancedtest",
  "runtime_security": "enabled (direct API)",
  "status": "healthy"
}
```

### Add to Red Teaming

1. Log into [Strata Cloud Manager](https://strata.paloaltonetworks.com)
2. Navigate to: **Insights → Prisma AIRS → Red Teaming → Targets**
3. Click **+ New Target**

**Configure:**
- **Name:** Runtime Security Test (advancedtest profile)
- **Type:** Application
- **Connection Method:** REST API
- **Endpoint Accessibility:** Public
- **API Endpoint:** `https://YOUR-NGROK-URL.ngrok-free.app/v1/chat/completions`

**Request JSON:**
```json
{
  "messages": [
    {
      "role": "user",
      "content": "{INPUT}"
    }
  ],
  "model": "gpt-3.5-turbo"
}
```

**Response JSON Path:**
```json
{
  "choices": [
    {
      "message": {
        "content": "{RESPONSE}"
      }
    }
  ]
}
```

4. Click **Add Target**
5. Navigate to: **Red Teaming → Scans**
6. Click **+ New Scan**
7. Select your target
8. Scan Type: **Attack Library**
9. Select categories (Prompt Injection, Jailbreak, etc.)
10. Click **Start Scan**

## Security Considerations

**⚠️ IMPORTANT:**
- Your test app will be publicly accessible while ngrok/tunnel is running
- Anyone with the URL can send requests
- Runtime Security will scan all requests, but you're still exposing your API key
- **DO NOT** use production API keys for this testing
- **DO NOT** leave tunnels running when not testing
- Monitor ngrok web interface (http://localhost:4040) to see all incoming requests

**For production testing:**
- Deploy to cloud with proper authentication
- Use IP whitelisting if possible
- Implement rate limiting
- Use short-lived credentials

## Monitoring Your Test

**ngrok Web Interface:**
```bash
# Open in browser
open http://localhost:4040
```

Shows:
- All HTTP requests received
- Request/response details
- Timing information
- Perfect for debugging Red Teaming scans

**Application Logs:**
Watch your application terminal for:
```
📨 Received prompt: Ignore all previous instructions...
🔍 Scan result: malicious / block
⚠️  Detected threats: injection
🚫 BLOCKED - Returning security error
```

## Troubleshooting

### ngrok "Failed to connect"
- Check your test app is running on port 5000
- Try: `curl http://localhost:5000/health`
- Restart ngrok: `pkill ngrok && ngrok http 5000`

### Red Teaming can't reach endpoint
- Verify ngrok URL is accessible: `curl https://YOUR-URL.ngrok-free.app/health`
- Check firewall rules
- Ensure ngrok is still running (URLs expire on free tier)

### Red Teaming scan shows errors
- Check application logs for errors
- Verify Runtime Security API key is valid
- Check `advancedtest` profile exists in SCM
- Test endpoint manually with curl first

## Quick Reference

**Start everything:**
```bash
# Terminal 1: Run app
cd /Users/scott/perfecxion/prisma-airs/red-teaming
source .venv/bin/activate
python runtime_test_app_direct_api.py

# Terminal 2: Start ngrok
ngrok http 5000

# Terminal 3: Test
curl https://YOUR-NGROK-URL.ngrok-free.app/health
```

**Stop everything:**
```bash
# Ctrl+C in Terminal 1 (app)
# Ctrl+C in Terminal 2 (ngrok)
```

---

**Next Steps:**
1. Install ngrok: `brew install ngrok`
2. Create free account: https://ngrok.com
3. Start tunnel: `ngrok http 5000`
4. Add target in SCM with ngrok URL
5. Run Red Teaming scan
6. Watch results and application logs
