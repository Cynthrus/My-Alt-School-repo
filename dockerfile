# -----------------------------
# Build Stage - Compile the Go application
# -----------------------------
FROM golang:1.25.5-alpine AS builder

WORKDIR /build

ENV GOPROXY=https://proxy.golang.org,direct
ENV GO111MODULE=on

# Copy Go modules first
COPY MuchToDo/go.mod MuchToDo/go.sum ./

# Download dependencies
RUN go mod download

# Copy source code
COPY MuchToDo/ ./

# Build the binary
RUN go build -o main ./cmd/api/main.go

# -----------------------------
# Runtime Stage - Minimal Alpine image
# -----------------------------
FROM alpine:3.20 AS runtime

# Install CA certificates and curl
RUN apk update && apk add --no-cache ca-certificates curl

# Create non-root user
RUN adduser -D -u 1000 appuser

WORKDIR /app

# Copy binary and docs from build stage
COPY --from=builder /build/main .
COPY --from=builder /build/docs ./docs

# Use non-root user
USER appuser

# Expose port
EXPOSE 8080

# Healthcheck
HEALTHCHECK --interval=30s --timeout=3s \
  CMD curl -f http://localhost:8080/health || exit 1

# Run the app
CMD ["./main"]
