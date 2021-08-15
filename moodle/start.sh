#!/usr/bin/env sh

MOODLE_LOG_FILE=$MOODLE_PATH/error.log
MOODLE_SQL_FILE=$MOODLE_PATH/install.sql
MYSQL_DATA_DIR=$MOODLE_PATH/mysql
MYSQL_USER=root
MYSQL_PASSWORD=root

mysql_start() {
    ( mysqld --user="$MYSQL_USER" --datadir="$MYSQL_DATA_DIR" >> "$MOODLE_LOG_FILE" 2>&1 & )
    timeout=30
    while [ $timeout -gt 0 ]; do
        if mysql_started; then
            sleep 3
            break;
        fi
        sleep 1
        timeout=$(( timeout - 1 ))
    done
    if [ $timeout -le 0 ]; then
        printf "timeout after %ds\n" "$timeout" 1>&2
        exit 1
    fi
}

mysql_started() {
    pidof -s mysqld > /dev/null 2>&1
}

printf "Cloning Moodle from %s to %s\n" "$MOODLE_URL" "$MOODLE_DOCUMENT_ROOT"
if [ ! -e "$MOODLE_DOCUMENT_ROOT" ]; then
    git clone "$MOODLE_URL" "$MOODLE_DOCUMENT_ROOT"
    cat "$MOODLE_PATH/config.php" > "$MOODLE_DOCUMENT_ROOT"/config.php
fi

printf "Starting Apache HTTP Server"

: > /etc/apache2/conf.d/custom.conf
cat << EOF >> /etc/apache2/conf.d/custom.conf
DocumentRoot $MOODLE_DOCUMENT_ROOT
Listen $APACHE_PORT
ServerName localhost:$APACHE_PORT
AddHandler php-script .php
Action php-script /cgi-bin/php-cgi7
EOF

: > /var/log/apache2/error.log
ln -sf /var/log/apache2/error.log "$MOODLE_LOG_FILE"

# shellcheck disable=SC2086
( httpd -k start > $MOODLE_LOG_FILE 2>&1 & )

while [ ! -s "$MOODLE_LOG_FILE" ]; do
    printf "."
    sleep .1
done

echo
echo "Starting MySQL Server..."

if [ ! -e "$MYSQL_DATA_DIR/mysql" ]; then
    mysql_install_db --datadir="$MYSQL_DATA_DIR" > /dev/null 2>&1
    mysql_start
    echo "Database \"mysql\" successfully created in $MYSQL_DATA_DIR" >> "$MOODLE_LOG_FILE"
    mysqladmin --user="$MYSQL_USER" password "$MYSQL_PASSWORD"
    mysql --user="$MYSQL_USER" --password="$MYSQL_PASSWORD" < "$MOODLE_SQL_FILE"
fi
mysql_started || mysql_start

echo "Now you can access http://your-host:port"

while true; do
    tail -n 5 "$MOODLE_LOG_FILE"
    : > "$MOODLE_LOG_FILE"
    sleep 1
done
