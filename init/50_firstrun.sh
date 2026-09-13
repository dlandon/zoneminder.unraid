#!/bin/bash
#
# 50_firstrun.sh
#

#
# Search for config files, if they don't exist, create the default ones
#
if [ ! -d /config/conf ]; then
	echo "Creating conf folder"
	mkdir /config/conf
else
	echo "Using existing conf folder"
fi

#
# Handle the zm.conf files
#
if [ ! -f /config/conf/zm.default ]; then
	echo "Copying zm.conf to config folder"
	cp /etc/zm/zm.conf /config/conf/zm.default
	cp /etc/zm/conf.d/README /config/conf/README
else
	echo "File zm.conf already copied"
fi

#
# Copy custom 99-mysql.conf to /etc/zm/conf.d/
#
if [ -f /config/conf/99-mysql.conf ]; then
	echo "Copy custom 99-mysql.conf to /etc/zm/conf.d/"
	cp /config/conf/99-mysql.conf /etc/zm/conf.d/99-mysql.conf
fi

#
# Handle the zmeventnotification.ini file
#
if [ -f /root/zmeventnotification/zmeventnotification.ini ]; then
	echo "Moving zmeventnotification.ini"
	cp /root/zmeventnotification/zmeventnotification.ini /config/zmeventnotification.ini.default
	if [ ! -f /config/zmeventnotification.ini ]; then
		mv /root/zmeventnotification/zmeventnotification.ini /config/zmeventnotification.ini
	else
		rm -f /root/zmeventnotification/zmeventnotification.ini
	fi
else
	echo "File zmeventnotification.ini already moved"
fi

#
# Handle the secrets.ini file
#
if [ -f /root/zmeventnotification/secrets.ini ]; then
	echo "Moving secrets.ini"
	cp /root/zmeventnotification/secrets.ini /config/secrets.ini.default
	if [ ! -f /config/secrets.ini ]; then
		mv /root/zmeventnotification/secrets.ini /config/secrets.ini
	else
		rm -f /root/zmeventnotification/secrets.ini
	fi
else
	echo "File secrets.ini already moved"
fi

#
# Handle the zmeventnotification.pl
#
if [ -f /root/zmeventnotification/zmeventnotification.pl ]; then
	echo "Moving the event notification server"
	mv /root/zmeventnotification/zmeventnotification.pl /usr/bin
	chmod 755 /usr/bin/zmeventnotification.pl 2>/dev/null
else
	echo "Event notification server already moved"
fi

#
# Handle the pushapi_pushover.pl
#
if [ -f /root/zmeventnotification/pushapi_pushover.pl ]; then
	echo "Moving the pushover api"
	mkdir -p /var/lib/zmeventnotification/bin/
	mv /root/zmeventnotification/pushapi_pushover.pl /var/lib/zmeventnotification/bin/
	chmod 755 /var/lib/zmeventnotification/bin/pushapi_pushover.pl 2>/dev/null
else
	echo "Pushover api already moved"
fi

#
# Move ssmtp configuration if it doesn't exist
#
if [ ! -d /config/ssmtp ]; then
	echo "Moving ssmtp to config folder"
	cp -p -R /etc/ssmtp/ /config/
else
	echo "Using existing ssmtp folder"
fi

#
# Move mysql database if it doesn't exit
#
if [ ! -d /config/mysql/mysql ]; then
	echo "Moving mysql to config folder"
	if [ -L /config/mysql ] || [ -f /config/mysql ]; then
		rm -f /config/mysql
	fi

	cp -p -R /var/lib/mysql /config/
else
	echo "Using existing mysql database folder"
fi

#
# files and directories no longer exposed at config.
#
rm -rf /config/perl5/
rm -rf /config/zmeventnotification/
rm -f /config/zmeventnotification.pl
rm -f /config/skins
rm -f /config/zm.conf

#
# Create Control folder if it doesn't exist and copy files into image
#
if [ ! -d /config/control ]; then
	echo "Creating control folder in config folder"
	mkdir /config/control
else
	echo "Copy /config/control/ scripts to /usr/share/perl5/ZoneMinder/Control/"
	cp /config/control/*.pm /usr/share/perl5/ZoneMinder/Control/ 2>/dev/null
	chown root:root /usr/share/perl5/ZoneMinder/Control/* 2>/dev/null
	chmod 644 /usr/share/perl5/ZoneMinder/Control/* 2>/dev/null
fi

if [ -d /config/conf ]; then
	echo "Copy /config/conf/ scripts to /etc/zm/conf.d/"
	cp /config/conf/*.conf /etc/zm/conf.d/ 2>/dev/null
	chown root:www-data /etc/zm/conf.d/* 2>/dev/null
	chmod 640 /etc/zm/conf.d/* 2>/dev/null
fi

echo "Creating symbolink links"

#
# security certificate keys
#
rm -f /etc/apache2/ssl/zoneminder.crt
ln -sf /config/keys/cert.crt /etc/apache2/ssl/zoneminder.crt
rm -f /etc/apache2/ssl/zoneminder.key
ln -sf /config/keys/cert.key /etc/apache2/ssl/zoneminder.key
mkdir -p /var/lib/zmeventnotification/push
mkdir -p /config/push
rm -f /var/lib/zmeventnotification/push/tokens.txt
ln -sf /config/push/tokens.txt /var/lib/zmeventnotification/push/tokens.txt

#
# ssmtp
#
rm -rl /etc/ssmtp 
ln -s /config/ssmtp /etc/ssmtp

#
# mysql
#
rm -rf /var/lib/mysql
ln -s /config/mysql /var/lib/mysql

#
# Set ownership for unRAID
#
PUID="${PUID:-99}"
PGID="${PGID:-100}"
usermod -o -u "$PUID" nobody

#
# Check if the group with GUID passed as environment variable exists and create it if not.
#
if ! getent group "$PGID" >/dev/null; then
	groupadd -g "$PGID" env-provided-group
	echo "Group with id: $PGID did not already exist, so we created it."
fi

usermod -g "$PGID" nobody
usermod -d /config nobody

#
# Set ownership for mail
#
usermod -a -G mail www-data

#
# Change some ownership and permissions
#
chown -R mysql:mysql /config/mysql
chown -R mysql:mysql /var/lib/mysql
chown -R "$PUID:$PGID" /config/conf
chmod 777 /config/conf
chmod 666 /config/conf/*

chown -R "$PUID:$PGID" /config/control
find /config/control -type d -exec chmod 777 {} \;
find /config/control -type f -exec chmod 666 {} \;

chown -R "$PUID:$PGID" /config/ssmtp
chmod -R 777 /config/ssmtp


chown -R "$PUID:$PGID" /config/zmeventnotification.*
chmod 666 /config/zmeventnotification.*

if [ -f /config/secrets.ini ]; then
	chown "$PUID:www-data" /config/secrets.ini
	chmod 640 /config/secrets.ini
fi

chown -R "$PUID:$PGID" /config/keys
chmod 777 /config/keys
chmod 666 /config/keys/*
chown -R www-data:www-data /config/push/
chown -R www-data:www-data /var/lib/zmeventnotification/

#
# Create events folder
#
if [ ! -d /var/cache/zoneminder/events ]; then
	echo "Create events folder"
	mkdir /var/cache/zoneminder/events
	chown -R www-data:www-data /var/cache/zoneminder/events
	chmod -R 777 /var/cache/zoneminder/events
else
	echo "Using existing data directory for events"

	# Check the ownership on the /var/cache/zoneminder/events directory
	if [ `stat -c '%U:%G' /var/cache/zoneminder/events` != 'www-data:www-data' ]; then
		echo "Correcting /var/cache/zoneminder/events ownership..."
		chown -R www-data:www-data /var/cache/zoneminder/events
	fi

	# Check the permissions on the /var/cache/zoneminder/events directory
	if [ `stat -c '%a' /var/cache/zoneminder/events` != '777' ]; then
		echo "Correcting /var/cache/zoneminder/events permissions..."
		chmod -R 777 /var/cache/zoneminder/events
	fi
fi

#
# Create images folder
#
if [ ! -d /var/cache/zoneminder/images ]; then
	echo "Create images folder"
	mkdir /var/cache/zoneminder/images
	chown -R www-data:www-data /var/cache/zoneminder/images
	chmod -R 777 /var/cache/zoneminder/images
else
	echo "Using existing data directory for images"

	# Check the ownership on the /var/cache/zoneminder/images directory
	if [ `stat -c '%U:%G' /var/cache/zoneminder/images` != 'www-data:www-data' ]; then
		echo "Correcting /var/cache/zoneminder/images ownership..."
		chown -R www-data:www-data /var/cache/zoneminder/images
	fi

	# Check the permissions on the /var/cache/zoneminder/images directory
	if [ `stat -c '%a' /var/cache/zoneminder/images` != '777' ]; then
		echo "Correcting /var/cache/zoneminder/images permissions..."
		chmod -R 777 /var/cache/zoneminder/images
	fi
fi

#
# Create temp folder
#
if [ ! -d /var/cache/zoneminder/temp ]; then
	echo "Create temp folder"
	mkdir /var/cache/zoneminder/temp
	chown -R www-data:www-data /var/cache/zoneminder/temp
	chmod -R 777 /var/cache/zoneminder/temp
else
	echo "Using existing data directory for temp"

	# Check the ownership on the /var/cache/zoneminder/temp directory
	if [ `stat -c '%U:%G' /var/cache/zoneminder/temp` != 'www-data:www-data' ]; then
		echo "Correcting /var/cache/zoneminder/temp ownership..."
		chown -R www-data:www-data /var/cache/zoneminder/temp
	fi

	# Check the permissions on the /var/cache/zoneminder/temp directory
	if [ `stat -c '%a' /var/cache/zoneminder/temp` != '777' ]; then
		echo "Correcting /var/cache/zoneminder/temp permissions..."
		chmod -R 777 /var/cache/zoneminder/temp
	fi
fi

#
# Create cache folder
#
if [ ! -d /var/cache/zoneminder/cache ]; then
	echo "Create cache folder"
	mkdir /var/cache/zoneminder/cache
	chown -R www-data:www-data /var/cache/zoneminder/cache
	chmod -R 777 /var/cache/zoneminder/cache
else
	echo "Using existing data directory for cache"

	# Check the ownership on the /var/cache/zoneminder/cache directory
	if [ `stat -c '%U:%G' /var/cache/zoneminder/cache` != 'www-data:www-data' ]; then
		echo "Correcting /var/cache/zoneminder/cache ownership..."
		chown -R www-data:www-data /var/cache/zoneminder/cache
	fi

	# Check the permissions on the /var/cache/zoneminder/cache directory
	if [ `stat -c '%a' /var/cache/zoneminder/cache` != '777' ]; then
		echo "Correcting /var/cache/zoneminder/cache permissions..."
		chmod -R 777 /var/cache/zoneminder/cache
	fi
fi

#
# set user crontab entries
#
crontab -r -u root
if [ -f /config/cron ]; then
	crontab -l -u root | cat - /config/cron | crontab -u root -
fi

#
# Symbolink for /config/zmeventnotification.ini
#
ln -sf /config/zmeventnotification.ini /etc/zm/zmeventnotification.ini
chown www-data:www-data /etc/zm/zmeventnotification.ini

#
# Symbolink for /config/secrets.ini
#
ln -sf /config/secrets.ini /etc/zm/

#
# Set Apache ports.
# Start with the default configuration on every container start.
#
cp /etc/apache2/ports.conf.default /etc/apache2/ports.conf
cp /etc/apache2/sites-enabled/default-ssl.conf.default /etc/apache2/sites-enabled/default-ssl.conf

#
# Set multi-ports in Apache for ES.
#
MULTI_PORT_START="${MULTI_PORT_START:-0}"
MULTI_PORT_END="${MULTI_PORT_END:-0}"

if [[ "$MULTI_PORT_START" =~ ^[0-9]+$ ]] &&
	[[ "$MULTI_PORT_END" =~ ^[0-9]+$ ]] &&
	(( MULTI_PORT_START > 0 && MULTI_PORT_END > MULTI_PORT_START )); then

	echo "Setting ES multi-port range from ${MULTI_PORT_START} to ${MULTI_PORT_END}."

	ORIG_VHOST="_default_:443"
	NEW_VHOST="${ORIG_VHOST}"
	PORT="${MULTI_PORT_START}"

	while (( PORT <= MULTI_PORT_END )); do
		egrep -sq "Listen ${PORT}" /etc/apache2/ports.conf ||
			echo "Listen ${PORT}" >> /etc/apache2/ports.conf

		NEW_VHOST="${NEW_VHOST} _default_:${PORT}"
		PORT=$((PORT + 1))
	done

	perl -pi -e \
		"s/${ORIG_VHOST}/${NEW_VHOST}/ if (/<VirtualHost/);" \
		/etc/apache2/sites-enabled/default-ssl.conf
else
	if [[ "$MULTI_PORT_START" =~ ^[0-9]+$ ]] &&
		(( MULTI_PORT_START != 0 )); then
		echo "Multi-port error start ${MULTI_PORT_START}, end ${MULTI_PORT_END}."
	fi
fi

#
#
# Configure services for Unraid Tailscale Serve.
#
# Tailscale Serve owns HTTPS port 443 when enabled. Move Apache's HTTPS
# listener to the backend port specified by TAILSCALE_SERVE_PORT so
# Tailscale can proxy HTTPS requests to Apache without a port conflict.
#
# The Event Notification Server uses plain WebSocket on port 9000.
# Configure Tailscale to terminate TLS on port 9001 and forward the
# resulting connection to the Event Notification Server.
#
if [[ "${TAILSCALE_SERVE_PORT:-}" =~ ^[0-9]+$ ]] &&
   (( TAILSCALE_SERVE_PORT >= 1 && TAILSCALE_SERVE_PORT <= 65535 )); then

	echo "Tailscale Serve detected. Setting Apache HTTPS port to ${TAILSCALE_SERVE_PORT}."

	# Replace the standard HTTPS listener.
	sed -i \
		-E "s/^[[:space:]]*Listen[[:space:]]+443$/Listen ${TAILSCALE_SERVE_PORT}/" \
		/etc/apache2/ports.conf

	# Replace the standard SSL VirtualHost port while preserving any
	# additional ES multi-port VirtualHosts configured above.
	sed -i \
		-E "s/_default_:443/_default_:${TAILSCALE_SERVE_PORT}/" \
		/etc/apache2/sites-enabled/default-ssl.conf

	# Terminate TLS for Event Server WebSocket connections and forward
	# the resulting connection to the local Event Server.
	echo "Configuring Tailscale Event Server TLS termination on port 9001."
	tailscale serve --bg --tls-terminated-tcp=9001 tcp://localhost:9000
fi

#
# Clean up mysql log files to insure mysql will start
#
rm -f /config/mysql/ib_logfile* 2>/dev/null

echo "Starting services..."
service apache2 start
if [ "$NO_START_ZM" != "1" ]; then
	# Start mariadb
	service mysql start

	# Wait until MariaDB is fully ready
	TIMEOUT=30
	for i in $(seq 1 "$TIMEOUT"); do
		if mysqladmin ping -uroot -sfu root >/dev/null 2>&1; then
			echo "MariaDB is ready."
			break
		fi
		echo "Waiting for MariaDB to start ($i/$TIMEOUT)..."
		sleep 1
	done

	# Update the database if necessary
	zmupdate.pl -nointeractive
	zmupdate.pl -f

	sleep 10
	service zoneminder start
else
	echo "MySql and Zoneminder not started."
fi
