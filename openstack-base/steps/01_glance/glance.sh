sudo apt update > /dev/null 2>&1
sudo apt -qyf install python3-openstackclient jq > /dev/null 2>&1

imagesuffix="-kvm"
declare -A arches=(["aarch64"]="arm64" ["x86_64"]="amd64")
declare -A imagetypes=(["aarch64"]="uefi1.img" ["x86_64"]="disk1.img")
declare -A diskformats=(["aarch64"]="qcow2" ["x86_64"]="raw")
declare -A firmwaretypes=(["aarch64"]="uefi" ["x86_64"]="bios")

nova_architectures=$( \
    for id in $(openstack hypervisor list | grep -o " [0-9]\+ "); \
    do
        openstack hypervisor show -c cpu_info $id | \
            cut -f 3 -d '|' | tail -n +4 | head -n 1 | jq -r ".arch"
    done | uniq)

mkdir -p $HOME/glance-images || true

for nova_arch in $nova_architectures;
do
    image_arch=${arches[$nova_arch]}
    imagetype=${imagetypes[$nova_arch]}
    diskformat=${diskformats[$nova_arch]}
    firmwaretype=${firmwaretypes[$nova_arch]}
    if [ ! -f $HOME/glance-images/xenial-server-cloudimg-${image_arch}-$imagetype ]; then
        debug "Downloading xenial image..."
        wget --user-agent="conjure-up/openstack-base" -qO ~/glance-images/xenial-server-cloudimg-${image_arch}-$imagetype https://cloud-images.ubuntu.com/xenial/current/xenial-server-cloudimg-${image_arch}-$imagetype
    fi
    if [ ! -f $HOME/glance-images/trusty-server-cloudimg-${image_arch}-$imagetype ]; then
        debug "Downloading trusty image..."
        wget --user-agent="conjure-up/openstack-base" -qO ~/glance-images/trusty-server-cloudimg-${image_arch}-$imagetype https://cloud-images.ubuntu.com/trusty/current/trusty-server-cloudimg-${image_arch}-$imagetype
    fi

    trusty_image=trusty${imagesuffix}-${image_arch}
    if ! glance image-list --property-filter name="$trusty_image" | grep -q "$trusty_image" ; then
        debug "Importing $trusty_image"
        glance image-create --name="$trusty_image" \
               --container-format=bare \
               --disk-format=$diskformat \
               --property hw_firmware_type=$firmwaretype \
               --property architecture="${nova_arch}" \
               --visibility=public --file=$HOME/glance-images/trusty-server-cloudimg-${image_arch}-$imagetype > /dev/null 2>&1
    fi
    xenial_image=xenial${imagesuffix}-${image_arch}
    if ! glance image-list --property-filter name="$xenial_image" | grep -q "$xenial_image" ; then
        debug "Importing $xenial_image"
        glance image-create --name="$xenial_image" \
               --container-format=bare \
               --disk-format=$diskformat \
               --property hw_firmware_type=$firmwaretype \
               --property architecture="${nova_arch}" \
               --visibility=public --file=$HOME/glance-images/xenial-server-cloudimg-${image_arch}-$imagetype > /dev/null 2>&1
    fi
done

printf "Glance images for Trusty (14.04) and Xenial (16.04) are imported and accessible via Horizon dashboard."
exit 0
