# Version-2-Terraformized-kube-the-hard-way-on-Azure

This project highlights the basic steps to set up Kubernetes the hard way with terraform asan automation tool. This takes us through a complete automated implementation  to bring up a Kubernetes cluster. To do so, we use terraform to provision and deploy the whole kubernetes ecosystem.

Kubernetes The Hard Way is optimized for learning, which means taking the long route to ensure you understand each task required to bootstrap a Kubernetes cluster.

Kubernetes The Hard Way guides you through bootstrapping a highly available Kubernetes cluster with end-to-end encryption between components and RBAC authentication.

In this project, we generate both tls certificates and kubernetes configuration files differently from the previous kubernetes project. Using terraform to implement kubernetes the hard way.

Cluster Details

Kubernetes The Hard Way guides you through bootstrapping a highly available Kubernetes cluster with end-to-end encryption between components and RBAC authentication.

Kubernetes 1.12.0
https://github.com/kubernetes/kubernetes

containerd Container Runtime 1.2.0-rc.0
gVisor 50c283b9f56bb7200938d9e207355f05f79f0d17
CNI Container Networking 0.6.0
etcd v3.3.9
CoreDNS v1.2.2

Steps to bring up the kubernetes cluster

Prerequisites
Install PKI tools such cfssl cfssljon 
Installing the Client Tools
Provisioning Compute Resources
Provisioning the CA and Generating TLS Certificates
Generating Kubernetes Configuration Files for Authentication
Generating the Data Encryption Config and Key
Bootstrapping the etcd Cluster
Bootstrapping the Kubernetes Control Plane
Bootstrapping the Kubernetes Worker Nodes
Configuring kubectl for Remote Access
Provisioning Pod Network Routes
Deploying the DNS Cluster Add-on
Testing the cluster

Installation
The following steps are required to setup and run this project:

Clone the repo
Generate an SSH key which can be used to SSH to the Kubernetes vms instances which will be created within MS Azure public cloud. The generated public/private key pair should be generated in a folder matching the path(s) found in the respective variables ssh_key_data for path to public key and make sure that both the public key and private key can be located from the .ssh directory. This will ensure that the Terraform variables file can read them correctly. An example of generating such a public/private key pair can be found on internet.

Ensure that the AZURE credentials profile that you wish to use to run this project is specified correctly in your Azure CLI authentication to Azure portal . Ensure that your subscription id is configured  int azure prvider file before testing. 

Install Terraform.
Install go.
Install the following cfssl tools:
go get -u github.com/cloudflare/cfssl/cmd/cfssl
go get -u github.com/cloudflare/cfssl/cmd/cfssljson
go get -u github.com/cloudflare/cfssl/cmd/mkbundle
Install kubectl

For now we initiate and apply twice fo a complete 
From the terraform root directory execute the following to ensure that the expected resources will be created:
comment out the certs module within main tarraform file
terraform init to download the environment plugins
terraform plan
and then to actually create the required Azure resources:

terraform apply


From project root run:
terraform init 







