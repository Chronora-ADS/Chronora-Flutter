FROM ghcr.io/cirruslabs/flutter:stable AS builder

WORKDIR /app

<<<<<<< HEAD
ARG API_BASE_URL=http://localhost:8085

=======
>>>>>>> master
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .
<<<<<<< HEAD
RUN flutter build web --release --dart-define=API_BASE_URL=$API_BASE_URL
=======
RUN flutter build web --release --dart-define=API_BASE_URL=https://chronora-java-master.onrender.com
>>>>>>> master

FROM node:20-alpine

WORKDIR /app

RUN npm install --global serve

COPY --from=builder /app/build/web ./

EXPOSE 10000

CMD ["sh", "-c", "serve -s . -l ${PORT:-10000}"]
