#!/bin/bash

cd $(dirname $0)

function json_parse () {
  grep "^\[" | sed -e 's/"{/{/g' -e 's/}"/}/g' -e 's/\\//g' | python -m json.tool
}

pkill -f dummy_server.py
python dummy_server.py &

tail -fn0 server.log | 
while read LINE
do
  if [ "${LINE:0:1}" = '[' ]; then
    echo ${LINE} | sed -u -e 's/"{/{/g' -e 's/}"/}/g' -e 's/\\//g' -e 's/: }/: {}}/g' | python -m json.tool
  else
    echo ${LINE}
  fi
done
