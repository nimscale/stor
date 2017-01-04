# Porting to python3 interface

## Generate .so file guide
* execute 'installDeps.sh' in this repo, this will install pmgen which generates .so files
* Run `compile4python.sh` which will generate .so file
* `.so` file is copied to

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
