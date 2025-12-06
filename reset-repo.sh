cd
rm -rf $HOME/Build-Scripts-master.tar.gz
downloader() {
if [ -f /usr/bin/wget ]; then
   wget -O $1 $2
elif [ -f $HOME/.build-scripts/wget/bin/wget ]; then
   $HOME/.build-scripts/wget/bin/wget -O $1 $2
elif [ -f /usr/bin/curl ]; then
   curl -o $1 $2
elif [ -f /usr/bin/python3 ]; then
   python3 <<EOF
import urllib.request
urllib.request.urlretrieve("$2", "$1")
EOF
elif [ -f /usr/bin/python2 ]; then
   python2 <<EOF
import urllib
urllib.urlretrieve("$2", "$1")
EOF
fi
}
downloader Build-Scripts-master.tar.gz https://codeload.github.com/andykimpe1/Build-Scripts/tar.gz/refs/heads/master
cat > /tmp/rest.sh <<EOF
#!/bin/bash
cd
rm -rf Build-Scripts-master .local
tar -xvf Build-Scripts-master.tar.gz
rm -rf Build-Scripts-master.tar.gz
cd Build-Scripts-master
find . -name '*.sh' -exec chmod +x {} \;
./set-variable.sh
source $HOME/.bashrc
if [ ! -f $HOME/.build-scripts/wget/bin/wget ]; then
    ./setup-cacerts.sh
    ./setup-wget.sh
fi
EOF
chmod +x /tmp/rest.sh
/tmp/rest.sh
