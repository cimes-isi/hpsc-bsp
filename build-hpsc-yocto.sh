#!/bin/bash

# The following SRCREV_* env vars allow the user to specify the commit hash or
# tag (e.g. 'hpsc-0.9') that will be checked out for each of the repositories
# below.  Alternatively, the user can specify "\${AUTOREV}" to check out the
# head of the hpsc branch.
export SRCREV_atf="\${AUTOREV}"
export SRCREV_linux_hpsc="\${AUTOREV}"
export SRCREV_qemu_devicetrees="\${AUTOREV}"
export SRCREV_qemu="\${AUTOREV}"
export SRCREV_u_boot="\${AUTOREV}"
# BB_ENV_EXTRAWHITE allows additional variables to pass through from
# the external environment into Bitbake's datastore
export BB_ENV_EXTRAWHITE="$BB_ENV_EXTRAWHITE \
                          SRCREV_atf \
                          SRCREV_linux_hpsc \
                          SRCREV_qemu_devicetrees \
                          SRCREV_qemu \
                          SRCREV_u_boot"

# Yocto configurations like hostname and additional packages to install
MACHINE_NAME="hpsc-chiplet"
YOCTO_INSTALL=(gdb gdbserver
               libc-staticdev
               libgomp libgomp-dev libgomp-staticdev
               libstdc++
               mpich
               mtd-utils
               openssh openssh-sftp-server
               python-core python-numpy
               util-linux
               watchdog)


# Script options
ACTION=$1
if [ -z "$ACTION" ]; then
    ACTION="all"
else
    case "$ACTION" in
        "all" |\
        "fetchall" |\
        "populate_sdk" |\
        "taskexp")
            ;;
        *)
            echo "Usage: $0 [ACTION]"
            echo "  where ACTION is one of:"
            echo "    all: (default) download source code and create all of the Yocto-generated files including kernel image and rootfs"
            echo "    fetchall: download source code to 'downloads' folder and then stop"
            echo "    populate_sdk: download source code, then build cross-compiler toolchain installer"
            echo "    taskexp: after the previous builds have completed, run the task dependency explorer"
            exit 1
    esac
fi

# Checkout repository if not already done, always pull branch/tag
# $1 = repository name, $2 = branch/tag name
function isi_github_pull()
{
    local repo=$1
    local brtag=$2
    echo "Pulling repository=$repo, branch/tag=$brtag"
    if [ ! -d "$repo" ]; then
        git clone "https://github.com/ISI-apex/$repo.git"
    fi
    cd "$repo"
    # `git pull origin "$brtag"` is causing conflicts...?
    git checkout "$brtag"
    git pull
    cd ..
}

# download the yocto poky git repository
isi_github_pull poky hpsc
cd poky
POKY_DIR=${PWD}

# add the meta-hpsc layer
if [ "${SRCREV_linux_hpsc}" == "hpsc-0.9" ]; then
    isi_github_pull "meta-hpsc" "hpsc-0.9"
else
    isi_github_pull "meta-hpsc" "hpsc"
fi
# add the meta-openembedded layer (for the mpich package)
isi_github_pull "meta-openembedded" "hpsc"
BITBAKE_LAYERS=("meta-hpsc/meta-xilinx-bsp"
                "meta-openembedded/meta-oe"
                "meta-openembedded/meta-python")

# create build directory and configure it
. ./oe-init-build-env build
for layer in "${BITBAKE_LAYERS[@]}"; do
    bitbake-layers add-layer "${POKY_DIR}/$layer"
done
# TODO: Don't keep appending to file, replace text that's already been modified?
{
    printf "\nMACHINE = \"%s\"" "${MACHINE_NAME}"
    printf "\nCORE_IMAGE_EXTRA_INSTALL = \"%s\"\n" "${YOCTO_INSTALL[*]}"
} >> conf/local.conf

# finally, execute the requested action
case "$ACTION" in
    "all")
        bitbake core-image-minimal
        ;;
    "fetchall")
        bitbake core-image-minimal -c fetchall
        ;;
    "populate_sdk")
        bitbake core-image-minimal -c populate_sdk
        ;;
    "taskexp")
        bitbake -u taskexp -g core-image-minimal
        ;;
    *)
        echo "Unknown ACTION"
        exit 1
esac
