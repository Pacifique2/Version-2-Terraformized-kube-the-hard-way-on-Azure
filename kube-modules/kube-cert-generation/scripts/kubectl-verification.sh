#!/usr/bin

set -e

echo "testing the remote user with kubectl"

#Verification
#Check the health of the remote Kubernetes cluster:

kubectl get componentstatuses

# List the nodes in the remote Kubernetes cluster:

kubectl get nodes

echo "done testing with kubectl"
