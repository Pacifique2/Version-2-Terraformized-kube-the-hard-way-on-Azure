resource "null_resource" "etcd_certs" {
  #count = "${length(var.controller_dns_names)}"
  count  = "${var.count}"
  depends_on = [
          "data.template_file.kubelet_config_template","null_resource.kubelet_provisioner","null_resource.kube-proxy-provisioner",
          "null_resource.kube-controller-manager-provisioner", "null_resource.kube-scheduler-provisioner","null_resource.admin-provisioner",
          "null_resource.encryption_config-provisioner"
  ]
  connection {
    type         = "ssh"
    host = "${element(var.controller_dns_names,count.index)}"
    user         = "${var.api_server_username}"
    password     = "${var.api_server_password}"
    private_key  = "${file("~/.ssh/kube-devolab_id_rsa")}"
    timeout      =  "1m"
    agent        = true
  }

  provisioner "remote-exec" {
    inline = [
      #"echo ${element(var.ca_cert_null_ids, count.index)}",
      #"echo ${element(var.kubernetes_certs_null_ids, count.index)}",
      "sudo mkdir -p /etc/etcd /var/lib/etcd",
      "sudo cp ca.pem kubernetes-key.pem kubernetes.pem /etc/etcd/",
    ]
  }
}

# Download etcd binary
resource "null_resource" "etcd_binary" {
  #count = "${length(var.controller_dns_names)}"
  count  = "${var.count}"
  depends_on ["null_resource.etcd_certs"]
  connection {                                            
    type         = "ssh"                                  
    host = "${element(var.controller_dns_names,count.index)}"   
    user         = "${var.api_server_username}"           
    password     = "${var.api_server_password}"           
    private_key  = "${file("~/.ssh/kube-devolab_id_rsa")}"
    timeout      =  "1m"                                  
    agent        = true                                   
  }                                                       

  provisioner "remote-exec" {
    inline = [
      "wget -q --show-progress --https-only --timestamping 'https://github.com/coreos/etcd/releases/download/v3.3.9/etcd-v3.3.9-linux-amd64.tar.gz'",
      "tar -xvf etcd-v3.3.9-linux-amd64.tar.gz",
      "sudo mv etcd-v3.3.9-linux-amd64/etcd* /usr/local/bin/",
    ]
  }
}

data "template_file" "etcd_service_template" {
  
  template =<<EOT
[Unit]
Description=etcd
Documentation=https://github.com/coreos

[Service]
ExecStart=/usr/local/bin/etcd \
  --name $${ETCD_NAME} \
  --cert-file=/etc/etcd/kubernetes.pem \
  --key-file=/etc/etcd/kubernetes-key.pem \
  --peer-cert-file=/etc/etcd/kubernetes.pem \
  --peer-key-file=/etc/etcd/kubernetes-key.pem \
  --trusted-ca-file=/etc/etcd/ca.pem \
  --peer-trusted-ca-file=/etc/etcd/ca.pem \
  --peer-client-cert-auth \
  --client-cert-auth \
  --initial-advertise-peer-urls https://$${INTERNAL_IP}:2380 \
  --listen-peer-urls https://$${INTERNAL_IP}:2380 \
  --listen-client-urls https://$${INTERNAL_IP}:2379,https://127.0.0.1:2379 \
  --advertise-client-urls https://$${INTERNAL_IP}:2379 \
  --initial-cluster-token etcd-cluster-0 \
  --initial-cluster $${m1}=https://10.240.0.10:2380,$${m2}=https://10.240.0.11:2380,$${m3}=https://10.240.0.12:2380 \
  --initial-cluster-state new \
  --data-dir=/var/lib/etcd
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
  EOT
  depends_on = ["null_resource.etcd_certs","null_resource.etcd_binary"]
  #depends_on = ["aws_elb.kubernetes-elb","","aws_instance.kubernetes_controllers","aws_instance.kubernetes_workers"] 
  count = "${var.count}"
  #count = "${length(var.controller_dns_names)}"
  #internal_master_private_ips

  vars {
    ETCD_NAME   = "${element(var.controller_node_names, count.index)}"
    INTERNAL_IP = "${element(var.internal_master_private_ips, count.index)}"
    #CONTLOLLER_NAME       =  "${element(var.master_nodes_names,count.index)}"
    m1 = "controller-terraform-0"
    m2 = "controller-terraform-1"
    m3 = "controller-terraform-2"
  }
}

resource "local_file" "etcd_config" {
  #count    = "${length(var.internal_master_private_ips)}"
  count  = "${var.count}"
  depends_on = ["data.template_file.etcd_service_template"]
  content  = "${data.template_file.etcd_service_template.*.rendered[count.index]}"
  filename = "./configs-etcd/${element(var.controller_node_names, count.index)}.etcd.service"
}

# Configure the etcd server
resource "null_resource" "etcd_server" {
  #count = "${length(var.controller_node_names)}"
  count  = "${var.count}"
  depends_on = ["local_file.etcd_config","null_resource.etcd_certs"]
  connection {                                            
    type         = "ssh"                                  
    host = "${element(var.controller_dns_names,count.index)}"   
    user         = "${var.api_server_username}"           
    password     = "${var.api_server_password}"           
    private_key  = "${file("~/.ssh/kube-devolab_id_rsa")}"
    timeout      =  "1m"                                  
    agent        = true                                   
  }                                                       

  # depends_on = ["local_file.etcd_config"]

  provisioner "file" {
    source      = "./configs-etcd/${element(var.controller_node_names, count.index)}.etcd.service"
    destination = "~/${element(var.controller_node_names, count.index)}.etcd.service"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mv ~/${element(var.controller_node_names, count.index)}.etcd.service /etc/systemd/system/etcd.service",
      "sudo systemctl daemon-reload",
      "sudo systemctl enable etcd",
      "sudo systemctl start etcd",
      "etvar=${element(var.internal_master_private_ips, count.index)}",
      ]
    /*
    inline = [
      "sudo ETCDCTL_API=3 etcdctl member list --endpoints=https://${element(var.internal_master_private_ips, count.index)}:2379 --cacert=/etc/etcd/ca.pem --cert=/etc/etcd/kubernetes.pem --key=/etc/etcd/kubernetes-key.pem",
     
    ]
     */
    #script = "${path.module}/etcd-script.sh"
  }
}

# test the etcd server
resource "null_resource" "etcd_server_test" {
  #count = "${length(var.controller_node_names)}"
  count  = "${var.count}"
  depends_on = ["null_resource.etcd_server","local_file.etcd_config"]
  connection {
    type         = "ssh"
    host = "${element(var.controller_dns_names,count.index)}"
    user         = "${var.api_server_username}"
    password     = "${var.api_server_password}"
    private_key  = "${file("~/.ssh/kube-devolab_id_rsa")}"
    timeout      =  "1m"
    agent        = true
  }

  # depends_on = ["local_file.etcd_config"]

  provisioner "remote-exec" {
    script = "${path.module}/etcd-script.sh"
  }

}

