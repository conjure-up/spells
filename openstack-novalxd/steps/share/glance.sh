imagetype=root.tar.xz
diskformat=raw
imagesuffix="-lxd"

mkdir -p $HOME/glance-images || true
if [ ! -f $HOME/glance-images/xenial-server-cloudimg-amd64-$imagetype ]; then
    debug "Downloading xenial image..."
    wget -qO ~/glance-images/xenial-server-cloudimg-amd64-$imagetype https://cloud-images.ubuntu.com/xenial/current/xenial-server-cloudimg-amd64-$imagetype
fi
if [ ! -f $HOME/glance-images/trusty-server-cloudimg-amd64-$imagetype ]; then
    debug "Downloading trusty image..."
    wget -qO ~/glance-images/trusty-server-cloudimg-amd64-$imagetype https://cloud-images.ubuntu.com/trusty/current/trusty-server-cloudimg-amd64-$imagetype
fi

if ! glance image-list --property-filter name="trusty$imagesuffix" | grep -q "trusty$imagesuffix" ; then
    debug "Importing trusty$imagesuffix"
    glance image-create --name="trusty$imagesuffix" \
           --container-format=bare \
           --disk-format=$diskformat \
           --property architecture="x86_64" \
           --visibility=public --file=$HOME/glance-images/trusty-server-cloudimg-amd64-$imagetype > /dev/null 2>&1
fi
if ! glance image-list --property-filter name="xenial$imagesuffix" | grep -q "xenial$imagesuffix" ; then
    debug "Importing xenial$imagesuffix"
    glance image-create --name="xenial$imagesuffix" \
           --container-format=bare \
           --disk-format=$diskformat \
           --property architecture="x86_64" \
           --visibility=public --file=$HOME/glance-images/xenial-server-cloudimg-amd64-$imagetype > /dev/null 2>&1
fi

printf "Glance images for Trusty (14.04) and Xenial (16.04) are imported and accessible via Horizon dashboard."
