import tables
import nimSHA2
import snappy
import xxtea
import crc32
import pudgeclient
import strutils
import msgpack
import streams
import net
let storageSpace = "test"


var
  objects = initTable[int, Socket]()
  counter = 0

proc getClientId*(address: string = "172.17.0.1", port: int = 11213): int =
  ## Gets client id of the database client
  var id: int = counter
  objects[id] = newClient(address, port)
  counter = counter + 1
  return id

proc calculateStatusByte(encrypt = true): string =
  if encrypt:
    return "10000000"
  return "00000000"

proc encodeBlock(data: string, len: int, encrypt = true): (string, string, string) =
  var
    data3: string
    hashb: string

  let statusByte = calculateStatusByte(encrypt)
  let key: string = computeSHA256(data).hex()

  if encrypt:
    data3 = xxtea.encrypt(compress(data), key)
  else:
    data3 = compress(data)
  hashb = computeSHA256(data3).hex()
  let crc: string = $crc32(data)
  let encodedBlock = statusByte & crc & data3

  return (encodedBlock, hashb, key)

proc decodeBlock(data: string, key: string): string =
  let
    statusByte = data[0..7]
    crc32 = data[8..15]
    storedData = data[16..^1]

  var finalResult: string
  if statusByte[0] == '1':
    let decrypted = xxtea.decrypt(storedData, key)
    finalResult = uncompress(decrypted)
  else:
    finalResult = uncompress(storedData)
  assert crc32 == $crc32(finalResult)
  return finalResult

proc uploadFile*(clientId: int, filename: string, encrypt: bool = true, blockSize: int = 1): string =
  ## Upload file to pudgedb
  ## Returns msgPk of hashes to restore the uploaded file
  var
    f: File
    bytesRead: int = 0
    blockSizeTmp = 1024 * 512 * blockSize  # 512 KB default
    buffer = newString(blockSizeTmp)
    encodingMap: seq[(string, string)] = @[]
    pudgeDbClient = objects[clientId]
    st: Stream = newStringStream()

  try:
    f = open(filename)
    bytesRead = f.readBuffer(buffer[0].addr, blockSizeTmp)
    setLen(buffer,bytesRead)

    while bytesRead > 0:
      var encodedBlock = encodeBlock(buffer, bytesRead, encrypt)
      let key = "$#:$#" % [storageSpace, encodedBlock[1]]
      assert pudgeDbClient.set(key,encodedBlock[0]) == true
      encodingMap.add((hashb: encodedBlock[1], key: encodedBlock[2]))
      setLen(buffer, bytesRead)
      bytesRead = f.readBuffer(buffer[0].addr, blockSizeTmp)
      setLen(buffer, bytesRead)
    var wrappedMsg = wrap(encodingMap)
    st.pack(wrappedMsg.wrap)
    st.setPosition(0)
    return st.readAll()
  except IOError:
    echo("File not found.")
  finally:
    if f != nil:
      f.close()

proc downloadFile*(clientId: int, filename: string, msg: string) =
  ## Restore file based on the msgpk passed,Writes the downloaded file to the filename
  var
    key: string
    value: string
    file = newFileStream(filename, fmWrite)
    pudgeDbClient = objects[clientId]
    st: Stream = newStringStream()

  st.write(msg)
  st.setPosition(0)
  let map = st.unpack()
  for e in map.unwrapMap:
    key = "$#:$#" % [storageSpace, e.key.unwrapStr]
    value = decodeBlock(pudgeDbClient.get(key), e.val.unwrapStr)
    file.write(value)
  file.close()

proc uploadFiles*(clientId: int, filenames: openArray[string], encrypt: bool = true, blockSize: int = 1): auto =
  ## Upload files to pudgedb
  ## Returns seq of msgPk object to restore the uploaded files
  var msgMaps: seq[string] = @[]
  for file in filenames:
    msgMaps.add($uploadFile(clientId, file, encrypt, blockSize))
  return msgMaps

proc downloadFiles*(clientId: int, filenames: openArray[string], msgs: openArray[string]): auto =
  ## Restore files based on the msgpk passed,Writes the downloaded files to based on filenames
  var index = 0
  for msg in msgs:
    downloadFile(clientId, filenames[index], msg)
    index = index + 1
