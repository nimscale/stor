package main

// nim c --app:staticLib --noMain --header stor.nim
// go build stor.go

/*
#include <stor.h>
#cgo LDFLAGS: libstor.a -ldl -lm
#cgo CFLAGS: -Inimcache -I/tmp/Nim/lib
*/
import "C"
import "fmt"

func main() {
	C.NimMain()

	client := C.getClientId(C.CString("127.0.0.1"), 6379)

	uploaded := C.uploadFile(client, C.CString("/tmp/install.sh"), 1)
	C.downloadFile(client, C.CString("/tmp/restore"), uploaded)
}

