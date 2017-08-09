#!/bin/bash

# usage: ./push-to-thingspeak.sh API_KEY field1_redis_name field2_redis_name ...
# ./push-to-thingspeak.sh XXXXXXXX sensor.room.106.temperature \
#                                  sensor.room.106.light \
#                                  door.106

field_values() {
  local api_key="$1" ; shift
  local request="https://api.thingspeak.com/update?api_key=$api_key"

  for n in 1 2 3 4 5 6 7 8
  do
    redis_key="$1" ; shift
    if [ -n "$redis_key" ]; then
      value=$(redis-cli --raw get $redis_key)
      if [ -n "$value" ]; then
        request="$request&field$n=$value"
      fi
    fi
  done
  echo "$request"
}

API_KEY="$1" ; shift
REDIS_KEYS="$*"

while true
do
  request=$(field_values $API_KEY $REDIS_KEYS)
  echo "$(date): $request"
  curl -S -s -X GET "$request" >/dev/null
  sleep 60
done
