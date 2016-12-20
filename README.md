# Super efficient object storage system


## Client Intreface:
* `getClientId(address: string = "172.17.0.1", port: int = 11213)`
    * Gets client id of the database client
* `uploadFile(clientId: int, filename: string, encrypt: bool = true, blockSize: int = 1)`
    * Returns msgPk object to restore the uploaded file
    * 1 blockSize = 512 KB
* `downloadFile(clientId: int, filename: string, msg: Msg)`
    * Restore file based on the msgpk passed,Writes the downloaded file to the filename
* `uploadFiles(clientId: int, filenames: seq, encrypt: bool = true, blockSize: int = 1)`
    * Returns seq of msgPk object to restore the uploaded files
    * 1 blockSize = 512 KB
* `downloadFiles(clientId: int, filenames: seq, msg: Msg)`
    * Restore files based on the msgpk passed,Writes the downloaded files to based on filenames

## Examples

* Upload and download one file

```nim
let client = getClientId(hostname, port)
let msgMap = uploadFile(clientId = client, filename = path/to/file, encrypt=true)
downloadFile(client, path/to/file, msgMap)
```

* Upload and download multiple files

```nim
Upload and download multiple files
let client = getClientId(hostname, port)
var msgs = uploadFiles(clientId = client, filenames = @["file1", "file2"], encrypt=true)
downloadFiles(client, @["file1", "file2"], msgs)
```