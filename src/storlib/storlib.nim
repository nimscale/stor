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
  docstring"""Get stor clientId"""
  return stor.getClientId(address, port)

proc uploadFilePy*(clientId: int, filename: string, encrypt: int): string {.exportpy.} =
  docstring"""
    Upload file to pudgedb
    @param clientId
    @param filename: path of file that'll be uploaded
    @param encrypt: 1 for encrypt, 0 to not encrypt
    return: hashed string by which file can be restored
  """
  var encryptTmp = true
  if encrypt == 0:
    encryptTmp = false
  var uploaded = stor.uploadFile(clientId, filename, encryptTmp)
  var uploadedRunes = $toRunes(uploaded)
  objects[uploadedRunes] = uploaded
  return uploadedRunes

proc downloadFilePy*(clientId: int, filename: string, msg: string) {.exportpy.} =
  docstring"""
    Download file to file system
    @param clientId
    @param filename: path to which the file will be downloaded
    @param msg: hashed string by which file can be restored
  """
  stor.downloadFile(clientId, filename, objects[msg])

proc uploadFilesPy*(clientId: int, filenames: string, encrypt: int): string {.exportpy.} =
  docstring"""
    Upload files to pudgedb
    @param clientId
    @param filenames: paths (string separated by ",") of file that'll be uploaded
    @param encrypt: 1 for encrypt, 0 to not encrypt
    return: hashed string by which files can be restored
  """
  var encryptTmp = true
  if encrypt == 0:
    encryptTmp = false
  let uploaded = stor.uploadFiles(clientId, filenames.split(","), encryptTmp)
  let uploadedRunes = $toRunes(uploaded)
  echo uploadedRunes
  objects[uploadedRunes] = uploaded
  return uploadedRunes

proc downloadFilesPy*(clientId: int, filenames: string, msgs: string) {.exportpy.} =
  docstring"""
    Download files to file system
    @param clientId
    @param filenames: paths (string separated by ",") to which the files will be downloaded
    @param msgs: hashed string by which files can be restored
  """
  stor.downloadFiles(clientId, filenames.split(","), objects[msgs])

initPyModule("_storlib", getClientIdPy, downloadFilePy, downloadFilesPy, uploadFilePy, uploadFilesPy)