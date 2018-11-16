#!/bin/bash

# The following SRCREV_* env vars allow the user to specify the commit hash or
# tag (e.g. 'hpsc-0.9') that will be checked out for each of the repositories
# below.  Alternatively, the user can specify '${AUTOREV}' to check out the
# head of the hpsc branch.
export SRCREV_atf='${AUTOREV}'
export SRCREV_linux_hpsc='${AUTOREV}'
export SRCREV_qemu_devicetrees='${AUTOREV}'
export SRCREV_qemu='${AUTOREV}'
export SRCREV_u_boot='${AUTOREV}'

# BB_ENV_EXTRAWHITE allows additional variables to pass through from
# the external environment into Bitbake's datastore
export BB_ENV_EXTRAWHITE="$BB_ENV_EXTRAWHITE SRCREV_atf SRCREV_linux_hpsc SRCREV_qemu_devicetrees SRCREV_qemu SRCREV_u_boot"

# download the yocto poky git repository
git clone -b hpsc https://github.com/ISI-apex/poky.git
cd poky
POKY_DIR=${PWD}

# add the meta-hpsc layer
if [ "${SRCREV_linux_hpsc}" = 'hpsc-0.9' ]
then
    git clone -b hpsc-0.9 https://github.com/ISI-apex/meta-hpsc.git
else
    git clone -b hpsc https://github.com/ISI-apex/meta-hpsc.git
fi

# add the meta-openembedded layer (for the mpich package)
git clone -b hpsc https://github.com/ISI-apex/meta-openembedded.git

# create build directory and configure it
. ./oe-init-build-env build
bitbake-layers add-layer ${POKY_DIR}/meta-hpsc/meta-xilinx-bsp
bitbake-layers add-layer ${POKY_DIR}/meta-openembedded/meta-oe
cd conf
printf "\nMACHINE = \"hpsc-chiplet\"" >> local.conf
printf "\nIMAGE_INSTALL_append = \" libgomp libgomp-dev libgomp-staticdev mpich libc-staticdev gdb gdbserver openssh openssh-sftp-server libstdc++ util-linux watchdog mtd-utils\"\n" >> local.conf
cd ..

# One or more of the following options should be enabled to start the download and/or build

# Option #1- run bitbake to download source code to "downloads" folder and then stop
#bitbake core-image-minimal -c fetchall

# Option #2- run bitbake to download source code, then create all of the Yocto-generated files including kernel image and rootfs
bitbake core-image-minimal

# Option #3- run bitbake to download source code, then build cross-compiler toolchain installer
#bitbake core-image-minimal -c populate_sdk


# after the previous builds have completed, run the task dependency explorer
#bitbake -u taskexp -g core-image-minimal