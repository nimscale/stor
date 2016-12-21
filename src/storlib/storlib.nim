import "../stor"
import unicode
import strutils
import tables
import pymod
import pymodpkg/docstrings
import pymodpkg/pyarrayobject

var
  objects = initTable[string, string]()

proc getClientIdPy*(address: string = "172.17.0.1", port: int = 11213): int {.exportpy.} =
  return stor.getClientId(address, port)

proc uploadFilePy*(clientId: int, filename: string, encrypt: int): string {.exportpy.}=
  var encryptTmp = true
  if encrypt == 0:
    encryptTmp = false
  var uploaded = stor.uploadFile(clientId, filename, encryptTmp)
  var uploadedRunes = $toRunes(uploaded)
  objects[uploadedRunes] = uploaded
  return uploadedRunes

proc downloadFilePy*(clientId: int, filename: string, msg: string) {.exportpy.} =
  stor.downloadFile(clientId, filename, objects[msg])

proc uploadFilesPy*(clientId: int, filenames: string, encrypt: int): string {.exportpy.} =
  var encryptTmp = true
  if encrypt == 0:
    encryptTmp = false
  return stor.uploadFiles(clientId, filenames.split(","), encryptTmp)

proc downloadFilesPy*(clientId: int, filenames: string, msgs: string) {.exportpy.} =
  stor.downloadFiles(clientId, filenames.split(","), msgs)

initPyModule("_storlib", getClientIdPy, downloadFilePy, uploadFilePy, uploadFilesPy)