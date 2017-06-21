#!/bin/sh

# 2017-04-17 17:04:11 +0900/467fd32695d242f2bbbc5c8f4610b120/8/0/-55/-86

set_slack_status()
{
  case "$1" in
  8)
      echo "$(date) I'm at 205"
      ame :smile: "I'm at 205"
      ;;
  0)
      echo "$(date) I'm out"
      ame :new_moon: "I'm out"
      ;;
  *)
      echo "unknown status $1"
  esac
}

while true
do
  status=$(redis-cli --raw get door.205 | sed 's!.*/\([80]\)/0/.*!\1!')
  if [ "$current_status" != "$status" ]; then
    current_status="$status"
    set_slack_status "$current_status"
  fi
  sleep 3
done
