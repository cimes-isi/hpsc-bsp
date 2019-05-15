#!/bin/bash

export GIT_REPO="https://github.com/ISI-apex/hpsc-baremetal.git"
export GIT_REV=8a58cb868ac9683d46b2d692fff6ffb24fb847bb
export GIT_BRANCH="hpsc"

export DEPENDS_ENVIRONMENT="sdk/gcc-arm-none-eabi"

DEPLOY_DIR=ssw/trch
DEPLOY_ARTIFACTS=(
    trch/bld/trch.elf
    trch/syscfg-schema.json
)

function do_undeploy()
{
    undeploy_artifacts "$DEPLOY_DIR" "${DEPLOY_ARTIFACTS[@]}"
}

function do_build()
{
    ENV_check_bm_toolchain
    make_parallel CROSS_COMPILE=arm-none-eabi-
}

function do_deploy()
{
    deploy_artifacts "$DEPLOY_DIR" "${DEPLOY_ARTIFACTS[@]}"
}
