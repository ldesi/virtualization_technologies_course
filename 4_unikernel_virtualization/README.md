# LESSON 4_Unikernel: Hands-on sessions

---
**NOTE**

This tutorial is completely taken from original GitHub repos https://github.com/unikraft/kraft and [https://github.com/unikraft/catalog/tree/main/examples/helloworld-c](https://github.com/unikraft/catalog/tree/main/examples/helloworld-c)
Please refer to them for other details.

---


To begin using [Unikraft](https://unikraft.org) you can use the
command-line utility `kraft`, which is a companion tool used for
defining, configuring, building, and running Unikraft applications.
With `kraft` you can seamlessly create a build environment for your
unikernel and painlessly manage dependencies for its build.

## Installing kraft

The `kraft` tool and Unikraft build system have several packages to be installed; please run the following command (on `apt-get`-based systems) to
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
$ kraft build
```

```
# kraft build
[?] select target:
    helloworld (fc/arm64)
    helloworld (fc/x86_64)
    helloworld (linuxu/x86_64)
    helloworld (qemu/arm64)
  ▸ helloworld (qemu/x86_64)
    helloworld (xen/x86_64)
```

Choose ``helloworld (qemu/x86_64)`` and, finally, run the application:
```
$ kraft run
o.   .o       _ _               __ _
Oo   Oo  ___ (_) | __ __  __ _ ' _) :_
oO   oO ' _ `| | |/ /  _)' _` | |_|  _)
oOo oOO| | | | |   (| | | (_) |  _) :_
 OoOoO ._, ._:_:_,\_._,  .__,_:_, \___)
                 Telesto 0.16.1~26012b7
Hello, world!
```

If you want more control you can also configure, build, and run the application manually by entering directory ``.unikraft/unikraft``and run the following:

```
$ make menuconfig
```

Finally, you can build the application:
```
$ make
```

Under ``.unikraft/build`` there are all build artifacts. For a ``qemu-x86_64``-based build, for example, the kernel binary generated is named ``helloworld_qemu-x86_64``. It can be run by explicitly using ``qemu-system-x86_64`` binary as in the following:

```
sudo qemu-system-x86_64 -kernel ".unikraft/build/helloworld_qemu-x86_64" \
                        -enable-kvm \
                        -nographic
```

- If you built the application bare-metal, choose `linuxu/x86_64`, and run it by:
```
# cd ~/catalog/examples/helloworld-c
# .unikraft/build/helloworld_linuxu-x86_64

Powered by
o.   .o       _ _               __ _
Oo   Oo  ___ (_) | __ __  __ _ ' _) :_
oO   oO ' _ `| | |/ /  _)' _` | |_|  _)
oOo oOO| | | | |   (| | | (_) |  _) :_
 OoOoO ._, ._:_:_,\_._,  .__,_:_, \___)
                 Telesto 0.16.1~26012b7
Hello, world!
```

- If you built the application for `xen`:
  - First, you need to create a configuration file `app-helloworld.cfg`.
    It should look something like:
    ```
    name          = "app-helloworld"
    vcpus         = "1"
    memory        = "4"
    kernel        = ".unikraft/build/helloworld_xen-x86_64"
    ```
  - To run the application you can use:
    ```
    xl create -c app-helloworld.cfg
    ```

For more information about `kraft` type `kraft -h` or read the
[documentation](http://docs.unikraft.org).

## Unikraft "nginx" Application

Under ``~catalog/library/nginx/1.15``you can build an ``nginx`` webserver by running ``kraft build`` as usual.

Start nginx unikernel as in the following:

```
kraft run -p 8080:80
```

If you choose a ``qemu-x86_64``-based build, the command above will run the unikernel ``~catalog/library/nginx/1.15/.unikraft/build/nginx_qemu-x86_64`` with slirp network model and a TCP port forwarding from host (port 8080) to the unikernel guest (port 80). To the if the nginx unikernel is running use ``curl`` like in the following:

```
$ curl localhost:8080
<!DOCTYPE html>
<html>
<head>
  <title>Hello, world!</title>
</head>
<body>
  <h1>Hello from Unikraft!</h1>

  <p>This message shows that your installation appears to be working correctly.</p>

  <p></p>For more examples and ideas, visit <a href="https://unikraft.org/docs/">Unikraft's Documentation</a>.</p>
</body>
</html>
```
