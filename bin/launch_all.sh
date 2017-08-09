#!/bin/sh

export PATH="$HOME/beacon_scanner/bin:$PATH"

room="$1"
api_key="$2"

if [ -z "$room" -o -z "$api_key" ]; then
  echo "Usage: launch_all ROOM SINGSPEAK_API_KEY" 1>&2
  exit 1
fi

(\
  beacon_scanner/bin/beacon_scanner.rb --redis sensor.room.$room   &\
  beacon_scanner/bin/doorkeeper.sh                                 &\
  ./read-temp-ds18b20.sh /sys/bus/w1/devices/28-0116106c44ee $room &\
  ./read-light-bh1750.sh 0x23 $room                                &\
  ./push-to-thingspeak.sh $api_key                                 \
     sensor.room.$room.temperature                                 \
     sensor.room.$room.light                                       \
     sensor.room.$room.locked                                      &\
) >> sensor.room.$room.log

echo $$

#while true
#do
#  sleep 60
#done
