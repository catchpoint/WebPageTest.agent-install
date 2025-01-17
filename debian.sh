#!/bin/bash

#**************************************************************************************************
# WebPageTest agent installation script for Debian-based systems.
# Tested with Ubuntu 18.04+ and Raspbian Buster+
# For headless operation options can be specified in the environment before launching the script:
#**************************************************************************************************
# DISABLE_IPV6=y WPT_CLOUD=ec2 WPT_UPDATE_OS=n bash <(curl -s https://raw.githubusercontent.com/WPO-Foundation/wptagent-install/master/debian.sh)
#
# WPT_CLOUD: blank, ec2 or gce
# AGENT_MODE: desktop, ios, android (defaults to desktop)
#
# Flags - y = enable, n = disable
#
# WPT_UPDATE_OS : dist-upgrade all of the existing OS packages every time the agent starts (daily)
# WPT_UPDATE_OS_NOW : dist-upgrade all of the existing OS packages now (during the install)
# WPT_UPDATE_BROWSERS : Update the browser install certificates and installations automatically daily
# WPT_UPDATE_AGENT : Update the agent code from github release branch hourly and lighthouse daily

#**************************************************************************************************
# Configure Defaults
#**************************************************************************************************

set -eu
: ${DISABLE_IPV6:='n'}
: ${WPT_SERVER:=''}
: ${WPT_LOCATION:=''}
: ${WPT_KEY:=''}
: ${WPT_CLOUD:=''}
: ${AGENT_MODE:='desktop'}
: ${WPT_UPDATE_OS:='y'}
: ${WPT_UPDATE_OS_NOW:='y'}
: ${WPT_UPDATE_AGENT:='y'}
: ${WPT_UPDATE_BROWSERS:='y'}
: ${WPT_CHROME:='y'}
: ${WPT_FIREFOX:='y'}
: ${WPT_BRAVE:='y'}
: ${WPT_EDGE:='y'}
: ${WPT_EPIPHANY:='y'}
: ${WPT_OPERA:='n'}
: ${WPT_VIVALDI:='n'}
: ${LINUX_DISTRO:=`(lsb_release -is)`}
: ${WPT_DEVICE_NAME:='Device'}
: ${WPT_INTERACTIVE:='n'}
if [ "${WPT_INTERACTIVE,,}" == 'y' ]; then
    : ${WPT_BRANCH:='master'}
else
    : ${WPT_BRANCH:='release'}
fi

#**************************************************************************************************
# Prompt for options
#**************************************************************************************************

# Prompt for the configuration options
echo "Installing and configuring WebPageTest agent..."
echo

if [ "${WPT_INTERACTIVE,,}" == 'n' ]; then
    while [[ $DISABLE_IPV6 == '' ]]
    do
        read -e -p "Disable IPv6 (recommended unless IPv6 connectivity is available) (Y/n): " -i "y" DISABLE_IPV6
    done
fi

if [ "${WPT_CLOUD,,}" != 'gce' ] && [ "${WPT_CLOUD,,}" != 'ec2' ]; then
    while [[ $WPT_SERVER == '' ]]
    do
    read -p "WebPageTest server (i.e. www.webpagetest.org): " WPT_SERVER
    done
    while [[ $WPT_LOCATION == '' ]]
    do
    read -p "Location ID (i.e. Dulles): " WPT_LOCATION
    done
    while [[ $WPT_KEY == '' ]]
    do
    read -p "Location Key (if required): " WPT_KEY
    done
fi

# Pre-prompt for the sudo authorization so it doesn't prompt later
sudo date

# Make sure sudo doesn't prompt for a password
echo "${USER} ALL=(ALL:ALL) NOPASSWD:ALL" | sudo tee "/etc/sudoers.d/wptagent"

cd ~
until sudo apt -y update
do
    sleep 1
done

# Disable the ubuntu 22.04 prompt for restarting services
echo "\$nrconf{restart} = 'a'" | sudo tee -a "/etc/needrestart/needrestart.conf" ||:

# system config
if [ "${WPT_INTERACTIVE,,}" == 'y' ]; then
    until sudo apt -y install git curl wget apt-transport-https gnupg2
    do
        sleep 1
    done
else
    until sudo apt -y install git screen watchdog curl wget apt-transport-https xserver-xorg-video-dummy gnupg2
    do
        sleep 1
    done
fi

if [ "${WPT_UPDATE_OS_NOW,,}" == 'y' ]; then
    until sudo DEBIAN_FRONTEND=noninteractive apt -yq -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" dist-upgrade
    do
        sleep 1
    done
fi

#**************************************************************************************************
# Agent code
#**************************************************************************************************

cd ~
rm -rf wptagent
if [ "${WPT_INTERACTIVE,,}" == 'y' ]; then
    until git clone --branch=$WPT_BRANCH https://github.com/WPO-Foundation/wptagent.git
    do
        sleep 1
    done
else
    until git clone --depth 1 --branch=$WPT_BRANCH https://github.com/WPO-Foundation/wptagent.git
    do
        sleep 1
    done
fi

#**************************************************************************************************
# OS Packages
#**************************************************************************************************

# Node JS
curl -sL https://deb.nodesource.com/setup_20.x | sudo -E bash -

# Agent dependencies
echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | sudo debconf-set-selections
until sudo apt -y install python3 python3-pip python3-ujson \
        imagemagick dbus-x11 traceroute software-properties-common psmisc libnss3-tools iproute2 net-tools openvpn \
        libtiff5-dev libjpeg-dev zlib1g-dev libfreetype6-dev liblcms2-dev libwebp-dev tcl8.6-dev tk8.6-dev python3-tk \
        python3-dev libavutil-dev libmp3lame-dev libx264-dev yasm autoconf automake build-essential libass-dev libfreetype6-dev libtheora-dev \
        libtool libvorbis-dev pkg-config texi2html libtext-unidecode-perl python3-numpy python3-scipy perl \
        adb ethtool nodejs cmake git-core libsdl2-dev libva-dev libvdpau-dev libxcb1-dev libxcb-shm0-dev libxcb-xfixes0-dev texinfo wget \
        ttf-mscorefonts-installer fonts-noto fonts-roboto fonts-open-sans
do
    sleep 1
done
sudo pip3 install --upgrade pip

sudo dbus-uuidgen --ensure
sudo fc-cache -f -v

# ffmpeg (built) manually for Raspbian
if [ "${LINUX_DISTRO}" == 'Raspbian' ]; then
    cd ~
    git clone --depth 1 https://github.com/FFmpeg/FFmpeg.git ffmpeg
    cd ffmpeg
    ./configure --extra-ldflags="-latomic" --arch=armel --target-os=linux --enable-gpl --enable-libx264 --enable-nonfree
    make -j4
    sudo make install
    cd ~
    rm -rf ffmpeg
else
    until sudo apt -y install ffmpeg
    do
        sleep 1
    done
fi

# Lighthouse
until sudo npm install -g lighthouse
do
    sleep 1
done
sudo npm update -g

#**************************************************************************************************
# Exiftool (latest from source)
#**************************************************************************************************
git clone https://github.com/exiftool/exiftool.git ~/exiftool
cd ~/exiftool
perl Makefile.PL
sudo make install
cd ~

#**************************************************************************************************
# Android device support
#**************************************************************************************************
if [ "${AGENT_MODE,,}" == 'android' ]; then
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
    echo "SUBSYSTEM==\"usb\", ATTR{idVendor}==\"2a70\", MODE=\"0666\", GROUP=\"plugdev\", OWNER=\"$USER\"" | sudo tee -a /etc/udev/rules.d/51-android.rules
    #sudo cp ~/wptagent/misc/adb/arm/adb /usr/bin/adb
    sudo udevadm control --reload-rules
    sudo service udev restart
fi

#**************************************************************************************************
# iOS support
#**************************************************************************************************
if [ "${AGENT_MODE,,}" == 'ios' ]; then
  until sudo pip install usbmuxwrapper
  do
      sleep 1
  done
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

  sudo sh -c 'echo /usr/local/lib > /etc/ld.so.conf.d/libimobiledevice-libs.conf'
  sudo ldconfig
fi


#**************************************************************************************************
# Python Modules
#**************************************************************************************************
until sudo pip3 install dnspython monotonic pillow psutil requests tornado wsaccel brotli fonttools selenium future usbmuxwrapper pytz tzlocal
do
    sleep 1
done

#**************************************************************************************************
# Browser Installs
#**************************************************************************************************
if [ "${AGENT_MODE,,}" == 'desktop' ]; then
    if [ "${LINUX_DISTRO}" == 'Raspbian' ]; then
        if [ "${WPT_CHROME,,}" == 'y' ]; then
            until sudo apt -y install chromium-browser
            do
                sleep 1
            done
        fi
    else
        if [ "${WPT_CHROME,,}" == 'y' ]; then
            wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
            sudo sh -c 'echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list'
            until sudo apt -y update
            do
                sleep 1
            done
            until sudo apt -yq install google-chrome-stable google-chrome-beta google-chrome-unstable
            do
                sleep 1
            done
        fi

        if [ "${WPT_FIREFOX,,}" == 'y' ]; then
            sudo add-apt-repository -y ppa:ubuntu-mozilla-daily/ppa
            sudo add-apt-repository -y ppa:mozillateam/ppa
            echo 'Package: *' | sudo tee "/etc/apt/preferences.d/mozilla-firefox" ||:
            echo 'Pin: release o=LP-PPA-mozillateam' | sudo tee -a "/etc/apt/preferences.d/mozilla-firefox" ||:
            echo 'Pin-Priority: 1001' | sudo tee -a "/etc/apt/preferences.d/mozilla-firefox" ||:
            echo 'Unattended-Upgrade::Allowed-Origins:: "LP-PPA-mozillateam:${distro_codename}";' | sudo tee "/etc/apt/apt.conf.d/51unattended-upgrades-firefox" ||:
            until sudo apt -y update
            do
                sleep 1
            done
            until sudo apt -yq install firefox firefox-trunk firefox-esr
            do
                sleep 1
            done
            wget https://github.com/mozilla/geckodriver/releases/download/v0.32.0/geckodriver-v0.32.0-linux64.tar.gz
            tar xvzf geckodriver-v0.32.0-linux64.tar.gz
            rm geckodriver-v0.32.0-linux64.tar.gz
            sudo mv geckodriver /usr/bin
        fi

        if [ "${WPT_BRAVE,,}" == 'y' ]; then
            curl -s https://www.webpagetest.org/keys/brave/release.asc | sudo apt-key --keyring /etc/apt/trusted.gpg.d/brave-browser-release.gpg add -
            echo "deb [arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo tee /etc/apt/sources.list.d/brave-browser-release.list
            until sudo apt -y update
            do
                sleep 1
            done
            until sudo apt -yq install brave-browser
            do
                sleep 1
            done
        fi

        if [ "${WPT_EDGE,,}" == 'y' ]; then
            curl -s https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key --keyring /etc/apt/trusted.gpg.d/microsoft.gpg add -
            echo "deb [arch=amd64] https://packages.microsoft.com/repos/edge stable main" | sudo tee /etc/apt/sources.list.d/microsoft-edge-dev.list
            until sudo apt -y update
            do
                sleep 1
            done
            until sudo apt -yq install microsoft-edge-dev microsoft-edge-beta microsoft-edge-stable
            do
                sleep 1
            done
        fi

        if [ "${WPT_EPIPHANY,,}" == 'y' ]; then
            until sudo apt -y update
            do
                sleep 1
            done
            until sudo apt -yq install epiphany-browser
            do
                sleep 1
            done
        fi

        if [ "${WPT_OPERA,,}" == 'y' ]; then
            wget -qO- https://www.webpagetest.org/keys/opera/archive.key | sudo apt-key add -
            sudo add-apt-repository -y 'deb https://deb.opera.com/opera-stable/ stable non-free'
            sudo add-apt-repository -y 'deb https://deb.opera.com/opera-beta/ stable non-free'
            sudo add-apt-repository -y 'deb https://deb.opera.com/opera-developer/ stable non-free'
            until sudo apt -y update
            do
                sleep 1
            done
            until sudo DEBIAN_FRONTEND=noninteractive apt-get install -yq opera-stable opera-beta opera-developer
            do
                sleep 1
            done
        fi

        if [ "${WPT_VIVALDI,,}" == 'y' ]; then
            wget -qO- https://www.webpagetest.org/keys/vivaldi/linux_signing_key.pub | sudo apt-key add -
            sudo add-apt-repository 'deb https://repo.vivaldi.com/archive/deb/ stable main' 
            until sudo apt -y update
            do
                sleep 1
            done
            until sudo apt -yq install vivaldi-stable
            do
                sleep 1
            done
        fi
    fi
fi

#**************************************************************************************************
# OS Config
#**************************************************************************************************

# Disable the built-in automatic updates
if [ "${WPT_INTERACTIVE,,}" == 'n' ]; then

sudo apt -y remove unattended-upgrades

# Clean-up apt
sudo apt -y autoremove

# Minimize the space for systemd journals
sudo mkdir --mode=755 /etc/systemd/journald.conf.d || true
echo 'SystemMaxUse=1M' | sudo tee /etc/systemd/journald.conf.d/wptagent.conf
sudo systemctl restart systemd-journald

# Reboot when out of memory
cat << _SYSCTL_ | sudo tee /etc/sysctl.d/60-wptagent-dedicated.conf
vm.panic_on_oom = 1
kernel.panic = 10
net.ipv4.tcp_syn_retries = 4
_SYSCTL_

# disable IPv6 if requested
if [ "${DISABLE_IPV6,,}" == 'y' ]; then
    cat << _SYSCTL_NO_IPV6_ | sudo tee /etc/sysctl.d/60-wptagent-no-ipv6.conf
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
_SYSCTL_NO_IPV6_
fi

cat << _LIMITS_ | sudo tee /etc/security/limits.d/wptagent.conf
# Limits increased for wptagent
* soft nofile 250000
* hard nofile 300000
_LIMITS_

if [ "${LINUX_DISTRO}" == 'Raspbian' ]; then
    # Boot options
    echo 'dtoverlay=pi3-disable-wifi' | sudo tee -a /boot/config.txt
    echo 'dtparam=sd_overclock=100' | sudo tee -a /boot/config.txt
    echo 'dtparam=watchdog=on' | sudo tee -a /boot/config.txt

    # Swap file
    echo "CONF_SWAPSIZE=1024" | sudo tee /etc/dphys-swapfile
    sudo dphys-swapfile setup
    sudo dphys-swapfile swapon
fi

# configure watchdog
cd ~
echo "test-binary = $PWD/wptagent/alive3.sh" | sudo tee -a /etc/watchdog.conf

fi

#**************************************************************************************************
# Startup Script
#**************************************************************************************************
if [ "${WPT_INTERACTIVE,,}" == 'n' ]; then

# build the startup script
echo '#!/bin/sh' > ~/startup.sh
echo "PATH=$PWD/bin:$PWD/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin" >> ~/startup.sh
echo 'sudo DEBIAN_FRONTEND=noninteractive apt update -yq' >> ~/startup.sh
echo 'sudo DEBIAN_FRONTEND=noninteractive apt install ca-certificates -yq' >> ~/startup.sh
echo 'cd ~' >> ~/startup.sh
echo 'if [ -e first.run ]' >> ~/startup.sh
echo 'then' >> ~/startup.sh
echo '    screen -dmS init ~/firstrun.sh' >> ~/startup.sh
echo 'else' >> ~/startup.sh
echo '    screen -dmS agent ~/agent.sh' >> ~/startup.sh
echo 'fi' >> ~/startup.sh
echo 'sudo service watchdog restart' >> ~/startup.sh
chmod +x ~/startup.sh

fi

#**************************************************************************************************
# First-run Script (reboot the first time after starting if ~/first.run file exists)
#**************************************************************************************************
if [ "${WPT_INTERACTIVE,,}" == 'n' ]; then

# build the firstrun script
echo '#!/bin/sh' > ~/firstrun.sh
echo 'cd ~' >> ~/firstrun.sh
echo 'until sudo apt -y update' >> ~/firstrun.sh
echo 'do' >> ~/firstrun.sh
echo '    sleep 1' >> ~/firstrun.sh
echo 'done' >> ~/firstrun.sh
echo 'until sudo DEBIAN_FRONTEND=noninteractive apt install ca-certificates -yq' >> ~/firstrun.sh
echo 'do' >> ~/firstrun.sh
echo '    sleep 1' >> ~/firstrun.sh
echo 'done' >> ~/firstrun.sh
echo 'until sudo DEBIAN_FRONTEND=noninteractive apt -yq -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" dist-upgrade' >> ~/firstrun.sh
echo 'do' >> ~/firstrun.sh
echo '    sleep 1' >> ~/firstrun.sh
echo 'done' >> ~/firstrun.sh
echo 'rm ~/first.run' >> ~/firstrun.sh
echo 'sudo reboot' >> ~/firstrun.sh
chmod +x ~/firstrun.sh

fi

#**************************************************************************************************
# Agent Script
#**************************************************************************************************

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

if [ "${WPT_INTERACTIVE,,}" == 'y' ]; then

# Agent invocation (depending on config)
if [ "${AGENT_MODE,,}" == 'android' ]; then
    echo "python3 ~/wptagent/wptagent.py -vvvv $NAME_OPTION --location $WPT_LOCATION $KEY_OPTION --server \"https://$WPT_SERVER/work/\" --android" >> ~/agent.sh
fi
if [ "${AGENT_MODE,,}" == 'ios' ]; then
    echo "python3 ~/wptagent/wptagent.py -vvvv $NAME_OPTION --location $WPT_LOCATION $KEY_OPTION --server \"https://$WPT_SERVER/work/\" --iOS" >> ~/agent.sh
fi
if [ "${AGENT_MODE,,}" == 'desktop' ]; then
    echo "python3 ~/wptagent/wptagent.py -vvvv --server \"https://$WPT_SERVER/work/\" --location $WPT_LOCATION $KEY_OPTION" >> ~/agent.sh
fi

else

echo 'export DEBIAN_FRONTEND=noninteractive' >> ~/agent.sh
echo 'cd ~/wptagent' >> ~/agent.sh

# Wait for networking to become available and update the package list
echo 'sleep 10' >> ~/agent.sh

# Browser Certificates
if [ "${WPT_UPDATE_BROWSERS,,}" == 'y' ]; then
    if [ "${LINUX_DISTRO}" != 'Raspbian' ]; then
        echo 'echo "Updating browser certificates"' >> ~/agent.sh
        if [ "${WPT_CHROME,,}" == 'y' ]; then
            echo 'wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add -' >> ~/agent.sh
        fi

        if [ "${WPT_FIREFOX,,}" == 'y' ]; then
            echo 'sudo add-apt-repository -y ppa:ubuntu-mozilla-daily/ppa' >> ~/agent.sh
            echo 'sudo add-apt-repository -y ppa:mozillateam/ppa' >> ~/agent.sh
        fi

        if [ "${WPT_BRAVE,,}" == 'y' ]; then
            echo 'curl -s https://www.webpagetest.org/keys/brave/release.asc | sudo apt-key --keyring /etc/apt/trusted.gpg.d/brave-browser-release.gpg add -' >> ~/agent.sh
        fi

        if [ "${WPT_EDGE,,}" == 'y' ]; then
            echo 'curl -s https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key --keyring /etc/apt/trusted.gpg.d/microsoft.gpg add -' >> ~/agent.sh
        fi

        if [ "${WPT_OPERA,,}" == 'y' ]; then
            echo 'wget -qO- https://www.webpagetest.org/keys/opera/archive.key | sudo apt-key add -' >> ~/agent.sh
        fi
    fi

    if [ "${WPT_VIVALDI,,}" == 'y' ]; then
        echo 'wget -qO- https://www.webpagetest.org/keys/vivaldi/linux_signing_key.pub | sudo apt-key add -' >> ~/agent.sh
    fi
fi

# OS Update
if [ "${WPT_UPDATE_OS,,}" == 'y' ]; then
    echo 'until sudo apt -y update' >> ~/agent.sh
    echo 'do' >> ~/agent.sh
    echo '    sleep 1' >> ~/agent.sh
    echo 'done' >> ~/agent.sh
    echo 'echo "Updating OS"' >> ~/agent.sh
    echo 'until sudo DEBIAN_FRONTEND=noninteractive apt -yq -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" dist-upgrade' >> ~/agent.sh
    echo 'do' >> ~/agent.sh
    echo '    sudo apt -f install' >> ~/agent.sh
    echo '    sleep 1' >> ~/agent.sh
    echo 'done' >> ~/agent.sh
elif [ "${WPT_UPDATE_BROWSERS,,}" == 'y' ]; then
    echo 'until sudo apt -y update' >> ~/agent.sh
    echo 'do' >> ~/agent.sh
    echo '    sleep 1' >> ~/agent.sh
    echo 'done' >> ~/agent.sh
    if [ "${LINUX_DISTRO}" == 'Raspbian' ]; then
        echo 'until sudo DEBIAN_FRONTEND=noninteractive apt -yq --only-upgrade install chromium-browser firefox-esr' >> ~/agent.sh
    else
        echo 'until sudo DEBIAN_FRONTEND=noninteractive apt -yq --only-upgrade -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" install google-chrome-stable google-chrome-beta google-chrome-unstable firefox firefox-trunk firefox-esr firefox-geckodriver brave-browser opera-stable opera-beta opera-developer vivaldi-stable' >> ~/agent.sh
    fi
    echo 'do' >> ~/agent.sh
    echo '    sleep 1' >> ~/agent.sh
    echo 'done' >> ~/agent.sh
fi

# Lighthouse Update
if [ "${WPT_UPDATE_AGENT,,}" == 'y' ]; then
    echo 'sudo npm i -g lighthouse' >> ~/agent.sh
fi

if [ "${LINUX_DISTRO}" == 'Raspbian' ]; then
    echo 'sudo fstrim -v /' >> ~/agent.sh
fi
if [ "${AGENT_MODE,,}" == 'ios' ]; then
    echo 'sudo usbmuxd' >> ~/agent.sh
fi

# Dummy X display
if [ "${AGENT_MODE,,}" == 'desktop' ]; then
    echo 'export DISPLAY=:1' >> ~/agent.sh
    echo 'Xorg -noreset +extension GLX +extension RANDR +extension RENDER -logfile /dev/null -config ./misc/xorg.conf :1 &' >> ~/agent.sh
fi

echo 'for i in `seq 1 24`' >> ~/agent.sh
echo 'do' >> ~/agent.sh

if [ "${WPT_UPDATE_AGENT,,}" == 'y' ]; then
    echo "    git pull origin $WPT_BRANCH" >> ~/agent.sh
fi

# Agent invocation (depending on config)
if [ "${AGENT_MODE,,}" == 'android' ]; then
    echo "    python3 wptagent.py -vvvv $NAME_OPTION --location $WPT_LOCATION $KEY_OPTION --server \"https://$WPT_SERVER/work/\" --android --exit 60 --alive /tmp/wptagent" >> ~/agent.sh
    echo "#    python3 wptagent.py -vvvv $NAME_OPTION --location $WPT_LOCATION $KEY_OPTION --server \"https://$WPT_SERVER/work/\" --android --vpntether2 eth0,192.168.0.1 --shaper netem,eth0 --exit 60 --alive /tmp/wptagent" >> ~/agent.sh
fi
if [ "${AGENT_MODE,,}" == 'ios' ]; then
    echo "    python3 wptagent.py -vvvv $NAME_OPTION --location $WPT_LOCATION $KEY_OPTION --server \"https://$WPT_SERVER/work/\" --iOS --exit 60 --alive /tmp/wptagent" >> ~/agent.sh
fi
if [ "${AGENT_MODE,,}" == 'desktop' ]; then
    if [ "${WPT_CLOUD,,}" == 'gce' ]; then
        echo "    python3 wptagent.py -vvvv --gce --exit 60 --alive /tmp/wptagent" >> ~/agent.sh
    elif [ "${WPT_CLOUD,,}" == 'ec2' ]; then
        echo "    python3 wptagent.py -vvvv --ec2 --exit 60 --alive /tmp/wptagent" >> ~/agent.sh
    else
        echo "    python3 wptagent.py -vvvv --server \"https://$WPT_SERVER/work/\" --location $WPT_LOCATION $KEY_OPTION --exit 60 --alive /tmp/wptagent" >> ~/agent.sh
    fi
fi

echo '    echo "Exited, restarting"' >> ~/agent.sh
echo '    sleep 10' >> ~/agent.sh
echo 'done' >> ~/agent.sh
# OS Update (again, just before reboot)
if [ "${WPT_UPDATE_OS,,}" == 'y' ]; then
    echo 'until sudo apt -y update' >> ~/agent.sh
    echo 'do' >> ~/agent.sh
    echo '    sleep 1' >> ~/agent.sh
    echo 'done' >> ~/agent.sh
    echo 'echo "Updating OS"' >> ~/agent.sh
    echo 'until sudo DEBIAN_FRONTEND=noninteractive apt -yq -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" dist-upgrade' >> ~/agent.sh
    echo 'do' >> ~/agent.sh
    echo '    sudo apt -f install' >> ~/agent.sh
    echo '    sleep 1' >> ~/agent.sh
    echo 'done' >> ~/agent.sh
fi
echo 'sudo apt -y autoremove' >> ~/agent.sh
echo 'sudo apt clean' >> ~/agent.sh
if [ "${AGENT_MODE,,}" == 'android' ]; then
    echo 'adb reboot' >> ~/agent.sh
fi
if [ "${AGENT_MODE,,}" == 'ios' ]; then
    echo 'idevicediagnostics restart' >> ~/agent.sh
fi
echo 'sudo reboot' >> ~/agent.sh

#end of non-interactive block
fi

chmod +x ~/agent.sh

#**************************************************************************************************
# Finish
#**************************************************************************************************

if [ "${WPT_INTERACTIVE,,}" == 'n' ]; then

# Overwrite the existing user crontab
echo "@reboot ${PWD}/startup.sh" | crontab -

# Allow X to be started within the screen session
sudo sed -i 's/allowed_users=console/allowed_users=anybody/g' /etc/X11/Xwrapper.config || true
sudo systemctl set-default multi-user

fi

echo
echo "Install is complete.  Please reboot the system to start testing (sudo reboot)"
