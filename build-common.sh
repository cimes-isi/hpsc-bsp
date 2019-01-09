#!/bin/bash
#
# Build scripts use this file to get build settings and for common functions.
#

# Assert that a string is not empty
function assert_str()
{
    if [ -z "$1" ]; then
        echo "String assertion failed!"
        exit 1
    fi
}

GIT_TAG_POKY=thud-20.0.0
# meta-openembedded doesn't tag releases, so we must choose a known revision
GIT_REV_META_OE=6094ae18c8a35e5cc9998ac39869390d7f3bb1e2

# Set git revisions to use - takes one argument, either "HEAD" or a tag name
function build_set_environment()
{
    local BUILD="$1"
    assert_str "$BUILD"
    if [ "$BUILD" == "HEAD" ]; then
        # Anything goes - read from the environment, otherwise use the latest
        export GIT_CHECKOUT_DEFAULT=${GIT_CHECKOUT_DEFAULT:-"hpsc"}
        export GIT_CHECKOUT_POKY=${GIT_CHECKOUT_POKY:-"$GIT_TAG_POKY"}
        export GIT_CHECKOUT_META_OE=${GIT_CHECKOUT_META_OE:-"$GIT_REV_META_OE"}
        # HPSC repositories built by poky
        # The following SRCREV_* env vars specify the commit hash or tag
        # (e.g. 'hpsc-0.9') that will be checked out for each repository.
        # Specify "\${AUTOREV}" to pull and use the head of the hpsc branch.
        export SRCREV_DEFAULT=${SRCREV_DEFAULT:-"\${AUTOREV}"}
        export SRCREV_atf=${SRCREV_atf:-"$SRCREV_DEFAULT"}
        export SRCREV_linux_hpsc=${SRCREV_linux_hpsc:-"$SRCREV_DEFAULT"}
        export SRCREV_u_boot=${SRCREV_u_boot:-"$SRCREV_DEFAULT"}
        # BB_ENV_EXTRAWHITE allows additional variables to pass through from
        # the external environment into Bitbake's datastore
        export BB_ENV_EXTRAWHITE="SRCREV_atf \
                                  SRCREV_linux_hpsc \
                                  SRCREV_u_boot"
        echo "Performing development build"
        echo "You may override the following environment variables:"
    else
        # Force git revisions for release
        export GIT_CHECKOUT_DEFAULT="$BUILD"
        export GIT_CHECKOUT_POKY="$GIT_TAG_POKY"
        export GIT_CHECKOUT_META_OE="$GIT_REV_META_OE"
        unset SRCREV_atf
        unset SRCREV_linux_hpsc
        unset SRCREV_u_boot
        unset BB_ENV_EXTRAWHITE
        echo "Performing release build"
        echo "The following environment variables are fixed:"
    fi
    echo "  GIT_CHECKOUT_DEFAULT = $GIT_CHECKOUT_DEFAULT"
    echo "  GIT_CHECKOUT_POKY    = $GIT_CHECKOUT_POKY"
    echo "  GIT_CHECKOUT_META_OE = $GIT_CHECKOUT_META_OE"
    echo "  SRCREV_DEFAULT       = $SRCREV_DEFAULT"
    echo "  SRCREV_atf           = $SRCREV_atf"
    echo "  SRCREV_linux_hpsc    = $SRCREV_linux_hpsc"
    echo "  SRCREV_u_boot        = $SRCREV_u_boot"
    echo ""

    #
    # If you need to pick specific revisions for individual repositories, edit
    # the values below.
    # In general, such changes should NOT be committed!
    #

    # Repositories used for poky and its layer configuration
    export GIT_CHECKOUT_META_HPSC="$GIT_CHECKOUT_DEFAULT"

    # Repositories not built by poky
    export GIT_CHECKOUT_BM="$GIT_CHECKOUT_DEFAULT"
    export GIT_CHECKOUT_UBOOT_R52="$GIT_CHECKOUT_DEFAULT"
    export GIT_CHECKOUT_HPSC_UTILS="$GIT_CHECKOUT_DEFAULT"
    export GIT_CHECKOUT_QEMU="$GIT_CHECKOUT_DEFAULT"
    export GIT_CHECKOUT_QEMU_DT="$GIT_CHECKOUT_DEFAULT"
}

# Clone repository if not already done, always pull and checkout
function git_clone_pull_checkout()
{
    local repo=$1
    local dir=$2
    local checkout=$3
    assert_str "$repo"
    assert_str "$dir"
    assert_str "$checkout"
    # Don't ask for credentials if requests are bad
    export GIT_TERMINAL_PROMPT=0 # for git > 2.3
    export GIT_ASKPASS=/bin/echo
    if [ ! -d "$dir" ]; then
        echo "$dir: fetch: $repo"
        git clone "$repo" "$dir" || return $?
    fi
    (
        cd "$dir" || return $?
        # in case remote URI changed
        git remote set-url origin "$repo"
        local is_detached=$(git status | grep -c detached)
        if [ "$is_detached" -eq 0 ]; then
            echo "$dir: pull: $repo"
            git pull origin "$checkout" || return $?
        fi
        echo "$dir: checkout: $checkout"
        git checkout "$checkout" || return $?
    )
}

function check_md5sum()
{
    local file=$1
    local md5_expected=$2
    assert_str "$file"
    assert_str "$md5_expected"
    local md5=$(md5sum "$file" | awk '{print $1}') || return $?
    if [ "$md5" != "$md5_expected" ]; then
        echo "md5sum mismatch for: $file"
        echo "  got: $md5"
        echo "  expected: $md5_expected"
        return 1
    fi
}
