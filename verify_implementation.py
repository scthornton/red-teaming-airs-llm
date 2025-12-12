#!/usr/bin/env python3
"""
Quick verification that BLOCK_STATUS_CODE is properly configured in all apps.
This doesn't require API credentials - just checks the code is correct.
"""

import os
import re

def check_file(filepath):
    """Check if file has correct BLOCK_STATUS_CODE implementation."""
    print(f"\nChecking {os.path.basename(filepath)}...")

    with open(filepath, 'r') as f:
        content = f.read()

    # Check 1: Variable defined in config section
    config_pattern = r'BLOCK_STATUS_CODE\s*=\s*int\(os\.getenv\("BLOCK_STATUS_CODE",\s*"200"\)\)'
    has_config = bool(re.search(config_pattern, content))

    # Check 2: Used in blocked response
    usage_pattern = r'\),\s*BLOCK_STATUS_CODE'
    has_usage = bool(re.search(usage_pattern, content))

    # Check 3: For streaming files, check Response() usage
    if 'streaming' in filepath:
        streaming_pattern = r'status=BLOCK_STATUS_CODE'
        has_streaming = bool(re.search(streaming_pattern, content))
    else:
        has_streaming = True  # Not applicable

    # Results
    if has_config:
        print("  ✅ BLOCK_STATUS_CODE defined with default 200")
    else:
        print("  ❌ Missing BLOCK_STATUS_CODE config")

    if has_usage:
        print("  ✅ Used in jsonify() return statement")
    else:
        print("  ❌ Not used in blocked responses")

    if has_streaming:
        print("  ✅ Applied to streaming responses")
    else:
        print("  ❌ Missing from streaming responses")

    return has_config and has_usage and has_streaming

def main():
    print("=" * 60)
    print("BLOCK_STATUS_CODE Implementation Verification")
    print("=" * 60)

    files_to_check = [
        "runtime_test_app.py",
        "runtime_test_app_direct_api.py",
        "runtime_test_app_streaming.py",
        "runtime_test_app_streaming_cloudrun.py"
    ]

    results = []
    for filename in files_to_check:
        filepath = os.path.join(os.path.dirname(__file__), filename)
        if os.path.exists(filepath):
            results.append(check_file(filepath))
        else:
            print(f"\n⚠️  {filename} not found")
            results.append(False)

    print("\n" + "=" * 60)
    if all(results):
        print("✅ All files correctly implemented!")
        print("\nTo test with real API:")
        print("  export BLOCK_STATUS_CODE=403")
        print("  python3 runtime_test_app.py")
    else:
        print("❌ Some files have issues - see above")
        return 1

    return 0

if __name__ == "__main__":
    exit(main())
