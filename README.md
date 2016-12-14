# super efficient object storage system

goals

- KIS

how (gen 1)

- store data in excelent sophiaDB (front ended by memcache daemon (pudge))


## specs for object store


```python
class storClient():

    def uploadFiles(self,storagespace,storageServerAddr,filePaths,compress=True,encrypt=True,blocksize=1024):
        """
        same as uploadFile but filePaths are msgpack encoded list of file paths
        """

    def downloadFiles(self,storageServerAddr,filePaths,FileMD):
        """
        same as uploadFile but filePaths are msgpack encoded list of file paths
        """


    def uploadFile(self,storagespace,storageServerAddr,filePath,compress=True,encrypt=True,blocksize=1024):
        """
        load file & cut in blocks & encode & upload to memcache db server (e.g. pudge which will store in sophia db)

        key in pudgedb = "%s:%s"%(storagespace,hashb)

        @param storageServerAddr= $addr:$port:$passwd  or dest= $addr:$port or dest= $addr
        @param blocksize in kbyte
        @return msgpack encoded list((hashb,encrkey))
        """

    def downloadFile(self,storageServerAddr,filePath,FileMD):
        """
        load file & cut in blocks & encode & upload to memcache db server (e.g. pudge which will store in sophia db)

        @param storageServerAddr= $addr:$port:$passwd  or dest= $addr:$port or dest= $addr
        @param FileMD= msgpack encoded list((hashb,encrkey))
        """

    def encodeBlock(self,data,compress=True,encrypt=True):
        """
        compression done with brotli
        encryption key = blake32 hash of data
        @return (data3,hashb,encrKey,size)

        max size of block = 4 MB

        process
        - hash a (encrKey)
        - compress
        - encrypt with hash a
           - result is data2 (bin object)
        - hash b of encr/compr file
        - size (after encr/compr)
        - data3 = statusByte+crc32+data2

        statusByte = ab000000 (byte): a=True if compress, b=True if encrypt

        """

    def decodeBlock(self,data2):
        """
        decrypt/decompress depending statusByte
        use CRC to verify, if not ok error

        @return (data,size)

        """        



```
