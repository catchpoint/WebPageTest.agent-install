# wptagent-install
Automated scripts for installing dedicated wptagent agents

For the debian.sh script, there are several environment variables that can control the options:

i.e.
```bash
WPT_SERVER="webpagetest.mycompany.com" WPT_LOCATION="Dulles" WPT_KEY="xxxSomeSecretKeyxxx" DISABLE_IPV6=y WPT_OPERA=y WPT_VIVALDI=y bash <(curl -s https://raw.githubusercontent.com/WPO-Foundation/wptagent-install/master/debian.sh)
```

Location config (these will prompt if not specified and not installing for cloud):
* **WPT_SERVER** - WebPageTest server. i.e. WPT_SERVER="webpagetest.mycompany.com"
* **WPT_LOCATION** - Location ID for the agent. i.e. WPT_LOCATION="Dulles"
* **WPT_KEY** - Key for the location

Agent:
* **WPT_CLOUD** - blank (default) for no cloud. "ec2" or "gce" to get config dynamically from user data in Google or Amazon cloud.
* **AGENT_MODE** - "desktop" (default), "ios" or "android".
* **WPT_UPDATE_AGENT** - "y" (default) or "n" : automatically update the agent from GitHub's release branch hourly and Lighthouse daily.

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

For convenience, the github url is also available shortened as http://tiny.cc/wptagent
```bash
WPT_SERVER="webpagetest.mycompany.com" WPT_LOCATION="Dulles" WPT_KEY="xxxSomeSecretKeyxxx" DISABLE_IPV6=y WPT_OPERA=y WPT_VIVALDI=y bash <(curl -sL http://tiny.cc/wptagent)
```

## Ubuntu 18.04+:
Tested on 18.04 LTS and 20.04 LTS

```bash
bash <(curl -s https://raw.githubusercontent.com/WPO-Foundation/wptagent-install/master/debian.sh)
```

### on Google Cloud:

```bash
WPT_CLOUD=gce bash <(curl -s https://raw.githubusercontent.com/WPO-Foundation/wptagent-install/master/debian.sh)
```

### on Amazon EC2:

```bash
WPT_CLOUD=ec2 bash <(curl -s https://raw.githubusercontent.com/WPO-Foundation/wptagent-install/master/debian.sh)
```

## Google Cloud Shared Image
This will create an instance template in the project that can be used to create Managed Instance Groups or individual instances in any region. The instances will be preemptable n1-standard-2.
Open the cloud shell for the project where the agents will run and paste:

```bash
bash <(curl -s https://raw.githubusercontent.com/WPO-Foundation/wptagent-install/master/gce_image.sh)
```

## Raspberry Pi (Raspbian Stretch+):
Still a work in progress and requires editing ~/agent.sh after install to configure tethering and traffic shaping.

Desktop testing works best with Raspbian Buster or later.

Warning: This takes a LONG time (several hours).  For multiple devices it is generally best to get one configured and then just clone the SD card for other devices.

```bash
bash <(curl -s https://raw.githubusercontent.com/WPO-Foundation/wptagent-install/master/debian.sh)
```

## MacOS (in-progress)
Tested on MacOS 11 (x86 and ARM)

* Install Xcode manually from the app store
* Install Network Link Conditioner ([additional download](https://swiftmania.io/network-link-conditioner/#simulator))
* Install the browsers to be used for testing
* Then install agent:
```bash
bash <(curl -s https://raw.githubusercontent.com/WPO-Foundation/wptagent-install/master/macos.sh)
```
* Grant the agent utilities the necessary permissions in the system privacy settings:
  * "Screen Recording" - Add the terminal app that is used to run the agent (i.e. iTerm or Terminal)
  * "Accessibility" - Add both scripts in <wptagent>/internal/support/osx