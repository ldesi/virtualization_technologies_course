## Summary

In this tutorial we will see:
* Basic installation of Xen 4.14 on Debian 11
* Creation of PV, HVM, PVHVM guests
* Xen tracing
* Xen build from source code

### Setup network

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

### Install XEN

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
Once booted, check Xen version:

```
root@test:~# dmesg |grep Xen\ version
[    0.361489] Xen version: 4.14.4-pre (preserve-AD)
root@test:~#
```

Please, note that we give all physical CPUs to Dom0 with the given configuration. Generally, it is recommended to limit the number of Dom0 vCPUs in order to not heavily impact execution of DomUs. Accordingly, we need to edit the configuration file /etc/default/grub.d/xen.cfg by using the ``dom0_max_vcpus``parameter to specify the amount of vCPUs (e.g., 2 vCPUs) allocated to Dom0:

```
...
GRUB_CMDLINE_XEN="com2=115200,8n1 console=com2 dom0_mem=1024M,max:1024M dom0_max_vcpus=2 iommu=dom0-passthrough"
...
```

### PV guest

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

Newer version of Xen can include these services within the ``xen`` service.

Now, create a logical volume within a volume group to be used as virtual disk space by Xen DomUs.

```
root@test:~# apt-get install lvm2
root@test:~# fdisk -l
Disk /dev/sda: 40 GiB, 42949672960 bytes, 83886080 sectors
Disk model: VMware Virtual S
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: dos
Disk identifier: 0x50e6b91f

Device     Boot    Start      End  Sectors  Size Id Type
/dev/sda1  *        2048 39061503 39059456 18,6G 83 Linux
/dev/sda2       39061504 46874623  7813120  3,7G 82 Linux swap / Solaris
/dev/sda3       46876670 83884031 37007362 17,6G  5 Extended
/dev/sda5       46876672 83884031 37007360 17,6G 8e Linux LVM
root@test:~# pvcreate /dev/sda5
  Physical volume "/dev/sda5" successfully created.
root@test:~# vgcreate test-vg /dev/sda5
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
  LV           VG      Attr       LSize Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  lv_vm_ubuntu test-vg -wi-a----- 5,00g
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
root@test:~# xl create -c /etc/xen/ubuntu-pv-example.cfg
```

The -c in this command tells xl that we wish to connect to the guest virtual console, a paravirtualized serial port within the domain that xen-create-image configured to listen with a getty. This command also starts the VM.

Further, note line ``disk = [ '/dev/test-vg/lv_vm_ubuntu,raw,xvda,rw' ]``. The disk device drive could be:
- ``xvda``: disk is not emulated by using qemu-dm. ``xvd`` device is always the best choice to use if you want use a PV driver;
- ``hda``: disk will be emulated as an IDE device, which will be initialized by the IDE driver of the Linux guest;
- ``sda`` will be emulated as a SCSI device, which will be initialized by the sym53c8xx driver. The ``sym53c8xx`` driver is often build as a kernel module.

To shutdown created guest:
```
root@test:~# xl shutdown ubuntu-pv-example
```
After creating VM and installing OS, you can get the assigned IP with:

```
root@test:# xl network-list ubuntu-pv-example
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

Finally, to boot the VM from the virtual disk you need to comment the _kernel_ and _ramdisk_ option, and remove the comment on _bootloader_ option in the ``/etc/xen/ubuntu-pv-example.cfg`` configuration file:
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
8ebed37e-a7a9-43cb-bb7b-ab42db3e3df8  8    ubuntu-pv-example
root@test:/home/test#
```

You can connect to the running VM console by running:

```
root@test:~# xl console ubuntu-pv-example
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

### HVM and PVHVM guests

The HVM mode inlcudes using hardware support to virtualize CPU. Virtualization hardware extensions are used to boost performance of the emulation. HVM requires Intel VT-x or AMD-V hardware extensions, and QEMU is used to emulate devices. In order to leverage paravirtualized drivers, you can leverage also PVHVM mode, which allows running PV guests within HVM context.
The [ubuntu-hvm-example.cfg](ubuntu-hvm-example.cfg) and [ubuntu-pvhvm-example.cfg](ubuntu-pvhvm-example.cfg) configuration files allow running respectively a HVM and PVHVM VM. In particular, once you start the VM in PVHVM, try to check, e.g., if pv drivers are loaded wihtin the HVM machine.

```
test@test:~$ dmesg |grep -i xen
...
[    0.000000] Xen Platform PCI: I/O protocol version 1
[    0.000000] Netfront and the Xen platform PCI driver have been compiled for this kernel: unplug emulated NICs.
[    0.000000] Blkfront and the Xen platform PCI driver have been compiled for this kernel: unplug emulated disks.
...
test@test:~$
```

### Xen tracing

#### Xen trace with PV mode
```
# xentrace -T 10 xentrace_sample_pv
# xenalyze xentrace_sample_pv

No output defined, using summary.
Using VMX hardware-assisted virtualization.
scan_for_new_pcpu: Activating pcpu 1 at offset 0
Creating vcpu 1 for dom 32768
init_pcpus: through first trace write, done for now.
Creating domain 0
Creating vcpu 0 for dom 0
Using first_tsc for d0v0 (1240203 cycles)
scan_for_new_pcpu: Activating pcpu 0 at offset 13912
Creating vcpu 0 for dom 32768
Creating domain 32767
Creating vcpu 1 for dom 32767
Creating vcpu 1 for dom 0
Creating vcpu 0 for dom 32767
Using first_tsc for d32767v0 (33279 cycles)
read_record: read returned zero, deactivating pcpu 0
deactivate_pcpu: setting d32767v0 to state LOST
read_record: read returned zero, deactivating pcpu 1
deactivate_pcpu: setting d0v0 to state LOST
deactivate_pcpu: Setting max_active_pcpu to -1
Total time: 7.49 seconds (using cpu speed 2.40 GHz)
--- Log volume summary ---
 - cpu 0 -
 gen   :          8
 sched :     282600
 pv    :      67844
 - cpu 1 -
 gen   :         40
 sched :     314136
 pv    :     132084
 hw    :       3816
|-- Domain 0 --|
 Runstates:
   blocked:     733  7.34s 24030691 {6863514|50726184|150083580}
  partial run:     796  0.13s 389582 {136749|521490|16292226}
  full run:     101  0.01s 201363 { 93450|238689|2795235}
  partial contention:     767  0.01s  35681 { 29553| 35343|950217}
  concurrency_hazard:     136  0.00s  39034 { 21921| 74259|323034}
  full_contention:      73  0.00s  25470 { 16917| 30129| 42684}
 Grant table ops:
  Done by:
  Done for:
 Populate-on-demand:
  Populated:
  Reclaim order:
  Reclaim contexts:
-- v0 --
 Runstates:
   running:     467  0.09s 482969 {235239|559149|1667760}
  runnable:     466  0.01s  45718 { 25734| 40902|1040919}
        wake:     466  0.01s  45718 { 25734| 40902|1040919}
   blocked:     466  7.39s 38052846 {13925433|73252032|180014346}
 cpu affinity:       1 17975278527 {17975278527|17975278527|17975278527}
   [1]:       1 17975278527 {17975278527|17975278527|17975278527}
PV events:
  emulate privop  2718
  hypercall  4161
    mmu_update                   [ 1]:     21
    stack_switch                 [ 3]:    700
    xen_version                  [17]:     11
    iret                         [23]:   1041
    vcpu_op                      [24]:   1031
    set_segment_base             [25]:    700
    mmuext_op                    [26]:     15
    sched_op                     [29]:    468
    evtchn_op                    [32]:     14
    physdev_op                   [33]:    159
    sysctl                       [35]:      1
...
```

#### Xen trace with HVM mode

```
# xentrace -T 10 xentrace_sample_hvm
# xenalyze xentrace_sample_hvm

...

+-vmentry:     495516
+-vmexit :     825860
+-handler:    1190580

...

PV events:
  emulate privop  78872
  hypercall  495358
    stack_switch                 [ 3]:  77018
    xen_version                  [17]:    898
    iret                         [23]: 206222
    vcpu_op                      [24]:  65303
    set_segment_base             [25]:  77018
    sched_op                     [29]:  28084
    evtchn_op                    [32]:  33104
    physdev_op                   [33]:    182
    (null)
...
-- v0 --
 Runstates:
   running:   32165  1.78s 132906 { 93171|134841|252207}
  runnable:   32163  0.88s  65633 { 38001| 53037|12807477}
        wake:   32163  0.88s  65633 { 38001| 53037|12807477}
   offline:   32163  4.81s 358831 {165516|556005|3623421}
 cpu affinity:       1 17926696455 {17926696455|17926696455|17926696455}
   [2]:       1 17926696455 {17926696455|17926696455|17926696455}
Exit reasons:
 EXTERNAL_INTERRUPT          4  0.01s  0.13% 5650049 cyc {19515|1951695|20600784}
  THERMAL_APIC(250): 2
  CALL_FUNCTION(251): 1
  EVENT_CHECK(252): 1
 PENDING_INTERRUPT         182  0.00s  0.02% 20325 cyc {17553|19749|25695}
 CR_ACCESS                 458  0.00s  0.02%  8330 cyc { 6237| 7740|10845}
   cr0      458  0.00s  0.02%  8330 cyc { 6237| 7740|10845}
 IO_INSTRUCTION          40647  5.48s 73.40% 323721 cyc { 8436|254469|798909}
   (no handler)    22758  2.81s 37.61% 296248 cyc {150810|258420|468636}
...
```


### Build Xen from source code

```
# git clone git://xenbits.xen.org/xen.git

# //update /sbin/installkernel

# vim /sbin/installkernel

...
CONFIG_XEN_DOM0=y
CONFIG_XEN_PRIVILEGED_GUEST=y
...

# apt-get install build-essential

# apt-get install bcc bin86 gawk bridge-utils iproute2 libcurl4 libcurl4-openssl-dev bzip2 transfig tgif mercurial make gcc libc6-dev zlib1g-dev python3 python3-dev python3-pip libnl-3-dev python3-twisted libncurses5-dev patch libvncserver-dev libsdl-dev libjpeg62-turbo-dev iasl libbz2-dev e2fslibs-dev git uuid-dev ocaml ocaml-findlib libx11-dev bison flex xz-utils libyajl-dev gettext libpixman-1-dev libaio-dev markdown pandoc libpci-dev pciutils

# pip install ninja

# cd /path/to/xen

# ./configure
# make dist

or 

$ make dist-xen
$ make dist-tools
$ make dist-docs

# make install

or

# make install-xen
# make install-tools
# make install-docs
# ... etc ...


# update-grub2

$ ... etc ...

```

### KVM virtio and vhost

#### Start VM with virtio-net device:

```
# qemu-system-x86_64 -drive "file=bionic-server-cloudimg-amd64.img,format=qcow2" \
	-drive "file=user-data.img,format=raw" \
	-device e1000,netdev=net0 -netdev user,id=net0 \
	-m 1024 -smp 4 -enable-kvm
```

#### Start VM with vhost-net device

On the host you need a kernel with ``CONFIG_VHOST_NET=y`` and in the guest you need a kernel with ``CONFIG_PCI_MSI=y``. Then:

```
qemu-system-x86_64 -drive "file=bionic-server-cloudimg-amd64.img,format=qcow2" \
	-drive "file=user-data.img,format=raw" \
	-netdev type=tap,id=guest0,vhost=on -device virtio-net-pci,netdev=guest0 \
	-m 1024 -smp 4 -enable-kvm
```



### References

- https://help.ubuntu.com/community/Xen
- https://wiki.xenproject.org/wiki/Xen_Project_Beginners_Guide
- https://wiki.xenproject.org/wiki/Xen_Linux_PV_on_HVM_drivers


