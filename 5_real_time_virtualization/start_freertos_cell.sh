#!/bin/bash

TIMEOUT=$1
FREERTOS_CELL_PATH=$2

if [ -z $TIMEOUT ]; then

	echo "Please, add timeout for wl..."
	exit -1
fi

if [ -z ${FREERTOS_CELL_PATH} ]; then

	echo "Please, specify FREERTOS_CELL_PATH..."
	exit -1
fi

jailhouse cell list|grep FreeRTOS 2> /dev/null

if [ $? -ne 0 ]; then
	echo "Please, create FreeRTOS cell before starting wl!"
	exit -1
fi

echo "Load FreeRTOS demo bin into FreeRTOS cell"
jailhouse cell load FreeRTOS ${FREERTOS_CELL_PATH}/freertos-demo.bin

echo "Start FreeRTOS cell for $TIMEOUT seconds..."
jailhouse cell start FreeRTOS
sleep $TIMEOUT

echo "Shutdown FreeRTOS cell"
jailhouse cell shutdown FreeRTOS
