#!/bin/sh

# 2017-04-17 17:04:11 +0900/467fd32695d242f2bbbc5c8f4610b120/8/0/-55/-86

set_slack_status()
{
  case "$1" in
  0)
      echo "$(date) I'm at 205"
      ame -m status :smile: "I'm at 205"
      ;;
  1)
      echo "$(date) I'm out"
      ame -m status :new_moon: "I'm out"
      ;;
  *)
      echo "unknown status $1"
  esac
}

set_doorplate()
{
  case "$1" in
  0)
      doorplate.py "在室"
      ;;
  1)
      doorplate.py "不在"
      ;;
  *)
      doorplate.py ""
  esac
}

while true
do
  status=$(redis-cli --raw get sensor.room.205.locked)
  if [ "$current_status" != "$status" ]; then
    current_status="$status"
    set_slack_status "$current_status"
    set_doorplate "$current_status"
  fi
  sleep 3
done
