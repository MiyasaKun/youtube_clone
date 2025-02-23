# Build stage
FROM rust:1.75-slim as builder

WORKDIR /usr/src/app

# Install required system dependencies
RUN apt-get update && \
    apt-get install -y pkg-config libssl-dev && \
    rm -rf /var/lib/apt/lists/*

# Copy the Cargo files
COPY backend/Cargo.toml backend/Cargo.lock ./

# Create a dummy main.rs to build dependencies
RUN mkdir src && \
    echo "fn main() {println!(\"dummy\")}" > src/main.rs

# Build dependencies - this layer will be cached if dependencies don't change
RUN cargo build --release

# Remove the dummy build artifacts
RUN rm -rf src

# Copy the actual source code
COPY backend/src ./src

# Build the actual application
RUN cargo build --release

# Production stage
FROM debian:bookworm-slim

WORKDIR /usr/local/bin

# Install runtime dependencies
RUN apt-get update && \
    apt-get install -y ca-certificates libssl3 && \
    rm -rf /var/lib/apt/lists/*

# Copy the built binary from builder
COPY --from=builder /usr/src/app/target/release/youtube-clone-backend ./app

# Expose the port the app runs on
EXPOSE 8080

# Run the binary
CMD ["./app"]