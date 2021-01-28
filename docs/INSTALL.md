![Raspberry NOAA](../assets/header_1600.png)

- [Raspberry PI operating system](#raspberry-pi-operating-system)
- [Automatic install](#automatic-install)
- [Manual install](#manual-install)
  - [Required packages and software](#required-packages-and-software)
    - [Install rtl_sdr](#install-rtl_sdr)
    - [Install WXToIMG](#install-wxtoimg)
  - [Raspberry-noaa configuration](#raspberry-noaa-configuration)
    - [Clone this repo](#clone-this-repo)
    - [Install the default configuration files](#install-the-default-configuration-files)
    - [Install Meteor software](#install-meteor-software)
    - [Setup Nginx](#setup-nginx)
    - [Setup Database](#setup-database)
    - [Setup RamFS](#setup-ramfs)
    - [Setup ISS reception and decoding (SSTV)](#setup-iss-reception-and-decoding-sstv)
    - [Cron the scheduling job](#cron-the-scheduling-job)
    - [Set your Twitter credentials](#set-your-twitter-credentials)

# Raspberry PI operating system
I'm using [Raspbian](https://www.raspberrypi.org/downloads/raspbian/) as it have full support for Raspberry PI, simple package manager and it's pretty stable

# Automatic install
1. Update repositories and install git
```
sudo apt update
sudo apt install git
```
2. Clone this repository on your home directory
```
cd $HOME
git clone https://github.com/jekhokie/raspberry-noaa-v2.git
cd raspberry-noaa-v2
```
2. Run `./install.sh`. You will be asked for your ground station lat/lon position.
3. If you want automatic Twitter posting, see: [Set your Twitter credentials](#set-your-twitter-credentials)


This is pretty much the entire setup. If you are interested about the behind of scenes please check the following section

---


# Manual install

## Required packages and software

```
sudo apt update -yq
sudo apt install -yq predict \
                     python-setuptools \
                     ntp \
                     cmake \
                     libusb-1.0 \
                     sox \
                     at \
                     bc \
                     nginx \
                     libncurses5-dev \
                     libncursesw5-dev \
                     libatlas-base-dev \
                     python3-pip \
                     imagemagick \
                     libxft-dev \
                     libxft2 \
                     libjpeg9 \
                     libjpeg9-dev \
                     socat \
                     php7.2-fpm \
                     php7.2-sqlite \
                     sqlite3 \
                     libgfortran5
``` 

```
sudo pip3 install numpy ephem tweepy Pillow
```

### Install rtl_sdr
```
sudo cp templates/modprobe.d/rtlsdr.conf /etc/modprobe.d/rtlsdr.conf
```

- clone rlt-sdr git repo and install rtl-sdr:
```
cd /tmp/
git clone https://github.com/osmocom/rtl-sdr.git
cd rtl-sdr/
mkdir build
cd build
cmake ../ -DINSTALL_UDEV_RULES=ON -DDETACH_KERNEL_DRIVER=ON
make
sudo make install
sudo ldconfig
cd /tmp/
sudo cp ./rtl-sdr/rtl-sdr.rules /etc/udev/rules.d/
```

### Install WXToIMG
There's a deb package for it
```
sudo dpkg -i software/wxtoimg-armhf-2.11.2-beta.deb
```

## Raspberry-noaa configuration
### Clone this repo
```
cd $HOME
git clone https://github.com/jekhokie/raspberry-noaa-v2.git
cd raspberry-noaa-v2
```

### Install the default configuration files
- noaa.conf: paths, satellite elevation and loggin 
```
cp "templates/noaa.conf" "$HOME/.noaa.conf"
```

- predict.qth: Predict's ground station settings
```
cp "templates/predict.qth" "$HOME/.predict/predict.qth"
```

- wxtoimgrc: WxToIMG ground station settings and license
```
cp "templates/wxtoimgrc" "$HOME/.wxtoimgrc"
```

Don't forget to adjust your settings in those files

### Install Meteor software
- meteor_demod
```
git clone https://github.com/dbdexter-dev/meteor_demod.git
cd meteor_demod
make
sudo make install
cd ..
```

- medet_arm
```
sudo cp software/medet_arm /usr/bin/medet_arm
sudo chmod +x /usr/bin/medet_arm
```

### Setup Nginx
```
sudo cp templates/nginx.cfg /etc/nginx/sites-enabled/default
sudo mkdir -p /var/www/wx
sudo chown -R www-data:www-data /var/www/wx
sudo usermod -a -G www-data pi
sudo chmod 775 /var/www/wx
sudo cp templates/index.html /var/www/wx/index.html
sudo cp templates/logo-small.png /var/www/wx/logo-small.png
sudo systemctl restart nginx
sudo cp -rp templates/webpanel/* /var/www/wx/
```

### Setup Database
```
sqlite3 "panel.db" < "templates/webpanel_schema.sql"
```

### Setup RamFS
```
sudo mkdir -p /var/ramfs
cat templates/fstab | sudo tee -a /etc/fstab > /dev/null
sudo mount -a
sudo chmod 777 /var/ramfs
```

### Setup ISS reception and decoding (SSTV)
```
wget -qr https://github.com/reynico/pd120_decoder/archive/master.zip -O /tmp/master.zip
cd /tmp
unzip master.zip
cd pd120_decoder-master/pd120_decoder/
pip3 install --user -r requirements.txt
cp demod.py utils.py "/home/pi/raspberry-noaa-v2/"
```

### Cron the scheduling job
```
cat <(crontab -l) <(echo "1 0 * * * /home/pi/raspberry-noaa-v2/schedule.sh") | crontab -
```

### Set your Twitter credentials
- Go to [Twitter Developer site](http://developer.twitter.com/) and apply for a developer account.
```
cp "templates/tweepy.conf" "$HOME/.tweepy.conf"
```
- Set your credentials on `"$HOME/.tweepy.conf"`
```
export CONSUMER_KEY = ''
export CONSUMER_SECRET = ''
export ACCESS_TOKEN_KEY = ''
export ACCESS_TOKEN_SECRET = ''
```
