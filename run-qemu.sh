#!/bin/bash

# Note: Before running the following script, please make sure to:
# 1.  Run the "yocto_hpsc.sh" script with the "bitbake core-image-minimal"
#     option in order to generate the rest of the needed QEMU files.
#
# 2.  Build the following repositories, that are not part of Yocto build:
#     - TRCH baremetal firmware: Cortex-M4 repo
#     - RTPS baremetal firmware: Cortex-R52 repo
#     Once built, adjust the paths to the built artifacts below.

YOCTO_DEPLOY_DIR=${PWD}/poky/build/tmp/deploy/images/zcu102-zynqmp
YOCTO_QEMU_DIR=${PWD}/poky/build/tmp/work/x86_64-linux/qemu-xilinx-native/v2.8.1-xilinx-v2017.3+gitAUTOINC+3ccd3bdaa4-r0/image/usr/local/bin

ARM_TF_FILE=${YOCTO_DEPLOY_DIR}/arm-trusted-firmware.elf
ROOTFS_FILE=${YOCTO_DEPLOY_DIR}/core-image-minimal-zcu102-zynqmp.cpio.gz.u-boot
KERNEL_FILE=${YOCTO_DEPLOY_DIR}/Image
LINUX_DT_FILE=${YOCTO_DEPLOY_DIR}/hpsc.dtb
QEMU_DT_FILE=${YOCTO_DEPLOY_DIR}/qemu-hw-devicetrees/hpsc-arch.dtb
BL_FILE=${YOCTO_DEPLOY_DIR}/u-boot.elf # TODO: Check whether this has to be u-boot not u-boot.elf

# Not generated by Yocto, you have to build them manually, and point to the path
DEV_PATH=/home/user/dev/hpsc
TRCH_FILE=$DEV_PATH/Cortex-M4/src/dummy_firmware/trch.elf
RTPS_FILE=$DEV_PATH/Cortex-R52/startup_Cortex-R52/startup_Cortex-R52.axf

KERNEL_ADDR=0x80080000
LINUX_DT_ADDR=0x84000000
ROOTFS_ADDR=0x86000000

# See QEMU User Guide in HPSC release for explanation of the command line arguments
# NOTE: order of -device args may matter, must load ATF last, because loader also sets PC
#gdb --args \
${YOCTO_QEMU_DIR}/qemu-system-aarch64 \
	-machine arm-generic-fdt \
	-serial udp:192.168.239.1:4441@:4451 \
	-serial udp:192.168.239.1:4442@:4452 \
	-serial udp:192.168.239.1:4443@:4453 \
	-nographic \
	-s -D /tmp/qemu.log -d fdt,guest_errors,unimp,cpu_reset \
	-hw-dtb $QEMU_DT_FILE \
	-device loader,addr=$ROOTFS_ADDR,file=$ROOTFS_FILE,force-raw,cpu-num=3 \
	-device loader,addr=$LINUX_DT_ADDR,file=$LINUX_DT_FILE,force-raw,cpu-num=3 \
	-device loader,addr=$KERNEL_ADDR,file=$KERNEL_FILE,force-raw,cpu-num=3 \
	-device loader,file=$BL_FILE,cpu-num=3 \
	-device loader,file=$ARM_TF_FILE,cpu-num=3 \
	-device loader,file=$RTPS_FILE,cpu-num=2 \
	-device loader,file=$RTPS_FILE,cpu-num=1 \
	-device loader,file=$TRCH_FILE,cpu-num=0  \
        -net nic,vlan=0 -net user,vlan=0,hostfwd=tcp:127.0.0.1:2345-10.0.2.15:2345,hostfwd=tcp:127.0.0.1:10022-10.0.2.15:22 \
