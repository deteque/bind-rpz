FROM debian:buster-slim
LABEL maintainer="Andrew Fried <afried@deteque.com>"
ENV BIND_VERSION 9.14.9

WORKDIR /tmp
RUN mkdir /root/bind \
	&& apt-get clean \
	&& apt-get update \
	&& apt-get -y dist-upgrade \
	&& apt-get install --no-install-recommends --no-install-suggests -y \
		apt-utils \
		build-essential \
		dnstop \
		ethstats \
		iftop \
		libcap-dev \
		libcurl4-openssl-dev \
		libevent-dev \
		libpcap-dev \
		libreadline-dev \
		libssl-dev \
		libxml2-dev \
		net-tools \
		procps \
		python-pip \
		sipcalc \
		sysstat \
		vim \
		wget \
	&& pip install -U pip \
	&& apt-get install -y python-ply \
	&& wget -O bind-${BIND_VERSION}.tar.gz https://downloads.isc.org/isc/bind9/${BIND_VERSION}/bind-${BIND_VERSION}.tar.gz \
	&& tar zxvf bind-${BIND_VERSION}.tar.gz \
	&& cd bind-${BIND_VERSION}\
	&& ./configure \
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
	&& make \
	&& make install \
	&& rm -rf /tmp/bind* \
	&& ln -s /etc/namedb/rndc.conf /etc/rndc.conf \
	&& ln -s /etc/namedb/named.conf /etc/named.conf \
	&& sync \
	&& ldconfig 

COPY rndc.conf /root/bind
COPY named.conf /root/bind
COPY update-root-cache.sh /root/bind
COPY start-bind.sh /root/bind
COPY root.cache /root/bind

EXPOSE 53/tcp 53/udp

CMD ["named","-c","/etc/namedb/named.conf","-f"]
