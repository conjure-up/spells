# Get host namserver
get_host_ns() {
    perl -lne 's/^nameserver\s+// or next; s/\s.*//; print && exit' /etc/resolv.conf
}

if ! neutron net-show ext-net > /dev/null 2>&1; then
    debug "adding ext-net"
    if ! openstack network create --external --provider-network-type flat --provider-physical-network physnet1 ext-net > /dev/null 2>&1; then
        debug "could not net-create ext-net"
    fi
fi

if ! neutron subnet-show ext-subnet > /dev/null 2>&1; then
    debug "adding ext-subnet"
    if ! neutron subnet-create --name ext-subnet  \
             --gateway "$LXD_GATEWAY" --disable-dhcp \
             --allocation-pool start="$LXD_DHCP_RANGE_START",end="$LXD_DHCP_RANGE_STOP" ext-net "$LXD_NETWORK" > /dev/null 2>&1; then
        debug "could not subnet-create ext-subnet"
    fi
fi

if ! neutron net-show ubuntu-net > /dev/null 2>&1; then
    debug "adding ubuntu-net"
    if ! neutron net-create ubuntu-net --shared > /dev/null 2>&1; then
        debug "could not net-create"
    fi
fi

if ! neutron subnet-show ubuntu-subnet > /dev/null 2>&1; then
    debug "adding ubuntu-subnet"
    if ! neutron subnet-create --name ubuntu-subnet \
            --gateway 10.101.0.1 \
            --dns-nameserver $(get_host_ns) ubuntu-net 10.101.0.0/24 > /dev/null 2>&1; then
        debug "could not add ubuntusubnet"
    fi
fi

if ! neutron router-show ubuntu-router > /dev/null 2>&1; then
    debug "adding ubuntu-router"
    if ! neutron router-create ubuntu-router > /dev/null 2>&1; then
        debug "couldnt create ubuntu-router"
    fi
fi

if ! neutron router-interface-add ubuntu-router ubuntu-subnet > /dev/null 2>&1; then
    debug "Could not add router-interface"
fi

debug "setting router gateway"
if ! neutron router-gateway-set ubuntu-router ext-net > /dev/null 2>&1; then
    debug "Could not set router gateway"
fi

# create pool of at least 5 floating ips
debug "creating floating ips"
existingips=$(neutron floatingip-list -f csv | tail -n +2| wc -l)
to_create=$((10 - existingips))
i=0
while [ $i -ne $to_create ]; do
    neutron floatingip-create ext-net > /dev/null 2>&1
    i=$((i + 1))
done

# configure security groups
debug "setting security roles"
neutron security-group-rule-create --direction ingress --ethertype IPv4 --protocol icmp --remote-ip-prefix 0.0.0.0/0 default > /dev/null 2>&1 || true
neutron security-group-rule-create --direction ingress --ethertype IPv4 --protocol tcp --port-range-min 22 --port-range-max 22 --remote-ip-prefix 0.0.0.0/0 default > /dev/null 2>&1 || true

printf "Neutron networking is now configured and is available to you during instance creation."
