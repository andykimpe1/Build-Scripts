#!/bin/bash
spec=$1
patch=$2
rm -f patch/$patch.patch
$HOME/.build-scripts/wget/bin/wget https://src.fedoraproject.org/rpms/$spec/raw/rawhide/f/$spec.spec -O $spec.spec
number=1
while [ $number -le 10000 ]
do
    cat $spec.spec | grep Patch$number > file
    line=$(head -n 1 file | sed "s|Patch$number: ||")
    if [[ -n $line ]]; then
    $HOME/.build-scripts/wget/bin/wget https://src.fedoraproject.org/rpms/$spec/raw/rawhide/f/$line -qO- >> patch/$patch.patch
    fi
    ((number++))
done
