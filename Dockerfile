FROM amazoncorretto:25-alpine-jdk
LABEL org.opencontainers.image.authors="Haiyo.Lunarstar!"

RUN apk upgrade --no-cache \
    && apk --no-cache add \
        bash \
        bash-completion \
        bash-doc \
        ca-certificates \
        graphicsmagick \
        ghostscript \
        ffmpeg \
        curl \
        exiftool \
        ttf-dejavu \
        fontconfig \
        su-exec \
        shadow \
    && update-ca-certificates

ENV PUID=0
ENV PGID=0

RUN busybox curl -o /tmp/CrushFTP11.zip https://www.crushftp.com/early11/CrushFTP11.zip
ADD ./setup.sh /var/opt/setup.sh

RUN chmod +x /var/opt/setup.sh

VOLUME [ "/var/opt/CrushFTP11" ]

ENTRYPOINT [ "/bin/bash", "/var/opt/setup.sh" ]

HEALTHCHECK --interval=1m --timeout=3s \
  CMD ps aux | grep -v grep | grep -q "CrushFTPJarProxy.jar" || exit 1

ENV CRUSH_ADMIN_PROTOCOL=http
ENV CRUSH_ADMIN_PORT=8080

EXPOSE 21 443 2000-2100 2222 8080 9090
