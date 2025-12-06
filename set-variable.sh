#!/usr/bin/env bash

# set environement variable

if [ -z $LD_LIBRARY_PATH ]; then
LD_LIBRARY_PATH=$HOME/.local/lib/
export LD_LIBRARY_PATH=$HOME/.local/lib/
echo 'LD_LIBRARY_PATH=$HOME/.local/lib/' >> $HOME/.bashrc
echo 'export LD_LIBRARY_PATH=$HOME/.local/lib/' >> $HOME/.bashrc
fi
if [ -z $PKG_CONFIG_PATH ]; then
PKG_CONFIG_PATH=$HOME/.local/lib/pkconfig/
export PKG_CONFIG_PATH=$HOME/.local/lib/pkconfig/
echo 'PKG_CONFIG_PATH=$HOME/.local/lib/pkconfig/' >> $HOME/.bashrc
echo 'export PKG_CONFIG_PATH=$HOME/.local/lib/pkconfig/' >> $HOME/.bashrc
fi
patchcheck="$(echo $PATH|grep $HOME/.local/bin)"
if [ -z $patchcheck ]; then
PATH=$PATH:$HOME/.local/bin/
export PATH=$PATH:$HOME/.local/bin/
echo 'PATH=$PATH:$HOME/.local/bin/' >> $HOME/.bashrc
echo 'export PATH=$PATH:$HOME/.local/bin/' >> $HOME/.bashrc
fi
patchcheck="$(echo $PATH|grep $HOME/.build-scripts/wget/bin)"
if [ -z $patchcheck ]; then
PATH=$PATH:$HOME/.build-scripts/wget/bin/
export PATH=$PATH:$HOME/.build-scripts/wget/bin/
echo 'PATH=$PATH:$HOME/.build-scripts/wget/bin/' >> $HOME/.bashrc
echo 'export PATH=$PATH:$HOME/.build-scripts/wget/bin/' >> $HOME/.bashrc
fi
if [ -z $INSTX_PREFIX ]; then
INSTX_PREFIX="$HOME/.local"
export INSTX_PREFIX="$HOME/.local"
echo 'INSTX_PREFIX="$HOME/.local"' >> $HOME/.bashrc
echo 'export INSTX_PREFIX="$HOME/.local"' >> $HOME/.bashrc
fi
