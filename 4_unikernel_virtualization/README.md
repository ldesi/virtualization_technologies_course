# Unikraft helloworld tutorial

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

