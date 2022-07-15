# build the binary
FROM golang:1.18 as build
WORKDIR /app

COPY go.mod ./
COPY go.sum ./

RUN go mod download

COPY *.go ./

RUN go build -o /trystuff

# build the final image
FROM gcr.io/distroless/base-debian11
COPY --from=build /trystuff /
COPY static /static
EXPOSE 8000
CMD [ "/trystuff" ]
