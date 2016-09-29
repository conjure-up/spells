if ! openstack keypair show ubuntu-keypair > /dev/null 2>&1; then
    debug "adding ssh keypair"
    openstack keypair create --public-key $SSHPUBLICKEY ubuntu-keypair > /dev/null 2>&1
fi
exposeResult "SSH Keypair is now imported and accessible when creating compute nodes." 0 "true"
