import tables
import nimSHA2
import snappy
import xxtea
import crc32
import pudgeclient
import strutils
import msgpack
# TODO: Use pointers to run data
# TODO: Need to check the return type of uploadFile

let pudgeDbClient = newClient("172.17.0.2", 11213)
let storageSpace = "test"

type StorClient = ref object of RootObj
  address: string
  port: int
  password: string

var
  objects = initTable[int, StorClient]()
  counter = 0

proc getClientId*(address: string, port: int, password: string = ""): int =
  var id: int = counter
  objects[id] = StorClient(address: address, port: port, password: password)
  counter = counter + 1
  return id

proc calculateStatusByte(compress = true, encrypt = true): string =
  if compress and encrypt:
    return "11000000"
  if compress:
    return "10000000"
  if encrypt:
    return "01000000"
  return "00000000"

proc encodeBlock*(data: string, len: int, compress = true, encrypt = true): (string, string, string) =
  var
    toEncrypt: string
    toEncode: string
    hashb: string

  let statusByte = calculateStatusByte(compress, encrypt)
  let key: string = computeSHA256(data).hex()
  if compress:
    toEncrypt = compress(data)
  else:
    toEncrypt = data

  if encrypt:
    toEncode = xxtea.encrypt(toEncrypt, key)
  else:
    toEncode = toEncrypt

  hashb = computeSHA256(toEncrypt).hex()
  let crc: string = $crc32(toEncode)
  let encodedBlock = statusByte & crc & toEncode
  return (encodedBlock, hashb, key)

proc uploadFile*(clientId: int, filename: string, compress: bool = true, encrypt: bool = true, blockSize: int = 1): Msg =
  var
    f: File
    bytesRead: int = 0
    blockSizeTmp = 1024 * 1024 * blockSize  # 1 MB default
    buffer = newString(blockSizeTmp)
    encodingMap: seq[(string, string)] = @[]

  try:
    f = open(filename)
    bytesRead = f.readBuffer(buffer[0].addr, blockSizeTmp)
    setLen(buffer,bytesRead)

    while bytesRead > 0:
      var encodedBlock = encodeBlock(buffer, bytesRead, compress, encrypt)
      let key = "$#:$#" % [storageSpace, encodedBlock[1]]
      discard pudgeDbClient.set(key,encodedBlock[0])
      encodingMap.add((hashb: encodedBlock[1], key: encodedBlock[2]))
      setLen(buffer,blockSizeTmp)
      bytesRead = f.readBuffer(buffer[0].addr, blockSizeTmp)
    return wrap(encodingMap)
  except IOError:
    echo("File not found.")
  finally:
    if f != nil:
      f.close()


var x = getClientId("", 22)
# uploadFile(clientId = x, filename = "/home/khaled/Downloads/ubuntu-16.04.1-server-amd64.iso", compress=true, encrypt=true)
