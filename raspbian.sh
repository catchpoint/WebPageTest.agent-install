#!/bin/bash

# Prompt for the configuration options
echo "Automatic agent install and configuration."
echo
read -e -p "Disable IPv6 (recommended unless IPv6 connectivity is available) (Y/n): " -i "y" DISABLE_IPV6
while [[ $WPT_SERVER == '' ]]
do
  read -p "WebPageTest server (i.e. www.webpagetest.org): " WPT_SERVER
done
while [[ $WPT_LOCATION == '' ]]
do
  read -p "Location ID (i.e. Dulles): " WPT_LOCATION
done
read -p "Location Key (if required): " WPT_KEY
read -p "Device Name (optional): " WPT_DEVICE_NAME

# Pre-prompt for the sudo authorization so it doesn't prompt later
sudo date

# Make sure sudo doesn't prompt for a password
echo "$USER ALL=(ALL:ALL) NOPASSWD:ALL" | sudo EDITOR='tee -a' visudo

echo "Trimming filesystem..."
sudo fstrim -v /

cd ~
until sudo apt update
do
    sleep 1
done
# Known-good kernel 4.14.62
# TODO: remove this when newer kernels stop panic'ing for netem
until sudo rpi-update 911147a3276beee09afc4237e1b7b964e61fb88a
do
    sleep 1
done
sudo apt-mark hold raspberrypi-bootloader raspberrypi-kernel

# Install OS packages
until sudo DEBIAN_FRONTEND=noninteractive apt -yq -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" dist-upgrade
do
    sleep 1
done
curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash -
echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | sudo debconf-set-selections
until sudo DEBIAN_FRONTEND=noninteractive apt install -yq git screen watchdog \
libtiff5-dev libjpeg-dev zlib1g-dev libfreetype6-dev liblcms2-dev libwebp-dev tcl8.6-dev tk8.6-dev python-tk python2.7 python-pip \
python-dev libavutil-dev libmp3lame-dev libx264-dev yasm autoconf automake build-essential libass-dev libfreetype6-dev libtheora-dev \
libtool libvorbis-dev pkg-config texi2html zlib1g-dev libtext-unidecode-perl python-numpy python-scipy \
imagemagick ffmpeg xvfb dbus-x11 adb \
cgroup-tools traceroute software-properties-common psmisc libnss3-tools iproute2 net-tools ethtool nodejs \
chromium-browser firefox-esr ttf-mscorefonts-installer fonts-noto*
do
    sleep 1
done
sudo apt install -y python-software-properties
until sudo npm install -g lighthouse
do
    sleep 1
done
sudo npm update -g
sudo dbus-uuidgen --ensure
sudo fc-cache -f -v

# Set up python
until sudo pip install dnspython monotonic pillow psutil pyssim requests ujson tornado wsaccel xvfbwrapper marionette_driver
do
    sleep 1
done
until git clone https://github.com/WPO-Foundation/wptagent.git
do
    sleep 1
done
cd ~/wptagent
git checkout origin/release
cd ~

# ffmpeg
cd ~
git clone --depth 1 https://github.com/FFmpeg/FFmpeg.git ffmpeg
cd ffmpeg
./configure --arch=armel --target-os=linux --enable-gpl --enable-libx264 --enable-nonfree
make -j4
sudo make install
cd ~
rm -rf ffmpeg

# iOS support
until sudo DEBIAN_FRONTEND=noninteractive apt -yq install build-essential \
cmake python-dev cython swig automake autoconf libtool libusb-1.0-0 libusb-1.0-0-dev \
libreadline-dev openssl libssl1.0.2 libssl1.1 libssl-dev
do
    sleep 1
done
cd ~

git clone --depth 1 https://github.com/libimobiledevice/libplist.git libplist
cd libplist
./autogen.sh
make
sudo make install
cd ~
rm -rf libplist

git clone --depth 1 https://github.com/libimobiledevice/libusbmuxd.git libusbmuxd
cd libusbmuxd
./autogen.sh
make
sudo make install
cd ~
rm -rf libusbmuxd

git clone --depth 1 https://github.com/libimobiledevice/libimobiledevice.git libimobiledevice
cd libimobiledevice
./autogen.sh
make
sudo make install
cd ~
rm -rf libimobiledevice

git clone --depth 1 https://github.com/libimobiledevice/usbmuxd.git usbmuxd
cd usbmuxd
./autogen.sh
make
sudo make install
cd ~
rm -rf usbmuxd

git clone --depth 1 https://github.com/google/ios-webkit-debug-proxy.git ios-webkit-debug-proxy
cd ios-webkit-debug-proxy
./autogen.sh
make
sudo make install
cd ~
rm -rf ios-webkit-debug-proxy


# System config
echo '# Limits increased for wptagent' | sudo tee -a /etc/security/limits.conf
echo '* soft nofile 250000' | sudo tee -a /etc/security/limits.conf
echo '* hard nofile 300000' | sudo tee -a /etc/security/limits.conf
echo '# wptagent end' | sudo tee -a /etc/security/limits.conf
echo '# Settings updated for wptagent' | sudo tee -a /etc/sysctl.conf
echo 'net.ipv4.tcp_syn_retries = 4' | sudo tee -a /etc/sysctl.conf

# Boot options
echo 'dtoverlay=pi3-disable-wifi' | sudo tee -a /boot/config.txt
echo 'dtparam=sd_overclock=100' | sudo tee -a /boot/config.txt
echo 'dtparam=watchdog=on' | sudo tee -a /boot/config.txt

# Swap file
echo "CONF_SWAPSIZE=1024" | sudo tee /etc/dphys-swapfile
sudo dphys-swapfile setup
sudo dphys-swapfile swapon

# disable IPv6 if requested
if [ "${DISABLE_IPV6,,}" == 'y' ]; then
  echo "net.ipv6.conf.all.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.conf
  echo "net.ipv6.conf.default.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.conf
  echo "net.ipv6.conf.lo.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.conf
fi

# Reboot when out of memory
echo "vm.panic_on_oom=1" | sudo tee -a /etc/sysctl.conf
echo "kernel.panic=10" | sudo tee -a /etc/sysctl.conf

# disable IPv6 if requested
if [ "${DISABLE_IPV6,,}" == 'y' ]; then
  echo "net.ipv6.conf.all.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.conf
  echo "net.ipv6.conf.default.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.conf
  echo "net.ipv6.conf.lo.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.conf
fi

echo '# wptagent end' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# disable hardware checksum offload
sudo sed -i 's/exit 0/ethtool --offload eth0 rx off tx off\nexit 0/g' /etc/network/interfaces

# configure adb
sudo gpasswd -a $USER plugdev
echo "SUBSYSTEM==\"usb\", ATTR{idVendor}==\"0502\", MODE=\"0666\", GROUP=\"plugdev\", OWNER=\"$USER\"" | sudo tee /etc/udev/rules.d/51-android.rules
echo "SUBSYSTEM==\"usb\", ATTR{idVendor}==\"0b05\", MODE=\"0666\", GROUP=\"plugdev\", OWNER=\"$USER\"" | sudo tee -a /etc/udev/rules.d/51-android.rules
echo "SUBSYSTEM==\"usb\", ATTR{idVendor}==\"413c\", MODE=\"0666\", GROUP=\"plugdev\", OWNER=\"$USER\"" | sudo tee -a /etc/udev/rules.d/51-android.rules
echo "SUBSYSTEM==\"usb\", ATTR{idVendor}==\"0489\", MODE=\"0666\", GROUP=\"plugdev\", OWNER=\"$USER\"" | sudo tee -a /etc/udev/rules.d/51-android.rules
echo "SUBSYSTEM==\"usb\", ATTR{idVendor}==\"04c5\", MODE=\"0666\", GROUP=\"plugdev\", OWNER=\"$USER\"" | sudo tee -a /etc/udev/rules.d/51-android.rules
echo "SUBSYSTEM==\"usb\", ATTR{idVendor}==\"091e\", MODE=\"0666\", GROUP=\"plugdev\", OWNER=\"$USER\"" | sudo tee -a /etc/udev/rules.d/51-android.rules
echo "SUBSYSTEM==\"usb\", ATTR{idVendor}==\"18d1\", MODE=\"0666\", GROUP=\"plugdev\", OWNER=\"$USER\"" | sudo tee -a /etc/udev/rules.d/51-android.rules
echo "SUBSYSTEM==\"usb\", ATTR{idVendor}==\"201e\", MODE=\"0666\", GROUP=\"plugdev\", OWNER=\"$USER\"" | sudo tee -a /etc/udev/rules.d/51-android.rules
echo "SUBSYSTEM==\"usb\", ATTR{idVendor}==\"109b\", MODE=\"0666\", GROUP=\"plugdev\", OWNER=\"$USER\"" | sudo tee -a /etc/udev/rules.d/51-android.rules
echo "SUBSYSTEM==\"usb\", ATTR{idVendor}==\"12d1\", MODE=\"0666\", GROUP=\"plugdev\", OWNER=\"$USER\"" | sudo tee -a /etc/udev/rules.d/51-android.rules
echo "SUBSYSTEM==\"usb\", ATTR{idVendor}==\"8087\", MODE=\"0666\", GROUP=\"plugdev\", OWNER=\"$USER\"" | sudo tee -a /etc/udev/rules.d/51-android.rules
echo "SUBSYSTEM==\"usb\", ATTR{idVendor}==\"24e3\", MODE=\"0666\", GROUP=\"plugdev\", OWNER=\"$USER\"" | sudo tee -a /etc/udev/rules.d/51-android.rules
echo "SUBSYSTEM==\"usb\", ATTR{idVendor}==\"2116\", MODE=\"0666\", GROUP=\"plugdev\", OWNER=\"$USER\"" | sudo tee -a /etc/udev/rules.d/51-android.rules
echo "SUBSYSTEM==\"usb\", ATTR{idVendor}==\"17ef\", MODE=\"0666\", GROUP=\"plugdev\", OWNER=\"$USER\"" | sudo tee -a /etc/udev/rules.d/51-android.rules
echo "SUBSYSTEM==\"usb\", ATTR{idVendor}==\"1004\", MODE=\"0666\", GROUP=\"plugdev\", OWNER=\"$USER\"" | sudo tee -a /etc/udev/rules.d/51-android.rules
echo "SUBSYSTEM==\"usb\", ATTR{idVendor}==\"22b8\", MODE=\"0666\", GROUP=\"plugdev\", OWNER=\"$USER\"" | sudo tee -a /etc/udev/rules.d/51-android.rules
echo "SUBSYSTEM==\"usb\", ATTR{idVendor}==\"0e8d\", MODE=\"0666\", GROUP=\"plugdev\", OWNER=\"$USER\"" | sudo tee -a /etc/udev/rules.d/51-android.rules
echo "SUBSYSTEM==\"usb\", ATTR{idVendor}==\"0409\", MODE=\"0666\", GROUP=\"plugdev\", OWNER=\"$USER\"" | sudo tee -a /etc/udev/rules.d/51-android.rules
echo "SUBSYSTEM==\"usb\", ATTR{idVendor}==\"2080\", MODE=\"0666\", GROUP=\"plugdev\", OWNER=\"$USER\"" | sudo tee -a /etc/udev/rules.d/51-android.rules
echo "SUBSYSTEM==\"usb\", ATTR{idVendor}==\"0955\", MODE=\"0666\", GROUP=\"plugdev\", OWNER=\"$USER\"" | sudo tee -a /etc/udev/rules.d/51-android.rules
echo "SUBSYSTEM==\"usb\", ATTR{idVendor}==\"2257\", MODE=\"0666\", GROUP=\"plugdev\", OWNER=\"$USER\"" | sudo tee -a /etc/udev/rules.d/51-android.rules
echo "SUBSYSTEM==\"usb\", ATTR{idVendor}==\"10a9\", MODE=\"0666\", GROUP=\"plugdev\", OWNER=\"$USER\"" | sudo tee -a /etc/udev/rules.d/51-android.rules
echo "SUBSYSTEM==\"usb\", ATTR{idVendor}==\"1d4d\", MODE=\"0666\", GROUP=\"plugdev\", OWNER=\"$USER\"" | sudo tee -a /etc/udev/rules.d/51-android.rules
echo "SUBSYSTEM==\"usb\", ATTR{idVendor}==\"0471\", MODE=\"0666\", GROUP=\"plugdev\", OWNER=\"$USER\"" | sudo tee -a /etc/udev/rules.d/51-android.rules
echo "SUBSYSTEM==\"usb\", ATTR{idVendor}==\"04da\", MODE=\"0666\", GROUP=\"plugdev\", OWNER=\"$USER\"" | sudo tee -a /etc/udev/rules.d/51-android.rules
echo "SUBSYSTEM==\"usb\", ATTR{idVendor}==\"05c6\", MODE=\"0666\", GROUP=\"plugdev\", OWNER=\"$USER\"" | sudo tee -a /etc/udev/rules.d/51-android.rules
echo "SUBSYSTEM==\"usb\", ATTR{idVendor}==\"1f53\", MODE=\"0666\", GROUP=\"plugdev\", OWNER=\"$USER\"" | sudo tee -a /etc/udev/rules.d/51-android.rules
echo "SUBSYSTEM==\"usb\", ATTR{idVendor}==\"04e8\", MODE=\"0666\", GROUP=\"plugdev\", OWNER=\"$USER\"" | sudo tee -a /etc/udev/rules.d/51-android.rules
echo "SUBSYSTEM==\"usb\", ATTR{idVendor}==\"04dd\", MODE=\"0666\", GROUP=\"plugdev\", OWNER=\"$USER\"" | sudo tee -a /etc/udev/rules.d/51-android.rules
echo "SUBSYSTEM==\"usb\", ATTR{idVendor}==\"054c\", MODE=\"0666\", GROUP=\"plugdev\", OWNER=\"$USER\"" | sudo tee -a /etc/udev/rules.d/51-android.rules
echo "SUBSYSTEM==\"usb\", ATTR{idVendor}==\"0fce\", MODE=\"0666\", GROUP=\"plugdev\", OWNER=\"$USER\"" | sudo tee -a /etc/udev/rules.d/51-android.rules
echo "SUBSYSTEM==\"usb\", ATTR{idVendor}==\"2340\", MODE=\"0666\", GROUP=\"plugdev\", OWNER=\"$USER\"" | sudo tee -a /etc/udev/rules.d/51-android.rules
echo "SUBSYSTEM==\"usb\", ATTR{idVendor}==\"0930\", MODE=\"0666\", GROUP=\"plugdev\", OWNER=\"$USER\"" | sudo tee -a /etc/udev/rules.d/51-android.rules
echo "SUBSYSTEM==\"usb\", ATTR{idVendor}==\"2970\", MODE=\"0666\", GROUP=\"plugdev\", OWNER=\"$USER\"" | sudo tee -a /etc/udev/rules.d/51-android.rules
echo "SUBSYSTEM==\"usb\", ATTR{idVendor}==\"1ebf\", MODE=\"0666\", GROUP=\"plugdev\", OWNER=\"$USER\"" | sudo tee -a /etc/udev/rules.d/51-android.rules
echo "SUBSYSTEM==\"usb\", ATTR{idVendor}==\"19d2\", MODE=\"0666\", GROUP=\"plugdev\", OWNER=\"$USER\"" | sudo tee -a /etc/udev/rules.d/51-android.rules
echo "SUBSYSTEM==\"usb\", ATTR{idVendor}==\"2b4c\", MODE=\"0666\", GROUP=\"plugdev\", OWNER=\"$USER\"" | sudo tee -a /etc/udev/rules.d/51-android.rules
echo "SUBSYSTEM==\"usb\", ATTR{idVendor}==\"0bb4\", MODE=\"0666\", GROUP=\"plugdev\", OWNER=\"$USER\"" | sudo tee -a /etc/udev/rules.d/51-android.rules
echo "SUBSYSTEM==\"usb\", ATTR{idVendor}==\"1bbb\", MODE=\"0666\", GROUP=\"plugdev\", OWNER=\"$USER\"" | sudo tee -a /etc/udev/rules.d/51-android.rules
#sudo cp ~/wptagent/misc/adb/arm/adb /usr/bin/adb
sudo udevadm control --reload-rules
sudo service udev restart

# build the startup script
echo '#!/bin/sh' > ~/startup.sh
echo "PATH=$PWD/bin:$PWD/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin" >> ~/startup.sh
echo 'screen -dmS agent ~/agent.sh' >> ~/startup.sh
echo 'sudo service watchdog restart' >> ~/startup.sh
chmod +x ~/startup.sh

# build the agent script
KEY_OPTION=''
if [ $WPT_KEY != '' ]; then
  KEY_OPTION="--key $WPT_KEY"
fi
NAME_OPTION=''
if [ $WPT_DEVICE_NAME != '' ]; then
  NAME_OPTION="--name \"$WPT_DEVICE_NAME\""
fi
echo '#!/bin/sh' > ~/agent.sh
echo 'export DEBIAN_FRONTEND=noninteractive' >> ~/agent.sh
echo 'cd ~/wptagent' >> ~/agent.sh
echo 'echo "Waiting for 30 second startup delay"' >> ~/agent.sh
echo 'sleep 30' >> ~/agent.sh
echo 'echo "Updating OS"' >> ~/agent.sh
echo 'until sudo apt update' >> ~/agent.sh
echo 'do' >> ~/agent.sh
echo '    sleep 1' >> ~/agent.sh
echo 'done' >> ~/agent.sh
echo 'until sudo DEBIAN_FRONTEND=noninteractive apt -yq -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" dist-upgrade' >> ~/agent.sh
echo 'do' >> ~/agent.sh
echo '    sudo apt -f install' >> ~/agent.sh
echo '    sleep 1' >> ~/agent.sh
echo 'done' >> ~/agent.sh
echo 'sudo npm i -g lighthouse' >> ~/agent.sh
echo 'sudo fstrim -v /' >> ~/agent.sh
echo 'for i in `seq 1 24`' >> ~/agent.sh
echo 'do' >> ~/agent.sh
echo '    git pull origin release' >> ~/agent.sh
echo "    python wptagent.py -vvvv $NAME_OPTION --location $WPT_LOCATION $KEY_OPTION --server \"http://$WPT_SERVER/work/\" --android --exit 60 --alive /tmp/wptagent" >> ~/agent.sh
echo "#    python wptagent.py -vvvv $NAME_OPTION --location $WPT_LOCATION $KEY_OPTION --server \"http://$WPT_SERVER/work/\" --android --vpntether eth0,192.168.0.1 --shaper netem,eth0 --exit 60 --alive /tmp/wptagent" >> ~/agent.sh
echo "#    python wptagent.py -vvvv $NAME_OPTION --location $WPT_LOCATION $KEY_OPTION --server \"http://$WPT_SERVER/work/\" --iOS --exit 60 --alive /tmp/wptagent" >> ~/agent.sh
echo '    echo "Exited, restarting"' >> ~/agent.sh
echo '    sleep 1' >> ~/agent.sh
echo 'done' >> ~/agent.sh
echo 'sudo apt -y autoremove' >> ~/agent.sh
echo 'sudo apt clean' >> ~/agent.sh
echo 'adb reboot' >> ~/agent.sh
echo 'sudo reboot' >> ~/agent.sh
chmod +x ~/agent.sh

# add it to the crontab
CRON_ENTRY="@reboot $PWD/startup.sh"
( crontab -l | grep -v -F "$CRON_ENTRY" ; echo "$CRON_ENTRY" ) | crontab -

sudo apt -y autoremove
sudo apt clean

# configure watchdog
echo "bcm2835_wdt" | sudo tee -a /etc/modules
sudo update-rc.d watchdog defaults
echo "watchdog-device = /dev/watchdog" | sudo tee -a /etc/watchdog.conf
echo "watchdog-timeout = 15" | sudo tee -a /etc/watchdog.conf
echo "test-binary = $PWD/wptagent/alive.sh" | sudo tee -a /etc/watchdog.conf
sudo modprobe bcm2835_wdt
echo "RuntimeWatchdogSec=10s" | sudo tee -a /etc/systemd/system.conf
echo "ShutdownWatchdogSec=10min" | sudo tee -a /etc/systemd/system.conf
echo "WantedBy=multi-user.target" | sudo tee -a /lib/systemd/system/watchdog.service
sudo systemctl start watchdog
sudo systemctl status watchdog
sudo systemctl enable watchdog

# Handle android prompts
adb devices -l

cd ~
echo
echo "Install is complete.  Please reboot the system to start testing (sudo reboot)"
