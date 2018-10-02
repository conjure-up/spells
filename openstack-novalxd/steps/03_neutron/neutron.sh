# Get host namserver
get_host_ns() {
    perl -lne 's/^nameserver\s+// or next; s/\s.*//; print && exit' /etc/resolv.conf
}

NEUTRON_LOG="neutron.log"

debug "Creating External Network"
./neutron-ext-net --network-type flat \
                  -g 10.101.0.1 \
                  -c 10.101.0.0/24 \
                  -f 10.101.0.10:10.101.0.254 ext_net >> $NEUTRON_LOG 2>&1

debug "Creating Internal Network"
./neutron-tenant-net -p admin -r provider-router \
                     -N "$(get_host_ns)" internal 10.5.5.0/24 >> $NEUTRON_LOG 2>&1

debug "Setting security roles"

sudo apt-get update -qq > /dev/null 2>&1
sudo apt-get install -qyf jq > /dev/null 2>&1

for secgroup_id in $(openstack security group list -f json|jq -r .[].ID); do
    neutron security-group-rule-create --protocol icmp \
            --direction ingress "$secgroup_id" >> $NEUTRON_LOG 2>&1
    neutron security-group-rule-create --protocol tcp \
        --port-range-min 22 --port-range-max 22 \
        --direction ingress "$secgroup_id" >> $NEUTRON_LOG 2>&1
done

printf "Neutron networking is now configured and is available to you during instance creation."
