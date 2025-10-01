# Use Ubuntu 22.04 LTS as base for ARM64 compatibility
FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=UTC \
    RIMWORLD_PORT=25555 \
    RIMWORLD_DATA_DIR=/app/data

# Install system dependencies
RUN apt-get update && apt-get install -y \
    wget \
    unzip \
    libicu70 \
    libssl3 \
    ca-certificates \
    tzdata \
    curl \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Create application directory structure
WORKDIR /app

# Download and extract RimWorld Together
RUN wget -q https://github.com/RimWorld-Together/Rimworld-Together/releases/download/25.7.11.1/linux-arm64.zip -O rimworld.zip && \
    unzip -q rimworld.zip && \
    rm rimworld.zip && \
    chmod +x RimWorldTogether && \
    mkdir -p data

# Create non-root user
RUN groupadd -r rimworld && \
    useradd -r -g rimworld -u 1000 rimworld && \
    chown -R rimworld:rimworld /app

# Switch to non-root user
USER rimworld

# Health check (commented out as it might not work without proper endpoint)
# HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
#     CMD curl -f http://localhost:25555/ || exit 1

# Expose the RimWorld Together port
EXPOSE 25555

# Set volume mount point
VOLUME ["/app/data"]

# Set entrypoint
ENTRYPOINT ["./RimWorldTogether"]
