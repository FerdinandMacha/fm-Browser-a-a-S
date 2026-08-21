# gpu_browserless.py
import json
import base64

def get_gpu_cdp_url(host: str = "localhost", port: int = 3000, token: str | None = None) -> str:
    """
    Generates a Browserless CDP URL configured for AMD/Intel/NVIDIA hardware acceleration.
    """
    launch_options = {
        "args": [
            "--use-gl=angle",
            "--use-angle=vulkan",
            "--ignore-gpu-blocklist",
            "--enable-gpu-rasterization",
            "--disable-gpu-sandbox",
            "--enable-features=Vulkan,UseSkiaRenderer"
        ]
    }
    
    launch_encoded = base64.b64encode(json.dumps(launch_options).encode()).decode()
    
    # Base URL targeting the explicit /chromium endpoint
    url = f"ws://{host}:{port}/chromium?launch={launch_encoded}"
    
    if token:
        url += f"&token={token}"
        
    return url