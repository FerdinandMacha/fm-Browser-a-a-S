# /// script
# requires-python = ">=3.9"
# dependencies = [
#     "playwright",
# ]
# ///

import asyncio
from playwright.async_api import async_playwright

async def main():
    print("🔍 Connecting to Browserless at http://localhost:3000 ...")
    
    async with async_playwright() as p:
        # Browserless exposes a standard CDP endpoint at the root URL
        browser = await p.chromium.connect_over_cdp("http://localhost:3000")
        
        context = await browser.new_context()
        page = await context.new_page()
        
        print("🌐 Evaluating WebGL context...")
        await page.goto("about:blank")
        
        # Execute the WebGL detection logic
        result = await page.evaluate("""() => {
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
        }""")
        
        print("\n✅ WebGL Information:")
        print(f"  Vendor:   {result['vendor']}")
        print(f"  Renderer: {result['renderer']}")
        
        if "SwiftShader" in result['renderer'] or "llvmpipe" in result['renderer']:
            print("\n⚠️  WARNING: Still using CPU software rendering.")
        
        await browser.close()

if __name__ == "__main__":
    asyncio.run(main())