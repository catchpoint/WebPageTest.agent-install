#!/usr/bin/env bash

set -eux

# Check if packages are installed
dpkg --status git > /dev/null
dpkg --status screen > /dev/null
dpkg --status watchdog > /dev/null
dpkg --status curl > /dev/null
dpkg --status wget > /dev/null
dpkg --status apt-transport-https > /dev/null
dpkg --status xserver-xorg-video-dummy > /dev/null

cd "${HOME}/wptagent"
# Test if current branch is `release`
test "$(git branch | grep "*")" == "* release"

test -f "${HOME}/wptagent/wptagent.py"

test -f "${HOME}/startup.sh"
test -f "${HOME}/agent.sh"

test "$(sudo cat /etc/sudoers.d/wptagent)" == "${USER} ALL=(ALL:ALL) NOPASSWD:ALL"
test "$(cat /etc/watchdog.conf | grep "test-binary = $HOME/wptagent/alive.sh")" == "test-binary = $HOME/wptagent/alive.sh"

sudo sysctl --system

test "$(sysctl vm.panic_on_oom)" == "vm.panic_on_oom = 1"
test "$(sysctl kernel.panic)" == "kernel.panic = 10"

test "$(sysctl net.ipv6.conf.all.disable_ipv6)" == "net.ipv6.conf.all.disable_ipv6 = 1"
test "$(sysctl net.ipv6.conf.default.disable_ipv6)" == "net.ipv6.conf.default.disable_ipv6 = 1"
test "$(sysctl net.ipv6.conf.lo.disable_ipv6)" == "net.ipv6.conf.lo.disable_ipv6 = 1"
