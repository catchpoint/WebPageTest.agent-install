#!/bin/bash

set -eu

: ${UBUNTU_VERSION:=`(lsb_release -rs | cut -b 1,2)`}

# Prompt for the configuration options
echo "Automatic agent install and configuration."

# Make sure sudo doesn't prompt for a password
sudo date
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

# Reboot when out of memory
cat << _SYSCTL_ | sudo tee /etc/sysctl.d/60-wptagent-dedicated.conf
vm.panic_on_oom = 1
kernel.panic = 10
_SYSCTL_

# disable IPv6
cat << _SYSCTL_NO_IPV6_ | sudo tee /etc/sysctl.d/60-wptagent-no-ipv6.conf
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
_SYSCTL_NO_IPV6_

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
echo 'cd ~' >> ~/startup.sh
echo 'if [ -e first.run ]' >> ~/startup.sh
echo 'then' >> ~/startup.sh
echo '    screen -dmS init ~/firstrun.sh' >> ~/startup.sh
echo 'else' >> ~/startup.sh
echo '    screen -dmS agent ~/agent.sh' >> ~/startup.sh
echo 'fi' >> ~/startup.sh
echo 'sudo service watchdog restart' >> ~/startup.sh
chmod +x ~/startup.sh

# build the firstrun script
echo '#!/bin/sh' > ~/firstrun.sh
echo 'cd ~' >> ~/firstrun.sh
echo 'until sudo apt -y update' >> ~/firstrun.sh
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

# build the agent script
echo '#!/bin/sh' > ~/agent.sh
echo 'export DEBIAN_FRONTEND=noninteractive' >> ~/agent.sh
echo 'cd ~/wptagent' >> ~/agent.sh
echo 'echo "Updating OS"' >> ~/agent.sh
echo 'wget -q -O - https://www.webpagetest.org/keys/google/linux_signing_key.pub | sudo apt-key add -' >> ~/agent.sh
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
    echo "    python wptagent.py -vvvv --gce --throttle --exit 60 --alive /tmp/wptagent" >> ~/agent.sh
else
    echo "    python3 wptagent.py -vvvv --gce --throttle --exit 60 --alive /tmp/wptagent" >> ~/agent.sh
fi
echo '    echo "Exited, restarting"' >> ~/agent.sh
echo '    sleep 1' >> ~/agent.sh
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
