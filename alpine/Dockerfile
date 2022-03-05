FROM docker.io/amd64/alpine:edge
LABEL maintainer="Leo <thinkabit.ukim@gmail.com>"

RUN rm /etc/apk/repositories && \
	printf -- >> /etc/apk/repositories \
  	'http://dl-cdn.alpinelinux.org/alpine/edge/%s\n' \
		main community testing && \
	printf -- >> /etc/apk/repositories \
		'/home/builder/packages/%s\n' \
		main community testing

RUN apk add --update-cache \
	alpine-conf \
	alpine-sdk \
	sudo \
	&& apk upgrade -a \
	&& setup-apkcache /var/cache/apk

RUN adduser -D builder -G users \
	&& addgroup builder abuild \
	&& echo 'builder ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

USER builder
WORKDIR /home/builder
COPY entrypoint.sh /home/builder
RUN mkdir packages

ENTRYPOINT ["/home/builder/entrypoint.sh"]
