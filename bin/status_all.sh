#!/bin/sh

room="$1"

echo "Working processes:"
sudo lsof | grep "sensor.room.$room.log"
