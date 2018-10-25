#!/bin/bash

cd $(dirname $0)

function json_parse () {
  grep "^\[" | sed -e 's/"{/{/g' -e 's/}"/}/g' -e 's/\\//g' | python -m json.tool
}

trap 'pkill -f dummy_server.py' 1 2 3 15
python dummy_server.py &

touch server.log
tail -fn0 server.log | 
while read LINE
do
  if [ "${LINE:0:1}" = '[' ]; then
    echo ${LINE} | sed -u -e 's/"{/{/g' -e 's/}"/}/g' -e 's/\\//g' -e 's/: }/: {}}/g' | python -m json.tool
  else
    echo ${LINE}
  fi
done
