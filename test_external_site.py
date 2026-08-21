# test_external_site.py
# /// script
# requires-python = ">=3.9"
# dependencies = [
# "playwright",
# ]
# ///
import asyncio
from playwright.async_api import async_playwright
from gpu_browserless import get_gpu_cdp_url

async def main():
    cdp_url = get_gpu_cdp_url(host="localhost", port=3000)
    print(f"🔍 Connecting to: {cdp_url}")
    
    async with async_playwright() as p:
        browser = await p.chromium.connect_over_cdp(cdp_url)
        page = await browser.new_page()
        
        print("🌐 Navigating to external site...")
        await page.goto("https://webglreport.com/")
        
        # Optional: Take a screenshot to verify visually
        await page.screenshot(path="webgl_report.png")
        print("✅ Screenshot saved to webgl_report.png")
        
        await browser.close()

if __name__ == "__main__":
    asyncio.run(main())