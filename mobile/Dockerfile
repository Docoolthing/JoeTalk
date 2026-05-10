# JoeTalk Flutter web — deploy on Railway (or any Docker host).
# Build-arg BACKEND_BASE_URL must match your *backend* service public HTTPS URL (no trailing slash).
# Railway: add variable BACKEND_BASE_URL to the *web* service; Docker will receive it as a build ARG.

FROM ghcr.io/cirruslabs/flutter:stable AS build

# Flutter warns if the tool runs as root; use an unprivileged account for all `flutter` commands.
RUN useradd -m -u 1001 app \
  && mkdir -p /app \
  && chown app:app /app

WORKDIR /app
USER app
ENV HOME=/home/app

# Flutter runs `git` against the SDK tree (owned by root in this image). Git 2.35+ blocks that unless
# the directory is marked safe for this user (“dubious ownership”).
RUN git config --global --add safe.directory /sdks/flutter

# Only pubspec.yaml is required here; lockfile may be absent from CI context (e.g. if not
# committed). `flutter pub get` resolves dependencies and writes pubspec.lock in-image.
COPY --chown=app:app pubspec.yaml ./
RUN flutter pub get

COPY --chown=app:app . .
RUN flutter pub get

ARG BACKEND_BASE_URL
RUN test -n "$BACKEND_BASE_URL" || (echo "BUILD FAILED: set BACKEND_BASE_URL (Railway Variable or docker build --build-arg)" >&2 && exit 1)
RUN flutter build web --release --dart-define=BACKEND_BASE_URL="${BACKEND_BASE_URL}"

FROM node:22-alpine
RUN addgroup -g 1001 -S nodejs && adduser -S -u 1001 -G nodejs nodejs
RUN npm install -g serve@14
WORKDIR /srv
COPY --from=build --chown=nodejs:nodejs /app/build/web ./web
USER nodejs
ENV NODE_ENV=production
EXPOSE 8080
CMD ["sh", "-c", "exec serve -s web -l tcp://0.0.0.0:${PORT:-8080}"]
