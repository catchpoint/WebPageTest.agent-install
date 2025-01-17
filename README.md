# wptagent-install
Automated scripts for installing dedicated wptagent agents

For the debian.sh script, there are several environment variables that can control the options:

i.e.
```bash
WPT_SERVER="webpagetest.mycompany.com" WPT_LOCATION="Dulles" WPT_KEY="xxxSomeSecretKeyxxx" DISABLE_IPV6=y WPT_OPERA=y WPT_VIVALDI=y bash <(curl -s https://raw.githubusercontent.com/catchpoint/WebPageTest.agent-install/master/debian.sh)
```

Location config (these will prompt if not specified and not installing for cloud):
* **WPT_SERVER** - WebPageTest server. i.e. WPT_SERVER="webpagetest.mycompany.com"
* **WPT_LOCATION** - Location ID for the agent. i.e. WPT_LOCATION="Dulles"
* **WPT_KEY** - Key for the location

Agent:
* **WPT_CLOUD** - blank (default) for no cloud. "ec2" or "gce" to get config dynamically from user data in Google or Amazon cloud.
* **AGENT_MODE** - "desktop" (default), "ios" or "android".
* **WPT_UPDATE_AGENT** - "y" (default) or "n" : automatically update the agent from GitHub's release branch hourly and Lighthouse daily.
* **WPT_BRANCH** - "release" (default) : specify Github branch to sync

OS:
* **DISABLE_IPV6** - "y" or "n" (default) : disable IPv6 networking (recommended for systems without IPv6 connectivity).
* **WPT_UPDATE_OS** - "y" (default) or "n" : Automatically apt dist-upgrade all packages daily after reboot.
* **WPT_UPDATE_OS_NOW** - "y" (default) or "n" : apt dist-upgrade all packages as part of the initial agent setup.

Browsers:
* **WPT_UPDATE_BROWSERS** - "y" (default) or "n" : Re-install the certificates for browser installers daily so they stay up to date and automatically update the browsers daily.
* **WPT_CHROME** - "y" (default) or "n" : Install Google Chrome (stable, beta and dev channels)
* **WPT_FIREFOX** - "y" (default) or "n" : Install Mozilla Firefox (Stable, ESR and Nightly)
* **WPT_EDGE** - "y" (default) or "n" : Install Microsoft Edge (Dev)
* **WPT_BRAVE** - "y" (default) or "n" : Install The Brave Browser (stable, beta and dev channels)
* **WPT_EPIPHANY** - "y" (default) or "n" : Install Epiphany for WebKit testing (Requires Ubunto 20.04+)
* **WPT_OPERA** - "y" or "n" (default) : Install Opera (stable, beta and dev channels)
* **WPT_VIVALDI** - "y" or "n" (default) : Install Vivaldi

Misc:
* **WPT_INTERACTIVE** = "y" or "n" (default) : Install in a shared OS environment. "y" will expect to take over the whole machine, configure watchdog, cron, etc. "n" can be used for development installs (and will default to the master branch).

For convenience, the github url is also available shortened as http://tiny.cc/wptagent
```bash
WPT_SERVER="webpagetest.mycompany.com" WPT_LOCATION="Dulles" WPT_KEY="xxxSomeSecretKeyxxx" DISABLE_IPV6=y WPT_OPERA=y WPT_VIVALDI=y bash <(curl -sL http://tiny.cc/wptagent)
```

## Ubuntu 18.04+:
Tested on 18.04 LTS, 20.04 LTS, and 22.04 LTS

```bash
bash <(curl -s https://raw.githubusercontent.com/catchpoint/WebPageTest.agent-install/master/debian.sh)
```

### on Google Cloud:

```bash
WPT_CLOUD=gce bash <(curl -s https://raw.githubusercontent.com/catchpoint/WebPageTest.agent-install/master/debian.sh)
```

### on Amazon EC2:

```bash
WPT_CLOUD=ec2 bash <(curl -s https://raw.githubusercontent.com/catchpoint/WebPageTest.agent-install/master/debian.sh)
```

## Raspberry Pi (Raspbian Stretch+):
Requires editing ~/agent.sh after install to configure tethering and traffic shaping.

Desktop testing works best with Raspbian Buster or later.

Warning: This takes a LONG time (several hours).  For multiple devices it is generally best to get one configured and then just clone the SD card for other devices.

```bash
bash <(curl -s https://raw.githubusercontent.com/catchpoint/WebPageTest.agent-install/master/debian.sh)
```

## MacOS
Tested on MacOS 11 (x86 and ARM)

* Configure MacOS to log in automatically (System Preferences->Users and Groups->Login Options)
* Turn off the screen saver and configure power management to never put the display to sleep
* Install Xcode manually from the app store. Launch it and accept the license.
  * If running on an M1 device, install rosetta when prompted (after accepting the license)
* Run the agent install script from a Terminal shell:
```bash
bash <(curl -s https://raw.githubusercontent.com/catchpoint/WebPageTest.agent-install/refs/heads/master/macos.sh)
```
* The install script should install all of the browsers and prompt for the necessary system permissions.
* Configure the agent and watchdog to start automatically at startup.
  * System Preferences->Users and Groups->Login Items
  * Add ~/wptagent-install/macos/Agent and Watchdog
* Reboot

## Dev Setup on Ubuntu Desktop (22.04 LTS recommended)
Will not configure X, watchdog, cron or a startup script.  There will be a master branch checkout in ~/wptagent/ and a script to run the agent at ~/agent.sh

```bash
WPT_INTERACTIVE="y" bash <(curl -sL http://tiny.cc/wptagent)
```
