FROM 0x01be/sigrok:lib as sigrok

FROM alpine as builder

COPY --from=sigrok /opt/sigrok/ /opt/sigrok/

RUN apk --no-cache add --virtual pulseview-build-dependencies \
    git \
    build-base \
    cmake \
    pkgconfig \
    python3-dev \
    glibmm-dev \
    libzip-dev \
    libusb-dev \
    libftdi1-dev \
    hidapi-dev \
    bluez-dev \
    boost-dev \
    libieee1284-dev


RUN apk --no-cache add --virtual pulseview-edge-build-dependencies \
    --repository http://dl-cdn.alpinelinux.org/alpine/edge/community \
    qt5-qtbase-dev \
    qt5-qttools-dev \
    qt5-qtsvg-dev

RUN git clone --depth 1 git://sigrok.org/pulseview.git /pulseview

RUN mkdir -p /pulseview/build
WORKDIR /pulseview/build

ENV SIGROK_CLI_LIBS /opt/sigrok/lib
ENV PKG_CONFIG_PATH $SIGROK_CLI_LIBS/pkgconfig/

RUN cmake \
    -DCMAKE_INSTALL_PREFIX=/opt/pulseview \
    -DENABLE_DECODE=ON \
    ..
RUN make VERBOSE=1
RUN make install

FROM 0x01be/xpra

COPY --from=builder /opt/pulseview/ /opt/pulseview/

RUN apk add --no-cache --virtual pulseview-edge-runtime-dependencies \
    --repository http://dl-cdn.alpinelinux.org/alpine/edge/community \
    qt5-qtbase \
    qt5-qtsvg \
    gtk+3.0

RUN apk add --no-cache --virtual pulseview-runtime-dependencies \
    boost \
    libieee1284-dev \
    glibmm-dev \
    libzip-dev \
    libusb-dev \
    libftdi1-dev \
    hidapi-dev \
    bluez-dev

COPY --from=sigrok /opt/sigrok/ /opt/sigrok/
ENV LD_LIBRARY_PATH $LD_LIBRARY_PATH:/opt/sigrok/lib

#COPY --from=sigrok /opt/sigrock/ /opt/sigrock/
ENV PATH $PATH:/opt/pulseview/bin/
#ENV PATH $PATH:/opt/sigrok/bin/:/opt/pulseview/bin/

EXPOSE 10000

VOLUME /workspace
WORKDIR /workspace

CMD /usr/bin/xpra start --bind-tcp=0.0.0.0:10000 --html=on --start-child="pulseview" --exit-with-children --daemon=no --xvfb="/usr/bin/Xvfb +extension  Composite -screen 0 1280x720x24+32 -nolisten tcp -noreset" --pulseaudio=no --notifications=no --bell=no --mdns=no

