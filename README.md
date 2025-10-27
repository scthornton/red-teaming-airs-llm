# Prisma AIRS Red Teaming + Runtime Security Test Setup

[![Python 3.8+](https://img.shields.io/badge/python-3.8+-blue.svg)](https://www.python.org/downloads/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)
[![Security](https://img.shields.io/badge/Security-Policy-red.svg)](SECURITY.md)

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

### 1. Install Dependencies

```bash
./setup.sh
```

This creates a Python virtual environment and installs required packages.

### 2. Configure Credentials

**Option A: Environment Variables**
```bash
export PANW_AI_SEC_API_KEY="your-runtime-security-api-key"
export PRISMA_AIRS_PROFILE="your-security-profile-name"
```

**Option B: .env File**
```bash
cp .env.example .env
# Edit .env with your credentials
```

**Get Your Credentials:**
- Log into [Strata Cloud Manager](https://strata.paloaltonetworks.com)
- Navigate to: **Settings → Prisma AIRS → Runtime Security**
- Copy your API Key and Security Profile name

### 3. Start Test Application

```bash
./start_test_app.sh
```

You should see:
```
🔒 Starting Runtime Security Test App
============================================================
Security Profile: your-profile-name
API Key: abc123...
============================================================

🚀 Starting server on http://localhost:5000
```

### 4. Expose to Internet with ngrok

Red Teaming runs in Palo Alto's cloud and can't reach localhost. Use ngrok to create a secure tunnel.

**Install ngrok:**
```bash
brew install ngrok
# Or download from https://ngrok.com/download
```

**Start tunnel (in new terminal):**
```bash
ngrok http 5000
```

**Copy the HTTPS URL shown:**
```
Forwarding  https://abc123def456.ngrok-free.app -> http://localhost:5000
```

### 5. Test Locally First

```bash
# Replace with your ngrok URL
curl https://abc123def456.ngrok-free.app/health
```

Expected response:
```json
{
  "status": "healthy",
  "runtime_security": "enabled (direct API)",
  "profile": "your-profile-name",
  "llm": "mock"
}
```

### 6. Add as Red Teaming Target

1. Log into [Strata Cloud Manager](https://strata.paloaltonetworks.com)
2. Navigate to: **Insights → Prisma AIRS → Red Teaming → Targets**
3. Click **+ New Target**

**Configure Target:**
- **Name:** Runtime Security Test
- **Type:** Application
- **Connection Method:** REST API
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

### 7. Run Red Team Scan

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

### 8. Monitor Results

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
├── README.md                      # This file
├── LICENSE                        # MIT License
├── CONTRIBUTING.md                # Contribution guidelines
├── SECURITY.md                    # Security policy
├── CODE_OF_CONDUCT.md            # Code of conduct
├── setup.sh                       # Setup script
├── start_test_app.sh             # Start application
├── runtime_test_app.py           # Flask test application
├── requirements.txt               # Python dependencies
├── .env.example                  # Example credentials file
├── .gitignore                    # Git ignore rules
├── EXPOSING_LOCALHOST.md         # Detailed ngrok guide
└── TESTING_RUNTIME_SECURITY.md   # Comprehensive testing guide
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
- [Python SDK Usage Guide](https://pan.dev/prisma-airs/api/airuntimesecurity/pythonsdkusage/)
- [Red Teaming Documentation](https://docs.paloaltonetworks.com/prisma/airs/red-teaming)

**Need Help?**
- Check `EXPOSING_LOCALHOST.md` for detailed ngrok setup
- Review `TESTING_RUNTIME_SECURITY.md` for comprehensive testing guide
- Contact your Prisma AIRS support team

## Next Steps

1. **Baseline Testing:** Run initial scan to establish baseline risk score
2. **Tune Security:** Adjust Runtime Security profile based on findings
3. **Re-test:** Run scan again to measure improvement
4. **Automate:** Schedule weekly scans to monitor defense effectiveness
5. **Track Trends:** Monitor risk score changes over time

**Goal:** Achieve Risk Score **< 20** with minimal false positives on legitimate prompts.

---

**Summary:** This package validates that Prisma AIRS Runtime Security effectively protects your AI applications against real-world attacks simulated by AI Red Teaming.

## Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Security

For security issues, please see our [Security Policy](SECURITY.md).

## Code of Conduct

This project adheres to a [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you're expected to uphold this code.

## License

This project is licensed under the MIT License - see [LICENSE](LICENSE) file for details.

## Acknowledgments

**Created by:** Scott Thornton
**Built for:** Prisma AIRS AI Security Platform by Palo Alto Networks

### Special Thanks

- Palo Alto Networks for the Prisma AIRS platform
- Contributors and security researchers who help improve this tool
- The AI security research community

## Contact

- **Author:** Scott Thornton
- **General Questions:** Open a GitHub issue

---

**© 2025 Scott Thornton** | Licensed under MIT
# red-teaming-airs-llm
