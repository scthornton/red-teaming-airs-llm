# Security Policy

## Supported Versions

We provide security updates for the following versions:

| Version | Supported          |
| ------- | ------------------ |
| 1.x.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Security Context

This project is a **security research and testing tool** designed to validate AI security defenses. It simulates attack scenarios in authorized, controlled environments.

### Authorized Use Only

This tool is intended for:

✅ **Authorized security testing** of your own AI applications
✅ **Research purposes** in controlled lab environments
✅ **Educational demonstrations** of AI security concepts
✅ **Validating Runtime Security** effectiveness with Red Teaming

**NOT for:**

❌ Attacking production systems without authorization
❌ Testing third-party services without explicit permission
❌ Circumventing security controls for malicious purposes
❌ Any illegal or unauthorized activities

### Responsible Use Guidelines

1. **Only test systems you own or have written authorization to test**
2. **Use test/sandbox credentials, never production API keys**
3. **Keep ngrok tunnels running only during active testing**
4. **Don't expose sensitive data or production systems**
5. **Follow coordinated vulnerability disclosure practices**
6. **Comply with all applicable laws and regulations**

## Reporting a Vulnerability

If you discover a security vulnerability in this project, please report it responsibly.

### What to Report

- Security vulnerabilities in the code
- Credential exposure risks
- Unsafe default configurations
- Dependencies with known vulnerabilities
- Documentation that could lead to insecure usage

### How to Report

**DO NOT** open a public GitHub issue for security vulnerabilities.

**Instead, please:**
- Open a GitHub issue with minimal details and request private disclosure
- Or contact the maintainer directly through GitHub

**Include in your report:**

1. **Description** of the vulnerability
2. **Steps to reproduce** the issue
3. **Potential impact** if exploited
4. **Suggested fix** (if you have one)
5. **Your contact information** for follow-up

### Response Timeline

- **24 hours:** Acknowledgment of your report
- **7 days:** Initial assessment and severity classification
- **30 days:** Fix developed and tested (for high/critical issues)
- **90 days:** Public disclosure (coordinated with reporter)

### Bug Bounty

While we don't currently offer a formal bug bounty program, we will:

- Acknowledge your contribution in release notes
- Credit you in security advisories (unless you prefer anonymity)
- Provide recognition in our contributors list

## Security Best Practices for Users

### Credential Management

**API Keys:**
```bash
# ✅ Good - Use environment variables
export PANW_AI_SEC_API_KEY="your-key"

# ✅ Good - Use .env file (git-ignored)
echo "PANW_AI_SEC_API_KEY=your-key" > .env

# ❌ Bad - Hardcode in scripts
API_KEY="abc123..."  # Don't do this!
```

**Verify .env is git-ignored:**
```bash
git check-ignore .env  # Should return .env
```

### Network Exposure

**ngrok Tunnels:**
- ⚠️ Your test app becomes publicly accessible
- ⚠️ Anyone with the URL can send requests
- ⚠️ Free ngrok URLs are not secret, treat as public

**Recommendations:**
```bash
# Monitor all incoming requests
open http://localhost:4040  # ngrok web interface

# Stop tunnel when not testing
pkill ngrok

# Use authentication if testing for extended periods
# (Add basic auth to Flask app)
```

### Dependency Security

**Keep dependencies updated:**
```bash
# Check for security updates
pip list --outdated

# Update specific package
pip install --upgrade pan-aisecurity

# Or update all
pip install --upgrade -r requirements.txt
```

**Known dependency vulnerabilities:**
- Check [GitHub Security Advisories](https://github.com/advisories)
- Run `pip-audit` or similar tools
- Review `requirements.txt` regularly

### SSL/TLS Configuration

**Note:** This test application disables SSL verification for development convenience.

```python
# In runtime_test_app.py:
verify=False  # ⚠️ Only for local testing!
```

**For production use:**
1. Remove `verify=False` parameter
2. Ensure proper CA certificates installed
3. Use valid SSL certificates
4. Don't disable SSL warnings

## Security Hardening Checklist

Before sharing or deploying this tool:

- [ ] Remove any hardcoded credentials
- [ ] Verify `.env` is in `.gitignore`
- [ ] Review all scripts for credential leakage
- [ ] Update dependencies to latest secure versions
- [ ] Enable SSL verification for production
- [ ] Add authentication if exposing publicly
- [ ] Implement rate limiting
- [ ] Add request logging and monitoring
- [ ] Document security assumptions
- [ ] Review Prisma AIRS security best practices

## Known Security Considerations

### SSL Verification Disabled

**Location:** `runtime_test_app.py:66`

```python
verify=False  # Disables SSL certificate verification
```

**Risk:** Susceptible to man-in-the-middle attacks

**Mitigation:** Only use on trusted networks for testing. Enable SSL verification for production use.

### Public Exposure via ngrok

**Risk:** Test application accessible to anyone with the URL

**Mitigation:**
- Use ngrok only during active testing
- Monitor incoming requests at http://localhost:4040
- Implement authentication for extended testing
- Use IP whitelisting if available

### Mock LLM Responses

**Risk:** Responses are predictable and contain user input

**Mitigation:** Use real LLM for production-like testing, or review mock response logic

## Disclosure Policy

We follow **coordinated vulnerability disclosure**:

1. **Private disclosure** to maintainers first
2. **90-day window** for fix development
3. **Coordinated public disclosure** with security advisory
4. **Credit to reporter** unless anonymity requested

## Additional Resources

- [OWASP Top 10 for LLMs](https://owasp.org/www-project-top-10-for-large-language-model-applications/)
- [Prisma AIRS Security Documentation](https://docs.paloaltonetworks.com/prisma/airs)
- [AI Red Team Attack Library](https://strata.paloaltonetworks.com)

## Contact

**Security Issues:** Open a GitHub issue with minimal details
**General Questions:** Open a GitHub issue
**Maintainer:** Scott Thornton

---

**Last Updated:** January 2025
**Maintained by:** Scott Thornton
