#!/bin/sh
mkdir -p /etc/namedb
/usr/bin/wget --user=ftp --password=ftp ftp://ftp.rs.internic.net/domain/db.cache -O /etc/namedb/root.cache
docker run \
	--rm \
	--detach \
	--name bind \
	--volume /etc/namedb:/etc/namedb \
	--publish 53:53 \
	--publish 53:53/udp \
	deteque/bind-rpz
