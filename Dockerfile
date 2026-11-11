FROM alpine:3.20
RUN apk add --no-cache bash
WORKDIR /app
COPY app/app.sh /app/app.sh
RUN chmod +x /app/app.sh && adduser -D -H appuser
USER appuser
ENTRYPOINT ["/app/app.sh"]
CMD ["help"]
