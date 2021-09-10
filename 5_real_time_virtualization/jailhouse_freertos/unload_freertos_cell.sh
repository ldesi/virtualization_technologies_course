#!/bin/bash


jailhouse cell list|grep FreeRTOS > /dev/null 2>&1

if [ $? -ne 0 ];then
	echo "FreeRTOS cell is not created or running..."
fi

echo "Shutdown FreeRTOS cell"
jailhouse cell shutdown FreeRTOS

echo "Destroy FreeRTOS cell"
jailhouse cell destroy FreeRTOS
