#!/usr/bin/env bash
set -euo pipefail

# where we do the things
WORKDIR="$(mktmp -d)"
ISO_MOUNT_DIR="$(mkdir -p ${WORKDIR}/mount)"
CDIMAGE_DIR="$(mkdir -p ${WORKDIR}/cdimage)"

#### CHANGE ME ####
# this is the custom iso path
CUSTOM_ISO_PATH="/tmp/fresh.iso"

# ubuntu iso and checksum
UBUNTU_VERSION="18.04"
PATCH_VERSION="1"
BASE_URL="http://cdimage.ubuntu.com/releases/${UBUNTU_VERSION}/release"

ISO_URL="${BASE_URL}/ubuntu-${UBUNTU_VERSION}.${PATCH_VERSION}-server-amd64.iso"

# clean up when we're done no matter wat
cleanup() {
    echo "Run this command to remove all the temp files:"
    echo /bin/rm -rv "${WORKDIR}"
}
# traps exits, SIGINT and SIGTERM
trap cleanup EXIT INT TERM

# downloads
download_iso() { curl -OJL "${ISO_URL}" }
download_checksums() { 
    curl -OJL "${BASE_URL}/SHA256SUMS"
    curl -OJL "${BASE_URL}/SHA256SUMS.gpg"
}

verify_files() {
    gpg --keyserver hkp://keyserver.ubuntu.com --recv-keys 0xFBB75451 0xEFE21092
    gpg --verify SHA256SUMS.gpg SHA256SUMS

    # probably a better way to do this
    sha256sum -c SHA256SUMS 2>&1 | grep OK
}

unpack_iso() {
    if [ `uname` = "Darwin"]; then
        # macOS mount
        # https://unix.stackexchange.com/questions/298685/can-a-mac-mount-a-debian-install-cd
        hdiutil attach -nomount ubuntu-${UBUNTU_RELEASE}.${PATCH_NUMBER}-server-amd64.iso
    else
        # linux mount
        # mount -o loop "ubuntu-${UBUNTU_RELEASE}.${PATCH_NUMBER}-server-amd64.iso" "${ISO_MOUNT_DIR}"
        # TODO: dynamically grab the disk that was attached
        mount -t cd9660 /dev/disk2 "${ISO_MOUNT_DIR}"
    fi

    # copy iso contents
    sudo cp -R "${ISO_MOUNT_DIR}" "${CDIMAGE_DIR}"

    if [ `uname` = "Darwin"]; then
        # macOS unmount
        umount /dev/disk2
        hdiutil detach /dev/disk2
    else
        # linux umount
        # umount "${ISO_MOUNT_DIR}"
    fi
}

edit_bootloader() {
    # set timeout to 1s
    sudo sed -i '' -e 's/^timeout 300/timeout 10/' cdimage/isolinux/isolinux.cfg
    # set default to the LABEL nuc
    sudo sed -i '' -e 's/^default.*/default nuc/' cdimage/isolinux/isolinux.cfg
    # add LABEL nuc
    sudo tee -a cdimage/isolinux/isolinux.cfg <<EOF
LABEL nuc
  menu label ^NUC installation (preseed)
  kernel /install/vmlinuz
  append auto file=/cdrom/preseed/nuc.seed console-setup/ask_detect=false console-setup/layoutcode=us console-setup/modelcode=pc105 debconf/frontend=noninteractive debian-installer=en_US grub-installer/bootdev=/dev/sda fb=false initrd=/install/initrd.gz ramdisk_size=16384 root=/dev/ram rw kbd-chooser/method=us keyboard-configuration/layout=USA keyboard-configuration/variant=USA locale=en_US netcfg/get_domain=vm netcfg/get_hostname=packer noapic --
EOF
}
copy_preseed() {
    sudo cp ../preseed.cfg cdimage/preseed/nuc.seed
}

repack_iso() {
    sudo mkisofs -r -V "Ubuntu for NUCs" \
            -cache-inodes \
            -J -l -b isolinux/isolinux.bin \
            -c isolinux/boot.cat -no-emul-boot \
            -boot-load-size 4 -boot-info-table \
            -o ${CUSTOM_ISO_PATH} ${CDIMAGE_DIR}
}

########################
# THIS IS THE ORDER OF OPERATIONS
# enter temp dir
cd "${WORKDIR}"

download_iso
verify_files

# following https://help.ubuntu.com/community/InstallCDCustomization
unpack_iso

copy_preseed
edit_bootloader
repack_iso

# we done
exit 0
