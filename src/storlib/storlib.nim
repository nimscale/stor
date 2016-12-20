import "../stor"

import pymod
import pymodpkg/docstrings
import pymodpkg/pyarrayobject

proc getClientIdPy*(address: string = "172.17.0.1", port: int = 11213): int {.exportpy.} =
  return stor.getClientId(address, port)

proc uploadFilePy*(clientId: int, filename: string, encrypt: int): string {.exportpy.}=
  var encryptTmp = true
  if encrypt == 0:
    encryptTmp = false
  return stor.uploadFile(clientId, filename, encryptTmp)

proc downloadFilePy*(clientId: int, filename: string, msg: string) {.exportpy.} =
  stor.downloadFile(clientId, filename, msg)

# TODO: needed
proc uploadFilesPy*(clientId: int, filenames: openArray[string], encrypt: int): string =
  var encryptTmp = true
  if encrypt == 0:
    encryptTmp = false
  return stor.uploadFiles(clientId, filenames, encryptTmp)

# TODO: needed
proc downloadFilesPy*(clientId: int, filenames: openArray[string], msgs: string) =
  stor.downloadFiles(clientId, filenames, msgs)

initPyModule("_storlib", getClientIdPy, downloadFilePy, uploadFilePy, uploadFilesPy)