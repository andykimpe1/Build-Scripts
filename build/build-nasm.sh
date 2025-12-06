#!/usr/bin/env bash
INSTX_TOPDIR=$(find $HOME -name Build-Scripts.racine | sed "s|/Build-Scripts.racine||")

if [[ ! -d "${INSTX_TOPDIR}/programs" ]]; then
        printf "INSTX_TOPDIR is not valid."
        [[ "$0" == "${BASH_SOURCE[0]}" ]] && exit 1 || return 1
fi

# Written and placed in public domain by Jeffrey Walton
# This script builds GnuTLS and its dependencies from sources.

PKG_NAME=nasm
NASM_VER=3.01
NASM_XZ=nasm-${NASM_VER}.tar.xz
NASM_TAR=nasm-${NASM_VER}.tar.xz
NASM_DIR=nasm-${NASM_VER}

###############################################################################

# Get the environment as eeded.
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

if ! ${INSTX_TOPDIR}/build/build-gnutls.sh
then
    echo "Failed to build gnutls"
    exit 1
fi

###############################################################################

if ! ${INSTX_TOPDIR}/build/build-bzip.sh
then
    echo "Failed to build Bzip2"
    exit 1
fi

###############################################################################

if ! ${INSTX_TOPDIR}/build/build-base.sh
then
    echo "Failed to build GNU base packages"
    exit 1
fi

###############################################################################

if ! ${INSTX_TOPDIR}/build/build-libtasn1.sh
then
    echo "Failed to build libtasn1"
    exit 1
fi

###############################################################################

if ! ${INSTX_TOPDIR}/build/build-idn2.sh
then
    echo "Failed to build IDN2"
    exit 1
fi

###############################################################################

if ! ${INSTX_TOPDIR}/build/build-libexpat.sh
then
    echo "Failed to build Expat"
    exit 1
fi

###############################################################################

if ! ${INSTX_TOPDIR}/build/build-nettle.sh
then
    echo "Failed to build Nettle"
    exit 1
fi

###############################################################################

if ! ${INSTX_TOPDIR}/build/build-unbound.sh
then
    echo "Failed to build Unbound"
    exit 1
fi

###############################################################################

if ! ${INSTX_TOPDIR}/build/build-p11kit.sh
then
    echo "Failed to build P11-Kit"
    exit 1
fi

###############################################################################

if [[ ! -f "${INSTX_PREFIX}/bin/xz" ]]
then
    if ! ${INSTX_TOPDIR}/build/build-xz.sh
    then
        echo "Failed to build XZ"
        exit 1
    fi
fi

###############################################################################

if [[ "${IS_LINUX}" -eq 1 ]]
then
    if ! ${INSTX_TOPDIR}/build/build-datefudge.sh
    then
        echo "Failed to build datefudge"
        exit 1
    fi
fi

###############################################################################

echo ""
echo "========================================"
echo "================ Nasm ================"
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
echo "${PKG_NAME} ${NASM_VER}..."

if ! "${WGET}" -q -O "nasm-3.01.tar.xz" \
     "https://www.nasm.us/pub/nasm/releasebuilds/3.01/nasm-3.01.tar.xz"
then
    echo "Failed to download nasm"
    exit 1
fi

tar -xvf "nasm-3.01.tar.xz"
cd "nasm-3.01"

# Patches are created with 'diff -u' from the pkg root directory.
if [[ -e ${INSTX_TOPDIR}/patch/nasm.patch ]]; then
    echo ""
    echo "**********************"
    echo "Patching package"
    echo "**********************"

    patch -u -p0 < ${INSTX_TOPDIR}/patch/nasm.patch
fi



echo ""
echo "**********************"
echo "Configuring package"
echo "**********************"

# We should probably include --disable-anon-authentication below

./autogen.sh
#    PKG_CONFIG_PATH="${INSTX_PKGCONFIG}" \
#    CPPFLAGS="${INSTX_CPPFLAGS}" \
#    ASFLAGS="${INSTX_ASFLAGS}" \
#    LIBS="${INSTX_LDLIBS}" \
#    --build="${AUTOCONF_BUILD}" \
#    --libdir="${INSTX_LIBDIR}" \
#    --enable-lto
./configure --prefix="${INSTX_PREFIX}"
make
make install

###############################################################################

echo "$PKG_NAME" > "${INSTX_PKG_CACHE}/${PKG_NAME}"

cd "${CURR_DIR}" || exit 1

###############################################################################

# Set to false to retain artifacts
if true;
then
    ARTIFACTS=("$NASM_XZ" "$NASM_TAR" "$NASM_DIR")
    for artifact in "${ARTIFACTS[@]}"; do
        rm -rf "$artifact"
    done
fi

exit 0



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
    echo "Failed to build nasm"
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
echo "Installing package"
echo "**********************"

MAKE_FLAGS=("install")
if [[ -n "${SUDO_PASSWORD}" ]]; then
    printf "%s\n" "${SUDO_PASSWORD}" | sudo ${SUDO_ENV_OPT} -S "${MAKE}" "${MAKE_FLAGS[@]}"
    printf "%s\n" "${SUDO_PASSWORD}" | sudo ${SUDO_ENV_OPT} -S bash "${INSTX_TOPDIR}/fix-permissions.sh" "${INSTX_PREFIX}"
    printf "%s\n" "${SUDO_PASSWORD}" | sudo ${SUDO_ENV_OPT} -S bash "${INSTX_TOPDIR}/copy-sources.sh" "${PWD}" "${INSTX_SRCDIR}/${GNUTLS_DIR}"
else
    "${MAKE}" "${MAKE_FLAGS[@]}"
    bash "${INSTX_TOPDIR}/fix-permissions.sh" "${INSTX_PREFIX}"
    bash "${INSTX_TOPDIR}/copy-sources.sh" "${PWD}" "${INSTX_SRCDIR}/${GNUTLS_DIR}"
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
    ARTIFACTS=("$NASM_XZ" "$NASM_TAR" "$NASM_DIR")
    for artifact in "${ARTIFACTS[@]}"; do
        rm -rf "$artifact"
    done
fi

exit 0
