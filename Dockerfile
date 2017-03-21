FROM debian:jessie


# see https://trac.ffmpeg.org/wiki/CompilationGuide/Ubuntu
# for detailed instructions on how to build ffmpeg


ENV BUILD_DEPS "libvpx-dev libopus-dev libmp3lame-dev mercurial cmake yasm autoconf automake build-essential libass-dev libfreetype6-dev libsdl2-dev libtheora-dev libtool libvorbis-dev pkg-config texinfo zlib1g-dev wget"
ENV BIN_DIR "/usr/local/bin"
ENV BUILD_DIR "/ffmpeg_build"
ENV SOURCE_DIR "/ffmpeg_sources"

RUN mkdir ${BUILD_DIR} \
  && mkdir ${SOURCE_DIR} \
  # download and install all necessary packages
  && apt-get update \
  && apt-get install -y ${BUILD_DEPS} \
  # compile x264
  && cd ${SOURCE_DIR} \
  && wget http://download.videolan.org/pub/x264/snapshots/last_x264.tar.bz2 \
  && tar xjvf last_x264.tar.bz2 \
  && cd x264-snapshot* \
  && ./configure --prefix="${BUILD_DIR}" --bindir="${BIN_DIR}" --enable-static --disable-opencl \
  && make \
  && make install \
  # compile x265
  && cd ${SOURCE_DIR} \
  && hg clone https://bitbucket.org/multicoreware/x265 \
  && cd ${SOURCE_DIR}/x265/build/linux \
  && cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="${BUILD_DIR}" -DENABLE_SHARED:bool=off ../../source \
  && make \
  && make install \
  # compile libfdk-aac-dev
  && cd ${SOURCE_DIR} \
  && wget -O fdk-aac.tar.gz https://github.com/mstorsjo/fdk-aac/tarball/master \
  && tar xzvf fdk-aac.tar.gz \
  && cd mstorsjo-fdk-aac* \
  && autoreconf -fiv \
  && ./configure --prefix="${BUILD_DIR}" --disable-shared \
  && make \
  && make install \
  # libmp3lame-dev, libopus-dev and libvpx-dev are installed via the official repsotories. no need for compiling
  # now lets compile ffmpeg
  && cd ${SOURCE_DIR} \
  && wget http://ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2 \
  && tar xjvf ffmpeg-snapshot.tar.bz2 \
  && cd ffmpeg \
  && PKG_CONFIG_PATH="${BUILD_DIR}/lib/pkgconfig" ./configure \
    --prefix="${BUILD_DIR}" \
    --pkg-config-flags="--static" \
    --extra-cflags="-I${BUILD_DIR}/include" \
    --extra-ldflags="-L${BUILD_DIR}/lib" \
    --bindir="${BIN_DIR}" \
    --enable-gpl \
    --enable-libass \
    --enable-libfdk-aac \
    --enable-libfreetype \
    --enable-libmp3lame \
    --enable-libopus \
    --enable-libtheora \
    --enable-libvorbis \
    --enable-libvpx \
    --enable-libx264 \
    --enable-libx265 \
    --enable-nonfree \
  && make \
  && make install \
  && hash -r \
  && apt-get remove --purge -y $BUILD_DEPS \
  && rm -rf /var/lib/apt/lists/* ${BUILD_DIR} ${SOURCE_DIR}

# execute ffmpeg on container execution
ENTRYPOINT ["/usr/local/bin/ffmpeg"]
