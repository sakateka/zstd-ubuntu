FROM ubuntu:trusty-20170119

# Required system packages
RUN apt-get update \
    && apt-get install -y \
        wget unzip build-essential \
        libpcre3-dev libssl-dev liblzma-dev liblz4-dev \
        devscripts debhelper

RUN mkdir -p /build/src
WORKDIR /build
COPY debian /build/src/debian

ARG DEBVERSION
ARG DEBFULLNAME
ARG DEBEMAIL

ENV DEBFULLNAME $DEBFULLNAME
ENV DEBEMAIL $DEBEMAIL

# Download packages
RUN wget -O /zstd_$DEBVERSION.tar.gz https://github.com/facebook/zstd/archive/v$DEBVERSION.tar.gz \
    && tar xfz /zstd_$DEBVERSION.tar.gz

# Compile and install
RUN cd /build/zstd-$DEBVERSION \
    && make install DESTDIR=/build/src
RUN cd /build/zstd-$DEBVERSION/contrib/pzstd \
    && make install DESTDIR=/build/src
WORKDIR /build/src

RUN sed -i "s/DEBFULLNAME/$DEBFULLNAME/" /build/src/debian/control
RUN sed -i "s/DEBEMAIL/$DEBEMAIL/" /build/src/debian/control
# Build deb
RUN /usr/bin/dch --newversion=$DEBVERSION -D trusty "Debianization for $DEBVERSION"
RUN debuild -us -uc
RUN mkdir -p /build/artifacts
RUN find /build -maxdepth 1 -type f -name "*$DEBVERSION*"|xargs -n1 -I _ mv -v _ /build/artifacts/
