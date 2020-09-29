FROM alpine
#
# Install packages
RUN    apk -U add \
                 ca-certificates \
                 curl \
                 file \
                 geoip \
                 hiredis \
                 jansson \
                 libcap-ng \
                 libmagic \
		 libmaxminddb \
                 libnet \
                 libnetfilter_queue \
                 libnfnetlink \
                 libpcap \
                 luajit \
                 lz4-libs \
                 musl \
                 nspr \
                 nss \
                 pcre \
                 yaml \
                 wget \
                 automake \
                 autoconf \
                 build-base \
                 cargo \
                 file-dev \
                 geoip-dev \
                 hiredis-dev \
                 jansson-dev \
                 libtool \
                 libcap-ng-dev \
                 luajit-dev \
		         libmaxminddb-dev \
                 libpcap-dev \
                 libnet-dev \
                 libnetfilter_queue-dev \
                 libnfnetlink-dev \
                 lz4-dev \
                 nss-dev \
                 nspr-dev \
                 pcre-dev \
                 python3 \
                 ethtool \
                 rust \
                 yaml-dev && \
#
# We need latest libhtp[-dev] which is only available in community
    apk -U add --repository=http://dl-cdn.alpinelinux.org/alpine/edge/community \
               libhtp \
               libhtp-dev && \
#
# Upgrade pip, install suricata-update to meet deps, however we will not be using it
# to reduce image (no python needed) and use the update script.
    pip3 install --no-cache-dir --upgrade pip && \
    pip3 install --no-cache-dir suricata-update

ADD . /opt/builder

WORKDIR /opt/builder

RUN ./autogen.sh
RUN ./configure \
	--prefix=/usr \
	--sysconfdir=/etc \
	--mandir=/usr/share/man \
	--localstatedir=/var \
	--enable-non-bundled-htp \
	--enable-nfqueue \
        --enable-rust \
	--disable-gccmarch-native \
	--enable-hiredis \
	--enable-geoip \
	--enable-gccprotect \
	--enable-pie \
	--enable-luajit
RUN make -j 8 && \
    make check && \
    make install && \
    make install-full

# Setup user, groups and configs
RUN addgroup -g 2000 suri && \
    adduser -S -H -u 2000 -D -g 2000 suri && \
    chmod 644 /etc/suricata/*.config && \
    cp /root/dist/suricata.yaml /etc/suricata/suricata.yaml && \
    mkdir -p /etc/suricata/rules && \
    cp /opt/builder/rules/* /etc/suricata/rules/
#
# Download the latest EmergingThreats ruleset, replace rulebase and enable all rules
RUN cp /root/dist/update.sh /usr/bin/ && \
    chmod 755 /usr/bin/update.sh && \
    update.sh

COPY docker-entrypoint.sh /
RUN chmod 755 /docker-entrypoint.sh
