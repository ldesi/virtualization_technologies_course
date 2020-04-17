#!/bin/bash

#NOTE that you need to set up properly your own MANAGER NODE IP
MANAGER_NODE=$1

if [ -z "${MANAGER_NODE}" ]; then

        echo "Please add manager node IP!"
        exit 1

fi

while :
do 
	curl -s ${MANAGER_NODE}/index.html|grep "<h1>Welcome"
	sleep 1
	echo
done
