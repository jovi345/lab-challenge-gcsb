# Export the value 

export IAP_NETWORK_TAG=allow-ssh-iap-ingress-ql-200
export INTERNAL_NETWORK_TAG=allow-ssh-internal-ingress-ql-200
export HTTP_NETWORK_TAG=allow-http-ingress-ql-200
export ZONE=europe-west1-c

# 1. Check the firewall rules. Remove the overly permissive rules.
gcloud compute firewall-rules list
# Then delete "open-access"
gcloud compute firewall-rules delete open-access

# 2. Navigate to Compute Engine in the Cloud console and identify the bastion host. The instance should be stopped. Start the instance.
# Just do this step from Google Cloud Console.
# In Compute engine > VM instance. Find "bastion", then click the 3 dots, "Start/Resume"

# 3. The bastion host is the one machine authorized to receive external SSH traffic. 
# Create a firewall rule that allows SSH (tcp/22) from the IAP service. 
# The firewall rule must be enabled for the bastion host instance using a network tag of grant-ssh-iap-ingress-ql-221.
gcloud compute firewall-rules create allow-ssh-ingress-from-iap --direction=INGRESS --action=allow --rules=tcp:22 --source-ranges=35.235.240.0/20 --target-tags=$IAP_NETWORK_TAG --network=acme-vpc
# Update the bastion host instance to enable the firewall rule via network tag.
gcloud compute instances add-tags bastion --tags=$IAP_NETWORK_TAG --zone=$ZONE

# 4. The juice-shop server serves HTTP traffic. 
# Create a firewall rule that allows traffic on HTTP (tcp/80) to any address. 
# The firewall rule must be enabled for the juice-shop instance using a network tag of grant-http-ingress-ql-221.
gcloud compute firewall-rules create allow-traffic-on-http --action=allow --rules=tcp:80 --source-ranges=0.0.0.0/0 --target-tags=$HTTP_NETWORK_TAG --network=acme-vpc
# Update the juice-shop instance to enable the firewall rule via network tag
gcloud compute instances add-tags juice-shop --tags=$HTTP_NETWORK_TAG --zone=$ZONE

# 5. You need to connect to juice-shop from the bastion using SSH. 
# Create a firewall rule that allows traffic on SSH (tcp/22) from acme-mgmt-subnet network address. 
# The firewall rule must be enabled for the juice-shop instance using a network tag of grant-ssh-internal-ingress-ql-221.
gcloud compute firewall-rules create allow-juice-shop-to-bastion-ssh --action=allow --rules=tcp:22 --source-ranges=192.168.10.0/24 --target-tags=$INTERNAL_NETWORK_TAG --network=acme-vpc
# Update the juice-shop instance to enable the firewall rule via network tag.
gcloud compute instances add-tags juice-shop --tags=$INTERNAL_NETWORK_TAG --zone=$ZONE

# 6. In the Compute Engine instances page, click the SSH button for the bastion host. Once connected, SSH to juice-shop.
# SSH to bastion host via IAP and juice-shop via bastion
# After SSH to bastion 
gcloud compute ssh juice-shop --internal-ip

# Finished
