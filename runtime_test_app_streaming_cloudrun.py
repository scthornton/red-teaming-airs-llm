#!/usr/bin/env python3
"""
Streaming test application for Cloud Run deployment.
Supports multiple streaming formats for Red Teaming testing.
"""

import os
import requests
import json
import time
from flask import Flask, request, jsonify, Response, stream_with_context
from datetime import datetime
import uuid

# Disable SSL warnings for testing
import urllib3
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# Configuration
API_KEY = os.getenv("PANW_AI_SEC_API_KEY")
PROFILE_NAME = os.getenv("PRISMA_AIRS_PROFILE", "chatbot")
RUNTIME_API_URL = "https://service.api.aisecurity.paloaltonetworks.com/v1/scan/sync/request"
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
USE_REAL_LLM = bool(OPENAI_API_KEY)
BLOCK_STATUS_CODE = int(os.getenv("BLOCK_STATUS_CODE", "200"))
PORT = int(os.getenv("PORT", 8080))  # Cloud Run uses PORT env var

if not API_KEY:
    print("❌ ERROR: PANW_AI_SEC_API_KEY not set")
    print("   Set in Cloud Run environment variables")
    exit(1)

app = Flask(__name__)

def scan_with_runtime_security(prompt, response=None):
    """Scan prompt/response using Runtime Security API."""
    headers = {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "x-pan-token": API_KEY
    }

    payload = {
        "tr_id": str(uuid.uuid4()),
        "ai_profile": {"profile_name": PROFILE_NAME},
        "contents": [{"prompt": prompt}]
    }

    if response:
        payload["contents"][0]["response"] = response

    try:
        resp = requests.post(
            RUNTIME_API_URL,
            headers=headers,
            json=payload,
            verify=False,
            timeout=30
        )
        resp.raise_for_status()
        return resp.json()
    except requests.exceptions.RequestException as e:
        print(f"❌ Runtime Security API error: {e}")
        return {
            "category": "error",
            "action": "allow",
            "error": str(e)
        }

def get_llm_response(prompt: str) -> str:
    """Get response from LLM (or mock for testing)."""
    if USE_REAL_LLM:
        # TODO: Add OpenAI streaming integration
        pass

    # Mock response for testing
    return f"This is a safe streaming response to your prompt: {prompt[:50]}..."

def generate_openai_stream(content, chunk_size=10):
    """Generate OpenAI-compatible SSE stream."""
    chunk_id = f"chatcmpl-{uuid.uuid4()}"
    words = content.split()
    chunks = [' '.join(words[i:i+chunk_size]) for i in range(0, len(words), chunk_size)]

    for i, chunk in enumerate(chunks):
        delta = {
            "id": chunk_id,
            "object": "chat.completion.chunk",
            "created": int(datetime.now().timestamp()),
            "model": "gpt-3.5-turbo",
            "choices": [{
                "index": 0,
                "delta": {
                    "content": chunk + (" " if i < len(chunks)-1 else "")
                },
                "finish_reason": None
            }]
        }
        yield f"data: {json.dumps(delta)}\n\n"
        time.sleep(0.05)

    # Final chunk
    final = {
        "id": chunk_id,
        "object": "chat.completion.chunk",
        "created": int(datetime.now().timestamp()),
        "model": "gpt-3.5-turbo",
        "choices": [{
            "index": 0,
            "delta": {},
            "finish_reason": "stop"
        }]
    }
    yield f"data: {json.dumps(final)}\n\n"
    yield "data: [DONE]\n\n"

def generate_textdelta_stream(content):
    """Generate text-delta format stream."""
    yield 'data: {"type":"start"}\n\n'
    yield 'data: {"type":"start-step"}\n\n'
    yield 'data: {"type":"text-start","id":"0"}\n\n'

    words = content.split()
    chunk_size = 10
    chunks = [' '.join(words[i:i+chunk_size]) for i in range(0, len(words), chunk_size)]

    for chunk in chunks:
        delta = {
            "type": "text-delta",
            "id": "0",
            "delta": chunk + " "
        }
        yield f"data: {json.dumps(delta)}\n\n"
        time.sleep(0.05)

    yield 'data: {"type":"text-end","id":"0"}\n\n'
    yield 'data: {"type":"finish-step"}\n\n'
    yield 'data: {"type":"finish"}\n\n'
    yield "data: [DONE]\n\n"

def generate_ndjson_stream(content):
    """Generate NDJSON stream."""
    words = content.split()
    chunk_size = 10
    chunks = [' '.join(words[i:i+chunk_size]) for i in range(0, len(words), chunk_size)]

    for i, chunk in enumerate(chunks):
        obj = {
            "type": "text-delta",
            "id": "0",
            "delta": chunk + (" " if i < len(chunks)-1 else "")
        }
        yield json.dumps(obj) + "\n"
        time.sleep(0.05)

    yield json.dumps({"type": "done"}) + "\n"

def generate_simple_json_stream(content):
    """Simple JSON stream."""
    obj = {"output": content}
    yield f"data: {json.dumps(obj)}\n\n"
    yield "data: [DONE]\n\n"

@app.route("/v1/chat/completions", methods=["POST"])
def chat_completions():
    """OpenAI-compatible endpoint with Runtime Security scanning."""
    try:
        data = request.json
        messages = data.get("messages", [])
        stream = data.get("stream", False)
        stream_format = request.args.get("format", "openai")

        # Extract user prompt
        user_prompt = None
        for msg in messages:
            if msg.get("role") == "user":
                user_prompt = msg.get("content")
                break

        if not user_prompt:
            return jsonify({"error": "No user message found"}), 400

        print(f"\n📨 Received prompt: {user_prompt[:100]}...")
        print(f"🔄 Streaming: {stream} (format: {stream_format})")

        # Scan with Runtime Security
        scan_result = scan_with_runtime_security(user_prompt)

        category = scan_result.get("category", "unknown")
        action = scan_result.get("action", "unknown")
        prompt_threats = scan_result.get("prompt_detected", {})
        detected = [k for k, v in prompt_threats.items() if v]

        print(f"🔍 Scan result: {category} / {action}")
        if detected:
            print(f"⚠️  Detected threats: {', '.join(detected)}")

        # Block malicious prompts
        if category == "malicious" or action == "block":
            print("🚫 BLOCKED - Returning security error")

            blocked_content = "⛔ This request was blocked by Prisma AIRS Runtime Security for violating security policies."

            if stream:
                def generate_blocked():
                    if stream_format == "openai":
                        yield from generate_openai_stream(blocked_content)
                    elif stream_format == "textdelta":
                        yield from generate_textdelta_stream(blocked_content)
                    elif stream_format == "ndjson":
                        yield from generate_ndjson_stream(blocked_content)
                    else:
                        yield from generate_simple_json_stream(blocked_content)

                return Response(
                    stream_with_context(generate_blocked()),
                    mimetype="text/event-stream",
                    status=BLOCK_STATUS_CODE
                )
            else:
                return jsonify({
                    "id": f"chatcmpl-{uuid.uuid4()}",
                    "object": "chat.completion",
                    "created": int(datetime.now().timestamp()),
                    "model": "gpt-3.5-turbo",
                    "choices": [{
                        "index": 0,
                        "message": {
                            "role": "assistant",
                            "content": blocked_content
                        },
                        "finish_reason": "stop"
                    }],
                    "usage": {
                        "prompt_tokens": len(user_prompt.split()),
                        "completion_tokens": 15,
                        "total_tokens": len(user_prompt.split()) + 15
                    }
                }), BLOCK_STATUS_CODE

        # Allow safe prompts
        print("✅ ALLOWED - Processing with LLM")
        llm_response = get_llm_response(user_prompt)

        # Scan response
        response_scan = scan_with_runtime_security(user_prompt, llm_response)
        response_threats = response_scan.get("response_detected", {})
        response_detected = [k for k, v in response_threats.items() if v]

        if response_detected:
            print(f"⚠️  Response threats: {', '.join(response_detected)}")
            if response_scan.get("action") == "block":
                print("🚫 Response BLOCKED")
                llm_response = "⛔ The model's response was blocked by security policies."

        # Return response
        if stream:
            print(f"📡 Starting {stream_format} stream...")

            def generate():
                if stream_format == "openai":
                    yield from generate_openai_stream(llm_response)
                elif stream_format == "textdelta":
                    yield from generate_textdelta_stream(llm_response)
                elif stream_format == "ndjson":
                    yield from generate_ndjson_stream(llm_response)
                else:
                    yield from generate_simple_json_stream(llm_response)

            return Response(
                stream_with_context(generate()),
                mimetype="text/event-stream",
                headers={
                    'Cache-Control': 'no-cache',
                    'X-Accel-Buffering': 'no'
                }
            )
        else:
            return jsonify({
                "id": f"chatcmpl-{uuid.uuid4()}",
                "object": "chat.completion",
                "created": int(datetime.now().timestamp()),
                "model": "gpt-3.5-turbo",
                "choices": [{
                    "index": 0,
                    "message": {
                        "role": "assistant",
                        "content": llm_response
                    },
                    "finish_reason": "stop"
                }],
                "usage": {
                    "prompt_tokens": len(user_prompt.split()),
                    "completion_tokens": len(llm_response.split()),
                    "total_tokens": len(user_prompt.split()) + len(llm_response.split())
                }
            })

    except Exception as e:
        print(f"❌ Error: {str(e)}")
        import traceback
        traceback.print_exc()
        return jsonify({"error": str(e)}), 500

@app.route("/health", methods=["GET"])
@app.route("/", methods=["GET"])
def health():
    """Health check endpoint."""
    return jsonify({
        "status": "healthy",
        "runtime_security": "enabled (direct API)",
        "profile": PROFILE_NAME,
        "llm": "mock" if not USE_REAL_LLM else "openai",
        "api_url": RUNTIME_API_URL,
        "streaming": "supported (openai, textdelta, ndjson, simple)",
        "environment": "Google Cloud Run"
    })

if __name__ == "__main__":
    print("="*60)
    print("🔒 AI Runtime Security Streaming App (Cloud Run)")
    print("="*60)
    print(f"Profile: {PROFILE_NAME}")
    print(f"API Key: {API_KEY[:10]}..." if API_KEY else "API Key: NOT SET")
    print(f"API URL: {RUNTIME_API_URL}")
    print(f"LLM: {'OpenAI' if USE_REAL_LLM else 'Mock responses'}")
    print(f"Port: {PORT}")
    print("="*60)
    print("\n🚀 Starting server")
    print(f"📋 Endpoints:")
    print(f"   • POST /v1/chat/completions (streaming & non-streaming)")
    print(f"   • GET  /health")
    print(f"   • GET  / (health check)")
    print("\n📡 Streaming formats (use ?format=<type>):")
    print("   • openai    - OpenAI-compatible SSE (default)")
    print("   • textdelta - Text-delta format")
    print("   • ndjson    - Newline-delimited JSON")
    print("   • simple    - Simple JSON stream")
    print("\n💚 Ready to receive requests\n")

    app.run(host="0.0.0.0", port=PORT, debug=False)
