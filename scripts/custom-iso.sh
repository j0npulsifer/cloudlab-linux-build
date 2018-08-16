#!/usr/bin/env bash
set -eu

# run as root check
! [ "$(id -u)" = "0" ] && { echo "Please run this script as root"; exit 1; }
# macos check
! [ "$(uname)" = "Darwin" ] && { echo "This script works on macOS only sry bout that"; exit 1; }
# dependencies
command -v gpg >/dev/null || { echo "Can not find gpg. Please run: brew install gpg"; exit 1; }
command -v mkisofs >/dev/null || { echo "Can not find mkisofs. Please run: brew install cdrtools"; exit 1; }

# where we build
WORKDIR="build"
ISO_MOUNT_DIR="mount"
CD_IMAGE_DIR="cd-image"
# create the dirs
mkdir -p "${WORKDIR}" "${WORKDIR}/${ISO_MOUNT_DIR}" "${WORKDIR}/${CD_IMAGE_DIR}"

#### CHANGE ME ####
# this is where you want the custom iso to end up
CUSTOM_ISO_PATH="fresh.iso"

# ubuntu iso and checksum
UBUNTU_VERSION="16.04"
PATCH_VERSION="5"
# XENIAL BASEURL
BASE_URL="http://releases.ubuntu.com/${UBUNTU_VERSION}"
# BIONIC BASEURL
# BASE_URL="http://cdimage.ubuntu.com/releases/${UBUNTU_VERSION}/release"
ISO_URL="${BASE_URL}/ubuntu-${UBUNTU_VERSION}.${PATCH_VERSION}-server-amd64.iso"

# clean up when we're done no matter wat
cleanup() {
    # only unmount if there is an error
    [ $? -gt 0 ] && unmount_iso "${ATTACHED_DISK}"
    echo "Run this command to remove all the temp files:"
    echo /bin/rm -rv "${WORKDIR}"
}
# traps exits, SIGINT and SIGTERM
trap cleanup EXIT INT TERM

# downloads
download_iso() { 
    curl -OJL "${ISO_URL}"
}

download_checksums() { 
    curl -OJL "${BASE_URL}/SHA256SUMS"
    curl -OJL "${BASE_URL}/SHA256SUMS.gpg"
}

verify_files() {
    gpg --keyserver hkp://keyserver.ubuntu.com --recv-keys 0xFBB75451 0xEFE21092
    gpg --verify SHA256SUMS.gpg SHA256SUMS

    # probably a better way to do this
    shasum -a 256 -c SHA256SUMS 2>&1 | grep OK
}

unpack_iso() {
    # macOS mount
    # https://unix.stackexchange.com/questions/298685/can-a-mac-mount-a-debian-install-cd
    ATTACHED_DISK=$(hdiutil attach -nomount "ubuntu-${UBUNTU_VERSION}.${PATCH_VERSION}-server-amd64.iso" | head -n 1 | awk '{print $1}')
    mount -t cd9660 "${ATTACHED_DISK}" "${ISO_MOUNT_DIR}"

    # copy iso contents
    rsync -av "${ISO_MOUNT_DIR}" "${CD_IMAGE_DIR}"

    unmount_iso "${ATTACHED_DISK}"
}

unmount_iso() {
    [ -z "$1" ] && { echo "Something went awry"; exit 1; }
    umount "$1"
    hdiutil detach "$1"
}

edit_bootloader() {
    # set timeout to 1s
    sed -i '' -e 's/^timeout 300/timeout 10/' ${CD_IMAGE_DIR}/${ISO_MOUNT_DIR}/isolinux/isolinux.cfg
    # set default to the LABEL nuc
    sed -i '' -e 's/^default.*/default nuc/' ${CD_IMAGE_DIR}/${ISO_MOUNT_DIR}/isolinux/isolinux.cfg
    # add LABEL nuc
    tee -a ${CD_IMAGE_DIR}/${ISO_MOUNT_DIR}/isolinux/isolinux.cfg <<EOF
LABEL nuc
  menu label ^NUC installation (preseed)
  kernel /install/vmlinuz
  append auto file=/cdrom/preseed/nuc.seed console-setup/ask_detect=false console-setup/layoutcode=us console-setup/modelcode=pc105 debconf/frontend=noninteractive debian-installer=en_US grub-installer/bootdev=/dev/sda fb=false initrd=/install/initrd.gz ramdisk_size=16384 root=/dev/ram rw kbd-chooser/method=us keyboard-configuration/layout=USA keyboard-configuration/variant=USA locale=en_US netcfg/get_domain=vm netcfg/get_hostname=packer noapic --
EOF
}
copy_preseed() {
    cp ../preseed.cfg ${CD_IMAGE_DIR}/${ISO_MOUNT_DIR}/preseed/nuc.seed
}

repack_iso() {
    mkisofs -r -V "Ubuntu ${UBUNTU_VERSION} preseed" \
            -cache-inodes \
            -J -l -b isolinux/isolinux.bin \
            -c isolinux/boot.cat -no-emul-boot \
            -boot-load-size 4 -boot-info-table \
            -o "${CUSTOM_ISO_PATH}" "${CD_IMAGE_DIR}/${ISO_MOUNT_DIR}"
}

########################
# THIS IS THE ORDER OF OPERATIONS
# enter temp dir
cd "${WORKDIR}"

# download and verify
download_iso
download_checksums
verify_files

# following https://help.ubuntu.com/community/InstallCDCustomization
unpack_iso
copy_preseed
edit_bootloader
repack_iso

# we done
exit 0
