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

Get up xenbr0 interface and check info about the bridge:

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

By default on a Xen system, the majority of the host's memory is assigned to dom0 on boot, and dom0's size is dynamically modified ("ballooned") automatically to accommodate new guests which are started.

To properly configure Dom0 Xen, you need to modify the _/etc/default/grub.d/xen.cfg_ file. For example, add the following to give 1Gb RAM to Dom0, and enable serial logging (assuming COM2) both from Linux kernel and Xen:

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

and run:

```
/usr/sbin/grub-mkconfig -o /boot/grub/grub.cfg
```

Now, if you reboot the machine, you could see another choice, Xen with Debian.

### 1. Create a PV Guest (basic option)

Check info about the hypervisor and Dom0 including version, free memory, etc.:

```
//Start xen services
root@test:~# /etc/init.d/xencommons start
root@test:~# /etc/init.d/xendomains start
root@test:~# /etc/init.d/xen-watchdog start
root@test:~# /etc/init.d/xendriverdomain start

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

Create 5Gb volume for the guest:
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

Start the creation of the guest.
Copy guest configuration file (in this repository) into /etc/xen and then run:

```
root@test:~# xl create -c /etc/xen/ubuntu_bionic1804LTS.cfg
```

The -c in this command tells xl that we wish to connect to the guest virtual console, a paravirtualized serial port within the domain that xen-create-image configured to listen with a getty. This command also starts the VM.

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

Finally, to boot the VM from the virtual disk you need to comment the _kernel_ and _ramdisk_ option, and remove the comment on _bootloader_ option in the ``/etc/xen/ubuntu_bionic1804LTS.cfg`` configuration file:
```
#kernel = "/root/vmlinuz"
#ramdisk = "/root/initrd.gz"
bootloader = "/usr/lib/xen-4.11/bin/pygrub"
```
Please, note that the bootloader path depends on the installed Xen version.
You can check the created and started VM by listing running VMs (you can notice that Dom0 VM is running):

```
root@test:/home/test# xl vm-list
UUID                                  ID    name
00000000-0000-0000-0000-000000000000  0    Domain-0
8ebed37e-a7a9-43cb-bb7b-ab42db3e3df8  8    bionic1804LTS
root@test:/home/test#
```

You can connect to the running VM console by running:

```
root@test:~# xl console bionic1804LTS
```

and disconnecting from the console using:

```
Ctrl+]
```

You can also install a VM by using libvirt and virt-install:

```
root@test:~# apt install libvirt-clients libvirt-daemon-system virtinst
root@test:~# virt-install --connect=xen:/// --name ubuntu_test_14.04 --ram 1024 --disk ubuntu_test_14.04.img,size=5 --location http://ftp.ubuntu.com/ubuntu/dists/trusty/main/installer-amd64/ --graphics none
```

### References

- https://help.ubuntu.com/community/Xen
- https://wiki.xenproject.org/wiki/Xen_Project_Beginners_Guide


