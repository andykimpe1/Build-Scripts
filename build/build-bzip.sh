#!/usr/bin/env bash
INSTX_TOPDIR=$(find $HOME -name Build-Scripts.racine | sed "s|/Build-Scripts.racine||")

if [[ ! -d "${INSTX_TOPDIR}/programs" ]]; then
        printf "INSTX_TOPDIR is not valid."
        [[ "$0" == "${BASH_SOURCE[0]}" ]] && exit 1 || return 1
fi

# Written and placed in public domain by Jeffrey Walton
# This script builds Bzip2 from sources.

# shellcheck disable=SC2191

# Bzip lost its website. It is now located on Sourceware.
# https://sourceware.org/bzip2/downloads.html

VERSION=1.0.8
BZIP2_TAR=bzip2-$VERSION.tar.gz
BZIP2_DIR=bzip2-$VERSION
PKG_NAME=bzip2

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


if [[ -f "${INSTX_PKG_CACHE}/${PKG_NAME}" && ( "$VERSION" = "$(cat ${INSTX_PKG_CACHE}/${PKG_NAME})" ) ]] ; then
    echo "$PKG_NAME $(cat ${INSTX_PKG_CACHE}/${PKG_NAME}) is installed."
    exit 0
fi

echo ""
echo "========================================"
echo "================= Bzip2 ================"
echo "========================================"

echo ""
echo "****************************"
echo "Downloading package"
echo "****************************"

echo ""
echo "Bzip2 $VERSION..."

if ! "${WGET}" -O "$BZIP2_TAR" \
     "ftp://sourceware.org/pub/bzip2/$BZIP2_TAR"
then
    echo "Failed to download Bzip"
    exit 1
fi

rm -rf "$BZIP2_DIR" &>/dev/null
gzip -d < "$BZIP2_TAR" | tar xf -
cd "$BZIP2_DIR" || exit 1

# The Makefiles needed so much work it was easier to rewrite them.
#if [[ -e ${INSTX_TOPDIR}/patch/bzip-makefiles.zip ]]; then
"${WGET}" -O "${INSTX_TOPDIR}/patch/bzip-makefiles.zip" \
     "https://raw.githubusercontent.com/andykimpe1/Build-Scripts/refs/heads/build/patch/bzip-makefiles.zip"
    echo ""
    echo "****************************"
    echo "Updating makefiles"
    echo "****************************"
#
    cp ${INSTX_TOPDIR}/patch/bzip-makefiles.zip .
    unzip -oq bzip-makefiles.zip
#fi

#$("${WGET}" -qO- https://raw.githubusercontent.com/andykimpe1/Build-Scripts/refs/heads/build/patch/$PKG_NAME-$VERSION.patch) | patch -p1

# Escape dollar sign for $ORIGIN in makefiles. Required so
# $ORIGIN works in both configure tests and makefiles.
bash "${INSTX_TOPDIR}/fix-makefiles.sh"

echo ""
echo "****************************"
echo "Building package"
echo "****************************"

# Since we call the makefile directly, we need to escape dollar signs.
PKG_CONFIG_PATH="${INSTX_PKGCONFIG}"
CPPFLAGS=$(echo "${INSTX_CPPFLAGS}" | sed 's/\$/\$\$/g')
ASFLAGS=$(echo "${INSTX_ASFLAGS}" | sed 's/\$/\$\$/g')
CFLAGS=$(echo "${INSTX_CFLAGS}" | sed 's/\$/\$\$/g')
CXXFLAGS=$(echo "${INSTX_CXXFLAGS}" | sed 's/\$/\$\$/g')
LDFLAGS=$(echo "${INSTX_LDFLAGS}" | sed 's/\$/\$\$/g')
LDLIBS="${INSTX_PREFIX}/lib"

MAKE_FLAGS=()
MAKE_FLAGS+=("-f" "Makefile")
MAKE_FLAGS+=("-j" "${INSTX_JOBS}")
MAKE_FLAGS+=("CC=${CC}")
MAKE_FLAGS+=("CPPFLAGS=${CPPFLAGS} -I.")
MAKE_FLAGS+=("ASFLAGS=${ASFLAGS}")
MAKE_FLAGS+=("CFLAGS=${CFLAGS}")
MAKE_FLAGS+=("CXXFLAGS=${CXXFLAGS}")
MAKE_FLAGS+=("LDFLAGS=${LDFLAGS}")
MAKE_FLAGS+=("LIBS=${INSTX_PREFIX}/lib")

if ! "${MAKE}" "${MAKE_FLAGS[@]}"
then
    echo ""
    echo "****************************"
    echo "Failed to build Bzip archive"
    echo "****************************"

    bash "${INSTX_TOPDIR}/collect-logs.sh" "${PKG_NAME}"
    exit 1
fi

# Fix flags in *.pc files
bash "${INSTX_TOPDIR}/fix-pkgconfig.sh"

# Fix runpaths
bash "${INSTX_TOPDIR}/fix-runpath.sh"

echo ""
echo "****************************"
echo "Installing package"
echo "****************************"

if [[ -n "${SUDO_PASSWORD}" ]]
then
    echo "Installing static archive..."
    MAKE_FLAGS=("-f" "Makefile" installdirs
                PREFIX="${INSTX_PREFIX}" LIBDIR="${INSTX_PREFIX}/lib")
    printf "%s\n" "${SUDO_PASSWORD}" | sudo ${SUDO_ENV_OPT} -S "${MAKE}" "${MAKE_FLAGS[@]}"

    MAKE_FLAGS=("-f" "Makefile" install
                PREFIX="${INSTX_PREFIX}" LIBDIR="${INSTX_PREFIX}/lib")
    printf "%s\n" "${SUDO_PASSWORD}" | sudo ${SUDO_ENV_OPT} -S "${MAKE}" "${MAKE_FLAGS[@]}"
else
    echo "Installing static archive..."
    MAKE_FLAGS=("-f" "Makefile" installdirs
                PREFIX="${INSTX_PREFIX}" LIBDIR="${INSTX_PREFIX}/lib")
    "${MAKE}" "${MAKE_FLAGS[@]}"

    MAKE_FLAGS=("-f" "Makefile" install
                PREFIX="${INSTX_PREFIX}" LIBDIR="${INSTX_PREFIX}/lib")
    "${MAKE}" "${MAKE_FLAGS[@]}"
fi

# Clean old artifacts
"${MAKE}" clean 2>/dev/null

###############################################################################

echo ""
echo "****************************"
echo "Building package"
echo "****************************"

if [[ "$IS_DARWIN" -ne 0 ]]; then
    MAKEFILE=Makefile-libbz2_dylib
else
    MAKEFILE=Makefile-libbz2_so
fi

MAKE_FLAGS=()
MAKE_FLAGS+=("-f" "$MAKEFILE")
MAKE_FLAGS+=("-j" "${INSTX_JOBS}")
MAKE_FLAGS+=("CC=${CC}")
MAKE_FLAGS+=("CPPFLAGS=${CPPFLAGS} -I.")
MAKE_FLAGS+=("ASFLAGS=${ASFLAGS}")
MAKE_FLAGS+=("CFLAGS=${CFLAGS}")
MAKE_FLAGS+=("CXXFLAGS=${CXXFLAGS}")
MAKE_FLAGS+=("LDFLAGS=${LDFLAGS}")
MAKE_FLAGS+=("LIBS=${INSTX_PREFIX}/lib")

if ! "${MAKE}" "${MAKE_FLAGS[@]}"
then
    echo ""
    echo "****************************"
    echo "Failed to build Bzip library"
    echo "****************************"

    bash "${INSTX_TOPDIR}/collect-logs.sh" "${PKG_NAME}"
    exit 1
fi

echo ""
echo "****************************"
echo "Installing package"
echo "****************************"

if [[ -n "${SUDO_PASSWORD}" ]]
then
    echo "Installing shared object..."
    MAKE_FLAGS=("-f" "$MAKEFILE" install
                PREFIX="${INSTX_PREFIX}" LIBDIR="${INSTX_PREFIX}/lib")
    printf "%s\n" "${SUDO_PASSWORD}" | sudo ${SUDO_ENV_OPT} -S "${MAKE}" "${MAKE_FLAGS[@]}"

    MAKE_FLAGS=("-f" "$MAKEFILE" installdirs
                PREFIX="${INSTX_PREFIX}" LIBDIR="${INSTX_PREFIX}/lib")
    printf "%s\n" "${SUDO_PASSWORD}" | sudo ${SUDO_ENV_OPT} -S "${MAKE}" "${MAKE_FLAGS[@]}"
else
    echo "Installing shared object..."
    MAKE_FLAGS=("-f" "$MAKEFILE" installdirs
                PREFIX="${INSTX_PREFIX}" LIBDIR="${INSTX_PREFIX}/lib")
    "${MAKE}" "${MAKE_FLAGS[@]}"

    MAKE_FLAGS=("-f" "$MAKEFILE" install
                PREFIX="${INSTX_PREFIX}" LIBDIR="${INSTX_PREFIX}/lib")
    "${MAKE}" "${MAKE_FLAGS[@]}"
fi

###############################################################################

# Write the *.pc file
{
    echo ""
    echo "prefix=${INSTX_PREFIX}"
    echo "exec_prefix=\${prefix}"
    echo "libdir=${INSTX_PREFIX}/lib"
    echo "sharedlibdir=\${libdir}"
    echo "includedir=\${prefix}/include"
    echo ""
    echo "Name: Bzip2"
    echo "Description: Bzip2 compression library"
    echo "Version: $VERSION"
    echo ""
    echo "Requires:"
    echo "Libs: -L\${libdir} -lbz2"
    echo "Cflags: -I\${includedir}"
} > libbz2.pc

if [[ -n "${SUDO_PASSWORD}" ]]
then
    printf "%s\n" "${SUDO_PASSWORD}" | sudo ${SUDO_ENV_OPT} -S cp ./libbz2.pc "${INSTX_PREFIX}/lib/pkgconfig"
    printf "%s\n" "${SUDO_PASSWORD}" | sudo ${SUDO_ENV_OPT} -S chmod u=rw,go=r "${INSTX_PREFIX}/lib/pkgconfig/libbz2.pc"
else
    cp ./libbz2.pc "${INSTX_PREFIX}/lib/pkgconfig"
    chmod u=rw,go=r "${INSTX_PREFIX}/lib/pkgconfig/libbz2.pc"
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

echo "$VERSION" > "${INSTX_PKG_CACHE}/${PKG_NAME}"

cd "${CURR_DIR}" || exit 1

###############################################################################

# Set to false to retain artifacts
if true;
then
    ARTIFACTS=("$BZIP2_TAR" "$BZIP2_DIR")
    for artifact in "${ARTIFACTS[@]}"; do
        rm -rf "$artifact"
    done
fi

exit 0
