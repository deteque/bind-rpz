FROM debian:bullseye-slim
LABEL maintainer="Andrew Fried <afried@deteque.com>"
ENV BIND_VERSION 9.18.2
ENV BUILD_DATE 2022-04-21

WORKDIR /tmp
RUN apt-get clean \
	&& apt-get update \
	&& apt-get -y dist-upgrade \
	&& apt-get install --no-install-recommends --no-install-suggests -y \
		apt-utils \
		build-essential \
		dh-autoreconf \
		dnstop \
		ethstats \
		git \
		iftop \
		libcap-dev \
		libcurl4-openssl-dev \
		libevent-dev \
		libnghttp2-dev \
		libpcap-dev \
		libreadline-dev \
		libssl-dev \
		libuv1-dev \
		libxml2-dev \
		net-tools \
		pkg-config \
		procps \
		python3-pip \
		sipcalc \
		sysstat \
		vim \
		wget \
	&& pip install -U pip \
	&& apt-get install -y python-ply

WORKDIR /tmp
RUN	wget -O /tmp/bind-${BIND_VERSION}.tar.xz https://downloads.isc.org/isc/bind9/${BIND_VERSION}/bind-${BIND_VERSION}.tar.xz \
	&& tar Jxvf bind-${BIND_VERSION}.tar.xz \
	&& git clone https://github.com/google/protobuf \
        && git clone https://github.com/protobuf-c/protobuf-c \
        && git clone https://github.com/farsightsec/fstrm 

WORKDIR /tmp/protobuf
RUN	autoreconf -i \
	&& ./configure \
	&& make \
	&& make install \
	&& ldconfig

WORKDIR /tmp/protobuf-c
RUN	autoreconf -i \
	&& ./configure \
	&& make \
	&&  make install

WORKDIR /tmp/fstrm
RUN	autoreconf -i \
 	&& ./configure \
 	&& make \
 	&& make install \
 	&& ldconfig

WORKDIR /tmp/bind-${BIND_VERSION}
RUN	./configure \
		--enable-threads \
		--with-randomdev=/dev/urandom \
		--prefix=/usr \
		--sysconfdir=/etc \
		--datadir=/etc/namedb \
		--with-openssl=yes \
		--with-tuning=large \
		--enable-largefile \
		--with-aes \
		--with-libxml2=yes \
		--with-libjson=no \
		--enable-dnstap \
	&& make \
	&& make install \
	&& rm -rf /tmp/bind* \
	&& ln -s /etc/namedb/rndc.conf /etc/rndc.conf \
	&& ln -s /etc/namedb/named.conf /etc/named.conf \
	&& sync \
	&& ldconfig \
	&& mkdir /root/bind

COPY rndc.conf /root/bind/
COPY named.conf /root/bind/
COPY update-root-cache.sh /root/bind/
COPY start-bind.sh /root/bind/
COPY root.cache /root/bind/

EXPOSE 53/tcp 53/udp

CMD ["named","-c","/etc/namedb/named.conf","-f"]
