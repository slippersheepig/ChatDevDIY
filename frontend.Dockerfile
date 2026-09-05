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

# ---- Stage 1: Builder - npm install + vite production build ----
FROM node:alpine AS builder
WORKDIR /app

# Copy package manifests first to maximize layer cache
COPY --from=source /src/frontend/package.json /src/frontend/package-lock.json* ./
RUN npm ci --no-audit --no-fund || npm install --no-audit --no-fund

# Copy the rest of the frontend source and build the static bundle
COPY --from=source /src/frontend/. .
RUN npm run build

# ---- Stage 2: Runtime - nginx serving the static build + API/WS proxy ----
FROM nginx:alpine AS runtime

# Backend origin the proxy forwards /api and /ws to; override at `docker run -e`
# or in compose.yml. nginx's official image auto-renders *.template files in
# /etc/nginx/templates via envsubst on container start.
ENV BACKEND_URL=http://backend:6400

COPY --from=builder /app/dist /usr/share/nginx/html
COPY --from=source /src/.chatdev_ref /usr/share/nginx/html/chatdev_ref.txt
COPY nginx.conf.template /etc/nginx/templates/default.conf.template

EXPOSE 80
