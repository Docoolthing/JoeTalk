# JoeTalk Flutter web — deploy on Railway (or any Docker host).
# Build-arg BACKEND_BASE_URL must match your *backend* service public HTTPS URL (no trailing slash).
# Railway: add variable BACKEND_BASE_URL to the *web* service; Docker will receive it as a build ARG.

FROM ghcr.io/cirruslabs/flutter:stable AS build
WORKDIR /app

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .

ARG BACKEND_BASE_URL
RUN test -n "$BACKEND_BASE_URL" || (echo "BUILD FAILED: set BACKEND_BASE_URL (Railway Variable or docker build --build-arg)" >&2 && exit 1)
RUN flutter build web --release --dart-define=BACKEND_BASE_URL="${BACKEND_BASE_URL}"

FROM node:22-alpine
RUN npm install -g serve@14
WORKDIR /srv
COPY --from=build /app/build/web ./web
ENV NODE_ENV=production
EXPOSE 8080
CMD ["sh", "-c", "exec serve -s web -l tcp://0.0.0.0:${PORT:-8080}"]
