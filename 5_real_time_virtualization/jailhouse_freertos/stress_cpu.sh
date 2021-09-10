#!/bin/bash

TIMEOUT=$1

if [ -z $TIMEOUT ]; then

	echo "Please, add timeout for wl..."
	exit -1
fi

stress-ng --cpu 8 --io 4 --vm 2 --vm-bytes 128M --fork 4 --timeout ${TIMEOUT}s -M