FROM ghcr.io/cirruslabs/flutter:stable AS builder

WORKDIR /app

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .
RUN flutter build web --release

FROM node:20-alpine

WORKDIR /app

RUN npm install --global serve

COPY --from=builder /app/build/web ./

EXPOSE 10000

CMD ["sh", "-c", "serve -s . -l ${PORT:-10000}"]
