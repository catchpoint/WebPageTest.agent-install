#!/usr/bin/env bash

# Tests only for ubuntu.sh.
# This test script should not applied to ec2_ubuntu.sh & gce_ubuntu.sh.

set -eux

test "$(cat /etc/systemd/journald.conf.d/wptagent.conf)" == "SystemMaxUse=1M"
