#!/usr/bin

echo "test all the scripts in one"

chmod +x ${path.module}/scripts/kubernetes-admin-user.sh ${path.module}/scripts/kubectl-verification.sh
cp -r ${path.module}/scripts/kubernetes-admin-user.sh ${path.module}/scripts/kubectl-verification.sh ~/myAzureProject/terraform/azure-k8s-terra-cluster/tls-certs/client-server"
sleep 30
cd ~/myAzureProject/terraform/azure-k8s-terra-cluster/tls-certs/client-server && ./kubernetes-admin-user.sh
echo "second script"
cd ~/myAzureProject/terraform/azure-k8s-terra-cluster/tls-certs/client-server && ./kubectl-verification.sh
echo done
