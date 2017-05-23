fail_cleanly() {
    exposeResult "$1" 1 "false"
}

# Get host namserver
get_host_ns() {
    perl -lne 's/^nameserver\s+// or next; s/\s.*//; print && exit' /etc/resolv.conf
}

sudo apt-get -qqyf python3-openstackclient > /dev/null 2>&1 || true

if ! openstack network show ext-net >/dev/null 2>&1; then
    debug "adding ext-net"
    if ! openstack network create --external ext-net >/dev/null 2>&1; then
        debug "could not net-create ext-net"
    fi
fi

if ! openstack subnet show ext-subnet >/dev/null 2>&1; then
    debug "adding ext-subnet"
    if ! openstack subnet create --network ext-net \
             --subnet-range 10.99.0.0/24 --gateway 10.99.0.1 --no-dhcp  \
             --allocation-pool start=10.99.0.3,end=10.99.0.254 \
             ext-subnet >/dev/null 2>&1; then
        debug "could not subnet-create ext-subnet"
    fi
fi

if ! openstack network show ubuntu-net >/dev/null 2>&1; then
    debug "adding ubuntu-net"
    if ! openstack network create --share ubuntu-net >/dev/null 2>&1; then
        debug "could not net-create"
    fi
fi

if ! openstack subnet show ubuntu-subnet >/dev/null 2>&1; then
    debug "adding ubuntu-subnet"
    if ! openstack subnet create --network ubuntu-net \
            --subnet-range 10.101.0.24/24 --gateway 10.101.0.1 \
            --dns-nameserver $(get_host_ns) ubuntu-subnet >/dev/null 2>&1; then
        debug "could not add ubuntu-subnet"
    fi
fi

if ! openstack router show ubuntu-router >/dev/null 2>&1; then
    debug "adding ubuntu-router"
    if ! openstack router create ubuntu-router >/dev/null 2>&1; then
        debug "couldnt create ubuntu-router"
    else
        if ! openstack router add subnet ubuntu-router ubuntu-subnet >/dev/null 2>&1; then
            debug "Could not add router-interface"
        fi
        debug "setting router gateway"
        if ! openstack router set ubuntu-router --external-gateway ext-net >/dev/null 2>&1; then
            debug "Could not set router gateway"
        fi
    fi
fi

# create pool of at least 5 floating ips
debug "creating floating ips"
existingips=$(openstack floating ip list -f csv | tail -n +2| wc -l)
to_create=$((10 - existingips))
i=0
while [ $i -ne $to_create ]; do
    openstack floating ip create ext-net >/dev/null 2>&1
    i=$((i + 1))
done

# configure security groups
debug "setting security roles"
SGID=$(openstack security group list --project admin -c ID -f value)
openstack security group rule create --ingress --ethertype IPv4 --protocol icmp --prefix 0.0.0.0/0 $SGID >/dev/null 2>&1
openstack security group rule create --ingress --ethertype IPv4 --protocol tcmp --dst-port 22 --prefix 0.0.0.0/0 $SGID >/dev/null 2>&1

exposeResult "Neutron networking is now configured and is available to you during instance creation." 0 "true"
