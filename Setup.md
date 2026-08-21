# Create the service user with a home directory
sudo useradd -m -s /bin/bash playwright-svc

# Ensure subuid/subgid ranges exist for rootless Podman
sudo usermod --add-subuids 100000-165535 --add-subgids 100000-165535 playwright-svc

# Add user to the render group for good measure
sudo usermod -aG render playwright-svc

# Enable systemd user service lingering
sudo loginctl enable-linger playwright-svc


Bash

sudo -u playwright-svc -i
mkdir -p ~/.config/containers/systemd/


# Save your container definition to ~/.config/containers/systemd/playwright-browser.container:
sudo mv homelab/playwright-browser.container /home/playwright-svc/.config/containers/systemd/

# Run the service
sudo machinectl shell playwright-svc@.host

  podman build -t localhost/playwright-browser-gpu:latest -f Containerfile .

systemctl --user daemon-reload
systemctl --user restart playwright-browser

systemctl --user status playwright-browser
journalctl --user -u playwright-browser -n 10 --no-pager
podman logs playwright-browser-service --tail 100 --since 5m  --timestamps

# Verify functionality
uv run test_playwright.py 
bash test-gl.sh 


1. Critical Paths & Required Permissions

Ensure the user inside the container (non-root is recommended) has the following access:
Path (inside container)	Purpose	Required Permission
<PROFILE_DIR>	Persistent Firefox profile (cookies, cache, localStorage, IndexedDB).	Read + Write (rwx)
Playwright Browser Dir
(e.g., /ms-playwright or ./cache/ms-playwright)	The installed Firefox executable files.	Read + Execute (rx)
/tmp	Firefox runtime temporary files.	Read + Write (rw)
/dev/shm	Shared memory (improves performance, prevents crashes).	Read + Write (rw).
Run Podman with --shm-size=2g to allocate enough space.


2. Verify the device is actually reaching the container with the right group
bash
ls -la /dev/dri                              # host: note the group owner (usually "render")
podman exec -it playwright-browser-service id
podman exec -it playwright-browser-service ls -la /dev/dri


3. Confirm the image itself has a real hardware Vulkan/Mesa driver, not just SwiftShader

This is the part people miss: ghcr.io/browserless/multi is built to run anywhere, including GPU-less cloud boxes, so it may only ship Chromium's bundled SwiftShader and not the Mesa Vulkan ICD (radv/anv/etc.) matching your host GPU. Even with perfect device access, there's nothing for Chrome to use.

bash
podman exec -it playwright-browser-service bash -c "vulkaninfo --summary 2>&1 | head -30"
# or, if vulkaninfo isn't installed:
podman exec -it playwright-browser-service bash -c "dpkg -l | grep -i mesa-vulkan"

If that comes back empty or only lists SwiftShader — that's your answer, and it's a container-image problem, not a Podman/permissions one.

Also worth a quick host-side sanity check on the GPU itself:

bash
lspci -k | grep -EA3 'VGA|3D|Display'

4. Debugging 
Enter the container and test access manually:
bash

podman exec -it <container-id> /bin/bash
# Inside container, try to list the PROFILE_DIR
ls -la /path/to/PROFILE_DIR

