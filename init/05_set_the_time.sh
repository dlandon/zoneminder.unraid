#!/bin/bash
#
# 05_set_the_time.sh
#

if [[ $(cat /etc/timezone) != "$TZ" ]]; then
	echo "Setting timezone to: $TZ"
	echo "$TZ" > /etc/timezone
	ln -fs /usr/share/zoneinfo/$TZ /etc/localtime
	dpkg-reconfigure -f noninteractive tzdata
	echo "Date: $(date)"

	# Detect installed PHP versions and update their ini files
	for phpver in $(ls -1 /etc/php/ 2>/dev/null); do
		for ini_path in "/etc/php/$phpver/cli/php.ini" "/etc/php/$phpver/fpm/php.ini" "/etc/php/$phpver/apache2/php.ini"; do
			if [[ -f "$ini_path" ]]; then
				sed -i "s#^;date.timezone =.*#date.timezone = $TZ#g" "$ini_path"
				echo "Updated PHP $phpver timezone in $ini_path"
			fi
		done
	done
fi
