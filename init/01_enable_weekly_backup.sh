#!/bin/bash
[ "$ENABLE_WEEKLY_MYSQL_BACKUPS" == "true" ] && touch /etc/.do_mysql_backups
