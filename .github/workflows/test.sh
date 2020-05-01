#!/usr/bin/env bash

set -eu

# Check if packages are installed
dpkg --status git > /dev/null
dpkg --status screen > /dev/null
dpkg --status watchdog > /dev/null
dpkg --status curl > /dev/null
dpkg --status wget > /dev/null
dpkg --status apt-transport-https > /dev/null
dpkg --status xserver-xorg-video-dummy > /dev/null

test -f "${HOME}/startup.sh"
test -f "${HOME}/agent.sh"

test "$(cat /etc/systemd/journald.conf | grep "SystemMaxUse=1M")" == "SystemMaxUse=1M"
test "$(cat /etc/watchdog.conf | grep "test-binary = $HOME/wptagent/alive.sh")" == "test-binary = $HOME/wptagent/alive.sh"

sudo sysctl --load

test "$(sysctl vm.panic_on_oom)" == "vm.panic_on_oom = 1"
test "$(sysctl kernel.panic)" == "kernel.panic = 10"
