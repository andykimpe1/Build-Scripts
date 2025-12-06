#!/usr/bin/env bash
INSTX_TOPDIR=$(find $HOME -name Build-Scripts.racine | sed "s|/Build-Scripts.racine||")

if [[ ! -d "${INSTX_TOPDIR}/programs" ]]; then
        printf "INSTX_TOPDIR is not valid."
        [[ "$0" == "${BASH_SOURCE[0]}" ]] && exit 1 || return 1
fi

# Written and placed in public domain by Jeffrey Walton
# This script builds Wget and its dependencies from sources.

UNZIP_VER=6.0
UNZIP_TAR=unzip60.tar.gz
UNZIP_DIR=unzip60
PKG_NAME=unzip

###############################################################################

# Get the environment as needed.
if [[ "${SETUP_ENVIRON_DONE}" != "yes" ]]; then
    if ! source ${INSTX_TOPDIR}/setup-environ.sh
    then
        echo "Failed to set environment"
        exit 1
    fi
fi

# The password should die when this subshell goes out of scope
if [[ "${SUDO_PASSWORD_DONE}" != "yes" ]]; then
    if ! source ${INSTX_TOPDIR}/setup-password.sh
    then
        echo "Failed to process password"
        exit 1
    fi
fi


if [[ -f "${INSTX_PKG_CACHE}/${PKG_NAME}" && ( "$UNZIP_VER" = "$(cat ${INSTX_PKG_CACHE}/${PKG_NAME})" ) ]] ; then
    echo "$PKG_NAME $(cat ${INSTX_PKG_CACHE}/${PKG_NAME}) is installed."
    exit 0
fi

###############################################################################

# c-ares needs a C++11 compiler. c-ares fails its self tests on Solaris.
if [[ "$INSTX_CXX11" -eq 0 || "$IS_SOLARIS" -ne 0 ]]
then
    ENABLE_CARES=0
else
    ENABLE_CARES=1
fi

###############################################################################

if ! ${INSTX_TOPDIR}/build/build-cacert.sh
then
    echo "Failed to install CA Certs"
    exit 1
fi

###############################################################################

if ! ${INSTX_TOPDIR}/build/build-zlib.sh
then
    echo "Failed to build zLib"
    exit 1
fi


echo ""
echo "========================================"
echo "================= Unzip ================="
echo "========================================"

echo ""
echo "************************"
echo "Downloading package"
echo "************************"

if ! "${WGET}" -q -O "$UNZIP_TAR" \
     "https://sourceforge.net/projects/infozip/files/UnZip%206.x%20%28latest%29/UnZip%206.0/$UNZIP_TAR"
then
    echo "Failed to download Unzip"
fi

if ! "$HOME/.build-scripts/wget/bin/wget" -q -O "$UNZIP_TAR" \
     "https://sourceforge.net/projects/infozip/files/UnZip%206.x%20%28latest%29/UnZip%206.0/$UNZIP_TAR"
then
    echo "Failed to download Unzip"
    exit 1
fi

rm -rf "$UNZIP_DIR" &>/dev/null
gzip -d < "$UNZIP_TAR" | tar xf -
cd "$UNZIP_DIR" || exit 1

# Patches are created with 'diff -u' from the pkg root directory.
if [[ -e ${INSTX_TOPDIR}/patch/unzip.patch ]]; then
    echo ""
    echo "**************************"
    echo "Patching package"
    echo "**************************"

    patch -u -p1 < ${INSTX_TOPDIR}/patch/unzip.patch
fi

# Fix sys_lib_dlsearch_path_spec
bash "${INSTX_TOPDIR}/fix-configure.sh"

echo ""
echo "************************"
echo "Configuring package"
echo "************************"

if [[ "${INSTX_DEBUG_MAP}" -eq 1 ]]; then
    unzip_cflags="${INSTX_CFLAGS} -fdebug-prefix-map=${PWD}=${INSTX_SRCDIR}/${UNZIP_DIR}"
    unzip_cxxflags="${INSTX_CXXFLAGS} -fdebug-prefix-map=${PWD}=${INSTX_SRCDIR}/${UNZIP_DIR}"
else
    unzip_cflags="${INSTX_CFLAGS}"
    unzip_cxxflags="${INSTX_CXXFLAGS}"
fi

    PKG_CONFIG_PATH="${INSTX_PKGCONFIG}"
    CPPFLAGS="${INSTX_CPPFLAGS}"
    ASFLAGS="${INSTX_ASFLAGS}"
    CFLAGS="${unzip_cflags}"
    CXXFLAGS="${unzip_cxxflags}"
    LDFLAGS="${INSTX_LDFLAGS}"
    LIBS="${INSTX_LDLIBS}"
echo no configure

if [[ "$?" -ne 0 ]]
then
    echo ""
    echo "************************"
    echo "Failed to configure Unzip"
    echo "************************"

    bash "${INSTX_TOPDIR}/collect-logs.sh" "${PKG_NAME}"
    exit 1
fi

# Escape dollar sign for $ORIGIN in makefiles. Required so
# $ORIGIN works in both configure tests and makefiles.
bash "${INSTX_TOPDIR}/fix-makefiles.sh"

echo ""
echo "************************"
echo "Building package"
echo "************************"


MAKE_FLAGS=("-f" "unix/Makefile" "-j" "${INSTX_JOBS}" "generic_gcc")
if ! "${MAKE}" "${MAKE_FLAGS[@]}"
then
    echo ""
    echo "************************"
    echo "Failed to build Unzip"
    echo "************************"

    bash "${INSTX_TOPDIR}/collect-logs.sh" "${PKG_NAME}"
    exit 1
fi

# Fix flags in *.pc files
bash "${INSTX_TOPDIR}/fix-pkgconfig.sh"

# Fix runpaths
bash "${INSTX_TOPDIR}/fix-runpath.sh"

echo ""
echo "************************"
echo "Installing package"
echo "************************"

MAKE_FLAGS=( "-f" "unix/Makefile" "prefix=${INSTX_PREFIX}" "install")
if [[ -n "${SUDO_PASSWORD}" ]]; then
    printf "%s\n" "${SUDO_PASSWORD}" | sudo ${SUDO_ENV_OPT} -S "${MAKE}" "${MAKE_FLAGS[@]}"
    printf "%s\n" "${SUDO_PASSWORD}" | sudo ${SUDO_ENV_OPT} -S bash "${INSTX_TOPDIR}/copy-sources.sh" "${PWD}" "${INSTX_SRCDIR}/${UNZIP_DIR}"
else
    "${MAKE}" "${MAKE_FLAGS[@]}"
    bash "${INSTX_TOPDIR}/copy-sources.sh" "${PWD}" "${INSTX_SRCDIR}/${UNZIP_DIR}"
fi

# Fix permissions once
if [[ -n "${SUDO_PASSWORD}" ]]; then
    printf "%s\n" "${SUDO_PASSWORD}" | sudo ${SUDO_ENV_OPT} -S bash "${INSTX_TOPDIR}/fix-permissions.sh" "${INSTX_PREFIX}"
else
    bash "${INSTX_TOPDIR}/fix-permissions.sh" "${INSTX_PREFIX}"
fi

###############################################################################

echo ""
echo "*****************************************************************************"
echo "Please run Bash's 'hash -r' to update program cache in the current shell"
echo "*****************************************************************************"

###############################################################################

echo "$UNZIP_VER" > "${INSTX_PKG_CACHE}/${PKG_NAME}"

cd "${CURR_DIR}" || exit 1

###############################################################################

# Set to true to retain artifacts
if true;
then
    ARTIFACTS=("$UNZIP_TAR" "$UNZIP_DIR")
    for artifact in "${ARTIFACTS[@]}"; do
        rm -rf "$artifact"
    done
fi

exit 0
