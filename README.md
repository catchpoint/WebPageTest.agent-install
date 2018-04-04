# wptagent-install
Automated scripts for installing dedicated wptagent agents

## Ubuntu 16.04:

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
