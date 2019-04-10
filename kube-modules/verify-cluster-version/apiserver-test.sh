#!/usr/bin

set -e

echo "start testing the api-server"
KUBERNETES_PUBLIC_IP_ADDRESS = $1
curl --cacert /var/lib/kubernetes/ca.pem https://${KUBERNETES_PUBLIC_IP_ADDRESS}:6443/version

echo "Okk!!! testing the api server health check"
echo done

