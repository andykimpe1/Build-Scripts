
# Written and placed in public domain by Jeffrey Walton
# This script builds FFMPEG and its dependencies from sources.

FFMPEG_VER=4.4.6
FFMPEG_XZ=ffmpeg_${FFMPEG_VER}.orig.tar.xz
FFMPEG_DIR=ffmpeg-${FFMPEG_VER}
PKG_NAME=ffmpeg

###############################################################################

# Get the environment as needed.
if [[ "${SETUP_ENVIRON_DONE}" != "yes" ]]; then
    if ! source ${INSTX_TOPDIR}/setup-environ.sh
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
    if ! source ${INSTX_TOPDIR}/setup-password.sh
    then
        echo "Failed to process password"
        exit 1
    fi
fi

###############################################################################

chmod +x ./*.sh
if ! ${INSTX_TOPDI${INSTX_TOPDIR}/build/build-nasm.sh
then
    echo "Failed to build nasm"
    exit 1
fi

###############################################################################

if ! ${INSTX_TOPDI${INSTX_TOPDIR}/build/build-yasm.sh
then
    echo "Failed to build yasm"
    exit 1
fi

###############################################################################

if ! ${INSTX_TOPDI${INSTX_TOPDIR}/build/build-x264.sh
then
    echo "Failed to build x264"
    exit 1
fi

###############################################################################

if ! ${INSTX_TOPDI${INSTX_TOPDIR}/build/build-x265.sh
then
    echo "Failed to build x265"
    exit 1
fi

###############################################################################

if ! ${INSTX_TOPDI${INSTX_TOPDIR}/build/build-idn2.sh
then
    echo "Failed to build IDN2"
    exit 1
fi

###############################################################################

if ! ${INSTX_TOPDI${INSTX_TOPDIR}/build/build-libexpat.sh
then
    echo "Failed to build Expat"
    exit 1
fi

###############################################################################

if ! ${INSTX_TOPDI${INSTX_TOPDIR}/build/build-nettle.sh
then
    echo "Failed to build Nettle"
    exit 1
fi

###############################################################################

if ! ${INSTX_TOPDI${INSTX_TOPDIR}/build/build-unbound.sh
then
    echo "Failed to build Unbound"
    exit 1
fi

###############################################################################

if ! ${INSTX_TOPDI${INSTX_TOPDIR}/build/build-p11kit.sh
then
    echo "Failed to build P11-Kit"
    exit 1
fi

###############################################################################

if [[ ! -f "${INSTX_PREFIX}/bin/xz" ]]
then
    if ! ${INSTX_TOPDI${INSTX_TOPDIR}/build/build-xz.sh
    then
        echo "Failed to build XZ"
        exit 1
    fi
fi

###############################################################################

if [[ "${IS_LINUX}" -eq 1 ]]
then
    if ! ${INSTX_TOPDI${INSTX_TOPDIR}/build/build-datefudge.sh
    then
        echo "Failed to build datefudge"
        exit 1
    fi
fi

###############################################################################

echo ""
echo "========================================"
echo "================ FFMPEG ================"
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
echo "ffmpeg 4.4.6..."

if ! "${WGET}" -q -O "$FFMPEG_XZ" \
     "https://launchpad.net/~savoury1/+archive/ubuntu/ffmpeg4/+sourcefiles/ffmpeg/7:4.4.6-0ubuntu1~22.04.sav2/$FFMPEG_XZ"
then
    echo "Failed to download ffmpeg"
    exit 1
fi

tar -xvf "$FFMPEG_XZ"
cd "$FFMPEG_DIR"

# Patches are created with 'diff -u' from the pkg root directory.
if [[ -e ${INSTX_TOPDIR}/build/build/ffmpeg.patch ]]; then
    echo ""
    echo "**********************"
    echo "Patching package"
    echo "**********************"

    patch -u -p0 < ${INSTX_TOPDIR}/build/build/ffmpeg.patch
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
    PKG_CONFIG_PATH="${INSTX_PKGCONFIG}" \
    CPPFLAGS="${INSTX_CPPFLAGS}" \
    ASFLAGS="${INSTX_ASFLAGS}" \
    LIBS="${INSTX_LDLIBS}" \
./configure \
    --prefix="${INSTX_PREFIX}" \
    --libdir="${INSTX_LIBDIR}" \
    --pkg-config-flags="--static" \
    --extra-cflags="-I/opt/ffmpeg4/include" \
    --extra-ldflags="-L/opt/ffmpeg4/lib" \
    --extra-libs="-lpthread -lm" \
    --ld="g++" \
    --bindir="/opt/ffmpeg4/bin" \
    --libdir="/opt/ffmpeg4/lib" \
    --enable-libx264 \
    --enable-libx265 \
    --enable-gpl \
    --enable-gnutls \
    --enable-libfreetype \
    --enable-nonfree

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
    echo "Failed to build ffmpeg"
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
    echo "Installing anyways..."
    echo "**********************"

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
    printf "%s\n" "${SUDO_PASSWORD}" | sudo ${SUDO_ENV_OPT} -S bash "${INSTX_TOPDIR}/copy-sources.sh" "${PWD}" "${INSTX_SRCDIR}/${FFMPEG_DIR}"
else
    "${MAKE}" "${MAKE_FLAGS[@]}"
    bash "${INSTX_TOPDIR}/fix-permissions.sh" "${INSTX_PREFIX}"
    bash "${INSTX_TOPDIR}/copy-sources.sh" "${PWD}" "${INSTX_SRCDIR}/${FFMPEG_DIR}"
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
    ARTIFACTS=("$FFMPEG_XZ" "$FFMPEG_TAR" "$FFMPEG_DIR")
    for artifact in "${ARTIFACTS[@]}"; do
        rm -rf "$artifact"
    done
fi

exit 0
