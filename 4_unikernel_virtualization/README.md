# kraft

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

## Building an Application

The simplest way to get the sources for, build and run an application
is by running the following commands:

    kraft list update
    kraft up -t helloworld@staging ./my-first-unikernel

At present, Unikraft and kraft support the following applications:

* [C "hello world"](https://github.com/unikraft/app-helloworld) (`helloworld`);
* [C "http reply"](https://github.com/unikraft/app-httpreply) (`httpreply`);
* [C++ "hello world"](https://github.com/unikraft/app-helloworld-cpp) (`helloworld-cpp`);
* [Golang](https://github.com/unikraft/app-helloworld-go) (`helloworld-go`);
* [Python 3](https://github.com/unikraft/app-python3) (`python3`);
* [Micropython](https://github.com/unikraft/app-micropython) (`micropython`);
* [Ruby](https://github.com/unikraft/app-ruby) (`ruby`);
* [Lua](https://github.com/unikraft/app-lua) (`lua`);
* [Click Modular Router](https://github.com/unikraft/app-click) (`click`);
* [JavaScript (Duktape)](https://github.com/unikraft/app-duktape) (`duktape`);
* [Web Assembly Micro Runtime (WAMR)](https://github.com/unikraft/app-wamr) (`wamr`);
* [Redis](https://github.com/unikraft/app-redis) (`redis`);
* [Nginx](https://github.com/unikraft/app-nginx) (`nginx`);
* [SQLite](https://github.com/unikraft/app-sqlite) (`sqlite`);

For more information about that command type `kraft up -h`. For more information
about `kraft` type ```kraft -h``` or read the documentation at
[Unikraft's website](https://docs.unikraft.org). If you find any problems please
[fill out an issue](https://github.com/unikraft/tools/issues/new/choose). Thank
you!

## Contributing

Please refer to the [`README.md`](https://github.com/unikraft/unikraft/blob/master/README.md)
as well as the documentation in the [`doc/`](https://github.com/unikraft/unikraft/tree/master/doc)
subdirectory of the main Unikraft repository.


# Unikraft "hello world" Application

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

