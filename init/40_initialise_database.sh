#!/bin/bash
set -e

echo "Starting temporary MariaDB for initialization..."
mysqld_safe --skip-networking &
sleep 5

# Check if zm database exists
DB_EXISTS=$(mysql -uroot -sfu root -e "SHOW DATABASES LIKE 'zm';" | grep zm || true)
if [ -z "$DB_EXISTS" ]; then
    echo "Creating zm database..."
    mysql -uroot -sfu root -e "CREATE DATABASE zm CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
else
    echo "Database zm already exists. Skipping creation."
fi

# Check if zmuser exists
USER_EXISTS=$(mysql -uroot -sfu root -e "SELECT User FROM mysql.user WHERE User='zmuser';" | grep zmuser || true)
if [ -z "$USER_EXISTS" ]; then
    echo "Creating zmuser with password..."
    mysql -uroot -sfu root -e "CREATE USER 'zmuser'@'localhost' IDENTIFIED BY 'zmpass';"
    mysql -uroot -sfu root -e "GRANT ALL PRIVILEGES ON zm.* TO 'zmuser'@'localhost';"
else
    echo "User zmuser already exists. Skipping creation."
fi

echo "Flushing privileges..."
mysql -uroot -sfu root -e "FLUSH PRIVILEGES;"

# Apply secure installation SQL if present
if [ -f /root/mysql_secure_installation.sql ]; then
    echo "Applying mysql_secure_installation.sql..."
    mysql -sfu root < /root/mysql_secure_installation.sql
    rm -f /root/mysql_secure_installation.sql
fi

# Apply ZoneMinder defaults if present
if [ -f /root/mysql_defaults.sql ]; then
    echo "Applying mysql_defaults.sql..."
    mysql -sfu root < /root/mysql_defaults.sql
    rm -f /root/mysql_defaults.sql
fi

echo "Stopping temporary MariaDB..."
killall mysqld
sleep 3
echo "Database initialization complete."
