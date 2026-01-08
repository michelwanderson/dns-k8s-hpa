#!/bin/sh

while true; do
  dd if=/dev/zero of=/dev/null bs=1M count=1024
done