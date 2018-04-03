# wptagent-install
Automated scripts for installing dedicated wptagent agents

## Ubuntu 16.04:

```bash
wget https://raw.githubusercontent.com/WPO-Foundation/wptagent-install/master/ubuntu.sh && \
chmod +x ubuntu.sh && \
./ubuntu.sh
```

### on Google Cloud:

```bash
wget https://raw.githubusercontent.com/WPO-Foundation/wptagent-install/master/gce_ubuntu.sh && \
chmod +x gce_ubuntu.sh && \
./gce_ubuntu.sh
```

### on Amazon EC2:

```bash
wget https://raw.githubusercontent.com/WPO-Foundation/wptagent-install/master/ec2_ubuntu.sh && \
chmod +x ec2_ubuntu.sh && \
./ec2_ubuntu.sh
```

## Google Cloud Shared Image
Open the cloud shell for the project where the agents will run and paste:

```bash
wget https://raw.githubusercontent.com/WPO-Foundation/wptagent-install/master/gce_image.sh && \
chmod +x gce_image.sh && \
./gce_image.sh
```

This will create an instance template in the project that can be used to create Managed Instance Groups or individual instances in any region.