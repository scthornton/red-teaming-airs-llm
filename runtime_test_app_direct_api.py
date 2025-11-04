#!/usr/bin/env python3
"""
Test application using Runtime Security API directly (without SDK).

This version works around SSL certificate issues by using requests directly.
Same functionality as runtime_test_app.py but with direct API calls.
"""

import os
import requests
import json
from flask import Flask, request, jsonify
from datetime import datetime
import uuid

# Disable SSL warnings for testing
import urllib3
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# Configuration
API_KEY = os.getenv("PANW_AI_SEC_API_KEY")
PROFILE_NAME = os.getenv("PRISMA_AIRS_PROFILE", "ai-sec-security")
RUNTIME_API_URL = "https://service.api.aisecurity.paloaltonetworks.com/v1/scan/sync/request"
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
USE_REAL_LLM = bool(OPENAI_API_KEY)

if not API_KEY:
    print("❌ ERROR: PANW_AI_SEC_API_KEY not set")
    print("   Run: export PANW_AI_SEC_API_KEY='your-key'")
    exit(1)

app = Flask(__name__)

def scan_with_runtime_security(prompt, response=None):
    """
    Scan prompt (and optionally response) using Runtime Security API.

    Returns dict with:
        - category: "benign" or "malicious"
        - action: "allow", "alert", or "block"
        - prompt_detected: dict of threat types
        - response_detected: dict of threat types (if response provided)
    """
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

    # Add response if provided
    if response:
        payload["contents"][0]["response"] = response

    try:
        # Make API call with SSL verification disabled (testing only!)
        resp = requests.post(
            RUNTIME_API_URL,
            headers=headers,
            json=payload,
            verify=False,  # Disable SSL verification for testing
            timeout=30
        )
        resp.raise_for_status()
        return resp.json()

    except requests.exceptions.RequestException as e:
        print(f"❌ Runtime Security API error: {e}")
        # Return error response
        return {
            "category": "error",
            "action": "allow",  # Fail open for testing
            "error": str(e)
        }

def get_llm_response(prompt: str) -> str:
    """Get response from LLM (or mock for testing)."""
    if USE_REAL_LLM:
        # TODO: Add OpenAI integration
        pass

    # Mock response for testing
    return f"This is a safe response to: {prompt[:50]}..."

@app.route("/v1/chat/completions", methods=["POST"])
def chat_completions():
    """OpenAI-compatible endpoint with Runtime Security scanning."""
    try:
        data = request.json
        messages = data.get("messages", [])

        # Extract user prompt
        user_prompt = None
        for msg in messages:
            if msg.get("role") == "user":
                user_prompt = msg.get("content")
                break

        if not user_prompt:
            return jsonify({"error": "No user message found"}), 400

        print(f"\n📨 Received prompt: {user_prompt[:100]}...")

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

            return jsonify({
                "id": f"chatcmpl-{uuid.uuid4()}",
                "object": "chat.completion",
                "created": int(datetime.now().timestamp()),
                "model": "gpt-3.5-turbo",
                "choices": [{
                    "index": 0,
                    "message": {
                        "role": "assistant",
                        "content": "⛔ This request was blocked by Prisma AIRS Runtime Security for violating security policies."
                    },
                    "finish_reason": "stop"
                }],
                "usage": {
                    "prompt_tokens": len(user_prompt.split()),
                    "completion_tokens": 15,
                    "total_tokens": len(user_prompt.split()) + 15
                }
            })

        # Allow safe prompts - get LLM response
        print("✅ ALLOWED - Processing with LLM")
        llm_response = get_llm_response(user_prompt)

        # Scan the response too (optional but recommended)
        response_scan = scan_with_runtime_security(user_prompt, llm_response)
        response_threats = response_scan.get("response_detected", {})
        response_detected = [k for k, v in response_threats.items() if v]

        if response_detected:
            print(f"⚠️  Response threats: {', '.join(response_detected)}")
            if response_scan.get("action") == "block":
                print("🚫 Response BLOCKED")
                llm_response = "⛔ The model's response was blocked by security policies."

        # Return OpenAI-compatible response
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
        return jsonify({"error": str(e)}), 500

@app.route("/health", methods=["GET"])
def health():
    """Health check endpoint."""
    return jsonify({
        "status": "healthy",
        "runtime_security": "enabled (direct API)",
        "profile": PROFILE_NAME,
        "llm": "mock" if not USE_REAL_LLM else "openai",
        "api_url": RUNTIME_API_URL
    })

if __name__ == "__main__":
    print("="*60)
    print("🔒 AI Runtime Security Test Application (Direct API)")
    print("="*60)
    print(f"Profile: {PROFILE_NAME}")
    print(f"API Key: {API_KEY[:10]}...")
    print(f"API URL: {RUNTIME_API_URL}")
    print(f"LLM: {'OpenAI' if USE_REAL_LLM else 'Mock responses'}")
    print("="*60)
    print("\n🚀 Starting server on http://localhost:5000")
    print("📋 OpenAI-compatible endpoint: http://localhost:5000/v1/chat/completions")
    print("💚 Health check: http://localhost:5000/health\n")

    app.run(host="0.0.0.0", port=5000, debug=True)
