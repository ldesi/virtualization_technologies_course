#!/bin/bash

JAILHOUSE_PATH=$1

if [ -z ${JAILHOUSE_PATH} ]; then
	echo "Please, specify JAILHOUSE_PATH..."
	exit -1
fi

echo "Create FreeRTOS cell..."
jailhouse cell create ${JAILHOUSE_PATH}/configs/arm/bananapi-freertos-demo.cell
