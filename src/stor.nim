import tables
import nimSHA2
import snappy
import xxtea
import crc32
import base64
import strutils
import msgpack
import streams
import net
import redis

let storageSpace = "test"


var
  objects = initTable[int, Redis]()
  counter = 0

proc getClientId*(address: string = "172.17.0.1", port: int = 16379): int =
  ## Gets client id of the database client
  var id: int = counter
  objects[id] = redis.open(address, port.Port)
  echo objects[id].flushall()
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
    dataTmp = data
    statusByte = dataTmp[0..7]
    crc32 = dataTmp[8..15]
    storedData = dataTmp[16..^1]

  var finalResult: string
  if statusByte[0] == '1':
    let decrypted = xxtea.decrypt(storedData, key)
    finalResult = uncompress(decrypted)
  else:
    finalResult = uncompress(storedData)
  assert crc32 == $crc32(finalResult)
  return finalResult

proc uploadFile*(clientId: int, filename: string, encrypt: bool = true): string =
  ## Upload file to pudgedb
  ## Returns msgPk of hashes to restore the uploaded file
  var
    f: File
    bytesRead: int = 0
    blockSizeTmp = 1024 * 64  # 64 KB default
    buffer = newString(blockSizeTmp)
    encodingMap: seq[(string, string)] = @[]
    ardbClient = objects[clientId]
    st: Stream = newStringStream()

  try:
    f = system.open(filename)
    bytesRead = f.readBuffer(buffer[0].addr, blockSizeTmp)
    setLen(buffer,bytesRead)

    while bytesRead > 0:
      var encodedBlock = encodeBlock(buffer, bytesRead, encrypt)
      let key = "$#:$#" % [storageSpace, encodedBlock[1]]
      ardbClient.setk(key, encode(encodedBlock[0]))
      # assert ardbClient.get(key) == encode(encodedBlock[0])
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

proc uploadFiles*(clientId: int, filenames: openArray[string], encrypt: bool = true): string =
  ## Upload files to pudgedb
  ## Returns seq of msgPk object to restore the uploaded files
  var msgMaps: seq[string] = @[]
  let st: Stream = newStringStream()
  for file in filenames:
    msgMaps.add($uploadFile(clientId, file, encrypt))
  st.pack(wrap(msgMaps).wrap)
  st.setPosition(0)
  return st.readAll()

proc downloadFile*(clientId: int, filename: string, msg: string) =
  ## Restore file based on the msgpk passed,Writes the downloaded file to the filename
  var
    key: string
    value: string
    file = newFileStream(filename, fmWrite)
    ardbClient = objects[clientId]
    st: Stream = newStringStream()

  st.write(msg)
  st.setPosition(0)
  let map = st.unpack()
  for e in map.unwrapMap:
    key = "$#:$#" % [storageSpace, e.key.unwrapStr]
    value = decodeBlock(decode(ardbClient.get(key)), e.val.unwrapStr)
    file.write(value)
  file.close()


proc downloadFiles*(clientId: int, filenames: openArray[string], msgs: string) =
  ## Restore files based on the msgpk passed,Writes the downloaded files to based on filenames
  var index = 0
  let st: Stream = newStringStream()
  st.write(msgs)
  st.setPosition(0)
  var map = st.unpack()
  for msg in map.unwrapArray:
    downloadFile(clientId, filenames[index], msg.unwrapStr)
    index = index + 1

let client = getClientId("172.17.0.2")
let msgMap = uploadFile(clientId = client, filename = "/home/khaled/Downloads/ngrok", encrypt=false)
echo "-------------------"
downloadFile(client, "/home/khaled/Desktop/ngrok", msgMap)