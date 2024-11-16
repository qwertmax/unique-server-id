#!/bin/bash

GOOS=linux GOARCH=amd64 go build -o getid main.go
scp ./getid admin@84.201.168.99:/home/admin
rm -rf getid