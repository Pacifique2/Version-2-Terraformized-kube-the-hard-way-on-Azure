#!/bin/sh

echo "Starting the etcd service"
# hi=${element(var.controller_node_names, count.index)}
#sudo mv ~/${etvar}.etcd.service /etc/systemd/system/etcd.service
#sudo systemctl daemon-reload
#sudo systemctl enable etcd
#sudo systemctl start etcd
sudo ETCDCTL_API=3 etcdctl member list \
     --endpoints=https://127.0.0.1:2379 \ 
     --cacert=/etc/etcd/ca.pem \
     --cert=/etc/etcd/kubernetes.pem \
     --key=/etc/etcd/kubernetes-key.pem

