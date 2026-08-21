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
systemctl --user daemon-reload
systemctl --user restart playwright-browser

# Verify functionality
uv run test_playwright.py 
bash test-gl.sh 


