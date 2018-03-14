#!/bin/bash

set -eu

###############################################################################
# Prerequisites
###############################################################################
# 0. vSphere cloud added and bootstrapped
#    - https://jujucharms.com/docs/2.3/help-vmware
# 1. CDK deployed
#    - juju deploy canonical-kubernetes
# 2. Disk UUID enabled on VMs
#    - https://sunekjaergaard.blogspot.dk/2018/02/making-canonical-distribution-of.html
#
# These will be handled automatically when Juju supports disk uuid model config:
#    - https://bugs.launchpad.net/juju/+bug/1751858


###############################################################################
# Modify to suite your environment
###############################################################################
# IP/Port of your vsphere server
JUJU_VSPHERE_ENDPOINT="1.2.3.4"
JUJU_VSPHERE_PORT="443"

# Array of vsphere datacenter names, available in vCenter from:
#  vCenter Inventory Lists > Resources > Datacenters
JUJU_VSPHERE_REGIONS=(dc0)

# Login info for your vsphere server (same used when adding juju credentials)
JUJU_VSPHERE_USER="admin"
JUJU_VSPHERE_PASSWORD="password"

# Config used when bootstrapping (override to prevent discovery):
#  https://jujucharms.com/docs/2.3/help-vmware#bootstrapping
JUJU_VSPHERE_DATASTORE=$(juju model-config datastore 2>/dev/null || echo "")
JUJU_VSPHERE_EXTERNAL_NET=$(juju model-config external-network 2>/dev/null || echo "")

# VM folder created in your vsphere datacenter
JUJU_VSPHERE_FOLDER="k8s-storage"

# Number of kubernetes master units in your deployment
NUMBER_OF_K8S_MASTERS=1


###############################################################################
# vSphere config template
###############################################################################
# From official vSphere docs:
#  https://vmware.github.io/vsphere-storage-for-kubernetes/documentation/existing.html
# As well as HOWTO from sunek:
#  https://sunekjaergaard.blogspot.dk/2018/02/making-canonical-distribution-of.html
VSPHERE_CONF=$(cat <<EOF
[Global]
        # properties in this section will be used for all specified vCenters unless overriden in VirtualCenter section.
        user = "$JUJU_VSPHERE_USER"
        password = "$JUJU_VSPHERE_PASSWORD"
        port = "$JUJU_VSPHERE_PORT" #Optional
        insecure-flag = "1" #set to 1 if the vCenter uses a self-signed cert
        datacenters = "${JUJU_VSPHERE_REGIONS[*]}"
        vm-uuid="VM_UUID" # we will set this value on each VM

[VirtualCenter "$JUJU_VSPHERE_ENDPOINT"]
        #Even though it's the same as the Global configuration it should still be there, otherewise the cloud provider will interpret the configuration file as an pre k8s 1.9 style config file.

[Workspace]
        # Specify properties which will be used for various vSphere Cloud Provider functionality.
        # e.g. Dynamic provisioing, Storage Profile Based Volume provisioning etc.
        server = "$JUJU_VSPHERE_ENDPOINT"
        datacenter = "${JUJU_VSPHERE_REGIONS[0]}"
        folder = "$JUJU_VSPHERE_FOLDER" #Make sure this folder exists in your vmware Datacenter
        default-datastore = "$JUJU_VSPHERE_DATASTORE" #Datastore to use for provisioning volumes using storage classes/dynamic provisioning
        resourcepool-path = "" # Used for dummy VM creation. Optional
[Disk]
        scsicontrollertype = pvscsi
[Network]
        public-network = "$JUJU_VSPHERE_EXTERNAL_NET"
EOF
)


###############################################################################
# Configure applications
###############################################################################
VSPHERE_LOCAL_CONF_FILE=$(mktemp /tmp/vsphere.conf.XXXX)
echo "Creating $VSPHERE_LOCAL_CONF_FILE"
echo "${VSPHERE_CONF}" > $VSPHERE_LOCAL_CONF_FILE

echo "Updating k8s masters"
for i in $(seq 0 $((NUMBER_OF_K8S_MASTERS-1))); do
  MASTER="kubernetes-master/${i}"
  echo "Transfering config to $MASTER"
  juju scp $VSPHERE_LOCAL_CONF_FILE ${MASTER}:vsphere.conf

  echo "Setting UUID in the $MASTER config"
  juju ssh ${MASTER} 'uuid=$(sudo sed -e "s/\s//g" /sys/class/dmi/id/product_serial); sed -i -e "s/VM_UUID/$uuid/" vsphere.conf'

  echo "Moving $MASTER config to /root/cdk"
  juju ssh ${MASTER} "sudo chown root:root /home/ubuntu/vsphere.conf; sudo mv /home/ubuntu/vsphere.conf /root/cdk/"
done

echo "Configuring k8s-master to use the vsphere provider"
juju config kubernetes-master controller-manager-extra-args="cloud-provider=vsphere cloud-config=/root/cdk/vsphere.conf" api-extra-args="cloud-provider=vsphere cloud-config=/root/cdk/vsphere.conf"

echo "Configuring k8s-workers to use the vsphere provider"
juju config kubernetes-worker kubelet-extra-args="cloud-provider=vsphere"

cat <<EOM

Configuration complete. You may now define a K8s storage class to autoprovision
vSphere storage. For example:

kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
 name: mystorage
provisioner: kubernetes.io/vsphere-volume
parameters:
 diskformat: zeroedthick
 fstype:     ext  4
EOM
