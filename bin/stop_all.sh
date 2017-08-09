#!/bin/sh

room="$1"

echo "Kill all:"
sudo lsof | grep "sensor.room.$room.log"

ALL_PIDS=$(sudo lsof | grep "sensor.room.$room.log" | awk '{print $2}' | sort | uniq) 
sudo kill $ALL_PIDS

echo "Result (remains?):"
sudo lsof | grep "sensor.room.$room.log"
