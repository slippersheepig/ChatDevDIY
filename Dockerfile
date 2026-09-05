# ---- Stage 0: fetch the latest (or pinned) ChatDev release source tree ----
FROM alpine AS source
ARG CHATDEV_REF=latest
RUN apk add --no-cache curl tar ca-certificates \
    && set -e \
    && if [ "$CHATDEV_REF" = "latest" ]; then \
         TAG=$(curl -fsS -o /dev/null -w '%{redirect_url}' "https://github.com/OpenBMB/ChatDev/releases/latest" | sed 's#.*/tag/##'); \
         [ -n "$TAG" ] || { echo "ERROR: could not resolve OpenBMB/ChatDev latest release tag" >&2; exit 1; }; \
       else \
         TAG="$CHATDEV_REF"; \
       fi \
    && echo ">>> Building against OpenBMB/ChatDev release: ${TAG}" \
    && curl -fsSL "https://github.com/OpenBMB/ChatDev/archive/${TAG}.tar.gz" -o /tmp/chatdev.tar.gz \
    && mkdir -p /src \
    && tar -xzf /tmp/chatdev.tar.gz -C /src --strip-components=1 \
    && rm -f /tmp/chatdev.tar.gz \
    && echo "${TAG}" > /src/.chatdev_ref

# ---- Stage 1: Builder - install deps with compilers and uv ----
FROM python:slim AS builder
ARG DEBIAN_FRONTEND=noninteractive
WORKDIR /app

# System deps required to build Python packages (cairo for xhtml2pdf/matplotlib, etc.)
RUN apt-get update && apt-get install -y --no-install-recommends \
        pkg-config \
        build-essential \
        python3-dev \
        libcairo2-dev \
    && rm -rf /var/lib/apt/lists/*

# Install uv just for dependency resolution/install
RUN pip install --no-cache-dir uv

# Install the project virtualenv outside /app so it stays isolated from the app code
ENV UV_PROJECT_ENVIRONMENT=/opt/venv

# Copy dependency files first to maximize layer cache
COPY --from=source /src/pyproject.toml /src/uv.lock ./

# Create the project virtualenv and install deps (reproducible, uses uv.lock)
RUN uv sync --no-cache --frozen

# ---- Stage 2: Runtime - minimal image with only runtime libs + app ----
FROM python:slim AS runtime
ARG DEBIAN_FRONTEND=noninteractive
ARG BACKEND_BIND=0.0.0.0
WORKDIR /app

# Install only runtime system libraries (no compilers)
RUN apt-get update && apt-get install -y --no-install-recommends \
        libcairo2 \
    && rm -rf /var/lib/apt/lists/*

# Copy the prebuilt virtualenv from the builder stage
COPY --from=builder /opt/venv /opt/venv

# Copy the fetched ChatDev application source
COPY --from=source /src /app

# Use the venv Python by default and keep Python output unbuffered.
ENV PATH="/opt/venv/bin:${PATH}" \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    BACKEND_BIND=${BACKEND_BIND}

# Drop privileges
RUN useradd -m appuser && chown -R appuser:appuser /app
USER appuser

EXPOSE 6400

# Run the DevAll backend server, parameterized by env
# (check `cat /app/.chatdev_ref` inside the container to see which
#  OpenBMB/ChatDev release this image was built against)
CMD ["sh", "-c", "python server_main.py --port 6400 --host ${BACKEND_BIND:-0.0.0.0}"]
