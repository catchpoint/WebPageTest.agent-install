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

# Pre-prompt for the sudo authorization so it doesn't prompt later
sudo date

# Make sure sudo doesn't prompt for a password
echo "$USER ALL=(ALL:ALL) NOPASSWD:ALL" | sudo EDITOR='tee -a' visudo

cd ~
until sudo timeout 20m apt-get update
do
    sleep 1
done
until sudo DEBIAN_FRONTEND=noninteractive apt-get -yq -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" dist-upgrade
do
    sleep 1
done
sudo apt-get install -y git screen watchdog
git clone https://github.com/WPO-Foundation/wptagent.git
wptagent/ubuntu_install.sh
sudo apt-get -y autoremove

# disable IPv6 if requested
if [ "${DISABLE_IPV6,,}" == 'y' ]; then
  echo "net.ipv6.conf.all.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.conf
  echo "net.ipv6.conf.default.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.conf
  echo "net.ipv6.conf.lo.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.conf
fi

# configure watchdog
cd ~
echo "test-binary = $PWD/wptagent/alive.sh" | sudo tee -a /etc/watchdog.conf

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
echo 'echo "Waiting for 30 second startup delay"' >> ~/agent.sh
echo 'sleep 30' >> ~/agent.sh
echo 'echo "Waiting for apt to become available"' >> ~/agent.sh
echo 'while fuser /var/lib/dpkg/lock >/dev/null 2>&1 ; do' >> ~/agent.sh
echo '    sleep 1' >> ~/agent.sh
echo 'done' >> ~/agent.sh
echo 'while :' >> ~/agent.sh
echo 'do' >> ~/agent.sh
echo '    echo "Updating OS"' >> ~/agent.sh
echo '    until sudo timeout 20m apt-get update' >> ~/agent.sh
echo '    do' >> ~/agent.sh
echo '        sleep 1' >> ~/agent.sh
echo '    done' >> ~/agent.sh
echo '    until sudo DEBIAN_FRONTEND=noninteractive apt-get -yq -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" dist-upgrade' >> ~/agent.sh
echo '    do' >> ~/agent.sh
echo '        sleep 1' >> ~/agent.sh
echo '    done' >> ~/agent.sh
echo '    sudo apt-get -y autoremove' >> ~/agent.sh
echo '    sudo npm i -g lighthouse' >> ~/agent.sh
echo '    for i in `seq 1 24`' >> ~/agent.sh
echo '    do' >> ~/agent.sh
echo '        timeout 10m git pull origin master' >> ~/agent.sh
echo "        python wptagent.py -vvvv --server \"http://$WPT_SERVER/work/\" --location $WPT_LOCATION $KEY_OPTION --xvfb --throttle --exit 60 --alive /tmp/wptagent" >> ~/agent.sh
echo '        echo "Exited, restarting"' >> ~/agent.sh
echo '        sleep 1' >> ~/agent.sh
echo '    done' >> ~/agent.sh
echo 'done' >> ~/agent.sh
chmod +x ~/agent.sh

# add it to the crontab
CRON_ENTRY="@reboot $PWD/startup.sh"
( crontab -l | grep -v -F "$CRON_ENTRY" ; echo "$CRON_ENTRY" ) | crontab -

echo
echo "Install is complete.  Please reboot the system to start testing (sudo reboot)"