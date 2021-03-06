#!/bin/bash

export GIT_REPO="https://github.com/ISI-apex/hpsc-baremetal.git"
export GIT_REV=53b778f861e91934613b8d94e27cfd6fd0f48175
export GIT_BRANCH=hpsc

export DEPENDS_ENVIRONMENT="sdk/gcc-arm-none-eabi"

DEPLOY_DIR=ssw/trch
DEPLOY_ARTIFACTS=(
    trch/bld/trch.bin
    trch/bld/trch.elf
    trch-bl0/bld/trch-bl0.elf
    trch/syscfg-schema.json
)

function do_undeploy()
{
    undeploy_artifacts "$DEPLOY_DIR" "${DEPLOY_ARTIFACTS[@]}"
}

function do_build()
{
    ENV_check_bm_toolchain || return $?
    make_parallel CROSS_COMPILE=arm-none-eabi-
}

function do_deploy()
{
    deploy_artifacts "$DEPLOY_DIR" "${DEPLOY_ARTIFACTS[@]}"
}
