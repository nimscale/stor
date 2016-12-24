# Porting to python3 interface

## Generate .so file guide
* Install [nim-pymod](https://github.com/jboy/nim-pymod) by running `nimble install pymod`
* Run `python3 path/to/pmgen.py greeting.nim`
* `.so` file will be generated that can be imported by `python3`

## Examples
```python
import _storlib
client = _storlib.getClientIdPy("172.17.0.1")

# upload and download multiple files
uploaded = _storlib.uploadFilesPy(client, "file1, file2", 1)
_storlib.downloadFilesPy(client, "file1, file2", uploaded)

# upload and download one file
uploaded = _storlib.uploadFilePy(client, "file1", 1)
_storlib.downloadFilePy(client, "file1", uploaded)
```
