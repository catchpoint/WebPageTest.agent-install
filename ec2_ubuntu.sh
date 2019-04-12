#!/bin/bash

# Prompt for the configuration options
echo "Automatic agent install and configuration."

# Make sure sudo doesn't prompt for a password
sudo date
echo "$USER ALL=(ALL:ALL) NOPASSWD:ALL" | sudo EDITOR='tee -a' visudo

cd ~
until sudo apt -y --allow-unauthenticated update
do
    sleep 1
done
until sudo DEBIAN_FRONTEND=noninteractive apt -yq --allow-unauthenticated -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" dist-upgrade
do
    sleep 1
done
sudo apt -y --allow-unauthenticated install git screen watchdog
until git clone https://github.com/WPO-Foundation/wptagent.git
do
    sleep 1
done
git checkout origin/release
wptagent/ubuntu_install.sh
sudo apt -y autoremove

# Reboot when out of memory
echo "vm.panic_on_oom=1" | sudo tee -a /etc/sysctl.conf
echo "kernel.panic=10" | sudo tee -a /etc/sysctl.conf

# disable IPv6
echo "net.ipv6.conf.all.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.conf
echo "net.ipv6.conf.lo.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.conf

# configure watchdog
cd ~
echo "test-binary = $PWD/wptagent/alive.sh" | sudo tee -a /etc/watchdog.conf

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
echo 'until sudo apt -y --allow-unauthenticated update' >> ~/firstrun.sh
echo 'do' >> ~/firstrun.sh
echo '    sleep 1' >> ~/firstrun.sh
echo 'done' >> ~/firstrun.sh
echo 'sudo rm /boot/grub/menu.lst' >> ~/firstrun.sh
echo 'sudo update-grub-legacy-ec2 -y' >> ~/firstrun.sh
echo 'until sudo DEBIAN_FRONTEND=noninteractive apt -yq --allow-unauthenticated -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" dist-upgrade' >> ~/firstrun.sh
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
echo 'until sudo apt -y --allow-unauthenticated update' >> ~/agent.sh
echo 'do' >> ~/agent.sh
echo '    sleep 1' >> ~/agent.sh
echo 'done' >> ~/agent.sh
echo 'sudo rm /boot/grub/menu.lst' >> ~/agent.sh
echo 'sudo update-grub-legacy-ec2 -y' >> ~/agent.sh
echo 'until sudo DEBIAN_FRONTEND=noninteractive apt -yq --allow-unauthenticated -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" dist-upgrade' >> ~/agent.sh
echo 'do' >> ~/agent.sh
echo '    sudo apt -f install' >> ~/agent.sh
echo '    sleep 1' >> ~/agent.sh
echo 'done' >> ~/agent.sh
echo 'sudo npm i -g lighthouse' >> ~/agent.sh
echo 'for i in `seq 1 24`' >> ~/agent.sh
echo 'do' >> ~/agent.sh
echo '    git pull origin release' >> ~/agent.sh
echo "    python wptagent.py -vvvv --ec2 --xvfb --throttle --exit 60 --alive /tmp/wptagent" >> ~/agent.sh
echo '    echo "Exited, restarting"' >> ~/agent.sh
echo '    sleep 1' >> ~/agent.sh
echo 'done' >> ~/agent.sh
echo 'sudo apt -y autoremove' >> ~/agent.sh
echo 'sudo apt clean' >> ~/agent.sh
echo 'sudo reboot' >> ~/agent.sh
chmod +x ~/agent.sh

# add it to the crontab
CRON_ENTRY="@reboot $PWD/startup.sh"
( crontab -l | grep -v -F "$CRON_ENTRY" ; echo "$CRON_ENTRY" ) | crontab -

echo
echo "Install is complete.  Rebooting..."
sudo reboot
