# ==============================================================================
# Multi-Stage Build untuk Backend Web Service Skripsi
# Menghasilkan kontainer ultra-ringan (< 15 MB) dengan konsumsi RAM idle < 5 MB
# ==============================================================================

# Tahap 1: Kompilasi Binary Go
FROM golang:1.22-alpine AS builder

WORKDIR /app

COPY go.mod ./
COPY main.go ./

RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o backend-app main.go

# Tahap 2: Runtime Image Ringan
FROM alpine:3.20

RUN apk --no-cache add ca-certificates tzdata

WORKDIR /root/

COPY --from=builder /app/backend-app .

ENV PORT=8080

EXPOSE 8080

CMD ["./backend-app"]
