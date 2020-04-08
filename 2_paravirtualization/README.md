## Summary

In this tutorial we will see:
* Basic installation of Xen on Debian 10
* Create a PV Guest

## Basic installation of Xen on Debian 10

### 1. Setup network

```
root@test:# apt-get install bridge-utils
```

In a bridged setup, it is required that we assign the IP address to the bridged interface. Configure network interfaces so that they persist after reboot:

```
$ sudo vi /etc/network/interfaces

# The primary network interface
allow-hotplug ens33
iface ens33 inet manual

auto xenbr0
iface xenbr0 inet dhcp
	bridge_ports ens33
```

Get up xenbr0 interface and check info about bridge:

```
root@test:~# ifup xenbr0

root@test:~# brctl show
bridge name	bridge id		STP enabled	interfaces
xenbr0		8000.00505686cf9c	no		ens33
root@test:~#
```

### 1. Install XEN

```
root@test:~# apt-get install xen-system-amd64
```

By default on a Xen system the majority of the hosts memory is assigned to dom0 on boot and dom0's size is dynamically modified ("ballooned") automatically in order to accommodate new guests which are started.

In order to properly configure Dom0 Xen, you need to modify the _/etc/default/grub.d/xen.cfg_ file. For example, add the following to give 1Gb RAM to Dom0, and enable serial logging (assuming COM2) both from Linux kernel and Xen:

```
root@test:~# vim /etc/default/grub.d/xen.cfg

...
GRUB_SERIAL_COMMAND="serial --unit=0 --speed=115200 --word=8 --parity=no --stop=1"
GRUB_TERMINAL="console serial"
GRUB_TIMEOUT=5
GRUB_CMDLINE_XEN="com2=115200,8n1 console=com2 dom0_mem=1024M,max:1024M iommu=dom0-passthrough"
GRUB_CMDLINE_LINUX="console=ttyS1 console=hvc0"
...
```

Now, if you reboot the machine, you could see another choice, Xen with Debian.

### 1. Create a PV Guest (basic option)

Check info about the hypervisor and Dom0 including version, free memory etc:

```
root@test:~# xl list
Name                                        ID   Mem VCPUs	State	Time(s)
Domain-0                                     0 16072     8     r-----     366.8
root@test:~#
```

List lvm groups:

```
root@test:~# vgs
  VG      #PV #LV #SN Attr   VSize    VFree
  test-vg   1   2   0 wz--n- <199.76g 60.06g
root@test:~#
```

Create 5Gb volume for guest:
```
root@test:~# lvcreate -L 5G -n lv_vm_ubuntu /dev/test-vg
``` 
List logical volumes:

```
root@test:~# lvs
  LV           VG      Attr       LSize    Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  lv_vm_ubuntu test-vg -wi-a-----    5.00g
  root         test-vg -wi-ao---- <123.70g
  swap_1       test-vg -wi-ao----  <16.00g
root@test:~#
```

Get Netboot Images. For example, we get Ubuntu 18.04 LTS netboot image:

```
root@test:~# wget http://archive.ubuntu.com/ubuntu/dists/bionic-updates/main/installer-amd64/current/images/netboot/xen/vmlinuz
root@test:~# wget http://archive.ubuntu.com/ubuntu/dists/bionic-updates/main/installer-amd64/current/images/netboot/xen/initrd.gz
```

Start creation of guest.
Copy guest configuration file (in this repository) into /etc/xen and then run:

```
root@test:~# xl create -c /etc/xen/ubuntu_bionic1804LTS.cfg
```

The -c in this command tells xl that we wish to connect to the guest virtual console, a paravirtualized serial port within the domain that xen-create-image configured to listen with a getty.

To shutdown created guest:
```
root@test:~# xl shutdown ubuntu_bionic1804LTS
```
After creating VM and installing OS, you can get the assigned IP with:

```
root@test:# xl network-list bionic1804LTS
Idx BE Mac Addr.         handle state evt-ch   tx-/rx-ring-ref BE-path
0   0  00:16:3e:57:db:c5     0     4     -1    -1/-1          /local/domain/0/backend/vif/2/0
```

And listen on bridge interface through:

```
root@test:# tcpdump -n -i ens33 ether src 00:16:3e:57:db:c5
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on ens33, link-type EN10MB (Ethernet), capture size 262144 bytes
18:15:09.378914 IP 172.16.39.175.36147 > 172.16.39.2.53: 17113+ SRV? _http._tcp.us.archive.ubuntu.com. (50)
18:15:09.473039 IP 172.16.39.175.45498 > 172.16.39.2.53: 27290+ A? us.archive.ubuntu.com. (39)
18:15:09.473210 IP 172.16.39.175.45498 > 172.16.39.2.53: 11939+ AAAA? us.archive.ubuntu.com. (39)
```
You can notice that 172.16.39.175 is the IP of PV Guest.

Finally, to boot the VM from the virtual disk you need to comment the _kernel_ and _ramdisk_ option, and remove comment on _bootloader_ option in the ``/etc/xen/ubuntu_bionic1804LTS.cfg`` configuration file:
```
#kernel = "/root/vmlinuz"
#ramdisk = "/root/initrd.gz"
bootloader = "/usr/lib/xen-4.11/bin/pygrub"
```
Now you can connect to VM console by:

```
xl console ubud1
```

disconnecting from the console using:

```
Ctrl+]
```

### Create a HVM Guest (some hardware emulated)

```
# apt-get install qemu-system-x86
```

TODO

### References

- https://help.ubuntu.com/community/Xen
- https://wiki.xenproject.org/wiki/Xen_Project_Beginners_Guide


