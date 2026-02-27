# Rust Backend Dockerfile for Moshi
# Multi-stage build for efficient production image

FROM rust:1.75-bookworm as builder

WORKDIR /app

# Install dependencies
RUN apt-get update && apt-get install -y \
    cmake \
    pkg-config \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy the entire workspace
COPY rust/ ./rust/
RUN mkdir -p client/dist && echo "Client dist placeholder"

WORKDIR /app/rust

# Build the moshi-backend binary
RUN cargo build --release --bin moshi-backend --features cuda

# Runtime stage
FROM nvidia/cuda:12.1.0-runtime-ubuntu22.04

WORKDIR /app

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates \
    libssl3 \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy the binary from builder
COPY --from=builder /app/rust/target/release/moshi-backend /usr/local/bin/moshi-backend

# Create directories for models and config
RUN mkdir -p /app/models /app/config /app/logs

# Copy default config
COPY rust/moshi-backend/config.json /app/config/config.json
RUN if [ -f rust/moshi-backend/config-q8.json ]; then cp rust/moshi-backend/config-q8.json /app/config/config-q8.json; else echo "Q8 config not found"; fi

# Set environment variables
ENV RUST_LOG=info
ENV HF_HOME=/app/models

# Expose the default port
EXPOSE 8998

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8998/health || exit 1

# Run the backend
ENTRYPOINT ["moshi-backend"]
CMD ["--config", "/app/config/config.json", "standalone"]
