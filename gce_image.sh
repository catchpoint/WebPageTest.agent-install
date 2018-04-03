#!/bin/bash

# Prompt for the configuration options
echo "WebPageTest instance template creator."

read -e -p "Instance template name: " -i "wpt-agent" TEMPLATE_NAME
while [[ $INSTANCE_METADATA == '' ]]
do
    read -p "Instance Metadata String (wpt_server=...): " INSTANCE_METADATA
done
ESCAPED_METADATA=$(printf %q "$INSTANCE_METADATA")
PROJECT_ID=$(curl "http://metadata.google.internal/computeMetadata/v1/project/project-id" -H "Metadata-Flavor: Google")
PROJECT_NUMBER=$(curl "http://metadata.google.internal/computeMetadata/v1/project/numeric-project-id" -H "Metadata-Flavor: Google")

gcloud compute --project=${PROJECT_ID} instance-templates create ${TEMPLATE_NAME} \
    --machine-type=n1-standard-2 --network=projects/${PROJECT_ID}/global/networks/default \
    --metadata=${ESCAPED_METADATA} \
    --no-restart-on-failure --maintenance-policy=TERMINATE --preemptible --service-account=${PROJECT_NUMBER}-compute@developer.gserviceaccount.com \
    --scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/trace.append \
    --min-cpu-platform=Automatic --image=wpt-linux-20180313 --image-project=webpagetest-official --boot-disk-size=10GB \
    --boot-disk-type=pd-standard --boot-disk-device-name=${TEMPLATE_NAME}

echo "Done."
