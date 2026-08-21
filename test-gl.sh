#!/bin/bash

# test-gl.sh
# Tests WebGL GPU rendering in a local Browserless container
# Works regardless of which user runs it, as long as port 3000 is accessible.

URL="http://localhost:3000/function"

# 1. Lightweight connectivity check
if ! curl -s --connect-timeout 2 -o /dev/null -w "%{http_code}" "http://localhost:3000/" | grep -q "200\|404\|401"; then
  echo "❌ Error: Cannot connect to $URL"
  echo "   The container might be stopped, or the port is not mapped correctly."
  echo "   Verify with: podman port playwright-browser-service"
  exit 1
fi

# 2. Define the JavaScript payload cleanly using a heredoc
read -r -d '' JS_PAYLOAD << 'EOF' || true
export default async ({ page }) => {
  await page.goto("about:blank");
  const result = await page.evaluate(() => {
    const canvas = document.createElement("canvas");
    const gl = canvas.getContext("webgl") || canvas.getContext("experimental-webgl");
    if (!gl) {
      return { vendor: "WebGL not supported", renderer: "WebGL not supported" };
    }
    const debugInfo = gl.getExtension("WEBGL_debug_renderer_info");
    if (!debugInfo) {
      return { 
        vendor: gl.getParameter(gl.VENDOR), 
        renderer: gl.getParameter(gl.RENDERER) 
      };
    }
    return {
      vendor: gl.getParameter(debugInfo.UNMASKED_VENDOR_WEBGL),
      renderer: gl.getParameter(debugInfo.UNMASKED_RENDERER_WEBGL)
    };
  });
  return {
    data: result,
    type: "application/json"
  };
}
EOF

echo "🔍 Testing WebGL rendering at $URL ..."

# 3. Execute the request, capturing both the body and the HTTP status code
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$URL" \
  -H "Content-Type: application/javascript" \
  -d "$JS_PAYLOAD")

# 4. Separate the HTTP status code from the response body
HTTP_CODE="${RESPONSE##*$'\n'}"
BODY="${RESPONSE%$'\n'*}"

# 5. Handle non-200 responses
if [ "$HTTP_CODE" -ne 200 ]; then
  echo "❌ Request failed with HTTP status: $HTTP_CODE"
  echo "Raw response from server:"
  echo "$BODY"
  echo ""
  echo "💡 Troubleshooting tips:"
  echo "   - If it says 'Unauthorized' or 'Token required', add '?token=YOUR_TOKEN' to the URL in this script."
  echo "   - Check container logs: podman logs playwright-browser-service"
  exit 1
fi

# 6. Try to parse as JSON
if echo "$BODY" | python3 -m json.tool > /dev/null 2>&1; then
  echo "✅ Successfully retrieved WebGL information:"
  echo "$BODY" | python3 -m json.tool
else
  echo "❌ Failed to parse JSON. The server returned:"
  echo "$BODY"
  exit 1
fi