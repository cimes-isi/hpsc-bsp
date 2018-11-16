The "hpsc-bsp" repository includes the "yocto_hpsc.sh" script, which first downloads the Yocto BSP software and the necessary meta-layers for the HPSC Chiplet.  The script then uses the Yocto framework to build the necessary files for running the QEMU emulation of the Chiplet.  In the process, it downloads the necessary source code from the ISI Github webpage.  Note the user can specify which version of each repo should be downloaded within the script.

Here is the sequence of steps for configuring and performing the build:
     1.  Verify that your system has python3 installed, which is needed to run bitbake.
     2.  Verify that the desired version of each repository will be used for the build.  This can be done by modifying the appropriate SRCREV_* environment variables listed in yocto_hpsc.sh.  Currently, the script uses the HEAD of the hpsc branch for each of the github repositories, but this can be changed.
     3.  Begin the build process by executing the following:
     	 > sh yocto_hpsc.sh

After the build completes, the QEMU executable is located in:
poky/build/tmp/work/x86_64-linux/qemu-native/2.11.1-r0/image/usr/local/bin

In addition, several of the other needed files are located in the following directory:
poky/build/tmp/deploy/images/zcu102-zynqmp

Specifically, the above directory includes the following generated files:
1.  arm-trusted-firmware.elf
	- The Arm Trusted Firmware binary
2.  core-image-minimal-zcu102-zynqmp.cpio.gz.u-boot
	- The Linux root file system for booting the dual A53 cluster
3.  Image
	- The Linux kernel binary image
4.  zynqmp-zcu102.dtb
	- The Chiplet device tree for SMP Linux
5.  qemu-hw-devicetrees/hpsc.dtb
	- The HPSC Chiplet device tree for QEMU
6.  u-boot.elf
	- The U-boot bootloader for the dual A53 cluster

The actual build directories for these files are located in the directory:
poky/build/tmp/work

The Yocto BSP is designed to download from the github repositories located at:
https://github.com/orgs/ISI-apex/teams/hpsc/repositories

Finally, after the build completes, the user can run the "run-qemu.sh" script (with some additional files that need to be built manually) in order to boot QEMU.