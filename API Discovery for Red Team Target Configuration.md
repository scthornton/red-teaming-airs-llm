# API Discovery for Red Team Target Configuration

When you're red-teaming a new application/model, here's a systematic approach to discover the API format.

------

## Phase 1: Reconnaissance

### 1. Browser DevTools Inspection

- Open the application in browser with DevTools (F12)
- Go to **Network** tab, filter for "Fetch/XHR"
- Interact with the AI feature (send a test message)
- Look for API calls - you'll see:
  - **Endpoint URL:** `https://api.example.com/v1/chat`
  - **HTTP Method:** Usually POST
  - **Request Headers:** Authorization, Content-Type, etc.
  - **Request Payload:** Click the call → Payload tab
  - **Response:** Click Response tab

### 2. cURL Replication

- Right-click the API call → **"Copy as cURL"**
- Test in terminal to confirm it works
- Strip unnecessary headers (keep Authorization, Content-Type)

### 3. Documentation Search

- Check if they have public API docs (common for SaaS AI tools)
- Search: `[company name] API documentation`
- Look for authentication method (Bearer tokens, API keys, OAuth)

------

## Phase 2: Format Analysis

### 4. Request Format Extraction

Typical patterns you'll see:

**OpenAI-compatible (most common):**

```json
{
  "messages": [{"role": "user", "content": "test"}],
  "model": "gpt-4",
  "max_tokens": 500
}
```

**Anthropic format:**

```json
{
  "messages": [{"role": "user", "content": "test"}],
  "model": "claude-3-opus-20240229",
  "max_tokens": 1024
}
```

**Custom application format:**

```json
{
  "query": "test",
  "session_id": "abc123",
  "parameters": {"temperature": 0.7}
}
```

### 5. Response Format Extraction

Look for where the AI's response text lives:

**OpenAI-compatible:**

```json
{
  "choices": [{
    "message": {"content": "RESPONSE TEXT HERE"}
  }]
}
```

**Custom format examples:**

```json
{
  "data": {"response": "TEXT"},
  "metadata": {...}
}
{
  "result": "TEXT",
  "status": "success"
}
```

------

## Phase 3: Prisma AIRS Configuration

### 6. Map to Prisma AIRS Fields

In Prisma AIRS red team target configuration:

| Field              | Description                                     |
| ------------------ | ----------------------------------------------- |
| Endpoint URL       | The full URL from DevTools                      |
| Request JSON       | Replace user content with `{INPUT}` placeholder |
| Response JSON Path | Use JSONPath to the response text field         |

**Example mapping:**

Request Template:

```json
{
  "messages": [{"role": "user", "content": "{INPUT}"}],
  "model": "gpt-4",
  "max_tokens": 500
}
```

Response Path (use nested notation):

```json
{
  "choices": [{
    "message": {"content": "{RESPONSE}"}
  }]
}
```

------

## Phase 4: Authentication Handling

### 7. Token Management

Three common patterns:

**A. Bearer Token (most common)**

```bash
curl -H "Authorization: Bearer sk-abc123..."
```

→ In Prisma AIRS: Add to "Custom Headers"

**B. API Key Header**

```bash
curl -H "X-API-Key: your-key-here"
```

→ Add to Custom Headers with exact header name

**C. Query Parameter**

```bash
curl "https://api.example.com/chat?api_key=abc123"
```

→ Include in endpoint URL

------

## Phase 5: Testing & Validation

### 8. Test Request Chain

**Test 1: Direct API call**

```bash
curl -X POST https://api.example.com/v1/chat \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"messages":[{"role":"user","content":"hello"}]}'
```

**Test 2: Through your wrapper (if using)**

```bash
curl -X POST http://your-wrapper:5006/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"messages":[{"role":"user","content":"hello"}]}'
```

**Test 3: In Prisma AIRS**

Use the UI "Test Target" button after configuration

------

## Tools for Discovery

| Tool                   | Use Case                                                     |
| ---------------------- | ------------------------------------------------------------ |
| Browser DevTools       | Primary reconnaissance tool                                  |
| Burp Suite / OWASP ZAP | For complex authentication flows                             |
| Postman                | For testing/iterating on API calls                           |
| jq                     | For parsing JSON responses: `curl ... | jq '.choices[0].message.content'` |
| Wireshark              | If API uses websockets or non-HTTP protocols                 |

------

## Common Gotchas

- **Rate Limiting:** Test endpoints may have different limits than production
- **Session Tokens:** Some apps use temporary JWT tokens that expire
- **CORS:** Browser-based discovery may show OPTIONS preflight requests
- **Streaming Responses:** Some AI APIs stream (SSE/WebSocket) - Prisma AIRS needs completed responses
- **Custom Headers:** Applications may require vendor-specific headers for routing

------

## Real Example: Discovering a Custom App

Let's say you're testing "ChatWidget Pro" embedded in a website:

1. Open site with DevTools → Network tab

2. Send "hello" through chat widget

3. See API call: `POST https://api.chatwidget.pro/inference`

4. Request payload:

   ```json
   {
     "input": "hello",
     "widget_id": "abc123",
     "config": {"temp": 0.7}
   }
   ```

5. Response:

   ```json
   {
     "output": "Hi there!",
     "tokens_used": 25
   }
   ```

6. **Prisma AIRS config:**

   | Setting        | Value                                                        |
   | -------------- | ------------------------------------------------------------ |
   | Endpoint       | `https://api.chatwidget.pro/inference`                       |
   | Request        | `{"input": "{INPUT}", "widget_id": "abc123", "config": {"temp": 0.7}}` |
   | Response path  | `{"output": "{RESPONSE}"}`                                   |
   | Custom headers | `Authorization: Bearer [token from DevTools]`                |

------

# cURL Reference for API Testing & Development

## Testing Your Own APIs

```bash
# Basic POST request
curl -X POST http://localhost:8000/api/query \
  -H "Content-Type: application/json" \
  -d '{"query": "test"}'

# Check API responses (includes headers)
curl -i https://api.example.com/status
```

## Downloading Files

```bash
# Download files directly
curl -O https://example.com/dataset.zip
curl -o model.bin https://huggingface.co/model/weights.bin

# Resume interrupted downloads
curl -C - -O https://example.com/large-file.tar.gz
```

## Structured Data APIs

```bash
# APIs that return JSON/XML directly
curl https://api.github.com/repos/anthropics/claude-code

# With authentication
curl -H "Authorization: Bearer $TOKEN" https://api.service.com/data
```

## Checking Endpoints

```bash
# Test if a service is up (just headers)
curl -I https://example.com

# Check response time
curl -w "@-" -o /dev/null -s https://api.example.com <<'EOF'
time_total: %{time_total}s
http_code: %{http_code}
EOF
```

## File Uploads

```bash
# Upload files
curl -F "file=@document.pdf" https://api.example.com/upload

# Post form data
curl -X POST -d "username=scott&api_key=xxx" https://service.com/api
```

## Debugging & Headers

```bash
# See full request/response flow
curl -v https://example.com

# Follow redirects
curl -L https://short.url/abc123
```