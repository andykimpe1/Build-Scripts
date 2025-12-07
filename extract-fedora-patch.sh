#!/bin/bash

## Parse command-line options
OPTS=$(getopt -o s:p:h --long spec:,patch:,help -n 'extract-fedora-patch.sh' -- "$@")

if [ $? -ne 0 ]; then
  echo "Failed to parse options" >&2
  exit 1
fi

## Reset the positional parameters to the parsed options
eval set -- "$OPTS"

## Initialize variables
spec=""
patch=""
HELP=false

## Process the options
while true; do
  case "$1" in
    -s | --spec)
      spec="$2"
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

if [ -z "$spec" ] && [ -z "$patch" ] && [ "$HELP" = false ]; then
  echo "No option specified. Use -h or --help for usage information."
fi

rm -f patch/$patch.patch
git clone https://src.fedoraproject.org/rpms/$spec.git /tmp/$spec
number=1
while [ $number -le 10000 ]
do
    cat /tmp/$spec/$spec.spec | grep Patch$number > file
    line=$(head -n 1 file | sed "s|Patch$number: ||")
    if [[ -n $line ]]; then
    cat /tmp/$spec/$line >> patch/$patch.patch
    fi
    ((number++))
done
