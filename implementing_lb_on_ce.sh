#! /bin/bash

# Export the value
# You might change this value
# according to your data
export REGION=us-west3
export ZONE=us-west3-a
export INSTANCE=nucleus-jumphost-281
export FIREWALL=grant-tcp-rule-175

# 1. Create VM or instance
gcloud compute instances create $INSTANCE --zone=$ZONE --machine-type=e2-micro

# 2. Set up an HTTP Load Balancer
# Use this code to configure the web servers
cat << EOF > startup.sh
#! /bin/bash
apt-get update
apt-get install -y nginx
service nginx start
sed -i -- 's/nginx/Google Cloud Platform - '"\$HOSTNAME"'/' /var/www/html/index.nginx-debian.html
EOF

# Create an instance template. 
# Don't use the default machine type. 
# Make sure you specify e2-medium as the machine type 
# and create the Global template.
gcloud compute instance-templates create lb-backend-template --machine-type=e2-medium --metadata-from-file startup-script=startup.sh --region=$REGION

# Create a managed instance group based on the template.
gcloud compute instance-groups managed create lb-backend-group --template=lb-backend-template --size=2 --zone=$ZONE

# Create a firewall rule named as grant-tcp-rule-175 to allow traffic (80/tcp).
gcloud compute firewall-rules create $FIREWALL --action=allow --rules=tcp:80 --network=default

# Create a health check
gcloud compute health-checks create http http-basic-check --port 80

# Create a backend service and add your instance group as the backend to the backend service group with named port (http:80).
gcloud compute instance-groups managed set-named-ports lb-backend-group --named-ports http:80 --zone=$ZONE
gcloud compute backend-services create web-backend-service --protocol=HTTP --port-name=http --health-checks=http-basic-check --global
gcloud compute backend-services add-backend web-backend-service --instance-group=lb-backend-group --instance-group-zone=$ZONE --global

# Create a URL map, and target the HTTP proxy to route the incoming requests to the default backend service.
gcloud compute url-maps create web-map-http --default-service web-backend-service

# Create a target HTTP proxy to route requests to your URL map
gcloud compute target-http-proxies create http-lb-proxy --url-map web-map-http

# Create a forwarding rule.
gcloud compute forwarding-rules create http-content-rule --global --target-http-proxy=http-lb-proxy --ports=80

# Check 
gcloud compute forwarding-rules list

