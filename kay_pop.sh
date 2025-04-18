#!/bin/bash
PORT=4444

# Run on Kali machine with nohup ./kay_pop.sh &

while true; do
    MESSAGE=$(nc -l -p $PORT)
    if [[ ! -z "$MESSAGE" ]]; then
        zenity --warning --text="$MESSAGE"
    fi
done
