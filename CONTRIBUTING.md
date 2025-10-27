# Contributing to Prisma AIRS Red Teaming Test Setup

Thank you for your interest in contributing to this project! This guide will help you get started.

## Code of Conduct

This project adheres to a Code of Conduct (see [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)). By participating, you're expected to uphold this code.

## How to Contribute

### Reporting Bugs

If you find a bug, please open an issue with:

- **Clear title** describing the problem
- **Steps to reproduce** the issue
- **Expected behavior** vs actual behavior
- **Environment details** (OS, Python version, dependency versions)
- **Logs or error messages** if applicable

**Example:**
```
Title: Runtime Security API returns 401 Unauthorized

Steps to reproduce:
1. Set PANW_AI_SEC_API_KEY environment variable
2. Run ./start_test_app.sh
3. Send test request to /health endpoint

Expected: 200 OK response
Actual: 401 Unauthorized error in logs

Environment:
- macOS 14.2
- Python 3.11.5
- pan-aisecurity 0.6.1a2
```

### Suggesting Enhancements

We welcome enhancement suggestions! Open an issue with:

- **Clear description** of the enhancement
- **Use case** - why is this useful?
- **Proposed implementation** (if you have ideas)
- **Alternatives considered**

### Pull Requests

1. **Fork the repository** and create a new branch
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes** following the coding standards below

3. **Test thoroughly**
   ```bash
   # Run the application
   ./start_test_app.sh

   # Test the endpoints
   curl http://localhost:5000/health
   ```

4. **Commit with clear messages**
   ```bash
   git commit -m "Add support for Anthropic Claude integration"
   ```

5. **Push to your fork**
   ```bash
   git push origin feature/your-feature-name
   ```

6. **Open a Pull Request** with:
   - Clear description of changes
   - Reference to related issues
   - Screenshots/logs if applicable
   - Confirmation that testing was done

## Development Guidelines

### Code Style

**Python:**
- Follow [PEP 8](https://pep8.org/) style guide
- Use meaningful variable names
- Add docstrings to functions
- Keep functions focused and small

**Example:**
```python
def scan_with_runtime_security(prompt: str, response: str = None) -> dict:
    """
    Scan prompt and optional response using Runtime Security API.

    Args:
        prompt: User input to scan
        response: Optional LLM response to scan

    Returns:
        dict: Scan results with category, action, and detected threats
    """
    # Implementation here
```

**Shell Scripts:**
- Use bash for compatibility
- Add comments for complex logic
- Check for required commands/variables
- Provide helpful error messages

### Documentation

- Update README.md if adding features
- Add inline comments for complex logic
- Include example usage in docstrings
- Update relevant guide files (EXPOSING_LOCALHOST.md, etc.)

### Security

**NEVER commit:**
- API keys or credentials
- `.env` files with real values
- Private configuration files

**Always:**
- Use environment variables for secrets
- Provide `.env.example` templates
- Update `.gitignore` for sensitive files
- Review diffs before committing

### Testing

Before submitting a PR, verify:

1. **Installation works from scratch**
   ```bash
   rm -rf .venv
   ./setup.sh
   ```

2. **Application starts successfully**
   ```bash
   export PANW_AI_SEC_API_KEY="test-key"
   export PRISMA_AIRS_PROFILE="test-profile"
   ./start_test_app.sh
   ```

3. **Endpoints respond correctly**
   ```bash
   curl http://localhost:5000/health
   ```

4. **Error handling works**
   - Test with missing credentials
   - Test with invalid API key
   - Test with malformed requests

## Project Structure

```
team-shared-setup/
├── runtime_test_app.py       # Main Flask application
├── setup.sh                   # Installation script
├── start_test_app.sh         # Startup script
├── requirements.txt           # Python dependencies
├── .env.example              # Credential template
├── README.md                 # Main documentation
├── EXPOSING_LOCALHOST.md     # ngrok guide
├── TESTING_RUNTIME_SECURITY.md  # Testing guide
├── CONTRIBUTING.md           # This file
├── SECURITY.md               # Security policy
├── CODE_OF_CONDUCT.md        # Code of conduct
└── LICENSE                   # MIT License
```

## Areas We Need Help

- **LLM Integrations:** Add support for more LLM providers (Anthropic, Cohere, Azure OpenAI)
- **Testing:** Automated tests for the application
- **Documentation:** Tutorials, troubleshooting guides, video walkthroughs
- **Deployment:** Docker support, Kubernetes manifests, cloud deployment guides
- **Monitoring:** Better logging, metrics, dashboard integration
- **Examples:** Sample Red Team scan configurations, attack libraries

## Getting Help

- **Questions?** Open a GitHub issue with the `question` label
- **Bugs?** Open a GitHub issue with the `bug` label
- **Feature requests?** Open a GitHub issue with the `enhancement` label

## Recognition

Contributors will be recognized in:
- README.md Contributors section
- Release notes for significant contributions
- Project documentation where applicable

Thank you for helping make this project better!

---

**Maintainer:** Scott Thornton
