import "stor"
import unicode
import strutils
import tables
import pymod
import pymodpkg/docstrings
import pymodpkg/pyarrayobject

var
  objects = initTable[string, string]()

proc getClientId0*(address: string = "127.0.0.1", port: int = 16379): int {.exportpy.} =
  docstring"""Get stor clientId"""
  return stor.getClientId(address, port)

proc uploadFile0*(clientId: int, filename: string, encrypt: int): string {.exportpy.} =
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
  var uploadedRunes = $toRunes($uploaded)
  # objects[uploadedRunes] = uploaded
  return uploadedRunes

proc downloadFile0*(clientId: int, filename: string, msg: string) {.exportpy.} =
  docstring"""
    Download file to file system
    @param clientId
    @param filename: path to which the file will be downloaded
    @param msg: hashed string by which file can be restored
  """
  stor.downloadFile(clientId, filename, objects[msg])

proc uploadFiles0*(clientId: int, filenames: string, encrypt: int): string {.exportpy.} =
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

proc downloadFiles0*(clientId: int, filenames: string, msgs: string) {.exportpy.} =
  docstring"""
    Download files to file system
    @param clientId
    @param filenames: paths (string separated by ",") to which the files will be downloaded
    @param msgs: hashed string by which files can be restored
  """
  stor.downloadFiles(clientId, filenames.split(","), objects[msgs])

initPyModule("g8storclient", getClientId0, downloadFile0, downloadFiles0, uploadFile0, uploadFiles0)
