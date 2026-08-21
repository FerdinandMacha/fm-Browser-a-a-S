#!/bin/bash

podman exec -i playwright-browser-service sh -c "NODE_PATH=/usr/src/app/node_modules node -" << 'EOF'
const { chromium } = require("playwright-core");

(async () => {
  try {
    const launchOptions = {
      args: [
        "--use-gl=angle",
        "--use-angle=vulkan",
        "--ignore-gpu-blocklist",
        "--enable-gpu-rasterization",
        "--disable-gpu-sandbox",
        "--enable-features=Vulkan,UseSkiaRenderer"
      ]
    };

    const launchEncoded = Buffer.from(JSON.stringify(launchOptions)).toString("base64");
    const cdpUrl = `ws://localhost:3000/chromium?launch=${launchEncoded}`;

    const browser = await chromium.connectOverCDP(cdpUrl);
    const context = browser.contexts()[0] || await browser.newContext();
    const page = await context.newPage();

    const cdpSession = await page.context().newCDPSession(page);
    await cdpSession.send("Emulation.setDeviceMetricsOverride", {
      width: 1920,
      height: 1080,
      deviceScaleFactor: 1,
      mobile: false,
      screenWidth: 1920,
      screenHeight: 1080
    });

    console.log("Navigating to https://bot.sannysoft.com/ ...");
    await page.goto("https://bot.sannysoft.com/", { waitUntil: "networkidle", timeout: 30000 });

    // Ensure asynchronous scripts complete
    await page.waitForTimeout(2000);

    const report = await page.evaluate(() => {
      const results = {};

      document.querySelectorAll("table").forEach((table, tableIndex) => {
        let sectionHeader = table.previousElementSibling?.innerText?.trim();

        // Standardize fallback names for headerless or overflow tables
        if (!sectionHeader || sectionHeader.length > 50) {
          sectionHeader = `Section ${tableIndex + 1}`;
        }

        results[sectionHeader] = [];

        table.querySelectorAll("tr").forEach((row) => {
          const cells = row.querySelectorAll("td, th");
          if (cells.length >= 2) {
            const testName = cells[0].innerText.trim();
            const testResult = cells[1].innerText.trim();
            const resultClass = cells[1].className || "info";

            // If a row is an explicit FP-Collect metric inside "Some details", re-route section
            let targetSection = sectionHeader;
            if (testName.startsWith("Canvas") || testName.includes("getBattery") || testName.includes("AudioContext")) {
              targetSection = "Fp-collect info";
              if (!results[targetSection]) results[targetSection] = [];
            }

            results[targetSection].push({
              test: testName,
              result: testResult,
              status: resultClass.includes("failed") ? "FAIL" : resultClass.includes("passed") ? "OK" : "INFO"
            });
          }
        });
      });

      return results;
    });

    console.log("\n--- SANNYSOFT BOT ASSESSMENT REPORT ---");
    console.log(JSON.stringify(report, null, 2));

    await browser.close();
  } catch (err) {
    console.error("Script execution failed:", err.message);
  }
})();
EOF