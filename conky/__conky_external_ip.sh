#!/bin/bash

curl http://ip.tupeux.com --connect-timeout 2 | grep -o "[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*"

