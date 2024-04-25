#!/bin/bash

# drop_in_bookworm_support_files.sh
#
# Copy support files needed for RN2 to successfully deploy on bookworm prior to ansible director executing

v_bookworm_source="$HOME/raspberry-noaa-v2/software/bookworm-support"
v_rw=644
v_rwx=755

cp ${v_bookworm_source}/main.yml.bookworm $HOME/raspberry-noaa-v2/ansible/roles/webserver/tasks/main.yml
chmod ${v_rw} $HOME/raspberry-noaa-v2/ansible/roles/webserver/tasks/main.yml

cp ${v_bookworm_source}/dependencies.yml.bookworm $HOME/raspberry-noaa-v2/ansible/roles/common/tasks/dependencies.yml
chmod ${v_rw} $HOME/raspberry-noaa-v2/ansible/roles/common/tasks/dependencies.yml

cp ${v_bookworm_source}/ntp.yml.bookworm $HOME/raspberry-noaa-v2/ansible/roles/common/tasks/ntp.yml
chmod ${v_rw} $HOME/raspberry-noaa-v2/ansible/roles/common/tasks/ntp.yml

cp ${v_bookworm_source}/nginx_tls_default.j2.bookworm $HOME/raspberry-noaa-v2/ansible/roles/webserver/templates/nginx_tls_default.j2
chmod ${v_rw} $HOME/raspberry-noaa-v2/ansible/roles/webserver/templates/nginx_tls_default.j2

cp ${v_bookworm_source}/nginx_default.j2.bookworm $HOME/raspberry-noaa-v2/ansible/roles/webserver/templates/nginx_default.j2
chmod ${v_rw} $HOME/raspberry-noaa-v2/ansible/roles/webserver/templates/nginx_default.j2

cp ${v_bookworm_source}/nginx_tls_default.j2.bookworm $HOME/raspberry-noaa-v2/ansible/roles/webserver/templates/nginx_tls_default.j2
chmod ${v_rw} $HOME/raspberry-noaa-v2/ansible/roles/webserver/templates/nginx_tls_default.j2

cp ${v_bookworm_source}/ntp.yml.bookworm $HOME/raspberry-noaa-v2/ansible/roles/common/tasks/ntp.yml
chmod ${v_rw} $HOME/raspberry-noaa-v2/ansible/roles/common/tasks/ntp.yml

cp ${v_bookworm_source}/dependencies.yml.bookworm $HOME/raspberry-noaa-v2/ansible/roles/common/tasks/dependencies.yml
chmod ${v_rw} $HOME/raspberry-noaa-v2/ansible/roles/common/tasks/dependencies.yml

cp ${v_bookworm_source}/Controller.php.bookworm $HOME/raspberry-noaa-v2/webpanel/Lib/Controller.php
chmod ${v_rw} $HOME/raspberry-noaa-v2/webpanel/Lib/Controller.php

cp ${v_bookworm_source}/composer.json.bookworm $HOME/raspberry-noaa-v2/webpanel/composer.json
chmod ${v_rw} $HOME/raspberry-noaa-v2/webpanel/composer.json

cp ${v_bookworm_source}/composer.lock.bookworm $HOME/raspberry-noaa-v2/webpanel/composer.lock
chmod ${v_rw} $HOME/raspberry-noaa-v2/webpanel/composer.lock
