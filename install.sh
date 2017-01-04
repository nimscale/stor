set -ex
nimble install pudge
cd ~/.nimble/pkgs/Pudge-0.1.1/
sh install.sh

#make sure python deps are installed
pip3 install numpy

nimble install pymod
echo 'python3 ~/.nimble/pkgs/pymod-0.1.0/pmgen.py $1' > /usr/local/bin/pmgen
chmod 777 /usr/local/bin/pmgen
