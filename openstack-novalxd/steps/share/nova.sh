create_flavor() {
    flavor=$1
    ram=$3
    disk=$5
    ephemeral=$7
    vcpus=$9
    if ! openstack flavor show "$flavor" >/dev/null 2>&1; then
       debug "creating flavor $flavor"
        if ! openstack flavor create \
              --public --ram $ram --disk $disk --ephemeral $ephemeral \
              --vcpus $vcpus $flavor >/dev/null 2>&1; then
            debug "could not create flavor $flavor"
        fi
    fi
}

create_keypair() {
    if ! openstack keypair show default >/dev/null 2>&1; then
        if [ -f ~/.ssh/id_rsa.pub ]; then
            debug "creating default keypair"
            if ! openstack keypair create \
                   --public-key ~/.ssh/id_rsa.pub \
                   default >/dev/null 2>&1; then
                debug "could not create default keypair"
            fi
        fi
    fi
}

create_flavor m1.tiny   --ram   512 --disk  1 --ephemeral 0 --vcpus 1
create_flavor m1.small  --ram  1024 --disk 20 --ephemeral 0 --vcpus 2
create_flavor m1.medium --ram  2048 --disk 40 --ephemeral 0 --vcpus 2
create_flavor m1.large  --ram  8192 --disk 40 --ephemeral 0 --vcpus 4
create_flavor m1.xlarge --ram 16384 --disk 80 --ephemeral 0 --vcpus 8
create_keypair

exposeResult "Nova is now configured and is available to you during instance creation." 0 "true"
