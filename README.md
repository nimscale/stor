# Super efficient object storage system


## Client Interface:
* `getClientId(address: string = "172.17.0.1", port: int = 11213)`
    * Gets client id
* `uploadFile(clientId: int, filename: string, encrypt: bool = true, blockSize: int = 1)`
    * Returns msgPk serialized string that's used to restore the uploaded file
    * 1 blockSize = 512 KB
* `downloadFile(clientId: int, filename: string, msg: string)`
    * Restore file based on the msgpk passed,Writes the downloaded file to the filename
* `uploadFiles(clientId: int, filenames: openArray[string], encrypt: bool = true, blockSize: int = 1)`
    * Returns msgPk serialized string to restore the uploaded files
    * 1 blockSize = 512 KB
* `downloadFiles(clientId: int, filenames: openArray[string], msg: string)`
    * Restore files based on the msgpk passed,Writes the downloaded files based on filenames


## Requirements:
* Pudgedb: To setup pudge please follow [Pudge](https://github.com/recoilme/pudge) docs

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

## For Python3 interface/porting check the [docs](./docs/howtopy.md) and [storlib](./src/storlib/storlib.nim)