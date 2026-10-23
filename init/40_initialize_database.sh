#!/bin/bash
#
# 40_initialize_database.sh
#

set -e

echo "Starting temporary MariaDB for initialization..."
mysqld_safe --skip-networking &
sleep 5

# Check if zm database exists
DB_EXISTS=$(mysql --user=root --silent -e "SHOW DATABASES LIKE 'zm';" | grep zm || true)
if [ -z "$DB_EXISTS" ]; then
	echo "Creating zm database..."
	mysql --user=root --silent -e "CREATE DATABASE zm CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
else
	echo "Database zm already exists. Skipping creation."
fi

# Check if zmuser exists
USER_EXISTS=$(mysql --user=root --silent -e "SELECT User FROM mysql.user WHERE User='zmuser';" | grep zmuser || true)
if [ -z "$USER_EXISTS" ]; then
	echo "Creating zmuser with password..."
	mysql --user=root --silent -e "CREATE USER 'zmuser'@'localhost' IDENTIFIED BY 'zmpass';"
	mysql --user=root --silent -e "GRANT ALL PRIVILEGES ON zm.* TO 'zmuser'@'localhost';"
else
	echo "User zmuser already exists. Skipping creation."
fi

echo "Flushing privileges..."
mysql --user=root --silent -e "FLUSH PRIVILEGES;"

# Create the ZoneMinder schema if its Config table is missing.
CONFIG_TABLE=$(mysql --user=root --silent --skip-column-names -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='zm' AND table_name='Config';")
if [ "$CONFIG_TABLE" -eq 0 ]; then
	echo "Creating ZoneMinder database schema..."
	mysql --user=root --silent < /usr/share/zoneminder/db/zm_create.sql
fi

# Apply secure installation SQL if present
if [ -f /root/mysql_secure_installation.sql ]; then
	echo "Applying mysql_secure_installation.sql..."
	mysql --user=root --silent < /root/mysql_secure_installation.sql
	rm -f /root/mysql_secure_installation.sql
fi

# Apply ZoneMinder defaults if present
if [ -f /root/mysql_defaults.sql ]; then
	echo "Applying mysql_defaults.sql..."
	mysql --user=root --silent < /root/mysql_defaults.sql
	rm -f /root/mysql_defaults.sql
fi

echo "Stopping temporary MariaDB..."
mysqladmin -uroot shutdown
sleep 3
echo "Database initialization complete."
