# /// script
# requires-python = ">=3.9"
# dependencies = [
# "playwright",
# ]
# ///
import asyncio
import json
import base64
from playwright.async_api import async_playwright

async def main():
    print("🔍 Connecting to Browserless at ws://localhost:3000/chromium ...")
    
    launch_options = {
        "args": [
            "--use-gl=angle",
            "--use-angle=vulkan",
            "--ignore-gpu-blocklist",
            "--enable-gpu-rasterization",
            "--disable-gpu-sandbox",
            "--enable-features=Vulkan,UseSkiaRenderer"  # Critical for headless Vulkan
        ]
    }
    
    # Base64 encode the launch options as required by Browserless v2
    launch_encoded = base64.b64encode(json.dumps(launch_options).encode()).decode()
    
    # IMPORTANT: Use the /chromium endpoint to ensure a fresh browser is launched 
    # with these specific arguments, bypassing any pre-booted browser pools.
    cdp_url = f"ws://localhost:3000/chromium?launch={launch_encoded}"
    
    async with async_playwright() as p:
        browser = await p.chromium.connect_over_cdp(cdp_url)
        
        context = await browser.new_context()
        page = await context.new_page()
        
        print("🌐 Evaluating WebGL context...")
        await page.goto("about:blank")
        
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
        print(f" Vendor: {result['vendor']}")
        print(f" Renderer: {result['renderer']}")
        
        if "SwiftShader" in result['renderer'] or "llvmpipe" in result['renderer']:
            print("\n⚠️ WARNING: Still using CPU software rendering.")
        else:
            print("\n🎉 SUCCESS: Hardware acceleration is active!")
            
        await browser.close()

if __name__ == "__main__":
    asyncio.run(main())