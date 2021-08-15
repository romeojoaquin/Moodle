FROM alpine:3.14.1

ARG APACHE_PORT=80
ARG MYSQL_PORT=3306
ARG MOODLE_PATH=/opt/moodle

ENV MOODLE_URL=https://github.com/romeojoaquin/Moodle
ENV MOODLE_DOCUMENT_ROOT=/var/www/localhost/moodle
ENV MOODLE_PATH=$MOODLE_PATH
ENV APACHE_PORT=$APACHE_PORT

EXPOSE $APACHE_PORT $MYSQL_PORT

RUN apk update && apk upgrade

RUN apk add git
RUN apk add apache2
RUN apk add mariadb mariadb-client
RUN apk add php7-cgi php7-bcmath php7-ctype php7-curl php7-dom php7-exif php7-fileinfo php7-ftp php7-gd php7-gettext php7-iconv php7-imap php7-intl php7-json php7-mcrypt php7-mysqli php7-opcache php7-openssl php7-pdo_mysql php7-posix php7-session php7-simplexml php7-soap php7-sockets php7-sodium php7-tokenizer php7-xml php7-xmlreader php7-xmlrpc php7-zip php7-zlib

RUN test -e /var/lib/mysql || mkdir -p /var/lib/mysql
RUN test -e /run/mysqld || mkdir -p /run/mysqld
RUN test -e $MOODLE_PATH/data || mkdir -p $MOODLE_PATH/data

COPY apache2/httpd.conf /etc/apache2/httpd.conf
COPY php/custom.ini /etc/php7/conf.d/custom.ini
COPY mysql/my.cnf /etc/mysql/my.cnf

COPY moodle $MOODLE_PATH

RUN chmod +x $MOODLE_PATH/start.sh
RUN chmod 777 $MOODLE_PATH/data

WORKDIR $MOODLE_PATH

ENTRYPOINT ["/opt/moodle/start.sh"]
