#!/bin/bash

set -eu

# Assign empty string if not defined
: ${DISABLE_IPV6:=''}
: ${WPT_SERVER:=''}
: ${WPT_LOCATION:=''}
: ${WPT_KEY:=''}
: ${UBUNTU_VERSION:=`(lsb_release -rs | cut -b 1,2)`}

# Prompt for the configuration options
echo "Automatic agent install and configuration."
echo

while [[ $DISABLE_IPV6 == '' ]]
do
  read -e -p "Disable IPv6 (recommended unless IPv6 connectivity is available) (Y/n): " -i "y" DISABLE_IPV6
done

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


# Pre-prompt for the sudo authorization so it doesn't prompt later
sudo date

# Make sure sudo doesn't prompt for a password
echo "${USER} ALL=(ALL:ALL) NOPASSWD:ALL" | sudo tee "/etc/sudoers.d/wptagent"

cd ~
until sudo apt -y update
do
    sleep 1
done
until sudo DEBIAN_FRONTEND=noninteractive apt -yq -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" dist-upgrade
do
    sleep 1
done
sudo apt -y install git screen watchdog curl wget apt-transport-https xserver-xorg-video-dummy
until git clone --branch=release https://github.com/WPO-Foundation/wptagent.git
do
    sleep 1
done

wptagent/ubuntu_install.sh
sudo apt -y autoremove

# Minimize the space for systemd journals
sudo mkdir --mode=755 /etc/systemd/journald.conf.d
echo 'SystemMaxUse=1M' | sudo tee /etc/systemd/journald.conf.d/wptagent.conf
sudo systemctl restart systemd-journald

# Reboot when out of memory
cat << _SYSCTL_ | sudo tee /etc/sysctl.d/60-wptagent-dedicated.conf
vm.panic_on_oom = 1
kernel.panic = 10
_SYSCTL_

# disable IPv6 if requested
if [ "${DISABLE_IPV6,,}" == 'y' ]; then
    cat << _SYSCTL_NO_IPV6_ | sudo tee /etc/sysctl.d/60-wptagent-no-ipv6.conf
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
_SYSCTL_NO_IPV6_
fi

# configure watchdog
cd ~
if [ "$UBUNTU_VERSION" \< "20" ]; then
  echo "test-binary = $PWD/wptagent/alive.sh" | sudo tee -a /etc/watchdog.conf
else
  echo "test-binary = $PWD/wptagent/alive3.sh" | sudo tee -a /etc/watchdog.conf
fi

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
echo '#!/bin/sh' > ~/agent.sh
echo 'export DEBIAN_FRONTEND=noninteractive' >> ~/agent.sh
echo 'cd ~/wptagent' >> ~/agent.sh
echo 'echo "Updating OS"' >> ~/agent.sh
echo 'wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -' >> ~/agent.sh
echo 'curl -s https://brave-browser-apt-release.s3.brave.com/brave-core.asc | sudo apt-key --keyring /etc/apt/trusted.gpg.d/brave-browser-release.gpg add -' >> ~/agent.sh
echo 'curl -s https://brave-browser-apt-beta.s3.brave.com/brave-core-nightly.asc | sudo apt-key --keyring /etc/apt/trusted.gpg.d/brave-browser-prerelease.gpg add -' >> ~/agent.sh
echo 'curl -s https://brave-browser-apt-dev.s3.brave.com/brave-core-nightly.asc | sudo apt-key --keyring /etc/apt/trusted.gpg.d/brave-browser-prerelease.gpg add -' >> ~/agent.sh
echo 'curl -s https://brave-browser-apt-nightly.s3.brave.com/brave-core-nightly.asc | sudo apt-key --keyring /etc/apt/trusted.gpg.d/brave-browser-prerelease.gpg add -' >> ~/agent.sh
echo 'wget -qO- https://deb.opera.com/archive.key | sudo apt-key add -' >> ~/agent.sh
echo 'sudo add-apt-repository -y ppa:ubuntu-mozilla-daily/ppa' >> ~/agent.sh
echo 'sudo add-apt-repository -y ppa:mozillateam/ppa' >> ~/agent.sh
echo 'until sudo apt -y update' >> ~/agent.sh
echo 'do' >> ~/agent.sh
echo '    sleep 1' >> ~/agent.sh
echo 'done' >> ~/agent.sh
echo 'until sudo DEBIAN_FRONTEND=noninteractive apt -yq -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" dist-upgrade' >> ~/agent.sh
echo 'do' >> ~/agent.sh
echo '    sudo apt -f install' >> ~/agent.sh
echo '    sleep 1' >> ~/agent.sh
echo 'done' >> ~/agent.sh
echo 'sudo npm i -g lighthouse' >> ~/agent.sh
echo 'export DISPLAY=:1' >> ~/agent.sh
echo 'Xorg -noreset +extension GLX +extension RANDR +extension RENDER -logfile /dev/null -config ./misc/xorg.conf :1 &' >> ~/agent.sh
echo 'for i in `seq 1 24`' >> ~/agent.sh
echo 'do' >> ~/agent.sh
echo '    git pull origin release' >> ~/agent.sh
if [ "$UBUNTU_VERSION" \< "20" ]; then
  echo "    python wptagent.py -vvvv --server \"http://$WPT_SERVER/work/\" --location $WPT_LOCATION $KEY_OPTION --throttle --exit 60 --alive /tmp/wptagent" >> ~/agent.sh
else
  echo "    python3 wptagent.py -vvvv --server \"http://$WPT_SERVER/work/\" --location $WPT_LOCATION $KEY_OPTION --throttle --exit 60 --alive /tmp/wptagent" >> ~/agent.sh
fi
echo '    echo "Exited, restarting"' >> ~/agent.sh
echo '    sleep 10' >> ~/agent.sh
echo 'done' >> ~/agent.sh
echo 'sudo apt -y autoremove' >> ~/agent.sh
echo 'sudo apt clean' >> ~/agent.sh
echo 'sudo reboot' >> ~/agent.sh
chmod +x ~/agent.sh

# add it to the crontab
CRON_ENTRY="@reboot ${PWD}/startup.sh"
( crontab -l | grep -v -F "$CRON_ENTRY" ; echo "$CRON_ENTRY" ) | crontab -

echo
echo "Install is complete.  Please reboot the system to start testing (sudo reboot)"
