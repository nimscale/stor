# Super efficient object storage system

## Installation
Follow theses steps to have a working environment (docker) to correctly compile the stor and the python binding

```bash
# Inside: docker run -ti --name=g8stor-nim-py --hostname=g8stor-nim-py ubuntu:16.04

apt-get update
apt-get install -y git vim build-essential

# Installing nim-lang
NIMTAG="v0.15.2"

cd /opt
git clone -b $NIMTAG https://github.com/nim-lang/Nim.git
cd Nim
git clone --depth 1 -b $NIMTAG https://github.com/nim-lang/csources
cd csources && sh build.sh
cd ..
./bin/nim c koch
./koch boot -d:release

export PATH=$PATH:$(pwd)/bin
nim e install_nimble.nims
nimble update
nimble install pymod

# Linking pmgen
apt-get install -y python3-numpy python3-dev libsnappy1v5
echo 'python3 ~/.nimble/pkgs/pymod-0.1.0/pmgen.py $1' > /usr/local/bin/pmgen
chmod +x /usr/local/bin/pmgen

# Installing dependencies
git clone https://github.com/nimscale/stor.git
nimble install msgpack nimsnappy nimSHA2 xxtea redis

# Comment lines (tests) in msgpack package
sed -i '1073,1085 s/^/#/' ~/.nimble/pkgs/msgpack-0.1.0/msgpack.nim

# Cloning Nimscale Stor
cd /opt
git clone https://github.com/nimscale/stor
cd stor/src

# g8storclient.so is ready
```

## Client Interface:
* `getClientId(address: string = "172.17.0.1", port: int = 11213)`
    * Gets client id
* `uploadFile(clientId: int, filename: string, encrypt: bool = true)`
    * Returns msgPk serialized string that's used to restore the uploaded file
    * 1 blockSize = 512 KB
* `downloadFile(clientId: int, filename: string, msg: string)`
    * Restore file based on the msgpk passed,Writes the downloaded file to the filename
* `uploadFiles(clientId: int, filenames: openArray[string], encrypt: bool = true)`
    * Returns msgPk serialized string to restore the uploaded files
    * 1 blockSize = 512 KB
* `downloadFiles(clientId: int, filenames: openArray[string], msg: string)`
    * Restore files based on the msgpk passed,Writes the downloaded files based on filenames

## Examples

* Upload and download single file

```nim
let client = getClientId(hostname, port)
let msgMap = uploadFile(clientId = client, filename = path/to/file, encrypt=true)
downloadFile(client, path/to/file, msgMap)
```

* Upload and download multiple files

```nim
let client = getClientId(hostname, port)
var msgs = uploadFiles(clientId = client, filenames = ["file1", "file2"], encrypt=true)
downloadFiles(client, ["file1", "file2"], msgs)
```

## For Python3 interface/porting check the [docs](./docs/howtopy.md)
