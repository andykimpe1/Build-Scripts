#!/bin/bash
rm -f /tmp/ca-certificate
mkdir -p /tmp/ca-certificate
cd /tmp/ca-certificate
chmod +x $HOME/Build-Scripts/bootstrap/mk-ca-bundle.pl
$HOME/Build-Scripts/bootstrap/mk-ca-bundle.pl
cat ca-bundle.crt > $HOME/Build-Scripts/bootstrap/cacert2.pem
cd
rm -rf /tmp/ca-certificate
