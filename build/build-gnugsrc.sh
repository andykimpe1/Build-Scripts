#!/usr/bin/env bash
INSTX_TOPDIR=$(find $HOME -name Build-Scripts.racine | sed "s|/Build-Scripts.racine||")

if [[ ! -d "${INSTX_TOPDIR}/programs" ]]; then
        printf "INSTX_TOPDIR is not valid."
        [[ "$0" == "${BASH_SOURCE[0]}" ]] && exit 1 || return 1
fi


if [ -z $1 ]; then VERSION=2021.11.19; else VERSION=$1; fi
PKG_NAME=gsrc
GSCR_TAR="$PKG_NAME-$VERSION.tar.gz"
GSCR_DIR="$PKG_NAME"

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
echo "=============== $PKG_NAME ==============="
echo "========================================"

echo ""
echo "**********************"
echo "Downloading package"
echo "**********************"

echo ""
echo "$PKG_NAME $VERSION..."

if ! "${WGET}" -O "$GSCR_TAR" \
     "https://ftp.gnu.org/gnu/gsrc/$GSCR_TAR"
then
    echo "Failed to download $PKG_NAME"
    exit 1
fi

rm -rf "$GSCR_DIR" &>/dev/null
gzip -d < "$GSCR_TAR" | tar xf -
cd "$GSCR_DIR" || exit 1

./bootstrap

# Fix sys_lib_dlsearch_path_spec
bash "${INSTX_TOPDIR}/fix-configure.sh"

echo "**********************"
echo "Configuring package"
echo "**********************"

    PKG_CONFIG_PATH="${INSTX_PKGCONFIG}" \
    CPPFLAGS="${INSTX_CPPFLAGS}" \
    ASFLAGS="${INSTX_ASFLAGS}" \
    CFLAGS="${INSTX_CFLAGS}" \
    CXXFLAGS="${INSTX_CXXFLAGS}" \
    LDFLAGS="${INSTX_LDFLAGS}" \
    LDLIBS="${INSTX_LDLIBS}" \
    LIBS="${INSTX_LDLIBS}" \
./configure \
    --program-suffix=-$SUFFIX \
    --build="${AUTOCONF_BUILD}" \
    --prefix="${INSTX_PREFIX}" \
    --libdir="${INSTX_LIBDIR}"

if [[ "$?" -ne 0 ]]; then
    echo ""
    echo "****************************"
    echo "Failed to configure $PKG_NAME"
    echo "****************************"

    bash "${INSTX_TOPDIR}/collect-logs.sh" "${PKG_NAME}"
    exit 1
fi

# Escape dollar sign for $ORIGIN in makefiles. Required so
# $ORIGIN works in both configure tests and makefiles.
bash "${INSTX_TOPDIR}/fix-makefiles.sh"

sed -e 's|^MAKEINFO =.*|MAKEINFO = true|g' Makefile > Makefile.fixed
mv Makefile.fixed Makefile

echo ""
echo "**********************"
echo "Building package"
echo "**********************"

MAKE_FLAGS=("-j" "${INSTX_JOBS}" "V=1")
if ! "${MAKE}" "${MAKE_FLAGS[@]}"
then
    echo ""
    echo "****************************"
    echo "Failed to build $PKG_NAME"
    echo "****************************"

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
else
    "${MAKE}" "${MAKE_FLAGS[@]}"
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
    ARTIFACTS=("$GSCR_TAR" "$GSCR_DIR")
    for artifact in "${ARTIFACTS[@]}"; do
        rm -rf "$artifact"
    done
fi

exit 0
