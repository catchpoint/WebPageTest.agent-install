# Reboot the system if the agent goes unresponsive for an hour
import os
import psutil
import subprocess
import time

def uptime():
    return int(time.time() - psutil.boot_time())

def time_since_agent_alive():
    elapsed = 999999
    try:
        modified = os.path.getmtime('/tmp/wptagent')
        elapsed = time.time() - modified
    except Exception:
        pass
    return int(elapsed)

reboot_attempted = False
while True:
    time_since_boot = uptime()
    if time_since_boot > 3600:
        alive = time_since_agent_alive()
        if alive > 3600:
            print("Agent not OK, last reported as alive {} seconds ago. Rebooting".format(alive))
            if reboot_attempted:
                # Force a reboot, it is not going gracefully
                subprocess.call(['sudo', 'reboot', '-q'])
            else:
                reboot_attempted = True
                subprocess.call(['sudo', 'reboot'])
        else:
            reboot_attempted = False
            print("Agent OK, last reported as alive {} seconds ago.".format(alive))
    else:
        reboot_attempted = False
        print("System started less than an hour ago ({} seconds). Waiting...".format(time_since_boot))

    # Check every 10 minutes
    time.sleep(600)