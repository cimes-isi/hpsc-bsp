#!/bin/bash

export GIT_REPO="https://github.com/ISI-apex/hpsc-sdk-tools"
export GIT_REV=739bc168f8e5611a74e2f0968f85f0a637cf4cc2
export GIT_BRANCH="hpsc"

DEPLOY_DIR_1=BSP/host-utils
DEPLOY_ARTIFACTS_1=(
    bin/qemu-ifup.sh
    bin/qmp.py
    bin/cfgc
    bin/mkmemimg
    bin/qemu-nand-creator
    bin/sram-image-utils
    bin/merge-env
    bin/merge-map
    bin/merge-ini
    bin/launch-qemu
    bin/hpsc-objcopy
    bin/memstripe
    bin/miniconfig.sh
    bin/qemu-chardev-ptys
    bin/qmp-mem-wait
)

function do_undeploy()
{
    undeploy_artifacts "$DEPLOY_DIR_1" "${DEPLOY_ARTIFACTS_1[@]}"
}

function do_build()
{
    make_parallel -C bin
}

function do_deploy()
{
    deploy_artifacts "$DEPLOY_DIR_1" "${DEPLOY_ARTIFACTS_1[@]}"
}
