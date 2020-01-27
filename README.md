# wptagent-install
Automated scripts for installing dedicated wptagent agents

## Ubuntu 18.04+:
Tested on 18.04 LTS

```bash
bash <(curl -s https://raw.githubusercontent.com/WPO-Foundation/wptagent-install/master/ubuntu.sh)
```

### on Google Cloud:

```bash
bash <(curl -s https://raw.githubusercontent.com/WPO-Foundation/wptagent-install/master/gce_ubuntu.sh)
```

### on Amazon EC2:

```bash
bash <(curl -s https://raw.githubusercontent.com/WPO-Foundation/wptagent-install/master/ec2_ubuntu.sh)
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
bash <(curl -s https://raw.githubusercontent.com/WPO-Foundation/wptagent-install/master/raspbian.sh)
```
