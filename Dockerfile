FROM alpine:3.15

ARG MAKE_JOBS=8

WORKDIR /root

# needed for pipewire
ENV XDG_RUNTIME_DIR='/root'

# although we will use pipewire instead of jack, we need the
# header bindings that aren't available for pipewire-jack. so we
# will instead compile against native jack but replace it later

RUN apk update && apk add \
    jack \
    jack-dev \
    git \
    emacs \
    vim

# ------------------  SUPERCOLLIDER

RUN apk add \
    alsa-lib-dev \
    boost-dev \
    boost-static \
    cmake \
    eudev-dev \
    fftw-dev \
    libsndfile-dev \
    libxt-dev \
    linux-headers \
    ncurses-dev \
    portaudio-dev \
    readline-dev \
    samurai \
    yaml-cpp-dev \
    g++ \
    make

RUN git clone --depth 1 --branch 3.13 https://github.com/SuperCollider/SuperCollider.git \
    && cd SuperCollider \
    && git submodule update --init --recursive \
    && mkdir -p /root/SuperCollider/build

WORKDIR /root/SuperCollider

# apply patch for alpine, see
# https://github.com/supercollider/supercollider/issues/5197#issuecomment-1047188442
COPY build/sc-alpine.patch .
RUN apk add patch && patch < sc-alpine.patch

WORKDIR /root/SuperCollider/build
RUN cmake \
	-DCMAKE_BUILD_TYPE=Release \
	-DSUPERNOVA=OFF \
	-DSC_ED=OFF \
	-DSC_EL=ON \
	-DSC_VIM=ON \
	-DNATIVE=ON \
	-DSC_IDE=OFF \
	-DNO_X11=ON \
	-DSC_ABLETON_LINK=OFF \
	-DSC_QT=OFF .. \
	&& cmake --build . --config Release --target all -j${MAKE_JOBS} \
    && cmake --build . --config Release --target install -j${MAKE_JOBS} \
    && rm -rf /root/SuperCollider

# now we replace jack with pipewire which is more stable
# in a virtualized environment than jack, which resulted
# in an unstable clock and dropouts

RUN apk del jack jack-dev

WORKDIR /root

# Install sc3-plugins
RUN git clone --depth 1 --branch "Version-3.13.0" https://github.com/supercollider/sc3-plugins.git \
  && cd sc3-plugins \
  && git submodule update --init --recursive \
  && mkdir -p /root/sc3-plugins/build

WORKDIR /root/sc3-plugins/build
RUN cmake \
  -DSC_PATH=/usr/local/include/SuperCollider \
  -DCMAKE_BUILD_TYPE=Release \
  -DNATIVE=ON \
  -DQUARKS=ON \
  -DSUPERNOVA=OFF .. \
  && cmake --build . --config Release -j${MAKE_JOBS} \
  && cmake --build . --config Release --target install -j${MAKE_JOBS} \
  && rm -rf /root/sc3-plugins \
  && mv /usr/local/share/SuperCollider/SC3plugins /usr/local/share/SuperCollider/Extensions/SC3plugins

WORKDIR /root

# ------------------  TIDAL CYCLES

WORKDIR /usr/local/share/SuperCollider/Extensions
RUN git clone --depth 1 --branch "v1.7.3" https://github.com/musikinformatik/SuperDirt.git \
  && git clone --depth 1 https://github.com/tidalcycles/Dirt-Samples.git \
  && git clone --depth 1 https://github.com/supercollider-quarks/Vowel.git

WORKDIR /root

RUN apk add cabal wget ghc libffi-dev \
  && cabal update \
  && cabal install tidal --lib

# ------------------  PIPEWIRE

RUN apk add \
    pipewire \
    pipewire-jack \
    pipewire-tools \
    pipewire-media-session

# ------------------  GSTREAMER

RUN apk add \
    gstreamer \
    gstreamer-dev \
    gst-plugins-good \
    gst-plugin-pipewire \
    gstreamer-tools

# ------------------  JANUS

RUN apk add \
    autoconf \
    automake \
    libtool \
    gengetopt \
    lua5.3-dev \
    cmake \
    libsrtp-dev \
	libnice-dev \
    jansson-dev \
    libconfig-dev \
    libusrsctp-dev \
    libmicrohttpd-dev \
	libwebsockets-dev \
    rabbitmq-c-dev \
    curl-dev \
    libogg-dev \
    libopusenc-dev \
	lua \
    duktape-dev \
    npm \
    ffmpeg-dev \
    zlib-dev \
    libogg-dev \
	libuv-dev \
    sofia-sip-dev

RUN git clone --depth 1 --branch "v0.14.3" https://github.com/meetecho/janus-gateway.git && \
    cd janus-gateway && \
    ./autogen.sh && \
    ./configure \
    --prefix=/opt/janus \
    --disable-rabbitmq \
	--disable-mqtt && \
    make -j ${MAKE_JOBS} && \
    make install && \
    make configs && \
    rm -rf /root/janus-gateway

# moreutils contains sponge which is needed for this
# https://stackoverflow.com/a/74551579/3475778
RUN apk add parallel moreutils

# ------------------  SUPERVISOR

RUN apk add supervisor

# ------------------  TTYD

RUN apk add ttyd tmux ncurses && \
  mkdir -p /config

COPY config/tmux.conf /config/tmux.conf

COPY build/terminfo-24bit.src /root/terminfo-24bit.src
RUN tic -x -o ~/.terminfo terminfo-24bit.src && \
  rm /root/terminfo-24bit.src

ENV MODE=both
ENV TTYD_BG_COLOR=1e1e2e

# ------------------  EMACS

# index SC docs so they can be accessed via w3m browser in emacs
RUN echo "SCDoc.renderAll();0.exit;" > docs.scd \
  && sclang /root/docs.scd \
  && rm docs.scd

RUN apk add w3m
RUN mkdir emacs \
  && git clone --depth 1 https://github.com/jwiegley/use-package.git emacs/use-package \
  && git clone https://github.com/catppuccin/emacs.git /tmp/catppuccin \
  && cd /tmp/catppuccin \
  && git checkout d990be3 \
  && cp /tmp/catppuccin/catppuccin-theme.el /config \
  && rm -r /tmp/catppuccin

COPY config/init.el /config/init.el

# smaller header for new sclang buffers
RUN sed -i 's/	  (insert line)/;;	  (insert line)/g' /usr/local/share/emacs/site-lisp/SuperCollider/sclang-interp.el \
  && rm /usr/local/share/emacs/site-lisp/SuperCollider/sclang-interp.elc

# ------------------  WEBPAGES

RUN apk add nginx
COPY web /config/web

# ------------------  USER

RUN apk add shadow \
    && usermod -a -G audio root

# ------------------  CONFIGS

COPY stream/start_stream.sh /config/stream/start_stream.sh
COPY stream/kill_stream.sh /config/stream/kill_stream.sh
COPY stream/startup.scd /config/stream/startup.scd
COPY stream/SCStreamer/ /usr/local/share/SuperCollider/Extensions/SCStreamer/

COPY config/supervisor.conf /root/supervisor.conf
COPY config/pipewire.conf /usr/share/pipewire/pipewire.conf
COPY config/start_ttyd.sh /root/start_ttyd.sh
COPY config/start_container.sh /root/start_container.sh

ENV JANUS_PUBLIC_IP=127.0.0.1
COPY janus/janus.jcfg /opt/janus/etc/janus/janus.jcfg
COPY janus/janus.plugin.streaming.jcfg /opt/janus/etc/janus/janus.plugin.streaming.jcfg
# COPY janus/janus.plugin.audiobridge.jcfg /opt/janus/etc/janus/janus.plugin.audiobridge.jcfg
# COPY janus/janus.plugin.audiobridge.jcfg.template /root/janus.plugin.audiobridge.jcfg.template
# COPY janus/janus.plugin.streaming.jcfg.template /root/janus.plugin.streaming.jcfg.template
# COPY janus/create_config.sh /root/create_config.sh

RUN mkdir /config/sclang-includes \
  && chmod -R +x /config

CMD ["/bin/sh", "-c", "/root/start_container.sh && supervisord -c /root/supervisor.conf"]
