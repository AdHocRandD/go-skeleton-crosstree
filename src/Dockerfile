FROM golang:1.19.2-alpine AS builder
RUN mkdir /build
ADD go.mod go.sum main.go /build/
WORKDIR /build
RUN go build

FROM alpine
RUN adduser -S -D -H -h /app nonroot
USER nonroot
COPY --from=builder /build/go-skeleton-crosstree /app/
COPY static/ /app/static/
WORKDIR /app
EXPOSE 8000:8000
CMD ["./go-skeleton-crosstree"]

