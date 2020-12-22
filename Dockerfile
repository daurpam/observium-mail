# Docker container for Observium Community Edition
# References:
#  - Follow platform guideline specified in https://github.com/docker-library/official-images
#

FROM ubuntu:16.04

LABEL maintainer "danimoncada@gmail.com"
LABEL version="1.0"
LABEL description="Docker container for Observium Community Edition including sendmail"

# set environment variables
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8
ENV OBSERVIUM_DB_HOST=$OBSERVIUM_DB_HOST
ENV OBSERVIUM_DB_USER=$OBSERVIUM_DB_USER
ENV OBSERVIUM_DB_PASS=$OBSERVIUM_DB_PASS
ENV OBSERVIUM_DB_NAME=$OBSERVIUM_DB_NAME

# install prerequisites
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
RUN apt-get update
RUN apt-get install -y libapache2-mod-php7.0 php7.0-cli php7.0-mysql php7.0-mysqli php7.0-gd php7.0-mcrypt php7.0-json \
      php-pear snmp fping mysql-client python-mysqldb rrdtool subversion whois mtr-tiny ipmitool \
      graphviz imagemagick apache2 sendmail
RUN apt-get install -y libvirt-bin
RUN apt-get install -y cron supervisor wget locales
RUN apt-get clean

# set locale
RUN locale-gen en_US.UTF-8

# install observium package
RUN mkdir -p /opt/observium /opt/observium/lock /opt/observium/logs /opt/observium/rrd
#COPY observium-community-latest.tar.gz /opt
RUN cd /opt && \
    wget http://www.observium.org/observium-community-latest.tar.gz && \
    tar zxvf observium-community-latest.tar.gz && \
    rm observium-community-latest.tar.gz

# check version
RUN [ -f /opt/observium/VERSION ] && cat /opt/observium/VERSION

# configure observium package
RUN cd /opt/observium && \
    cp config.php.default config.php && \
    sed -i -e "s/= 'localhost';/= getenv('OBSERVIUM_DB_HOST');/g" config.php && \
    sed -i -e "s/= 'USERNAME';/= getenv('OBSERVIUM_DB_USER');/g" config.php && \
    sed -i -e "s/= 'PASSWORD';/= getenv('OBSERVIUM_DB_PASS');/g" config.php && \
    sed -i -e "s/= 'observium';/= getenv('OBSERVIUM_DB_NAME');/g" config.php && \
    echo "\$config['base_url'] = getenv('OBSERVIUM_BASE_URL');" >> config.php

COPY observium-init /opt/observium/observium-init.sh
RUN chmod a+x /opt/observium/observium-init.sh

RUN chown -R www-data:www-data /opt/observium
RUN find /opt -ls

# configure php modules
RUN phpenmod mcrypt

# configure apache modules
RUN a2dismod mpm_event && \
    a2enmod mpm_prefork && \
    a2enmod php7.0 && \
    a2enmod rewrite

# configure apache configuration
COPY observium-apache24 /etc/apache2/sites-available/000-default.conf
RUN rm -fr /var/www

# configure observium cron job
COPY observium-cron /etc/cron.d/observium
COPY crontab /tmp/observium
RUN echo "" >> /etc/crontab && \
    cat /tmp/observium >> /etc/crontab && \
    rm -f /tmp/observium

# configure container interfaces
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
CMD ["/usr/bin/supervisord"]

EXPOSE 80/tcp

VOLUME ["/opt/observium/lock", "/opt/observium/logs","/opt/observium/rrd"]
