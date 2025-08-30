FROM phusion/baseimage:focal-1.2.0

LABEL maintainer="dlandon"

ENV	DEBCONF_NONINTERACTIVE_SEEN="true" \
	DEBIAN_FRONTEND="noninteractive" \
	DISABLE_SSH="true" \
	HOME="/root" \
	LC_ALL="C.UTF-8" \
	LANG="en_US.UTF-8" \
	LANGUAGE="en_US.UTF-8" \
	TZ="Etc/UTC" \
	TERM="xterm" \
	PHP_VERS="7.4" \
	ZM_VERS="1.36" \
	PUID="99" \
	PGID="100"

COPY init/ /etc/my_init.d/
COPY defaults/ /root/
COPY zmeventnotification/ /root/zmeventnotification/

RUN echo -e "Package: php8.4*\nPin: release *\nPin-Priority: -1" > /etc/apt/preferences.d/no-php8.4 && \
	apt-get update --allow-releaseinfo-change && \
	add-apt-repository -y ppa:iconnor/zoneminder-$ZM_VERS && \
	add-apt-repository ppa:ondrej/php && \
	add-apt-repository ppa:ondrej/apache2 && \
	apt-get update --allow-releaseinfo-change && \
	apt-get -y install --no-install-recommends apache2 mariadb-server mariadb-client ssmtp mailutils net-tools \
		wget sudo make php$PHP_VERS php$PHP_VERS-fpm libapache2-mod-php$PHP_VERS php$PHP_VERS-mysql php$PHP_VERS-gd \
		php-intl php$PHP_VERS-intl php$PHP_VERS-apc libcrypt-mysql-perl libyaml-perl libjson-perl libavutil-dev \
		ffmpeg libvlc-dev libvlccore-dev vlc-bin vlc-plugin-base vlc-plugin-video-output zoneminder \
		vainfo i965-va-driver libva2 && \
	apt-mark hold php8.4 php8.4-* || true && \
	apt-get -y autoremove && \
	apt-get -y clean && \
	rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
		
RUN  cp /etc/mysql/mariadb.conf.d/50-server.cnf /etc/mysql/mariadb.cnf && \
     adduser www-data video && \
     a2enmod php$PHP_VERS proxy_fcgi setenvif ssl rewrite expires headers && \
     a2enconf php$PHP_VERS-fpm zoneminder && \
     echo "extension=mcrypt.so" > /etc/php/$PHP_VERS/mods-available/mcrypt.ini && \
     perl -MCPAN -e "force install Net::WebSocket::Server" && \
     perl -MCPAN -e "force install LWP::Protocol::https" && \
     perl -MCPAN -e "force install Config::IniFiles" && \
     perl -MCPAN -e "force install Net::MQTT::Simple" && \
     perl -MCPAN -e "force install Net::MQTT::Simple::Auth" && \
     perl -MCPAN -e "force install Config::Tiny"

RUN	systemd-tmpfiles --create zoneminder.conf && \
	mv /root/zoneminder /etc/init.d/zoneminder && \
	chmod +x /etc/init.d/zoneminder

RUN	mv /root/default-ssl.conf /etc/apache2/sites-enabled/default-ssl.conf && \
	mkdir /etc/apache2/ssl/ && \
	mkdir -p /var/lib/zmeventnotification/images && \
	chown -R www-data:www-data /var/lib/zmeventnotification/ && \
	chmod -R +x /etc/my_init.d/ && \
	cp -p /etc/zm/zm.conf /root/zm.conf && \
	echo "#!/bin/sh\n\n/usr/bin/zmaudit.pl -f" >> /etc/cron.weekly/zmaudit && \
	chmod +x /etc/cron.weekly/zmaudit && \
	cp /etc/apache2/ports.conf /etc/apache2/ports.conf.default && \
	cp /etc/apache2/sites-enabled/default-ssl.conf /etc/apache2/sites-enabled/default-ssl.conf.default && \
	echo "ServerName localhost" >> /etc/apache2/apache2.conf

RUN	apt-get -y remove make && \
	/etc/my_init.d/20_apt_update.sh

VOLUME \
	["/config"] \
	["/var/cache/zoneminder"]

EXPOSE 80 443 9000

CMD ["/sbin/my_init"]
