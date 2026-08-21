FROM ghcr.io/browserless/multi:latest

USER root

RUN apt-get update && apt-get install -y \
    mesa-vulkan-drivers \
    libgl1-mesa-dri \
    libegl1 \
    libgl1 \
    vulkan-tools \
    mesa-utils \
    && rm -rf /var/lib/apt/lists/*