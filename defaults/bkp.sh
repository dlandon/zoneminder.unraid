#!/bin/bash
[ -f /etc/.do_mysql_backups ] || exit 0
mkdir -p /config/mysql-bkps/
find /config/mysql-bkps  -type f -ctime +60 -delete # keep backups for 2 months
mysqldump -u root zm | nice -n19 bzip2 -c > /config/mysql-bkps/dump.$(date +%F).dump.bz2
