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

RUN	add-apt-repository -y ppa:iconnor/zoneminder-$ZM_VERS && \
	add-apt-repository ppa:ondrej/php && \
	add-apt-repository ppa:ondrej/apache2 && \
	apt-get update && \
	apt-get -y upgrade -o Dpkg::Options::="--force-confold" && \
	apt-get -y dist-upgrade -o Dpkg::Options::="--force-confold" && \
	apt-get -y install apache2 mariadb-server && \
	apt-get -y install ssmtp mailutils net-tools wget sudo make && \
	apt-get -y install php$PHP_VERS php$PHP_VERS-fpm libapache2-mod-php$PHP_VERS php$PHP_VERS-mysql php$PHP_VERS-gd php-intl php$PHP_VERS-intl php$PHP_VERS-apc && \
	apt-get -y install libcrypt-mysql-perl libyaml-perl libjson-perl libavutil-dev ffmpeg && \
	apt-get -y install --no-install-recommends libvlc-dev libvlccore-dev vlc-bin vlc-plugin-base vlc-plugin-video-output && \
	apt-get -y install zoneminder
	
RUN	rm /etc/mysql/my.cnf && \
	cp /etc/mysql/mariadb.conf.d/50-server.cnf /etc/mysql/my.cnf && \
	adduser www-data video && \
	a2enmod php$PHP_VERS proxy_fcgi setenvif ssl rewrite expires headers && \
	a2enconf php$PHP_VERS-fpm zoneminder && \
	echo "extension=mcrypt.so" > /etc/php/$PHP_VERS/mods-available/mcrypt.ini && \
	perl -MCPAN -e "force install Net::WebSocket::Server" && \
	perl -MCPAN -e "force install LWP::Protocol::https" && \
	perl -MCPAN -e "force install Config::IniFiles" && \
	perl -MCPAN -e "force install Net::MQTT::Simple" && \
	perl -MCPAN -e "force install Net::MQTT::Simple::Auth"

RUN	cd /root && \
	chown -R www-data:www-data /usr/share/zoneminder/ && \
	echo "ServerName localhost" >> /etc/apache2/apache2.conf && \
	sed -i "s|^;date.timezone =.*|date.timezone = ${TZ}|" /etc/php/$PHP_VERS/apache2/php.ini && \
	service mysql start && \
	mysql -uroot -e "grant all on zm.* to 'zmuser'@localhost identified by 'zmpass';" && \
	mysqladmin -uroot reload && \
	mysql -sfu root < "mysql_secure_installation.sql" && \
	rm mysql_secure_installation.sql && \
	mysql -sfu root < "mysql_defaults.sql" && \
	rm mysql_defaults.sql

RUN	systemd-tmpfiles --create zoneminder.conf && \
	mv /root/zoneminder /etc/init.d/zoneminder && \
	chmod +x /etc/init.d/zoneminder && \
	service mysql restart && \
	sleep 5 && \
	service apache2 restart && \
	service zoneminder start

RUN	mv /root/default-ssl.conf /etc/apache2/sites-enabled/default-ssl.conf && \
	mkdir /etc/apache2/ssl/ && \
	mkdir -p /var/lib/zmeventnotification/images && \
	chown -R www-data:www-data /var/lib/zmeventnotification/ && \
	chmod -R +x /etc/my_init.d/ && \
	cp -p /etc/zm/zm.conf /root/zm.conf && \
	echo "#!/bin/sh\n\n/usr/bin/zmaudit.pl -f" >> /etc/cron.weekly/zmaudit && \
	chmod +x /etc/cron.weekly/zmaudit && \
	cp /etc/apache2/ports.conf /etc/apache2/ports.conf.default && \
	cp /etc/apache2/sites-enabled/default-ssl.conf /etc/apache2/sites-enabled/default-ssl.conf.default

RUN	apt-get -y remove make && \
	apt-get -y autoremove && \
	rm -rf /tmp/* /var/tmp/* && \
	chmod +x /etc/my_init.d/*.sh && \
	/etc/my_init.d/20_apt_update.sh

VOLUME \
	["/config"] \
	["/var/cache/zoneminder"]

EXPOSE 80 443 9000

CMD ["/sbin/my_init"]
