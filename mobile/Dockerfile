# JoeTalk Flutter web — deploy on Railway (or any Docker host).
# Runtime: set BACKEND_BASE_URL on the container (Railway Variables). The entrypoint writes
# web/runtime-config.js so the SPA picks up the API URL without compile-time docker build-args.
# Optional: pass BACKEND_BASE_URL as a build-arg to also bake it via --dart-define (not required).

FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

# Run Flutter as root in this stage so tools can write the SDK cache under /sdks/flutter (owned by
# root in the base image). The final runtime image still serves static files as a non-root user.

COPY pubspec.yaml ./
RUN flutter pub get

COPY . .
RUN flutter pub get

ARG BACKEND_BASE_URL=
RUN set -e; \
  opts=""; \
  if [ -n "$BACKEND_BASE_URL" ]; then \
    opts="--dart-define=BACKEND_BASE_URL=${BACKEND_BASE_URL}"; \
  fi; \
  flutter build web --release --no-wasm-dry-run $opts

FROM node:22-alpine
RUN addgroup -g 1001 -S nodejs && adduser -S -u 1001 -G nodejs nodejs
RUN npm install -g serve@14
WORKDIR /srv
COPY docker-entrypoint.sh /srv/docker-entrypoint.sh
RUN chmod +x /srv/docker-entrypoint.sh
COPY --from=build --chown=nodejs:nodejs /app/build/web ./web
USER nodejs
ENV NODE_ENV=production
EXPOSE 8080
CMD ["/srv/docker-entrypoint.sh"]
