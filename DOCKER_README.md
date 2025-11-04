# Docker Setup for Prisma AIRS Red Teaming

Run the Prisma AIRS red teaming test environment in Docker with ngrok tunneling built-in.

## Quick Start (5 minutes)

### 1. Prerequisites

- Docker installed ([Get Docker](https://docs.docker.com/get-docker/))
- Docker Compose installed (included with Docker Desktop)
- ngrok account ([Sign up free](https://ngrok.com))
- Prisma AIRS API key from Strata Cloud Manager

### 2. Setup Environment Variables

```bash
# Copy the example file
cp .env.example .env

# Edit with your actual credentials
nano .env  # or use your favorite editor
```

**Required values in `.env`:**
```bash
PANW_AI_SEC_API_KEY=your-actual-api-key
NGROK_AUTHTOKEN=your-actual-ngrok-token
PRISMA_AIRS_PROFILE=chatbot
OPENAI_API_KEY=sk-proj-your-key  # Optional
```

### 3. Start Everything

```bash
# Build and start the container
docker-compose up --build
```

**Expected output:**
```
🐳 Starting Prisma AIRS Red Teaming Test Environment
🔧 Configuring ngrok...
🚀 Starting Flask application...
✅ Flask app is healthy
🌐 Starting ngrok tunnel...

started tunnel    url=https://xyz123.ngrok-free.dev
```

### 4. Get Your Public URL

**Option A: From logs**
```bash
# Look for this line in the output
started tunnel    url=https://xyz123.ngrok-free.dev
```

**Option B: From ngrok web interface**
```bash
# Open in browser:
http://localhost:4040
```

### 5. Test It Works

```bash
# Replace with YOUR ngrok URL from step 4
curl https://YOUR-URL.ngrok-free.dev/health
```

**Expected:**
```json
{
  "status": "healthy",
  "profile": "chatbot",
  "runtime_security": "enabled (direct API)",
  "llm": "openai"
}
```

---

## Usage

### Start the Container
```bash
docker-compose up
```

### Start in Background (Detached)
```bash
docker-compose up -d
```

### View Logs
```bash
docker-compose logs -f
```

### Stop Everything
```bash
docker-compose down
```

### Restart
```bash
docker-compose restart
```

### Rebuild After Code Changes
```bash
docker-compose up --build
```

---

## Adding to Red Teaming

Once your container is running:

1. **Get ngrok URL** from logs or http://localhost:4040
2. **Log into SCM:** https://strata.paloaltonetworks.com
3. **Navigate to:** Insights → Prisma AIRS → Red Teaming → Targets
4. **Click:** + New Target

**Use this cURL command:**
```bash
curl -X POST https://YOUR-NGROK-URL.ngrok-free.dev/v1/chat/completions -H "Content-Type: application/json" -d '{"messages":[{"role":"user","content":"{INPUT}"}],"model":"gpt-3.5-turbo"}'
```

---

## Accessing Services

| Service | URL | Purpose |
|---------|-----|---------|
| Flask App | http://localhost:5000 | Test application endpoint |
| Health Check | http://localhost:5000/health | Verify app is running |
| ngrok Web UI | http://localhost:4040 | View all HTTP requests |
| Public Endpoint | https://xyz.ngrok-free.dev | Red Teaming access |

---

## Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `PANW_AI_SEC_API_KEY` | Yes | - | Prisma AIRS Runtime Security API key |
| `NGROK_AUTHTOKEN` | Yes | - | ngrok authentication token |
| `PRISMA_AIRS_PROFILE` | No | `chatbot` | Security profile name in SCM |
| `OPENAI_API_KEY` | No | - | OpenAI API key (uses mocks if not provided) |

---

## Troubleshooting

### Container Won't Start

**Check logs:**
```bash
docker-compose logs
```

**Common issues:**
- Missing environment variables
- Invalid API keys
- Port 5000 or 4040 already in use

**Fix port conflicts:**
```bash
# Find what's using the port
lsof -i :5000
lsof -i :4040

# Kill the process
kill -9 <PID>
```

### ngrok URL Not Working

**Verify ngrok is running:**
```bash
docker-compose logs | grep "started tunnel"
```

**Check ngrok auth token:**
```bash
# View current config
docker-compose exec red-team-app ngrok config check
```

**Restart container:**
```bash
docker-compose restart
```

### API Key Issues

**Test Runtime Security API:**
```bash
docker-compose exec red-team-app curl -X POST \
  https://service.api.aisecurity.paloaltonetworks.com/v1/scan/sync/request \
  -H "x-pan-token: $PANW_AI_SEC_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"profile":"chatbot","prompt":"test"}'
```

### View Container Internals

```bash
# Enter container shell
docker-compose exec red-team-app bash

# Check environment variables
docker-compose exec red-team-app env | grep -E "PANW|NGROK|PRISMA"

# Test local Flask app
docker-compose exec red-team-app curl http://localhost:5000/health
```

---

## Advanced Configuration

### Custom Port Mapping

Edit `docker-compose.yml`:
```yaml
ports:
  - "8080:5000"   # Map host port 8080 to container port 5000
  - "8040:4040"   # Map host port 8040 to container port 4040
```

### Use Specific Python Version

Edit `Dockerfile`:
```dockerfile
FROM python:3.12-slim  # Change from 3.11
```

### Add Custom Dependencies

Edit `requirements.txt`, then rebuild:
```bash
docker-compose up --build
```

### Persistent ngrok URL (Paid Plan)

If you have ngrok Pro/Enterprise with a custom domain:

Edit `start-docker.sh`:
```bash
# Replace this line:
exec ngrok http 5000 --log=stdout

# With:
exec ngrok http 5000 --domain=your-custom-domain.ngrok.app --log=stdout
```

---

## Production Considerations

### Don't Use This for Production!

This setup is for **testing only**:
- ⚠️ Flask development server (not production-grade)
- ⚠️ ngrok free tier (URLs change on restart)
- ⚠️ Exposed API keys in environment variables

### For Production Testing:

1. **Deploy to cloud provider** (AWS, GCP, Azure)
2. **Use production WSGI server** (gunicorn, uvicorn)
3. **Implement proper authentication**
4. **Use secrets management** (AWS Secrets Manager, etc.)
5. **Set up monitoring and logging**

---

## Team Sharing

### Share the Setup

1. Push Docker files to your repo
2. Team members clone the repo
3. They create their own `.env` file
4. Run `docker-compose up`

### .gitignore Recommendations

```bash
# Add to .gitignore
.env
.env.local
```

**Never commit `.env` with real credentials!**

---

## Cleanup

### Stop and Remove Container
```bash
docker-compose down
```

### Remove Images
```bash
docker-compose down --rmi all
```

### Remove Everything (Including Volumes)
```bash
docker-compose down -v --rmi all
```

### Remove Unused Docker Resources
```bash
docker system prune -a
```

---

## FAQ

**Q: Do I need to install Python locally?**
A: No! Docker contains everything needed.

**Q: Will my ngrok URL change?**
A: Yes, on free tier. Upgrade to ngrok Pro for static domains.

**Q: Can I run multiple instances?**
A: Yes, but change port mappings to avoid conflicts.

**Q: How do I update the code?**
A: Edit `runtime_test_app_direct_api.py`, then run `docker-compose up --build`

**Q: Can I use this on Windows?**
A: Yes! Docker Desktop supports Windows, Mac, and Linux.

**Q: How do I see what Red Teaming is sending?**
A: Open http://localhost:4040 to see all requests in ngrok's web interface.

---

## Next Steps

1. ✅ Container running
2. ✅ ngrok tunnel active
3. ✅ Health check passing
4. **➡️ Add target in Red Teaming**
5. **➡️ Run your first scan**
6. **➡️ Review results and strengthen profiles**

See `START_HERE.md` for Red Teaming configuration details.

---

## Support

**Issues?**
- Check logs: `docker-compose logs`
- Verify `.env` file has correct values
- Ensure Docker is running
- Try rebuilding: `docker-compose up --build`

**Still stuck?**
- Review `TROUBLESHOOTING.md`
- Check Docker daemon: `docker info`
- Verify network connectivity: `docker-compose exec red-team-app ping google.com`
