#!/usr/bin/env bash

# Written and placed in public domain by Jeffrey Walton
# This script builds FFMPEG and its dependencies from sources.

X264_VER=stable
X264_XZ=x264_${X264_VER}.orig.tar.xz
X264_DIR=x264-${X264_VER}
PKG_NAME=x264

###############################################################################

# Get the environment as needed.
if [[ "${SETUP_ENVIRON_DONE}" != "yes" ]]; then
    if ! source ./setup-environ.sh
    then
        echo "Failed to set environment"
        exit 1
    fi
fi

if [[ -e "${INSTX_PKG_CACHE}/${PKG_NAME}" ]]; then
    echo ""
    echo "$PKG_NAME is already installed."
    exit 0
fi

# The password should die when this subshell goes out of scope
if [[ "${SUDO_PASSWORD_DONE}" != "yes" ]]; then
    if ! source ./setup-password.sh
    then
        echo "Failed to process password"
        exit 1
    fi
fi

###############################################################################

chmod +x ./*.sh
if ! ./build-git.sh
then
    echo "Failed to build git"
    exit 1
fi

###############################################################################

if ! ./build-yasm.sh
then
    echo "Failed to build yasm"
    exit 1
fi

###############################################################################

if ! ./build-base.sh
then
    echo "Failed to build GNU base packages"
    exit 1
fi

###############################################################################

if ! ./build-libtasn1.sh
then
    echo "Failed to build libtasn1"
    exit 1
fi

###############################################################################

if ! ./build-idn2.sh
then
    echo "Failed to build IDN2"
    exit 1
fi

###############################################################################

if ! ./build-libexpat.sh
then
    echo "Failed to build Expat"
    exit 1
fi

###############################################################################

if ! ./build-nettle.sh
then
    echo "Failed to build Nettle"
    exit 1
fi

###############################################################################

if ! ./build-unbound.sh
then
    echo "Failed to build Unbound"
    exit 1
fi

###############################################################################

if ! ./build-p11kit.sh
then
    echo "Failed to build P11-Kit"
    exit 1
fi

###############################################################################

if [[ ! -f "${INSTX_PREFIX}/bin/xz" ]]
then
    if ! ./build-xz.sh
    then
        echo "Failed to build XZ"
        exit 1
    fi
fi

###############################################################################

if [[ "${IS_LINUX}" -eq 1 ]]
then
    if ! ./build-datefudge.sh
    then
        echo "Failed to build datefudge"
        exit 1
    fi
fi

###############################################################################

echo ""
echo "========================================"
echo "================ X265 ================"
echo "========================================"

if [[ -z "$(command -v datefudge 2>/dev/null)" ]]
then
    echo ""
    echo "datefudge not found. Some tests will be skipped."
    echo "To fix this issue, please install datefudge."
fi

echo ""
echo "**********************"
echo "Downloading package"
echo "**********************"

echo ""
echo "x264..."


git clone --branch stable --depth 1 https://code.videolan.org/videolan/x264.git "$X265_DIR"
cd "$X265_DIR"
wget -O x265.tar.bz2 https://bitbucket.org/multicoreware/x265_git/get/master.tar.bz2
tar xjvf x265.tar.bz2
cd multicoreware*/build/linux




# Patches are created with 'diff -u' from the pkg root directory.
if [[ -e ../patch/x265.patch ]]; then
    echo ""
    echo "**********************"
    echo "Patching package"
    echo "**********************"

    patch -u -p0 < ../patch/x265.patch
fi



echo ""
echo "**********************"
echo "Configuring package"
echo "**********************"

# We should probably include --disable-anon-authentication below
#    --enable-aom \
#    --enable-libass \
#    --enable-libdav1d \
#    --enable-libsvtav1 \
#    --enable-libfdk-aac \
#    --enable-libmp3lame \
#    --enable-libopus \
#    --enable-libvorbis \
#    --enable-libvpx \
#    --enable-libx264 \
#    --enable-libx265 \
PATH="${INSTX_PREFIX}/bin:$PATH" cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="${INSTX_PREFIX}" -DENABLE_SHARED=off ../../source


if [[ "$?" -ne 0 ]]; then
    echo ""
    echo "**************************"
    echo "Failed to configure ffmpeg"
    echo "**************************"
    exit 1
fi


echo ""
echo "**********************"
echo "Building package"
echo "**********************"

MAKE_FLAGS=("-j" "${INSTX_JOBS}" "V=1")
if ! "${MAKE}" "${MAKE_FLAGS[@]}"
then
    echo ""
    echo "**********************"
    echo "Failed to build x265"
    echo "**********************"

    bash "${INSTX_TOPDIR}/collect-logs.sh" "${PKG_NAME}"
    exit 1
fi

# Fix flags in *.pc files
bash "${INSTX_TOPDIR}/fix-pkgconfig.sh"

# Fix runpaths
bash "${INSTX_TOPDIR}/fix-runpath.sh"

echo ""
echo "**********************"
echo "Testing package"
echo "**********************"

MAKE_FLAGS=("check" "-k" "V=1")
if ! "${MAKE}" "${MAKE_FLAGS[@]}"
then
    echo ""
    echo "**********************"
    echo "Failed to test FFMPEG"
    echo "**********************"

    bash "${INSTX_TOPDIR}/collect-logs.sh" "${PKG_NAME}"
    # exit 1

    echo ""
    echo "**********************"
    echo "Installing anyways..."
    echo "**********************"
fi

# Fix runpaths again
bash "${INSTX_TOPDIR}/fix-runpath.sh"

echo ""
echo "**********************"
echo "Installing package"
echo "**********************"

MAKE_FLAGS=("install")
if [[ -n "${SUDO_PASSWORD}" ]]; then
    printf "%s\n" "${SUDO_PASSWORD}" | sudo ${SUDO_ENV_OPT} -S "${MAKE}" "${MAKE_FLAGS[@]}"
    printf "%s\n" "${SUDO_PASSWORD}" | sudo ${SUDO_ENV_OPT} -S bash "${INSTX_TOPDIR}/fix-permissions.sh" "${INSTX_PREFIX}"
    printf "%s\n" "${SUDO_PASSWORD}" | sudo ${SUDO_ENV_OPT} -S bash "${INSTX_TOPDIR}/copy-sources.sh" "${PWD}" "${INSTX_SRCDIR}/${x265_DIR}"
else
    "${MAKE}" "${MAKE_FLAGS[@]}"
    bash "${INSTX_TOPDIR}/fix-permissions.sh" "${INSTX_PREFIX}"
    bash "${INSTX_TOPDIR}/copy-sources.sh" "${PWD}" "${INSTX_SRCDIR}/${x265_DIR}"
fi

###############################################################################

echo ""
echo "*****************************************************************************"
echo "Please run Bash's 'hash -r' to update program cache in the current shell"
echo "*****************************************************************************"

###############################################################################

touch "${INSTX_PKG_CACHE}/${PKG_NAME}"

cd "${CURR_DIR}" || exit 1

###############################################################################

# Set to false to retain artifacts
if true;
then
    ARTIFACTS=("$X265_XZ" "$X265_TAR" "$X265_DIR")
    for artifact in "${ARTIFACTS[@]}"; do
        rm -rf "$artifact"
    done
fi

exit 0
