#!/bin/bash

local_ip=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1'|head -n1)

sed -i "s/Welcome to nginx!/Welcome to nginx TEST ITEE PHD => HOST: ${local_ip}/" /usr/share/nginx/html/index.html

exec "${@}"

