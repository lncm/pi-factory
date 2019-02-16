FROM alpine:3.9

RUN apk add bash \
            parted \
            wget \
            gnupg

RUN mkdir -p /src/

COPY ./make_all.sh /src/
COPY ./ncopa.asc /src/

COPY ./etc /src/etc/
COPY ./home /src/home/
COPY ./usr /src/usr/
COPY ./defaults /src/defaults/

WORKDIR /src/

ENV VERSION "v0.5.0"
ENV ALPINE_IMAGE "alpine-rpi-3.9.0-armhf.tar.gz"

RUN chmod +x /src/make_all.sh

VOLUME /src/downloads/
VOLUME /bin/

CMD [ "/src/make_all.sh" ]
