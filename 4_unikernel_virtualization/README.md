# LESSON 4_Unikernel: Hands-on sessions

---
**NOTE**

This tutorial is completely took from original github repos https://github.com/unikraft/kraft and https://github.com/unikraft/app-helloworld
Please refer to them for other details.

---


To begin using [Unikraft](https://unikraft.org) you can use the
command-line utility `kraft`, which is a companion tool used for
defining, configuring, building, and running Unikraft applications.
With `kraft` you can seamlessly create a build environment for your
unikernel and painlessly manage dependencies for its build.

## Installing kraft

The `kraft` tool and Unikraft build system have a number of package
requirements; please run the following command (on `apt-get`-based systems) to
install the requirements:

    apt-get install -y --no-install-recommends build-essential libncurses-dev libyaml-dev flex git wget socat bison unzip uuid-runtime;

To install `kraft` simply run:

    pip3 install git+https://github.com/unikraft/kraft.git@staging

You can then type `kraft` to see its help menu

## Unikraft "hello world" Application

This application prints a basic "Hello World!" message.

To configure, build and run the application you need to have [kraft](https://github.com/unikraft/kraft) installed.

To be able to run it, configure the application to run on the desired platform and architecture:
```
$ kraft configure -p PLATFORM -m ARCH
```

Build the application:
```
$ kraft build
```

And, finally, run the application:
```
$ kraft run
Hello World!
```

If you want to have more control you can also configure, build and run the application manually.

To configure it with the desired features:
```
$ make menuconfig
```

Build the application:
```
$ make
```

Run the application:
- If you built the application for `kvm`:
```
sudo qemu-system-x86_64 -kernel "build/app-helloworld_kvm-x86_64" \
                        -enable-kvm \
                        -nographic
```

- If you built the application for `linuxu`:
```
./build/app-helloworld_linuxu-x86_64
```

- If you built the application for `xen`:
  - First, you need to create a configuration file `app-helloworld.cfg`.
    It should look something like:
    ```
    name          = "app-helloworld"
    vcpus         = "1"
    memory        = "4"
    kernel        = "./build/app-helloworld_xen-x86_64"
    ```
  - To run the application you can use:
    ```
    xl create -c app-helloworld.cfg
    ```

For more information about `kraft` type `kraft -h` or read the
[documentation](http://docs.unikraft.org).

## Unikraft "httpreply" Application

Create a Linux bridge to assign static IP to unikernel NIC:

```
$ sudo brctl addbr myvirbr0
$ sudo ip a a 172.44.0.1/24 dev myvirbr0
$ sudo ip l set dev myvirbr0 up
```

Create and start httpreply unikernel by assigning 192.168.100.2 internal IP.

```
$ sudo vim /etc/qemu/bridge.conf
```

Add the following line ``allow myvirbr0``. Then:

```
$ sudo chown root:root /etc/qemu/bridge.conf
$ sudo chmod 0640 /etc/qemu/bridge.conf
```

Create and start the unikernel VM:

```
$ kraft up -p kvm -m x86_64 -t httpreply@staging httpreply_unikernel_kvm
$ sudo qemu-system-x86_64 -netdev bridge,id=en0,br=myvirbr0 -device virtio-net-pci,netdev=en0 -kernel "httpreply_unikernel_kvm/build/httpreply_unikernel_kvm_kvm-x86_64" -append "netdev.ipv4_addr=172.44.0.2 netdev.ipv4_gw_addr=172.44.0.1 netdev.ipv4_subnet_mask=255.255.255.0 --" -enable-kvm -nographic 

Booting from ROM..0: Set IPv4 address 172.44.0.2 mask 255.255.255.0 gw 172.44.0.1
en0: Added
en0: Interface is up
Powered by
o.   .o       _ _               __ _
Oo   Oo  ___ (_) | __ __  __ _ ' _) :_
oO   oO ' _ `| | |/ /  _)' _` | |_|  _)
oOo oOO| | | | |   (| | | (_) |  _) :_
 OoOoO ._, ._:_:_,\_._,  .__,_:_, \___)
                   Tethys 0.5.0~b8be82b
Listening on port 8123...
```

Get file ``index.html``:

```
$ wget 172.44.0.2:8123
--2022-02-10 14:06:13--  http://172.44.0.2:8123/
Connecting to 172.44.0.2:8123... connected.
HTTP request sent, awaiting response... 200 OK
Length: unspecified [text/html]
Saving to: ‘index.html.1’

index.html.1                          [ <=>                                                         ]     160  --.-KB/s    in 0s

2022-02-10 14:06:13 (13.6 MB/s) - ‘index.html.1’ saved [160]

test@test:~$
```

If you want to clean up created bridge, run the following:

```
$ sudo ip l set dev myvirbr0 down
$ sudo brctl delbr myvirbr0
```
