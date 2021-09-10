#!/bin/bash

JAILHOUSE_PATH=$1

if [ -z ${JAILHOUSE_PATH} ]; then
	echo "Please, specify JAILHOUSE_PATH..."
	exit -1
fi

echo "Load jailhouse module..."
modprobe jailhouse

echo "Enable root cell..."
jailhouse enable ${JAILHOUSE_PATH}/configs/arm/bananapi.cell

echo "Create FreeRTOS cell..."
jailhouse cell create ${JAILHOUSE_PATH}/configs/arm/bananapi-freertos-demo.cell
