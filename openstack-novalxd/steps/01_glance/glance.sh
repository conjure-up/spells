imagetype=root.tar.xz
diskformat=raw
imagesuffix="-lxd"

GLANCE_LOG="glance.log"

mkdir -p "$HOME/glance-images" || true
if [ ! -f "$HOME/glance-images/xenial-server-cloudimg-amd64-$imagetype" ]; then
    debug "Downloading xenial image..."
    wget --user-agent="conjure-up/openstack-novalxd" -qO ~/glance-images/xenial-server-cloudimg-amd64-$imagetype https://cloud-images.ubuntu.com/xenial/current/xenial-server-cloudimg-amd64-$imagetype
fi
if [ ! -f "$HOME/glance-images/bionic-server-cloudimg-amd64-$imagetype" ]; then
    debug "Downloading bionic image..."
    wget --user-agent="conjure-up/openstack-novalxd" -qO ~/glance-images/bionic-server-cloudimg-amd64-$imagetype https://cloud-images.ubuntu.com/bionic/current/bionic-server-cloudimg-amd64-$imagetype
fi

if ! glance image-list --property-filter name="bionic$imagesuffix" | grep -q "bionic$imagesuffix" ; then
    debug "Importing bionic$imagesuffix"
    glance image-create --name="bionic$imagesuffix" \
           --container-format=bare \
           --disk-format=$diskformat \
           --property architecture="x86_64" \
           --visibility=public --file="$HOME/glance-images/bionic-server-cloudimg-amd64-$imagetype" >> $GLANCE_LOG 2>&1
fi
if ! glance image-list --property-filter name="xenial$imagesuffix" | grep -q "xenial$imagesuffix" ; then
    debug "Importing xenial$imagesuffix"
    glance image-create --name="xenial$imagesuffix" \
           --container-format=bare \
           --disk-format=$diskformat \
           --property architecture="x86_64" \
           --visibility=public --file="$HOME/glance-images/xenial-server-cloudimg-amd64-$imagetype" >> /dev/null 2>&1
fi

openstack flavor create --id 1 --ram 2048 --disk 20 --vcpus 1 m1.small >> $GLANCE_LOG 2>&1

printf "Glance images for Bionic (18.04) and Xenial (16.04) are imported and accessible via Horizon dashboard."
