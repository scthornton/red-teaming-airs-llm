# Streaming Support & Troubleshooting

## Current Status: ⚠️ Experimental

Based on team testing, **Red Teaming's streaming support has known issues**. We recommend using **REST API mode** for production testing until these are resolved.

---

## Known Issues with Red Teaming Streaming

### Issue #1: 502 Server Errors

```json
{
  "detail": "Server error 502: API endpoint is unavailable"
}
```

**Cause:** Red Teaming's backend may not properly handle SSE streams
**Workaround:** Use REST API connection method instead

### Issue #2: Read() Not Called

```json
{
  "detail": "Streaming functionality test failed: Attempted to access streaming response content, without having called `read()`."
}
```

**Cause:** Red Teaming's client doesn't properly consume streaming responses
**Workaround:** Use REST API mode

### Issue #3: Format Incompatibility

Different streaming formats tried:
- ✅ SSE with `data: ` prefix
- ✅ NDJSON (newline-delimited JSON)
- ✅ Regular JSON over stream
- ❌ None reliably work with Red Teaming

**Recommendation:** Use non-streaming REST API mode

---

## Testing Streaming Locally

Our `runtime_test_app_streaming.py` supports multiple formats for **local testing**:

### Start the Streaming App

```bash
# Instead of runtime_test_app_direct_api.py, use:
python runtime_test_app_streaming.py
```

### Test OpenAI-Compatible Streaming

```bash
curl -X POST http://localhost:5000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "messages": [{"role": "user", "content": "Hello"}],
    "model": "gpt-3.5-turbo",
    "stream": true
  }'
```

**Output:**
```
data: {"id":"chatcmpl-...","choices":[{"delta":{"content":"This is a"},...}]}

data: {"id":"chatcmpl-...","choices":[{"delta":{"content":"safe streaming response"},...}]}

data: [DONE]
```

### Test Text-Delta Format

```bash
curl -X POST "http://localhost:5000/v1/chat/completions?format=textdelta" \
  -H "Content-Type: application/json" \
  -d '{
    "messages": [{"role": "user", "content": "Hello"}],
    "stream": true
  }'
```

**Output:**
```
data: {"type":"start"}

data: {"type":"text-delta","id":"0","delta":"This is a"}

data: {"type":"text-delta","id":"0","delta":"safe streaming response"}

data: {"type":"finish"}

data: [DONE]
```

### Test NDJSON Format

```bash
curl -X POST "http://localhost:5000/v1/chat/completions?format=ndjson" \
  -H "Content-Type: application/json" \
  -d '{
    "messages": [{"role": "user", "content": "Hello"}],
    "stream": true
  }'
```

**Output:**
```
{"type":"text-delta","id":"0","delta":"This is a"}
{"type":"text-delta","id":"0","delta":"safe streaming response"}
{"type":"done"}
```

---

## Supported Streaming Formats

| Format | Query Param | Use Case | Status |
|--------|-------------|----------|--------|
| **OpenAI** | `?format=openai` (default) | Most compatible with LLM APIs | ✅ Implemented |
| **Text-Delta** | `?format=textdelta` | Matches colleague's example | ✅ Implemented |
| **NDJSON** | `?format=ndjson` | Lightweight, no SSE overhead | ✅ Implemented |
| **Simple** | `?format=simple` | Minimal JSON stream | ✅ Implemented |

---

## Adding Streaming Target to Red Teaming

**⚠️ Warning:** This may not work due to platform limitations.

If you want to try anyway:

### 1. Start Streaming App

```bash
python runtime_test_app_streaming.py
```

### 2. Start ngrok

```bash
ngrok http 5000
```

### 3. Configure in SCM

**Target Type:** Model
**Connection Method:** Streaming

**cURL for OpenAI format:**
```bash
curl -X POST https://YOUR-URL.ngrok-free.dev/v1/chat/completions -H "Content-Type: application/json" -d '{"messages":[{"role":"user","content":"{INPUT}"}],"model":"gpt-3.5-turbo","stream":true}'
```

**cURL for text-delta format:**
```bash
curl -X POST https://YOUR-URL.ngrok-free.dev/v1/chat/completions?format=textdelta -H "Content-Type: application/json" -d '{"messages":[{"role":"user","content":"{INPUT}"}],"stream":true}'
```

### 4. Expected Issues

You'll likely encounter one of these errors:
- 502 Server Error
- "Attempted to access streaming response content, without having called `read()`"
- Timeout errors
- Format parsing errors

---

## Recommendation: Use REST API Mode

**For reliable Red Teaming scans, use the standard non-streaming endpoint:**

### Use This Instead

```bash
# Start the non-streaming app
python runtime_test_app_direct_api.py

# Start ngrok
ngrok http 5000

# In Red Teaming SCM:
# Connection Method: REST API (not Streaming)
# Use this cURL:
curl -X POST https://YOUR-URL.ngrok-free.dev/v1/chat/completions -H "Content-Type: application/json" -d '{"messages":[{"role":"user","content":"{INPUT}"}],"model":"gpt-3.5-turbo"}'
```

This works reliably and avoids all streaming-related issues.

---

## Docker Support for Streaming

The Docker setup supports both streaming and non-streaming:

### Use Streaming App in Docker

Edit `Dockerfile` to use the streaming version:

```dockerfile
# Change this line:
COPY runtime_test_app_direct_api.py .

# To:
COPY runtime_test_app_streaming.py .
```

Then update `start-docker.sh`:

```bash
# Change:
python runtime_test_app_direct_api.py &

# To:
python runtime_test_app_streaming.py &
```

Rebuild:
```bash
docker-compose up --build
```

---

## Testing Runtime Security with Streaming

Both streaming and non-streaming apps scan prompts/responses identically:

```python
# Scan happens before streaming starts
scan_result = scan_with_runtime_security(user_prompt)

if scan_result["action"] == "block":
    # Return blocked message (as stream or regular response)
    return blocked_response
```

**Security scanning is unaffected by streaming mode** - it works the same way.

---

## Debugging Streaming Issues

### Enable Verbose Logging

```bash
# Set Flask debug mode
export FLASK_DEBUG=1
python runtime_test_app_streaming.py
```

### Check What Format is Being Used

Watch app logs:
```
📨 Received prompt: Hello...
🔄 Streaming: True (format: openai)
🔍 Scan result: benign / allow
✅ ALLOWED - Processing with LLM
📡 Starting openai stream...
```

### Test Locally Without Red Teaming

```bash
# Terminal 1: Run app
python runtime_test_app_streaming.py

# Terminal 2: Test streaming
curl -N -X POST http://localhost:5000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"messages":[{"role":"user","content":"test"}],"stream":true}'
```

The `-N` flag disables curl's output buffering, allowing you to see the stream in real-time.

---

## When to Use Each App

| App | Use Case |
|-----|----------|
| `runtime_test_app_direct_api.py` | **Recommended** - Production Red Teaming scans |
| `runtime_test_app_streaming.py` | Experimental testing of streaming formats |

---

## Future Updates

If Palo Alto Networks resolves streaming issues in Red Teaming:

1. Update this guide with working configuration
2. Switch Docker default to streaming app
3. Add streaming-specific attack tests

**For now, stick with REST API mode for reliable testing.**

---

## Questions?

- **Can I test streaming locally?** Yes, use `runtime_test_app_streaming.py`
- **Will streaming work with Red Teaming?** Probably not, based on team testing
- **Should I use streaming for production?** No, use REST API mode
- **Does streaming affect security scanning?** No, scanning works the same way
- **Can I switch between streaming and non-streaming?** Yes, just change which Python file you run

---

## Summary

✅ **Use for Red Teaming:** `runtime_test_app_direct_api.py` + REST API mode
⚠️ **Experimental only:** `runtime_test_app_streaming.py` + Streaming mode
🔒 **Security scanning:** Works identically in both modes
📊 **Recommendation:** Wait for platform fixes before using streaming in production
