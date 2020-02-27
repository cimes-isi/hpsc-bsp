#!/bin/bash

ECLIPSE_VERSION=2018-09
export WGET_OUTPUT="eclipse-cpp-${ECLIPSE_VERSION}-linux-gtk-x86_64.tar.gz"
export WGET_URL="https://www.eclipse.org/downloads/download.php?file=/technology/epp/downloads/release/${ECLIPSE_VERSION}/R/${WGET_OUTPUT}&r=1"
export WGET_OUTPUT_MD5="6087e4def4382fd334de658f9bde190b"

export DO_BUILD_OUT_OF_SOURCE=1

# Required b/c there aren't any version-specific repositories available
ECLIPSE_REPO_VER_GNU_MCU=4.5.1-201901011632
ECLIPSE_REPO_ZIP_GNU_MCU=ilg.gnumcueclipse.repository-${ECLIPSE_REPO_VER_GNU_MCU}.zip
ECLIPSE_REPO_SHA_GNU_MCU=bcac8d27b88989f021cd72ce900055e57cc395a3848baa805a27005d07060b14
ECLIPSE_REPO_URL_GNU_MCU=https://github.com/gnu-mcu-eclipse/eclipse-plugins/releases/download/v${ECLIPSE_REPO_VER_GNU_MCU}/${ECLIPSE_REPO_ZIP_GNU_MCU}

# Eclipse update sites
# Use version-specific repos to prevent breakage when newer plugin versions are
# released to the main update sites (the ones usually documented for users).
# This obviously requires providers to make version-specific sites available.
# You may have to dig around a bit to find the correct URLs.
ECLIPSE_REPOSITORIES=(
    "http://download.eclipse.org/tm/updates/4.5.0/repository/"
    # TODO: This path is tied to the build system --> not portable!
    #       Can't seem to get relative paths working
    #       Should we deploy the archive instead and let users add local repo?
    # "jar:file:${REC_SRC_DIR}/${ECLIPSE_REPO_ZIP_GNU_MCU}!/" # "http://gnu-mcu-eclipse.netlify.com/v4-neon-updates/"
    "http://downloads.yoctoproject.org/releases/eclipse-plugin/2.6.1/oxygen"
    "http://download.eclipse.org/linuxtools/update-7.1.0"
)

# Plugins to install
ECLIPSE_PLUGIN_IUS=(
    org.yocto.doc.feature.group/1.4.1.201901082310
    org.yocto.sdk.feature.group/1.4.1.201901082311
    # ilg.gnumcueclipse.core/4.5.1.201901011632
    # ilg.gnumcueclipse.managedbuild.cross.arm/2.6.4.201901011632
    # ilg.gnumcueclipse.debug.core/1.2.2.201901011632
    # ilg.gnumcueclipse.templates.cortexm.feature.feature.group/1.4.4.201901011632
    org.eclipse.linuxtools.perf.feature.feature.group/7.1.0.201812121718
    org.eclipse.linuxtools.perf.remote.feature.feature.group/7.1.0.201812121718
    org.eclipse.linuxtools.perf.feature.source.feature.group/7.1.0.201812121718
    org.eclipse.linuxtools.perf.remote.feature.source.feature.group/7.1.0.201812121718
    org.eclipse.linuxtools.profiling.feature.group/7.1.0.201812121718
    org.eclipse.linuxtools.profiling.remote.feature.group/7.1.0.201812121718
    org.eclipse.linuxtools.profiling.source.feature.group/7.1.0.201812121718
    org.eclipse.linuxtools.profiling.remote.source.feature.group/7.1.0.201812121718
)

ECLIPSE_DIR=eclipse
ECLIPSE_HPSC=hpsc-${WGET_OUTPUT}

DEPLOY_DIR=sdk
DEPLOY_ARTIFACTS=("$ECLIPSE_HPSC")

function eclipse_repos_fetch_local()
{
    env_maybe_wget "$ECLIPSE_REPO_URL_GNU_MCU" \
                   "$ECLIPSE_REPO_ZIP_GNU_MCU" || return $?
    env_check_sha256sum "$ECLIPSE_REPO_ZIP_GNU_MCU" \
                        "$ECLIPSE_REPO_SHA_GNU_MCU"
}

function eclipse_p2_install_ius()
{
    # Get repos and IUs as comma-delimited lists
    local ECLIPSE_REPOSITORY_LIST
    ECLIPSE_REPOSITORY_LIST=$(printf ",%s" "${ECLIPSE_REPOSITORIES[@]}")
    ECLIPSE_REPOSITORY_LIST=${ECLIPSE_REPOSITORY_LIST:1}
    local ECLIPSE_PLUGIN_IU_LIST
    ECLIPSE_PLUGIN_IU_LIST=$(printf ",%s" "${ECLIPSE_PLUGIN_IUS[@]}")
    ECLIPSE_PLUGIN_IU_LIST=${ECLIPSE_PLUGIN_IU_LIST:1}
    "$ECLIPSE_DIR/eclipse" -application org.eclipse.equinox.p2.director \
                           -nosplash \
                           -repository "$ECLIPSE_REPOSITORY_LIST" \
                           -installIUs "$ECLIPSE_PLUGIN_IU_LIST"
}

function do_post_fetch()
{
    # Fetch versioned archives for repos that don't have versioned update sites
    echo "hpsc-eclipse: fetching local plugin archives..."
    eclipse_repos_fetch_local || return $?

    # Always re-create the eclipse directory and re-fetch plugins.
    # This avoids problems when plugins are incrementally upgraded or removed.
    # We could handle the upgrade case, but there's a non-trivial likelihood of
    # subtle/unforeseen issues, so just keep it simple and solve both problems.
    echo "hpsc-eclipse: removing old eclipse directory..."
    rm -rf "$ECLIPSE_DIR"

    # Extract eclipse
    echo "hpsc-eclipse: extracting archive..."
    tar -xzf "$WGET_OUTPUT" || return $?

    # Fetch additional plugins
    echo "hpsc-eclipse: fetching plugins..."
    eclipse_p2_install_ius
}

function do_undeploy()
{
    undeploy_artifacts "$DEPLOY_DIR" "${DEPLOY_ARTIFACTS[@]}"
}

function do_build()
{
    # Create distribution archive
    echo "hpsc-eclipse: creating HPSC eclipse distribution: $ECLIPSE_HPSC"
    tar -czf "$ECLIPSE_HPSC" -C "$REC_SRC_DIR" "$ECLIPSE_DIR"
}

function do_deploy()
{
    deploy_artifacts "$DEPLOY_DIR" "${DEPLOY_ARTIFACTS[@]}"
}
