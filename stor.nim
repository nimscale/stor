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

proc getClientId*(address: string, port: int, password: string = ""): int =
  var id: int = counter
  objects[id] = newClient(address, port)
  counter = counter + 1
  return id

proc calculateStatusByte(encrypt = true): string =
  if encrypt:
    return "10000000"
  return "00000000"

proc encodeBlock*(data: string, len: int, encrypt = true): (string, string, string) =
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

proc uploadFile*(clientId: int, filename: string, encrypt: bool = true, blockSize: int = 1): Msg =
  var
    f: File
    bytesRead: int = 0
    blockSizeTmp = 1024 * 512 * blockSize  # 512 KB default
    buffer = newString(blockSizeTmp)
    encodingMap: seq[(string, string)] = @[]
    pudgeDbClient = objects[clientId]

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
    return wrap(encodingMap)
  except IOError:
    echo("File not found.")
  finally:
    if f != nil:
      f.close()

proc decodeBlock*(data: string, key: string): string =
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

proc downloadFile*(clientId: int, filename: string, msg: Msg) =
  var
    key: string
    value: string
    file = newFileStream(filename, fmWrite)
    pudgeDbClient = objects[clientId]

  for e in msg.unwrapMap:
    key = "$#:$#" % [storageSpace, e.key.unwrapStr]
    value = decodeBlock(pudgeDbClient.get(key), e.val.unwrapStr)
    file.write(value)
  file.close()

var x = getClientId("172.17.0.2", 11213)
var xx = uploadFile(clientId = x, filename = "/home/khaled/Downloads/ngrok", encrypt=false)
downloadFile(x, "ngrok", xx)
