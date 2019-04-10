#!/bin/sh

set -e

echo "In this section you will gather the information required to create routes in the kubernetes-vnet."
echo "Print the internal IP address and Pod CIDR range for each worker instance:"
for instance in worker-terraform-0 worker-terraform-1 worker-terraform-2; do
  PRIVATE_IP_ADDRESS=$(az vm show -d -g RG-Kube-Free -n ${instance} --query "privateIps" -otsv)
  POD_CIDR=$(az vm show -g RG-Kube-Free --name ${instance} --query "tags" -o tsv)
  echo $PRIVATE_IP_ADDRESS $POD_CIDR
done

echo Routes
echo "Create network routes for worker instance:"


