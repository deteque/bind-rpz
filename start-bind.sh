docker run \
	--rm \
	--detach \
	--name bind \
	--volume /etc/namedb:/etc/namedb \
	--network host \
	deteque/bind-rpz
