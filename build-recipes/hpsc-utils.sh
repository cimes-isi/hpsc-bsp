#!/bin/bash

export GIT_REPO="https://github.com/ISI-apex/hpsc-utils.git"
export GIT_REV=90e19f673e5e30fd7da0343db6f56262f52521f7
export GIT_BRANCH="hpsc"

export DEPENDS_ENVIRONMENT="hpsc-yocto-hpps" # exports YOCTO_HPPS_SDK

DEPLOY_DIR_1=BSP/host-utils
DEPLOY_ARTIFACTS_1=(
    host/qemu-nand-creator
    host/sram-image-utils
)
DEPLOY_DIR_2=BSP/aarch64-poky-linux-utils
DEPLOY_ARTIFACTS_2=(
    linux/mboxtester
    linux/rtit-tester
    linux/shm-standalone-tester
    linux/shm-tester
    linux/wdtester
)

function do_undeploy()
{
    undeploy_artifacts "$DEPLOY_DIR_1" "${DEPLOY_ARTIFACTS_1[@]}"
    undeploy_artifacts "$DEPLOY_DIR_2" "${DEPLOY_ARTIFACTS_2[@]}"
}

function do_build()
{
    for s in host linux; do
        (
            echo "hpsc-utils: $s: build"
            if [ "$s" == "linux" ]; then
                echo "hpsc-utils: source poky environment"
                ENV_check_yocto_hpps_sdk
                source "${YOCTO_HPPS_SDK}/environment-setup-aarch64-poky-linux"
                unset LDFLAGS
            fi
            make_parallel -C "$s"
        )
    done
}

function do_deploy()
{
    deploy_artifacts "$DEPLOY_DIR_1" "${DEPLOY_ARTIFACTS_1[@]}"
    deploy_artifacts "$DEPLOY_DIR_2" "${DEPLOY_ARTIFACTS_2[@]}"
}
