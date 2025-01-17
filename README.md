# wptagent-install

Automated scripts for installing [dedicated `wptagent` agents](https://github.com/WPO-Foundation/wptagent).


## Configuration

For [the `debian.sh` script](./debian.sh), environment variables control the options. For example:

```bash
WPT_SERVER="webpagetest.mycompany.com" \
WPT_LOCATION="Dulles" \
WPT_KEY="xxxSomeSecretKeyxxx" \
DISABLE_IPV6=y \
WPT_OPERA=y \
WPT_VIVALDI=y \
bash <(curl -s https://raw.githubusercontent.com/catchpoint/wptagent-install/master/debian.sh)
```

### Location config

These will prompt if not specified _and_ not installing for cloud.

* `WPT_SERVER` - WebPageTest server. i.e. `WPT_SERVER="webpagetest.mycompany.com"`
* `WPT_LOCATION` - Location ID for the agent. i.e. `WPT_LOCATION="Dulles"`.
* `WPT_KEY` - [API Key](https://docs.webpagetest.org/api/keys/) for the location.

### Agent config

* `WPT_CLOUD` - blank (default) for no cloud, `ec2` or `gce` : get config dynamically from user data in Google or Amazon cloud.
* `AGENT_MODE` - `desktop` (default), `ios` or `android`.
* `WPT_UPDATE_AGENT` - `y` (default) or `n` : Automatically update the agent from GitHub’s release branch hourly and Lighthouse daily.
* `WPT_BRANCH` - `release` (default) : Specify GitHub branch to sync.

### OS config

* `DISABLE_IPV6` - `y` or `n` (default) : Disable IPv6 networking (recommended for systems without IPv6 connectivity).
* `WPT_UPDATE_OS` - `y` (default) or `n` : Automatically `apt dist-upgrade` all packages daily after reboot.
* `WPT_UPDATE_OS_NOW` - `y` (default) or `n` : `apt dist-upgrade` all packages as part of the initial agent setup.

### Browser(s) config

* `WPT_UPDATE_BROWSERS` - `y` (default) or `n` : Reinstall certificates for browser installers daily, so they can auto-update the browsers daily.
* `WPT_CHROME` - `y` (default) or `n` : Install Google Chrome (Stable, Beta, and Dev channels).
* `WPT_FIREFOX` - `y` (default) or `n` : Install Mozilla Firefox (Stable, ESR, and Nightly).
* `WPT_EDGE` - `y` (default) or `n` : Install Microsoft Edge (Dev).
* `WPT_BRAVE` - `y` (default) or `n` : Install The Brave Browser (Stable, Beta, and Dev channels).
* `WPT_EPIPHANY` - `y` (default) or `n` : Install Epiphany for WebKit testing (requires Ubuntu 20.04+).
* `WPT_OPERA` - `y` or `n` (default) : Install Opera (Stable, Beta, and Dev channels).
* `WPT_VIVALDI` - `y` or `n` (default) : Install Vivaldi.


### Miscellaneous config

* `WPT_INTERACTIVE` - `y` or `n` (default) : Install in a shared OS environment. `y` will expect to take over the whole machine, configure watchdog, cron, etc. `n` can be used for development installs and will default to the `master` branch.

## Installation/Usage

```bash
WPT_SERVER="webpagetest.mycompany.com" \
WPT_LOCATION="Dulles" \
WPT_KEY="xxxSomeSecretKeyxxx" \
DISABLE_IPV6=y \
WPT_OPERA=y \
WPT_VIVALDI=y \
bash <(curl -sL https://raw.githubusercontent.com/catchpoint/wptagent-install/master/debian.sh)
```

### Ubuntu 22.04+
 
Tested on 20.04 LTS.

```bash
bash <(curl -s https://raw.githubusercontent.com/catchpoint/WebPageTest.agent-install/master/debian.sh)
```

### Google Cloud
 
```sh
WPT_CLOUD=gce bash <(curl -s https://raw.githubusercontent.com/catchpoint/wptagent-install/master/debian.sh)
```

### Amazon EC2
 
```sh
WPT_CLOUD=ec2 bash <(curl -s https://raw.githubusercontent.com/catchpoint/wptagent-install/master/debian.sh)
```

### Raspberry Pi (Raspbian Stretch+)
 
Requires editing `~/agent.sh` after install to configure tethering and traffic shaping. Desktop testing works best with Raspbian Buster or later.

**⚠️ Warning:** This takes a ***long*** time (several hours). For multiple devices, it’s generally best to configure one then clone its SD card for other devices.

```sh
bash <(curl -s https://raw.githubusercontent.com/catchpoint/wptagent-install/master/debian.sh)
```

### MacOS
 
Tested on MacOS 11 (x86 and ARM).

1. Configure MacOS to log in automatically. (System Preferences→Users→Groups→Login Options)
2. Turn off the screen saver, and configure power management to never put the display to sleep.
3. Install Xcode manually from the app store. Launch it and accept the license.
   * If running on an M1 device, install rosetta when prompted (after accepting the license).
4. Run the agent install script from Terminal:
  ```sh
  bash <(curl -s https://raw.githubusercontent.com/catchpoint/wptagent-install/master/macos.sh)
  ```
5. The install script should install all browsers and prompt for the necessary system permissions.
6. Configure the agent and watchdog to start automatically at startup:
   1. Navigate to System Preferences→Users→Groups→Login Items
   2. Add `~/wptagent-install/macos/Agent` and Watchdog
7. Reboot.

### Dev Setup on Ubuntu Desktop (22.04 LTS recommended)
 
Will not configure X, watchdog, cron, or a startup script. There will be a `master` branch checkout in `~/wptagent/` and a script to run the agent at `~/agent.sh`.

```sh
WPT_INTERACTIVE=y bash <(curl -sL https://raw.githubusercontent.com/catchpoint/wptagent-install/master/debian.sh)
```
