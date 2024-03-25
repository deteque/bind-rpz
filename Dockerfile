FROM debian:bookworm-slim
LABEL maintainer="Deteque <admin-deteque@spamhaus.com>"
LABEL build_date="2024-03-25"
ENV BIND_VERSION 9.18.25

WORKDIR /tmp
RUN apt-get clean \
	&& apt-get update \
	&& apt-get -y dist-upgrade \
	&& apt-get install --no-install-recommends --no-install-suggests -y \
		apt-transport-https \
		apt-utils \
		bazel-bootstrap \
		bison \
		build-essential \
		ca-certificates \
		dh-autoreconf \
		dnstop \
		ethstats \
		flex \
		git \
		iftop \
		libcap-dev \
		libcurl4-openssl-dev \
		libevent-dev \
		libexpat1-dev \
		libfstrm-dev \
		libnghttp2-dev \
		libpcap-dev \
		libprotobuf-c-dev \
		libprotobuf-dev \
		libreadline-dev \
		libssl-dev \
		libuv1-dev \
		libxml2-dev \
		libnghttp2-dev \
		locate \
		lsb-release \
		net-tools \
		net-tools\
		php-cli \
		php-curl \
		php-mysql \
		pkg-config \
		procps \
		protobuf-c-compiler \
		python3-pip \
		python3-ply \
		rsync \
		sipcalc \
		sysstat \
		vim \
		wget

WORKDIR /tmp
RUN	wget -O /tmp/bind-${BIND_VERSION}.tar.xz https://downloads.isc.org/isc/bind9/${BIND_VERSION}/bind-${BIND_VERSION}.tar.xz \
	&& tar Jxvf bind-${BIND_VERSION}.tar.xz

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
