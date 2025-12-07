#!/bin/bash

## Parse command-line options
OPTS=$(getopt -o s:p:h --long src:,patch:,help -n 'extract-rpm-patch.sh' -- "$@")

if [ $? -ne 0 ]; then
  echo "Failed to parse options" >&2
  exit 1
fi

## Reset the positional parameters to the parsed options
eval set -- "$OPTS"

## Initialize variables
src=""
patch=""
HELP=false

## Process the options
while true; do
  case "$1" in
    -s | --src)
      src="$2"
      shift 2
      ;;
    -p | --patch)
      patch="$2"
      shift 2
      ;;
    -h | --help)
      HELP=true
      shift
      ;;
    --)
      shift
      break
      ;;
    *)
      echo "Internal error!"
      exit 1
      ;;
  esac
done

## Display the results
if [ "$HELP" = true ]; then
  echo "Usage: $0 [-s|--spec specfile] [-p|--patch patchdirectory] [-h|--help]"
  echo ""
  echo "Exemple:"
  echo "  -f, --file FILE      Specify a file to process"
  exit 0
fi

if [ -z "$src" ] && [ -z "$patch" ] && [ "$HELP" = false ]; then
  echo "No option specified. Use -h or --help for usage information."
fi
rm -f *.rpm
yumdownloader $src --source
rpm -i *.rpm
rm -f *.rpm


rm -f patch/$patch.patch
number=1
while [ $number -le 10000 ]
do
    cat $HOME/rpmbuild/SPECS/$src.spec | grep Patch$number > file
    line=$(head -n 1 file | sed "s|Patch$number: ||")
    if [[ -n $line ]]; then
    cat $HOME/rpmbuild/SOURCES/$line >> patch/$patch.patch
    fi
    ((number++))
done
