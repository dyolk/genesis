
FROM  golang:1.26-alpine AS builder

WORKDIR /app

COPY go.mod main.go ./

RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o server main.go

FROM scratch AS runtime

COPY --from=builder /app/server /server

EXPOSE 8080

CMD ["/server"]
