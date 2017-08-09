#!/bin/sh

# Usage: read-temp-ds18b20.sh {device_file} {room_number}
# read-temp-ds18b20.sh /sys/bus/w1/devices/28-0116075989ee 106

DEVICE_DIR="$1"
DEVICE_FILE="$1/w1_slave"
DEVICE_ROOM="$2"
REDIS_KEY="sensor.room.$DEVICE_ROOM.temperature"

calc() {
  awk "BEGIN {print $1}"
}

get_temperature() {
  local device_file="$1"
  temp=$(cat "$device_file" | sed -n 's/.*t=\([0-9]*\)/\1/p')
  calc "$temp / 1000"
}

while true
do
  value=$(get_temperature "$DEVICE_FILE")

  if [ "$current_value" != "$value" ]; then
    current_value="$value"
    redis-cli --raw set "$REDIS_KEY" "$current_value" > /dev/null
  fi

  echo "$(date): $current_value celsius"
  sleep 10
done
