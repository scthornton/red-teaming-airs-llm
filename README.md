# Prisma AIRS Red Teaming + Runtime Security Test Setup

[![Python 3.8+](https://img.shields.io/badge/python-3.8+-blue.svg)](https://www.python.org/downloads/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

This package allows you to test **Prisma AIRS Runtime Security** effectiveness by using **AI Red Teaming** to attack a protected test application.

**Author:** Scott Thornton

## What This Does...

```
┌─────────────────┐
│  AI Red Teaming │  Sends attack prompts
│  (Cloud-based)  │
└────────┬────────┘
         │
         ▼  (via ngrok tunnel)
┌─────────────────┐
│  Test App       │  Flask app on localhost:5000
│  (This package) │
└────────┬────────┘
         │
         ▼  Scans all prompts
┌─────────────────┐
│  Runtime        │  Blocks malicious, allows benign
│  Security API   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  LLM Response   │  OpenAI or mock response
│  (Optional)     │
└─────────────────┘
```

**Goal:** Validate that Runtime Security blocks Red Team attacks while allowing legitimate prompts through.

## Quick Start

**Three deployment options:**

1. **🐳 Docker (Recommended)** - One command, fully containerized
2. **☁️ Cloud Run** - Production deployment on GCP
3. **🐍 Manual Setup** - Traditional Python virtualenv

### Option 1: Docker Quick Start (Recommended)

**Prerequisites:**
- Docker Desktop installed and running
- ngrok account (free) from https://ngrok.com

**One-command setup:**
```bash
# 1. Copy environment template
cp .env.example .env

# 2. Edit .env with your credentials:
#    - PANW_AI_SEC_API_KEY
#    - NGROK_AUTHTOKEN
#    - PRISMA_AIRS_PROFILE

# 3. Start everything
./docker-quickstart.sh
```

That's it! The container:
- Starts Flask app on port 5000
- Configures and starts ngrok tunnel
- Shows your public HTTPS URL
- Provides ngrok web UI at http://localhost:4040

See **[DOCKER_README.md](DOCKER_README.md)** for complete Docker documentation.

### Option 2: Cloud Run Deployment

Deploy to Google Cloud for production-like testing without ngrok:

**5-minute setup:**
```bash
# 1. Copy Cloud Run environment template
cp .env.cloudrun.example .env.cloudrun

# 2. Edit with your GCP project ID and API key

# 3. Deploy
./deploy-to-cloudrun.sh
```

Returns a permanent HTTPS URL for Red Teaming configuration.

See **[CLOUDRUN_QUICKSTART.md](CLOUDRUN_QUICKSTART.md)** for details.

### Option 3: Manual Python Setup

**1. Install Dependencies**

```bash
./setup.sh
```

This creates a Python virtual environment and installs required packages.

**2. Configure Credentials**

```bash
export PANW_AI_SEC_API_KEY="your-runtime-security-api-key"
export PRISMA_AIRS_PROFILE="your-security-profile-name"
```

Or create .env file:
```bash
cp .env.example .env
# Edit .env with your credentials
```

**Get Your Credentials:**
- Log into [Strata Cloud Manager](https://strata.paloaltonetworks.com)
- Navigate to: **Settings → Prisma AIRS → Runtime Security**
- Copy your API Key and Security Profile name

**3. Start Test Application**

```bash
./start_test_app.sh
```

**4. Expose with ngrok** (in new terminal):

```bash
ngrok http 5000
```

Copy the HTTPS URL shown.

## Configuring Red Teaming Target

### Method 1: cURL Import (Recommended)

**Why this works:** Red Teaming's cURL import parser works best with:
- Single-line JSON (no line breaks)
- Minimal headers (just Content-Type)
- Standard short flags (-X, -H, -d)

**Copy this exact format:**

```bash
curl -X POST https://YOUR-NGROK-URL.ngrok-free.dev/v1/chat/completions -H "Content-Type: application/json" -d '{"messages":[{"role":"user","content":"{INPUT}"}],"model":"gpt-3.5-turbo"}'
```

**To configure in Red Teaming:**

1. Log into [Strata Cloud Manager](https://strata.paloaltonetworks.com)
2. Navigate to: **Insights → Prisma AIRS → Red Teaming → Targets**
3. Click **+ New Target**
4. Choose **Import from cURL**
5. Paste the cURL command above (with your actual ngrok URL)
6. Click **Import**

Done! The parser automatically extracts:
- Endpoint URL
- Headers
- Request body format
- Response structure

### Method 2: Manual JSON Configuration

If you prefer manual configuration:

**Configure Target:**
- **Name:** Runtime Security Test
- **Type:** Application
- **Connection Method:** REST API
- **API Endpoint:** `https://YOUR-NGROK-URL.ngrok-free.app/v1/chat/completions`

**Request JSON (compact format required):**
```json
{"messages":[{"role":"user","content":"{INPUT}"}],"model":"gpt-3.5-turbo"}
```

**Response JSON Path:**
```json
{"choices":[{"message":{"content":"{RESPONSE}"}}]}
```

**⚠️ Common Issue:** Multi-line JSON with formatting causes "INVALID_API_HEADERS" error. Use compact format above.

## Run Red Team Scan

1. Navigate to: **Red Teaming → Scans**
2. Click **+ New Scan**
3. Select your target
4. Scan Type: **Attack Library**
5. Select attack categories:
   - Prompt Injection
   - Jailbreak
   - System Prompt Leak
   - Violent Crimes/Weapons
   - OWASP Top 10 for LLMs
6. Click **Start Scan**

## Monitor Results

**Watch your terminal running the test app:**
```
📨 Received prompt: Ignore all previous instructions...
🔍 Scan result: malicious / block
⚠️  Detected threats: injection
🚫 BLOCKED - Returning security error
```

**Check Red Teaming report:**
- **Risk Score 0-20:** Runtime Security working well ✅
- **Risk Score 50-100:** Security gaps, tune configuration ⚠️

## What Gets Tested

**Runtime Security Capabilities:**
- ✅ Prompt injection detection
- ✅ Jailbreak prevention
- ✅ Data loss prevention (DLP)
- ✅ Malicious URL filtering
- ✅ Toxic content blocking
- ✅ Response scanning for data leakage

**Red Teaming Attacks:**
- Prompt injection attempts
- Jailbreak techniques
- System prompt extraction
- Sensitive data exfiltration
- Harmful content generation
- Code injection

## Understanding Results

### Risk Score Interpretation

| Risk Score | Runtime Security Status | Action Required |
|------------|------------------------|-----------------|
| 0-10 | Excellent | Maintain configuration |
| 11-30 | Good with minor gaps | Fine-tune specific rules |
| 31-60 | Moderate vulnerabilities | Review security profile |
| 61-80 | Significant exposure | Immediate config review |
| 81-100 | Critical gaps | Verify Runtime Security is active |

### Expected Outcomes

**Well-Configured Runtime Security:**
- Most basic attacks: **BLOCKED**
- Only sophisticated attacks succeed
- Low false positive rate on benign prompts

**Weak Configuration:**
- Many attacks: **SUCCESSFUL**
- Basic jailbreaks work
- High risk score

## Troubleshooting

### Test App Won't Start

**Check Python environment:**
```bash
source .venv/bin/activate
python --version  # Should be Python 3.8+
```

**Verify credentials set:**
```bash
echo $PANW_AI_SEC_API_KEY
echo $PRISMA_AIRS_PROFILE
```

### Red Teaming Can't Reach Endpoint

**Verify ngrok is running:**
```bash
curl https://YOUR-NGROK-URL.ngrok-free.app/health
```

**Check ngrok hasn't expired:**
- Free ngrok URLs expire when you restart
- Copy the new URL and update Red Teaming target

### All Attacks Blocked (0% Success)

**Good, but verify not too restrictive:**
```bash
curl -X POST https://YOUR-NGROK-URL.ngrok-free.app/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"messages": [{"role": "user", "content": "Hello, how are you?"}]}'
```

Should return a normal response, not blocked.

### All Attacks Succeed (100% Success)

**Check Runtime Security is active:**
1. Verify API key is correct
2. Check security profile exists in SCM
3. Ensure profile has detections enabled
4. Review app logs for API errors

## Files Included

```plaintext
team-shared-setup/
├── README.md                              # This file
├── LICENSE                                # MIT License
│
├── Core Applications
├── runtime_test_app_direct_api.py        # Direct API integration (no SDK)
├── runtime_test_app_streaming.py         # Streaming support (4 formats)
├── runtime_test_app_streaming_cloudrun.py # Cloud Run optimized version
├── runtime_test_app.py                   # Original test app
│
├── Docker Setup
├── Dockerfile                             # Local development container
├── Dockerfile.cloudrun                    # Cloud Run container
├── docker-compose.yml                     # Docker Compose config
├── docker-quickstart.sh                   # One-command Docker start
├── start-docker.sh                        # Container startup script
├── .dockerignore                          # Docker build exclusions
│
├── Cloud Deployment
├── deploy-to-cloudrun.sh                  # GCP deployment script
├── .env.cloudrun.example                  # Cloud Run environment template
│
├── Manual Setup Scripts
├── setup.sh                               # Python virtualenv setup
├── start_test_app.sh                      # Start application
│
├── Documentation
├── DOCKER_README.md                       # Complete Docker guide
├── CLOUDRUN_DEPLOYMENT.md                 # Full Cloud Run guide
├── CLOUDRUN_QUICKSTART.md                 # 5-minute Cloud Run setup
│
├── Configuration
├── requirements.txt                       # Python dependencies
├── .env.example                          # Environment variables template
└── .gitignore                            # Git ignore rules
```

## Advanced Usage

### Use Real LLM (OpenAI)

By default, the app returns mock responses. To use a real LLM:

```bash
export OPENAI_API_KEY="your-openai-key"
./start_test_app.sh
```

Then uncomment the OpenAI integration in `runtime_test_app.py` lines 84-85.

### Custom Security Profiles

Test different security postures:

```bash
# Strict mode
export PRISMA_AIRS_PROFILE="strict-security"
./start_test_app.sh

# Run Red Team scan
# Compare Risk Score

# Balanced mode
export PRISMA_AIRS_PROFILE="balanced-security"
./start_test_app.sh

# Run Red Team scan again
# Compare results
```

### Monitor All Requests

ngrok provides a web interface to see all requests:

```bash
# While ngrok is running, open:
open http://localhost:4040
```

Shows every request Red Teaming sends with full details.

## Security Considerations

**⚠️ IMPORTANT:**
- Your test app is publicly accessible while ngrok runs
- Anyone with the ngrok URL can send requests
- **DO NOT** use production API keys for testing
- **DO NOT** leave ngrok running when not testing
- Use test/sandbox credentials only

**For production testing:**
- Deploy to cloud with proper authentication
- Use IP whitelisting
- Implement rate limiting
- Use short-lived credentials

## Support and Resources

**Documentation:**
- [Runtime Security API Reference](https://pan.dev/prisma-airs/api/airuntimesecurity/)
- [Red Teaming Documentation](https://docs.paloaltonetworks.com/prisma/airs/red-teaming)
- [DOCKER_README.md](DOCKER_README.md) - Complete Docker setup guide
- [CLOUDRUN_DEPLOYMENT.md](CLOUDRUN_DEPLOYMENT.md) - Full Cloud Run deployment
- [CLOUDRUN_QUICKSTART.md](CLOUDRUN_QUICKSTART.md) - 5-minute Cloud Run setup

**Need Help?**
- Review documentation files above
- Contact your Prisma AIRS support team
- Open an issue on GitHub

## Next Steps

1. **Baseline Testing:** Run initial scan to establish baseline risk score
2. **Tune Security:** Adjust Runtime Security profile based on findings
3. **Re-test:** Run scan again to measure improvement
4. **Automate:** Schedule weekly scans to monitor defense effectiveness
5. **Track Trends:** Monitor risk score changes over time

**Goal:** Achieve Risk Score **< 20** with minimal false positives on legitimate prompts.

---

**Summary:** This package validates that Prisma AIRS Runtime Security effectively protects your AI applications against real-world attacks simulated by AI Red Teaming.

## License

This project is licensed under the MIT License - see [LICENSE](LICENSE) file for details.

---

**Created by:** Scott Thornton
**Built for:** Prisma AIRS AI Security Platform by Palo Alto Networks
**© 2025 Scott Thornton** | Licensed under MIT
