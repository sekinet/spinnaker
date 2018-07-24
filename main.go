package main

import (
	"io"
	"net/http"
)

func hello(w http.ResponseWriter, r *http.Request) {
	io.WriteString(w, "Hello World! Shohei won!!")
}

func main() {
	http.HandleFunc("/", hello)
	http.ListenAndServe(":80", nil)
}
