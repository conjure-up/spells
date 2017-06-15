if ! openstack keypair show ubuntu-keypair > /dev/null 2>&1; then
    debug "adding ssh keypair from $SSHPUBLICKEY"
    openstack keypair create --public-key $SSHPUBLICKEY ubuntu-keypair > /dev/null 2>&1
fi
printf "SSH Keypair is now imported and accessible when creating compute nodes."
exit 0
