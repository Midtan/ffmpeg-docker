## building
FROM alpine:edge AS builder

RUN tail /etc/apk/repositories -n 1|sed s/community/testing/>>/etc/apk/repositories

# Installing build dependencies
RUN apk add --no-cache --update --virtual .build-deps \
    autoconf \
    automake \
    cmake \
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
    gzip \
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

# Building dependencies

# Building x264
WORKDIR /tmp/x264
RUN curl -s --ftp-method nocwd ftp://ftp.videolan.org/pub/videolan/x264/snapshots/last_stable_x264.tar.bz2 | tar jxf - -C . --strip-components 1
RUN ./configure --enable-static --disable-shared --enable-pic --enable-lto
RUN make -j 8 && make install
RUN cp libx264.a /usr/local/libass
RUN cp x264_config.h x264.h /usr/local/include

# Building x265
WORKDIR /tmp/x265
# This should not depend on a specific version
RUN curl -s -L https://bitbucket.org/multicoreware/x265/downloads/x265_3.1.2.tar.gz | tar zxf - -C . --strip-components 1
WORKDIR /tmp/x265/build/linux
RUN cmake ../../source -DCMAKE_BUILD_TYPE=RELEASE -DBUILD_SHARED_LIBS=OFF
RUN ./multilib.sh
RUN cp ./8bit/libx265.a /usr/local/lib/libx265.a
RUN cp ./8bit/x265.pc /usr/local/lib/pkgconfig/
RUN cp ./8bit/x265_config.h /usr/local/include/
RUN cp ../../source/x265.h /usr/local/include 

# Building fdk-aac
WORKDIR /tmp/fdk-aac
# This should not depend on a specific version
RUN curl -s -L https://github.com/mstorsjo/fdk-aac/archive/v2.0.0.tar.gz | tar zxf - -C . --strip-components 1
RUN ./autogen.sh
RUN ./configure --enable-static --disable-shared
RUN make -j 8 && make install

# Building lame
WORKDIR /tmp/lame
# This should not depend on a specific version
RUN curl -s -L https://downloads.sourceforge.net/project/lame/lame/3.100/lame-3.100.tar.gz | tar zxf - -C . --strip-components 1
RUN ./configure --enable-static --disable-shared 
RUN make -j 8 && make install

# Building ogg
WORKDIR /tmp/ogg
# This should not depend on a specific version
RUN curl -s -L https://ftp.osuosl.org/pub/xiph/releases/ogg/libogg-1.3.3.tar.gz | tar zxf - -C . --strip-components 1
RUN ./configure --enable-static --disable-shared 
RUN make -j 8 && make install

# Building vorbis
WORKDIR /tmp/vorbis
# This should not depend on a specific version
RUN curl -s -L https://ftp.osuosl.org/pub/xiph/releases/vorbis/libvorbis-1.3.6.tar.gz | tar zxf - -C . --strip-components 1
RUN ./configure --enable-static --disable-shared 
RUN make -j 8 && make install

# Building theora
WORKDIR /tmp/theora
RUN git clone https://github.com/xiph/theora.git .
RUN autogen.sh
RUN ./configure --enable-static --disable-shared 
RUN make -j 8 && make install

# Building speex
WORKDIR /tmp/speex
# This should not depend on a specific version
RUN curl -s -L https://ftp.osuosl.org/pub/xiph/releases/speex/speex-1.2.0.tar.gz | tar zxf - -C . --strip-components 1
RUN ./configure --enable-static --disable-shared 
RUN make -j 8 && make install

# Building xvid
WORKDIR /tmp/xvid
# This should not depend on a specific version
RUN curl -s -L http://downloads.xvid.org/downloads/xvidcore-1.3.5.tar.gz | tar zxf - -C . --strip-components 1
WORKDIR /tmp/xvid/build/generic
RUN ./configure --enable-static --disable-shared 
RUN make -j 8 && make install

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
