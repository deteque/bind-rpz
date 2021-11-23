docker run \
	--rm \
	--detach \
	--name bind \
	--volume /etc/namedb:/etc/namedb \
	deteque/bind-rpz
