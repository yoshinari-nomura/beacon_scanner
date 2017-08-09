#!/bin/bash

calc() {
  awk "BEGIN {print $1}"
}

get_light_intensity() {
  local device_address="$1"

  # Command 0x01 -- power ON
  sudo i2cset -y 1 $device_address 0x01 c
  sleep 1

  # Command 0x20 -- set ONETIME_H_RESOLUTION_MODE
  #   Start measurement at 1lx resolution. Time typically 120ms
  #   Device is automatically set to Power Down after measurement.
  # cf. BH1750 Datasheet P.17
  sudo i2cset -y 1 $device_address 0x20 c
  sleep 1

  local VAL=$(i2cget -y 1 $device_address 0x00 w)
  local MSB="0x$(echo $VAL | cut -c 5-6)"
  local LSB="0x$(echo $VAL | cut -c 3-4)"
  IL=$(( ($MSB << 8) | $LSB ))

  calc "$IL / 1.2"
}

device_address="$1"
DEVICE_ROOM="$2"
REDIS_KEY="sensor.room.$DEVICE_ROOM.light"

while true
do
  value=$(get_light_intensity "$device_address")

  if [ "$current_value" != "$value" ]; then
    current_value="$value"
    redis-cli --raw set "$REDIS_KEY" "$current_value" > /dev/null
  fi

  echo "$(date): $current_value lux"
  sleep 10
done
