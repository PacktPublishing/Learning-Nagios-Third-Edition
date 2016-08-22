#!/bin/sh

# Automatically install Nagios and Nagios plugins on multiple popular
# Linux distributions - including Debian, Ubuntu, CentOS, RHEL and others
#
# Copyright (c) 2008 - 2016, Wojciech Kocjan
# 
# This script is licensed under BSD license
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
# 
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

do_install() {
  NAGIOS_VERSION=4.1.1
  NAGIOS_PLUGINS_VERSION=2.1.1

  # needed for older Linux distributions such as Ubuntu 12 or Debian 7
  WGET="wget --no-check-certificate"

  # check if running as root
  if [ "x`id -u`" != "x0" ] ; then
    echo "This script is not being run as root."
    echo "Please run it as root user by using either sudo or su command."
    exit 1
  fi
 
  # Install prerequisites
  if which apt-get >/dev/null 2>/dev/null ; then
    export DEBIAN_FRONTEND=noninteractive

    # detect PHP module version
    if grep xenial /etc/lsb-release >/dev/null ; then
      PHPMODULE=libapache2-mod-php
    else
      PHPMODULE=libapache2-mod-php5
    fi

    apt-get update || exit 1
    apt-get -y upgrade || exit 1
    apt-get -y install wget gcc make binutils cpp \
      libpq-dev libmysqlclient-dev \
      libssl1.0.0 libssl-dev pkg-config \
      libgd2-xpm-dev libgd-tools \
      perl libperl-dev libnet-snmp-perl snmp \
      apache2 apache2-utils $PHPMODULE \
      unzip tar gzip || exit 1
  elif yum --help >/dev/null 2>/dev/null ; then
    yum -y update || exit 1
    yum -y install wget gcc make imake binutils cpp \
      postgresql-devel mysql-libs mysql-devel \
      openssl openssl-devel pkgconfig \
      gd gd-devel gd-progs libpng libpng-devel \
      libjpeg libjpeg-devel perl perl-devel \
      net-snmp net-snmp-devel net-snmp-perl net-snmp-utils \
      httpd php \
      unzip tar gzip || exit 1
  else
    echo "Unknown or not supported packaging system - only apt-get and yum package managers are supported"
    exit 1
  fi
  # Determine web server username
  if [ -d /etc/apache2 ] ; then
    HTTPD_FILES=`find /etc/apache2 -type f`
    USER_RESULT=`grep -h '^ *User ' $HTTPD_FILES | grep -v '^ *User .*APACHE_RUN_USER'`
  elif [ -d /etc/httpd ] ; then
    HTTPD_FILES=`find /etc/httpd -type f`
    USER_RESULT=`grep -h '^ *User ' $HTTPD_FILES | grep -v '^ *User .*APACHE_RUN_USER'`
  else
    USER_RESULT=''
  fi

  # Parse the output if available or determine user based on known values
  if [ "x$USER_RESULT" != "x" ] ; then
    WEB_USER=`echo "$USER_RESULT" | sed 's,^\s*User\s\+,,;s,^.*APACHE_RUN_USER=,,'`
  else
    for NAME in apache www-data daemon ; do
      if id -u $NAME >/dev/null 2>/dev/null ; then
        WEB_USER=$NAME
        break
      fi
    done
  fi

  if [ "x$WEB_USER" = "x" ] ; then
    echo "Unable to determine web server username"
    exit 1
  fi

  if [ ! -d /opt/nagios/sbin ] ; then
    # delete users from previous installation attempts to avoid re-running the script causing errors
    userdel nagios >/dev/null 2>/dev/null
    groupdel nagios >/dev/null 2>/dev/null
    groupdel nagioscmd >/dev/null 2>/dev/null
  fi

  # Set up users and groups
  groupadd nagios \
    && groupadd nagioscmd \
    && useradd -g nagios -G nagioscmd -d /opt/nagios nagios \
  || ( echo "Unable to create system users and groups" ; exit 1)

  if [ "x$WEB_USER" != "x" ] ; then
    usermod -G nagioscmd $WEB_USER || ( echo "Unable to add $WEB_USER to nagioscmd group" ; exit 1)
  fi

  # create required directories and ensure proper ownership permissiosn
  mkdir -p /opt/nagios /etc/nagios /var/nagios \
    && chown root:root /etc/nagios /opt/nagios \
    && chown nagios:nagios /var/nagios \
    && chmod 0755 /opt/nagios /etc/nagios \
  || ( echo "Unable to create system directories" ; exit 1)

  # Prepare compilation directory
  rm -fR /usr/src/nagios
  mkdir -p /usr/src/nagios \
    || (echo "Unable to create nagios source directory (all source code has been left in /usr/src/nagios)" ; exit 1)

  # Compile Nagios
  cd /usr/src/nagios \
    && $WGET -O nagios.tar.gz https://assets.nagios.com/downloads/nagioscore/releases/nagios-${NAGIOS_VERSION}.tar.gz \
    && tar -xzf nagios.tar.gz \
    && rm nagios.tar.gz \
    && cd nagios-${NAGIOS_VERSION} \
    || (echo "Unable to download nagios (all source code has been left in /usr/src/nagios)" ; exit 1)

  sh configure \
    --prefix=/opt/nagios \
    --sysconfdir=/etc/nagios \
    --localstatedir=/var/nagios \
    --libexecdir=/opt/nagios/plugins \
    --with-command-group=nagioscmd \
    && make all \
    || (echo "Unable to compile nagios (all source code has been left in /usr/src/nagios)" ; exit 1)

  # Compile Nagios plugins
  cd /usr/src/nagios \
    && $WGET -O nagios-plugins.tar.gz http://www.nagios-plugins.org/download/nagios-plugins-${NAGIOS_PLUGINS_VERSION}.tar.gz \
    && tar -xzf nagios-plugins.tar.gz \
    && rm nagios-plugins.tar.gz \
    && cd nagios-plugins-${NAGIOS_PLUGINS_VERSION} \
    || (echo "Unable to download nagios-plugins (all source code has been left in /usr/src/nagios)" ; exit 1)

  sh configure \
    --prefix=/opt/nagios \
    --sysconfdir=/etc/nagios \
    --localstatedir=/var/nagios \
    --libexecdir=/opt/nagios/plugins \
    && make all \
    || (echo "Unable to compile nagios-plugins (all source code has been left in /usr/src/nagios)" ; exit 1)

  # Install Nagios
  cd /usr/src/nagios/nagios-${NAGIOS_VERSION} \
    && make install \
    && make install-commandmode \
    && make install-config \
    && make install-init \
    || (echo "Unable to install nagios-plugins (all source code has been left in /usr/src/nagios)" ; exit 1)

  # Install Nagios plugins
  cd /usr/src/nagios/nagios-plugins-${NAGIOS_PLUGINS_VERSION} \
    && make install \
    || (echo "Unable to install nagios-plugins (all source code has been left in /usr/src/nagios)" ; exit 1)

  # re-apply permissions
  cd / \
    && chown root:root /etc/nagios /opt/nagios \
    && chown nagios:nagios /var/nagios \
    && chmod 0755 /opt/nagios /etc/nagios \
    || (echo "Unable to re-apply permissions (all source code has been left in /usr/src/nagios)" ; exit 1)

  for DIR in /etc/apache2 /etc/httpd ; do
    if [ -d "$DIR" ] ; then
      HTTPD_CONFIG_DIR=$DIR
      break
    fi
  done

  # for Ubuntu/Debian, enable cgi and auth_basic modules
  if which a2enmod >/dev/null 2>/dev/null ; then
    a2enmod cgi \
      && a2enmod auth_basic \
      || (echo "Unable to change Apache 2 settings (all source code has been left in /usr/src/nagios)" ; exit 1)
  fi

  if [ "x$HTTPD_CONFIG_DIR" != "x" ] ; then
    if [ -d "$HTTPD_CONFIG_DIR/conf-available" ] && [ -d "$HTTPD_CONFIG_DIR/conf-enabled" ] ; then
      HTTPD_CONFIG_FILE="$HTTPD_CONFIG_DIR/conf-available/nagios.conf"
      HTTPD_CONFIG_LINK="$HTTPD_CONFIG_DIR/conf-enabled/010-nagios.conf"
    elif [ -d "$HTTPD_CONFIG_DIR/conf.d" ] ; then
      HTTPD_CONFIG_FILE="$HTTPD_CONFIG_DIR/conf.d/nagios.conf"
    fi
  fi

  if [ "x$HTTPD_CONFIG_FILE" != "x" ] ; then
    cat >$HTTPD_CONFIG_FILE <<EOF
  ScriptAlias /nagios/cgi-bin /opt/nagios/sbin
  Alias /nagios /opt/nagios/share
  <Location "/nagios">
  AuthName "Nagios Access"
  AuthType Basic
  AuthUserFile /etc/nagios/htpasswd.users
  require valid-user
  </Location>
  <Directory "/opt/nagios/share">
  AllowOverride None
  Options +ExecCGI -MultiViews +SymLinksIfOwnerMatch
  Require all granted
  Order allow,deny
  Allow from all
  </Directory>
  <Directory "/opt/nagios/sbin">
  AllowOverride None
  Options +ExecCGI -MultiViews +SymLinksIfOwnerMatch
  Require all granted
  Order allow,deny
  Allow from all
  </Directory>
EOF
      cp /dev/null /etc/nagios/htpasswd.groups \
        && htpasswd -b -c /etc/nagios/htpasswd.users nagiosadmin nagiosadmin \
        || (echo "Unable to create htpasswd for nagios (all source code has been left in /usr/src/nagios)" ; exit 1)

    if [ "x${HTTPD_CONFIG_LINK}" != "x" ] ; then
      ln -s ${HTTPD_CONFIG_FILE} ${HTTPD_CONFIG_LINK} \
        || (echo "Unable to create Apache 2 configuration symlink (all source code has been left in /usr/src/nagios)" ; exit 1)
    fi
  else
    echo "Unable to locate Apache configuration directory - skipping web server configuration"
    exit 1
  fi

  # create nagios service
  if which chkconfig >/dev/null 2>/dev/null ; then
    chkconfig --add nagios \
      && chkconfig nagios on \
      || echo "Unable to set up nagios service using chkconfig - Nagios may not be starting automatically"
  elif which update-rc.d >/dev/null 2>/dev/null ; then
    update-rc.d nagios defaults 99 01 \
      || echo "Unable to set up nagios service using update-rc.d - Nagios may not be starting automatically"
  else
    echo "Unable to create Nagios as a service - only chkconfig and update-rc.d commands are supported"
  fi

  # restart Apache
  if which apachectl >/dev/null 2>/dev/null ; then
    apachectl restart \
      || echo "Unable to restart Apache - you may need to restart it manually"
  elif which service >/dev/null 2>/dev/null ; then
    OK=0
    for SERVICENAME in apache2 httpd ; do
      if [ -f "/etc/init/${SERVICENAME}.conf" ] \
        || [ -f "/etc/init.d/${SERVICENAME}" ] \
        || [ -f "/usr/lib/systemd/system/${SERVICENAME}.service" ] \
        || [ -f "/etc/systemd/system/${SERVICENAME}.service" ] \
      ; then
        service ${SERVICENAME} stop
        if service ${SERVICENAME} start ; then
          OK=1
          break
        fi
      fi
    done
    if [ "x$OK" = "x0" ] ; then
      echo "Unable to restart Apache - you may need to restart it manually"
    fi
  else
    echo "Unable to restart Apache - you may need to restart it manually"
  fi

  IP_ADDRESS=`ifconfig 2>/dev/null|grep 'inet addr'|sed 's,^.*inet addr:,,;s, .*$,,'|grep -v '127\.0\.0\.1'|head -1`
  if [ "x$IP_ADDRESS" = "x" ] ; then
    IP_ADDRESS=`ip addr show 2>/dev/null|grep  'inet '|sed 's,^.* inet ,,;s, .*$,,;s,/.*$,,'|grep -v '127\.0\.0\.1'|head -1`
  fi
  if [ "x$IP_ADDRESS" = "x" ] ; then
    IP_ADDRESS="127.0.0.1"
  fi

  echo "Congratulations! Nagios and standard plugins are now installed."
  echo ""
  echo "To access your Nagios instance, go to http://${IP_ADDRESS}/nagios/"
  echo "  Username: nagiosadmin"
  echo "  Password: nagiosadmin"
  echo ""
}

do_install

