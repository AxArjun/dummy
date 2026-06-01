# ─────────────────────────────────────────────────────────────────────────────
# FuelIQ Backend — Multi-stage Dockerfile
# Production-grade: minimal image, non-root user, no dev deps
# ─────────────────────────────────────────────────────────────────────────────

# ─── Build Stage ──────────────────────────────────────────────────────────────
FROM python:3.13-slim-bookworm AS builder

WORKDIR /build

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip install --upgrade pip && \
    pip install --no-cache-dir --user -r requirements.txt

# ─── Runtime Stage ────────────────────────────────────────────────────────────
FROM python:3.13-slim-bookworm AS runtime

# Security: Create non-root user
RUN groupadd --gid 1001 fueliq && \
    useradd --uid 1001 --gid fueliq --no-create-home --shell /bin/false fueliq

# Install only runtime system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq5 \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy installed packages from builder
COPY --from=builder /root/.local /home/fueliq/.local

# Copy application code
COPY --chown=fueliq:fueliq . .

# Use non-root user
USER fueliq

# Add local packages to PATH
ENV PATH=/home/fueliq/.local/bin:$PATH \
    PYTHONPATH=/app \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

EXPOSE 8000

# Gunicorn with Uvicorn workers
# Workers = (2 × CPU_COUNT) + 1 — tuned at runtime via environment
CMD ["gunicorn", "app.main:app", \
    "--worker-class", "uvicorn.workers.UvicornWorker", \
    "--workers", "4", \
    "--bind", "0.0.0.0:8000", \
    "--timeout", "120", \
    "--keepalive", "5", \
    "--max-requests", "1000", \
    "--max-requests-jitter", "100", \
    "--access-logfile", "-", \
    "--error-logfile", "-", \
    "--log-level", "info"]
