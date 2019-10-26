#!/bin/bash

ping -W 1 -c 1 8.8.8.8 -q | grep rtt | egrep [0-9]+\.[0-9]+ -o | head -n 2 | tail -n 1

