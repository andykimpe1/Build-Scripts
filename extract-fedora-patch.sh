#!/bin/bash
OPTS=$(getopt -o s:p:h --long spec:,patch:,help -n 'extract-fedora-patch.sh' -- "$@")

if [ $? -ne 0 ]; then
  echo "Option analysis failed" >&2
  exit 1
fi
eval set -- "$OPTS"
spec=""
patch=""
help=false

## Traite les options
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
      $help=true
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

if [ "$help" = true ]; then
  echo "Usage : $0 [-f|--spec spec] [-p|--patch patch] [-h|--help]"
  echo ""
  echo "Options :"
  echo "  -s, --spec spec  traiter"
  echo "  -p, -- "
  echo "  -h, --help           Affiche ce message d'aide"
  exit 0
fi

spec=$1
patch=$2
rm -f patch/$patch.patch
git clone https://src.fedoraproject.org/rpms/$spec.git /tmp/$spec

$HOME/.build-scripts/wget/bin/wget https://src.fedoraproject.org/rpms/$spec/raw/rawhide/f/$spec.spec -O $spec.spec
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
