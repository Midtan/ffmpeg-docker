## building
FROM alpine:edge AS builder

RUN tail /etc/apk/repositories -n 1|sed s/community/testing/>>/etc/apk/repositories

# Installing build dependencies
RUN apk add --no-cache --update --virtual .build-deps \
    autoconf \
    automake \
    libtool \
    git \
    python3-dev \
    lcms2-dev \
    imagemagick-dev \
    tesseract-ocr-dev \
    coreutils \
    build-base \
    curl \
    nasm \
    tar \
    bzip2 \
    zlib-dev \
    openssl-dev \
    yasm-dev \
    lame-dev \
    libogg-dev \
    x264-dev \
    x265-dev \
    libvpx-dev \
    libvorbis-dev \
    fdk-aac-dev \
    freetype-dev \
    libass-dev \
    libwebp-dev \
    libtheora-dev \
    linux-headers \
    opus-dev

# Building ffmpeg
WORKDIR /tmp
RUN curl -s http://ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2 | tar jxf - -C .
WORKDIR /tmp/ffmpeg
RUN ./configure --disable-debug --enable-static --enable-nonfree --enable-postproc --disable-shared --enable-small --enable-version3 --enable-swresample --enable-fontconfig --enable-gpl --enable-libass --enable-libfdk-aac --enable-libfreetype --enable-libmp3lame --enable-libopus --enable-libtheora --enable-libvorbis --enable-libvpx --enable-libwebp --enable-libx264 --enable-libx265 --enable-openssl
RUN make -j 8

## distribution
FROM alpine:latest

RUN apk add build-base

COPY --from=builder /tmp/ffmpeg/ffmpeg /usr/local/bin/ffmpeg
COPY --from=builder /tmp/ffmpeg/ffprobe /usr/local/bin/ffprobe

WORKDIR /
#ENTRYPOINT ["ffmpeg"]
