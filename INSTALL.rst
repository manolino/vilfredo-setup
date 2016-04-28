.. -*- coding: utf-8 -*-

This guide is divided into two parts.

The first one explains how to install Vilfredo on an existing server, which is already running other applications, without disrupting the system.

The second one describes a full setup of a dedicated virtual machine or physical server.

================================
Installing on an existing system
================================

We're assuming you're running a ``Debian/GNU Linux`` based distribution (such as Debian stable or Ubuntu). Vilfredo could likely run on other flavours of Linux, but these are not covered by this guide.

Requirements:

- a MySQL server installation (on the same server or on an external server)
- a NGINX web server installation (other web servers are not covered by this guide)

WARNING: Do not attempt to run installation if other web servers such as Apache are running on the same server (unless you know how to set up NGINX to run on a different IP address or port). Two web servers on the same IP address and port will conflict and prevent installation of each other.

Run the following commands (please note you'll have to replace the value of some variables: do not copy and paste code to the terminal without revising it first!):

.. code:: sh

    #############################
    # Set configuration variables
    #############################
    # Replace "your_mysql_password" with your chosen "vilfredo" (not "root") MySQL user password
    # Replace "your_mysql_password" with a secret key chosen by you
    # Replace "your_vilfredo_salt" with a salt chosen by you
    YOUR_VILFREDO_MYSQL_PASSWORD=your_mysql_password
    YOUR_SECRET_KEY=your_secret_key
    YOUR_VILFREDO_SALT=your_vilfredo_salt
    # Replace "vilfredo" with the name of system user you want to run Vilfredo
    NAME=vilfredo
    #################################################################################
    # Install required packages (some of them could be already present on the system)
    #################################################################################
    sudo apt-get update
    sudo apt-get install python-virtualenv python-dev libmysqlclient-dev libsqlite3-0 graphviz git gcc sudo nginx ntpdate mysql-server postfix libjansson4 libmatheval1 libyaml-0-2 libzmq3 uuid-dev libcap-dev libssl-dev libssl-doc libpcre3-dev libpcrecpp0
    # Install customized uwsgi-pypy package
    wget https://raw.githubusercontent.com/fairdemocracy/vilfredo-setup/master/uwsgi-pypy.deb
    sudo dpkg -i uwsgi-pypy.deb
    rm uwsgi-pypy.deb
    ######################
    # Install the database
    ######################
    wget https://raw.githubusercontent.com/fairdemocracy/vilfredo-setup/master/database.sql
    # Enter MySQL command line prompt (please enter your MySQL root password to proceed)
    # Replace "vilfredo" with the name of the database you want to use for Vilfredo installation
    # Replace "vilfredo_mysql_password" with your chosen "vilfredo" user MySQL password
    mysql -u root -p
    DROP DATABASE IF EXISTS $NAME;
    CREATE DATABASE $NAME;
    USE $NAME;
    SET NAMES UTF8;
    SOURCE database.sql;
    GRANT USAGE ON *.* TO '$NAME'@'localhost' IDENTIFIED BY PASSWORD 'vilfredo_mysql_password';
    GRANT SELECT, INSERT, UPDATE, DELETE ON `$NAME`.* TO '$NAME'@'localhost';
    exit
    rm database.sql
    #####################
    # Install application
    #####################
    sudo adduser $NAME
    sudo -u $NAME bash
    cd /home/$NAME
    git clone -b master https://github.com/fairdemocracy/vilfredo-core.git
    git clone -b master https://github.com/fairdemocracy/vilfredo-client.git
    virtualenv vilfredo-ve --python=/usr/bin/pypy
    . vilfredo-ve/bin/activate
    pip install -U setuptools
    pip install itsdangerous==0.23
    pip install argparse==1.2.1
    pip install alembic==0.7.4
    pip install Flask-Script==0.6.7
    pip install Flask-Migrate==1.3.0
    pip install Pillow==2.8.1
    pip install requests==2.7.0
    pip install ipython==4.0.0
    pip install Flask==0.10
    pip install Flask-Mail==0.8.2
    pip install Flask-Babel==0.8
    pip install Flask-Login==0.2.6
    pip install SQLAlchemy==0.8.2
    pip install Flask-SQLAlchemy==1.0
    pip install Flask-CDN==1.2.1
    pip install flask-util-js==0.2.19
    pip install MySQL-python==1.2.5
    pip install pyparsing==1.5.7
    pip install pydot==1.0.2
    # Create symbolic links
    ln -sf /home/$NAME/vilfredo-client/static /home/$NAME/vilfredo-core/VilfredoReloadedCore/static
    ln -sf /home/$NAME/vilfredo-client/templates /home/$NAME/vilfredo-core/VilfredoReloadedCore/templates
    exit
    sudo chgrp www-data /home/$NAME/vilfredo-client/static
    # Move configuration files to a centralized folder
    sudo mkdir /etc/$NAME
    sudo chown $NAME:www-data /etc/$NAME
    sudo -u $NAME bash
    cp /home/$NAME/vilfredo-setup/settings.cfg /etc/$NAME
    replace www.vilfredo.org $DOMAIN -- /etc/$NAME/settings.cfg
    replace https https -- /etc/$NAME/settings.cfg
    replace vilfredo_mysql_password $YOUR_VILFREDO_MYSQL_PASSWORD -- /etc/$NAME/settings.cfg
    replace secret_key $YOUR_SECRET_KEY -- /etc/$NAME/settings.cfg
    replace vilfredo_salt $YOUR_VILFREDO_SALT -- /etc/$NAME/settings.cfg
    chown $NAME /etc/$NAME/settings.cfg
    ln -sf /etc/$NAME/settings.cfg /home/$NAME/vilfredo-core/VilfredoReloadedCore
    chown -h $NAME /home/$NAME/vilfredo-core/VilfredoReloadedCore/settings.cfg
    mv /home/$NAME/vilfredo-client/static/js/settings.js /etc/$NAME
    replace www.vilfredo.org $DOMAIN -- /etc/$NAME/settings.js
    replace https http -- /etc/$NAME/settings.js
    ln -s /etc/$NAME/settings.js /home/$NAME/vilfredo-client/static/js
    cp /home/$NAME/vilfredo-setup/logging_debug.conf /etc/$NAME
    ln -s /etc/$NAME/logging_debug.conf /home/$NAME/vilfredo-core/VilfredoReloadedCore
    mkdir /var/log/$NAME
    chown $NAME /var/log/$NAME
    # This file is not needed in this setup - delete it if it has been downloaded from repository
    rm /home/$NAME/vilfredo-core/VilfredoReloadedCore/main.py
    chown -R $NAME:www-data /home/$NAME
    ############################
    # Configure NGINX web server
    ############################
    cat > /etc/nginx/sites-available/$NAME <<EOF
    server {
      listen 80;
      listen [::]:80;

      server_name $DOMAIN;

      location /static {
        root /home/$NAME/vilfredo-client/static;
        try_files $uri @vilfredo;
      }
      location /templates {
        root /home/$NAME/vilfredo-client/static/templates;
        try_files $uri @vilfredo;
      }
      location / {
        try_files $uri @vilfredo;
      }
      location @vilfredo {
        include uwsgi_params;
        uwsgi_pass unix:/tmp/uwsgi_$NAME.sock;
      }
      # Enables GZIP compression if not already enabled
      gzip on;
      gzip_disable "msie6";
      gzip_vary on;
      gzip_proxied any;
      gzip_comp_level 9;
      gzip_buffers 16 8k;
      gzip_http_version 1.1;
      gzip_types text/plain text/css application/json application/javascript application/x-javascript text/xml application/xml application/xml+rss text/javascript;

    }
    EOF
    sudo ln -sf /etc/nginx/sites-available/$NAME.conf /etc/nginx/sites-enabled
    sudo cat > /etc/uwsgi-pypy/apps-available/$NAME.ini <<EOF
    [uwsgi]
    # Note: We cannot use /var/run/uwsgi_$NAME.sock due to permissions issues
    socket=/tmp/uwsgi_$NAME.sock
    chmod-socket=666
    abstract-socket=false

    master=true
    workers=2

    uid=$NAME
    gid=www-data

    post-buffering=8192

    vhost=true
    chdir=/home/$NAME

    # Configuration when running under Python
    pp=/home/$NAME/vilfredo-core/VilfredoReloadedCore
    venv=/home/$NAME/vilfredo-ve
    module=main
    callable=app

    # Configuration when running under PyPy
    pypy-lib=/usr/lib/pypy/libpypy-c.so
    pypy-pp=/home/$NAME/vilfredo-core
    pypy-home=/home/$NAME/vilfredo-ve
    pypy-wsgi=VilfredoReloadedCore:app
    EOF
    sudo ln -sf /etc/uwsgi-pypy/apps-available/$NAME.ini /etc/uwsgi-pypy/apps-enabled
    service uwsgi-pypy restart
    service php5-fpm restart
    service nginx restart

=====================================
Full virtual or physical server setup
=====================================

In the case you've got an available virtual machine or physical server to devote to Vilfredo, here follows how to install the whole system which is currently running on www.vilfredo.org

It includes:

- partitioning guide (for LVM setups and virtual machines where partitioning has not been performed before)
- a PHPMyAdmin installation to easily manage the MySQL database through a web-based interface
- settings DNS adding the SPF and DKIM records

Partitioning guide
==================

First of all, on some servers there could be the need to define partitions on LVM to take advantage of additional disk space.

In this case, create partitions before proceeding with any other installation step.

The following example assumes an empty partition is available at ``/dev/sda3`` and three volumes have to be created:

.. code:: sh

    vgextend localhost-vg /dev/sda3
    lvcreate -L 30G -n log localhost-vg
    lvcreate -L 12G -n mysql localhost-vg
    # If there's no space available, note down the number of free extents
    # and replace "-L 8G" with "-l number_of_extents"
    lvcreate -L 32G -n home localhost-vg
    mkfs -t ext4 /dev/localhost-vg/home
    mkfs -t ext4 /dev/localhost-vg/mysql
    mkfs -t ext4 /dev/localhost-vg/log
    # Then edit /etc/fstab and move existing folders or remove them
    reboot

Now download all ``vilfredo-setup`` repository files to ``/home/vilfredo/vilfredo-setup``

Log in as ``root`` user and run the following commands:

.. code:: sh

    apt-get update
    apt-get install vim
    dpkg-reconfigure locales

and add your locale from the list displayed on the console, then specify it as default.
Then enter the following commands:

.. code:: sh

    apt-get install --reinstall locales
    # During this phase, you'll have to choose the MySQL "root" password.
    # It should be the same as indicated in the .my.cnf file (see below)
    # The password will have to be entered again when installing phpmyadmin
    # You'll also have to specify the mail server host name
    apt-get install python-virtualenv python-dev libmysqlclient-dev libsqlite3-0 graphviz git gcc sudo nginx ntpdate mysql-server postfix php5-fpm php5-mysqlnd phpmyadmin lbzip2
    apt-get remove --purge apache2 apache2-bin apache2-data exim4 exim4-base exim4-daemon-light
    replace "\"syntax on" "syntax on" -- /etc/vim/vimrc
    replace "\"set background" "set background" -- /etc/vim/vimrc
    apt-get dist-upgrade
    apt-get install libjansson4 libmatheval1 libyaml-0-2 libzmq3 uuid-dev libcap-dev libssl-dev libssl-doc libpcre3-dev libpcrecpp0
    apt-get autoremove --purge
    # This assumes you've downloaded the precompiled uwsgi-pypy module
    # You might compile uwsgi and pypy on your own, but would require hours
    # (pypy alone needs more than 4Gb and 3 CPU cores to successfully compile)
    # Instructions to compile the "uwsgi-pypy" package are provided in "uwsgi-pypy.rst" file
    dpkg -i uwsgi-pypy.deb
    adduser vilfredo

confirming all questions and choosing a strong password.
If you want to allow the ``vilfredo`` user executing commands with ``sudo``, edit the ``/etc/group`` file and place ``vilfredo`` after the line starting with ``sudo``.

Database installation instructions
==================================

Before installing the application, create the MySQL database schema:

.. code:: sh

    # This assumes the "root" password has been stored in .my.cnf file
    mysql
    DROP DATABASE IF EXISTS vilfredo;
    CREATE DATABASE vilfredo;
    USE vilfredo;
    SET NAMES UTF8;
    SOURCE /home/vilfredo/vilfredo-setup/database.sql;
    # Replace "vilfredo_mysql_password" with your chosen "vilfredo" user MySQL password
    GRANT USAGE ON *.* TO 'vilfredo'@'localhost' IDENTIFIED BY PASSWORD 'vilfredo_mysql_password';
    GRANT SELECT, INSERT, UPDATE, DELETE ON `vilfredo`.* TO 'vilfredo'@'localhost';
    exit

Software installation instructions
==================================

Download the Vilfredo source code and install it onto the server:

.. code:: sh

    cd /home/vilfredo
    git clone -b master https://github.com/fairdemocracy/vilfredo-core.git
    git clone -b master https://github.com/fairdemocracy/vilfredo-client.git

The above could be configured as well as a cron job in order to always run the latest version of the software.

You could save space on the server by deleting all ``.git`` subfolders:

    rm -r /home/vilfredo/vilfredo-client/.git /home/vilfredo/vilfredo-client/.gitignore /home/vilfredo/vilfredo-core/.git /home/vilfredo/vilfredo-core/.gitignore

but this is not recommended. Not only you would not be able to post your changes, you couldn't also update website with latest repository changes!

Now create the virtual environment:

.. code:: sh

    cd /home/vilfredo
    virtualenv vilfredo-ve --python=/usr/bin/pypy
    . vilfredo-ve/bin/activate
    cd /home/vilfredo/vilfredo-core
    # Note: These commands only works if you entered the Virtual Environment as explained above!
    pip install -U setuptools
    pip install itsdangerous==0.23
    pip install argparse==1.2.1
    pip install alembic==0.7.4
    pip install Flask-Script==0.6.7
    pip install Flask-Migrate==1.3.0
    pip install Pillow==2.8.1
    pip install requests==2.7.0
    pip install ipython==4.0.0
    pip install Flask==0.10
    pip install Flask-Mail==0.8.2
    pip install Flask-Babel==0.8
    pip install Flask-Login==0.2.6
    pip install SQLAlchemy==0.8.2
    pip install Flask-SQLAlchemy==1.0
    pip install Flask-CDN==1.2.1
    pip install flask-util-js==0.2.19
    pip install MySQL-python==1.2.5
    pip install pyparsing==1.5.7
    pip install pydot==1.0.2

then add some symbolic links in Vilfredo core pointing to static files and templates (although the first one could not be needed if NGINX is configured to serve static files) and create configuration files:

.. code:: sh

    cd VilfredoReloadedCore
    ln -sf /home/vilfredo/vilfredo-client/static /home/vilfredo/vilfredo-core/VilfredoReloadedCore/static
    ln -sf /home/vilfredo/vilfredo-client/templates /home/vilfredo/vilfredo-core/VilfredoReloadedCore/templates
    # Set required permissions for the "static" folder
    chgrp www-data /home/vilfredo/vilfredo-client/static

    # Creates a file which will be later needed to access MySQL server
    # Replace ROOT_MYSQL_PASSWORD with your MySQL server "root" password
    cat > /root/.my.cnf <<EOF
    [mysql]
    user=root
    password=ROOT_MYSQL_PASSWORD

    [mysqldump]
    user=root
    password=ROOT_MYSQL_PASSWORD
    EOF

    chmod 600 /root/.my.cnf
    # Move configuration files to a centralized folder
    mkdir /etc/vilfredo
    cp /home/vilfredo/vilfredo-setup/settings.cfg /etc/vilfredo/settings.cfg
    mv /home/vilfredo/vilfredo-client/static/js/settings.js /etc/vilfredo
    ln -s /etc/vilfredo/settings.js /home/vilfredo/vilfredo-client/static/js
    # Replace YOUR_VILFREDO_MYSQL_PASSWORD with your chosen "vilfredo" (not "root") MySQL user password
    # Replace YOUR_SECRET_KEY with a secret key chosen by you
    # Replace YOUR_VILFREDO_SALT with a salt chosen by you
    replace vilfredo_mysql_password YOUR_VILFREDO_MYSQL_PASSWORD -- /etc/vilfredo/settings.cfg
    replace secret_key YOUR_SECRET_KEY -- /etc/vilfredo/settings.cfg
    replace vilfredo_salt YOUR_VILFREDO_SALT -- /etc/vilfredo/settings.cfg
    chown vilfredo /etc/vilfredo/settings.cfg
    ln -sf /etc/vilfredo/settings.cfg /home/vilfredo/vilfredo-core/VilfredoReloadedCore
    chown -h vilfredo /home/vilfredo/vilfredo-core/VilfredoReloadedCore/settings.cfg
    cp /home/vilfredo/vilfredo-setup/logging_debug.conf /etc/vilfredo
    ln -s /etc/vilfredo/logging_debug.conf /home/vilfredo/vilfredo-core/VilfredoReloadedCore
    mkdir /var/log/vilfredo
    chown vilfredo /var/log/vilfredo
    # This file is not needed in this setup - delete it if it has been downloaded from repository
    rm /home/vilfredo/vilfredo-core/VilfredoReloadedCore/main.py
    chown -R vilfredo:www-data /home/vilfredo

Web server installation instructions
====================================

We selected NGINX instead of other web servers because of its remarkable performance and low memory consumption.

The following instructions assume you're installing the actual www.vilfredo.org website.

This also features a PHPMyAdmin installation protected by an additional password.

Configuration will have to be trimmed down or expanded for different scenarios.

.. code:: sh

    # Install the NGINX web server configuration for vilfredo.org domain
    # This specifies a SSL certificate and adds a virtual folder to PHPMyAdmin
    # Should be edited if needed, changing domain and certificate name.
    # To generate a certificate with a commercial authority, refer to "ssl-howto.txt"
    # The SSL certificate might as well be created through Let's Encrypt
    # (in this case, edit certificate path accordingly in NGINX configuration).
    # A simplified configuration file can be found in instance-nginx.conf
    cp /home/vilfredo/vilfredo-setup/vilfredo-nginx.conf /etc/nginx/sites-available/vilfredo.conf
    ln -sf /etc/nginx/sites-available/vilfredo.conf /etc/nginx/sites-enabled
    rm /etc/nginx/sites-enabled/default
    # Generates additional password to further protect PHPMyAdmin installation
    sudo apt-get install apache2-utils
    htpasswd -c /etc/nginx/htpasswd root
    chown www-data:www-data /etc/nginx/htpasswd
    chmod 600 /etc/nginx/htpasswd
    # Creates log folder for PHPMyAdmin installation
    mkdir /var/log/nginx/phpmyadmin
    replace ";opcache.enable=0" "opcache.enable=1" -- /etc/php5/fpm/php.ini
    replace ";opcache.save_comments=1" "opcache.save_comments=0" -- /etc/php5/fpm/php.ini
    replace ";opcache.fast_shutdown=0" "opcache.fast_shutdown=1" -- /etc/php5/fpm/php.ini
    cp /home/vilfredo/vilfredo-setup/vilfredo-uwsgi.ini /etc/uwsgi-pypy/apps-available/vilfredo.ini
    ln -sf /etc/uwsgi-pypy/apps-available/vilfredo.ini /etc/uwsgi-pypy/apps-enabled
    chown -R root:root /etc/uwsgi-pypy
    # Create the /etc/nginx/dhparam.pem file (requires some time)
    openssl dhparam -out /etc/nginx/dhparam.pem 2048
    service uwsgi-pypy restart
    service php5-fpm restart
    service nginx restart

If the server has an assigned domain name, edit the ``server_name`` directive in the ``/etc/nginx/sites-available/vilfredo.conf`` file and enter it following ``server_name``, replacing ``vilfredo.org``. Also edit the ``PROTOCOL`` and ``SITE_DOMAIN`` directives in the ``/etc/vilfredo/settings.cfg`` file as needed to suit your domain name (replacing ``https`` with ``http`` if SSL not supported) and restart services:

.. code:: sh

    service uwsgi-pypy restart
    service php5-fpm restart
    service nginx restart

If you want to generate a SSL certificate for a different domain, refer to the ``ssl-howto.txt`` file.

Moreover, you may edit the client configuration file named

    /etc/vilfredo/settings.js

replacing ``VILFREDO_URL`` with your website URL and setting ``PROTOCOL`` to "http://" or "https://"

You should also edit the ``/home/vilfredo/vilfredo-client/static/templates/analytics.template.html`` file and replace ``UA-XXXXXXXX-X`` with your Google Analytics ID.
Please note this file could cause JavaScript errors in some Vilfredo versions - in this case, just rename it to ``/home/vilfredo/vilfredo-client/static/templates/analytics.template.html.old`` to prevent the webserver from serving it.

Now you should be able to access the Vilfredo installation by entering the server IP address into your browser location bar. There could be other issues to be solved - you might have a look at the ``/var/log/vilfredo/vilfredo-vr.log`` for more information.

Mail server installation instructions
=====================================

Vilfredo requires a working mail server to send email messages to users.
To avoid messages being marked as spam by recipients, the server should support DKIM and SPF.
DKIM is a sort of "digital signature" which is added to all email messages to ensure they had been originated by a server in the domain of the sender. A public-private key has to be generated on the server, then a dedicated daemon (for instance OpenDKIM) will take care of generating a digital signature using those keys, adding it to the message headers. The public key must also be added to a TXT record in the domain zone on DNS.
SPF is used to specify the list of IP addresses and servers which are allowed sending messages from a given domain. It does not require generating public-private key pairs. Just add a TXT record in the domain zone on DNS specifying the list of servers and IP addresses.
As always, feel free to replace ``vilfredo.org`` with your mail server domain name.

First of all, install Postfix and OpenDKIM on your server:

.. code:: sh

    apt-get install postfix opendkim opendkim-tools
    cp /home/vilfredo/vilfredo-setup/opendkim.conf /etc
    mkdir /etc/dkim
    # The /etc/dkim/domains file contains the list of domains authorized to send mail messages
    # The following line allows the server itself sending digitally signed messages
    echo "localhost [::1]" > /etc/dkim/domains
    # Note: From now on, replace "vilfredo.org" with the site domain if different
    echo "vilfredo.org" >> /etc/dkim/domains
    echo "default._domainkey.vilfredo.org  vilfredo.org:default:/etc/dkim/keys/vilfredo.org/default" > /etc/dkim/keytable
    echo "vilfredo.org  default._domainkey.vilfredo.org" > /etc/dkim/signingtable
    mkdir -p /etc/dkim/keys/vilfredo.org
    cd /etc/dkim/keys/vilfredo.org
    opendkim-genkey -r -d vilfredo.org
    mv /etc/dkim/keys/vilfredo.org/default.private /etc/dkim/keys/vilfredo.org/default
    chmod 600 /etc/dkim/keys/vilfredo.org/default
    chown -R opendkim:opendkim /etc/dkim
    chmod -R o-r,o-w,o-x /etc/dkim
    # WARNING: Do not mistype this - do not enter ">" instead of ">>" or you'll erase Postfix configuration!
    cat /home/vilfredo/vilfredo-setup/postfix-dkim.conf >> /etc/postfix/main.cf
    replace "#myorigin" "myorigin" -- /etc/postfix/main.cf
    service opendkim restart
    service postfix restart

Now get the contents of the ``/etc/dkim/keys/vilfredo.org/default.txt`` file (or whatever, depending from the domain name chosen) and copy its contents to the domain zone file in the DNS.
If you DNS is externally managed (you do not have access to the configuration files but only to a web-based interface):

- add a new TXT type record
- specify as name ``default._domainkey``
- enter the text between quotes as value (without any additional quotes!)

If you want to send mail from a subdomain (for instance demo.vilfredo.org) do not forget to add the TXT record containing the DKIM key to the subdomain instead of the main domain!

Moreover, ensure the ``/etc/hostname`` and ``/etc/mailname`` files contains the server domain name (for instance vilfredo.org).

To avoid triggering SpamAssassin filter (rule ``TVD_PH_SUBJ_ACCOUNTS_POST``), also ensure the subject of messages sent by Vilfredo does not match the following regular expression:

    /\b(?:(?:re-?)?activat[a-z]*| secure| verify| restore| flagged| limited| unusual| report| notif(?:y| ication)| suspen(?:d| ded| sion)| confirm[a-z]*) (?:[a-z_,-]+ )*?accounts?\b/i

So it should be different from "Vilfredo - Activate Your Account".
Additionally, please note other steps could be needed in order to circumvent spam filters.

Fine tuning
===========

To improve security of the server, you might limit users allowed to log in through SSH, by editing the /etc/ssh/sshd_config file and adding

    AllowUsers root user1 user2

replacing ``user1`` and ``user2`` with other users allowed to log in.
Then enter

.. code:: sh

    service ssh restart

This way, there will be no risks in case a weak password has been chosen for system users or users running Vilfredo instances.

Installing other instances
==========================

To create other instances of Vilfredo, enter

.. code:: sh

    /home/vilfredo/vilfredo-setup/scripts/makeinstance [name] [domain] [branch] [mysql database password]

where ``[name]`` could be, for instance, "test", "nightly" or "demo", ``[domain]`` is the assigned domain name, ``[branch]`` is the GIT repository branch from where to download code (usually "master").

A system user will be created with the name specified, with its corresponding folder.

An additional ``/etc/$NAME`` folder will be created, so this means the instance name cannot match existing folders in the system.

The procedure will also create a new MySQL user with proper permissions and set up an empty database with the same name as the instance.
