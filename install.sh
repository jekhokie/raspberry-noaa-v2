### Setup ramFS
SYSTEM_MEMORY=$(free -m | awk '/^Mem:/{print $2}')
if [ "$SYSTEM_MEMORY" -lt 2000 ]; then
	sed -i -e "s/1000M/200M/g" templates/fstab
fi
set +e
cat /etc/fstab | grep -q "ramfs"
if [ $? -eq 0 ]; then
    log_done "ramfs already setup"
else
    sudo mkdir -p /var/ramfs
    cat templates/fstab | sudo tee -a /etc/fstab > /dev/null
    log_done "Ramfs installed"
fi
sudo mount -a
sudo chmod 777 /var/ramfs
set -e

sed -i -e "s/'lang' => '.*'$/'lang' => '${lang}'/" "/var/www/wx/Config.php"

echo "Visit https://www.php.net/manual/en/timezones.php for a list of available timezones"
read -rp "Enter your preferred timezone: "
    timezone=$REPLY
timezone=$(echo $timezone | sed 's/\//\\\//g')
sed -i -e "s/date_default_timezone_set('.*');/date_default_timezone_set('${timezone}');/" "/var/www/wx/header.php"


### Running WXTOIMG to have the user accept the licensing agreement
wxtoimg

sudo reboot
