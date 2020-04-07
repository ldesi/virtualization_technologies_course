Hands on summary:

* Basic usage of KVM/QEMU
* Use of virt-manager
* Use of virsh

## Basic usage of QEMU

### 1. Check requirements for KVM

```
# egrep -c '(vmx|svm)' /proc/cpuinfo
# 0 not good
# 1 or more is good
```

If 0 it means that VT-x or AMD-v are not enabled.
Please enable it by BIOS. If you are using a VM, you need to enable virtualization extensions according to your type-2 hypervisors.

### 2. Check if KVM module is loaded

```
# lsmod | grep kvm  
#prints:
#kvm
#kvm_intel or kvm_amd
```
If not loaded, please load it by:

```
#eg. for intel
modprobe kvm  
sudo modprobe kvm_intel
```

Check kernel logs if something wrong:

```
# dmesg | grep kvm
```

### 3. Install qemu-kvm userspace tool

```
# sudo apt-get install qemu-kvm
```

Check details about created special device /dev/kvm:

``` 
# ls -la /dev/kvm
crw-rw---- 1 root kvm 10, 232 Mar 11 18:01 /dev/kvm
```
The device is a charcter device and it is writable by kvm group.

### 4. Creating and managing images

In order to start a VM, we need to create a "container" or virtual drive image. In this tutorial, we will use qcow2 format. It is the most featured format in QEMU and is meant to replace qcow. This format support sparse images independent of underlying fs capabilities. It supports multiple VM-snapshots, encryption (AES) and compression. 

Creating of images is supported through qemu-img command.

```
# apt-get install qemu-utils
```


For example, create an image of 5Gb:

```
# qemu-img create -f qcow2 test_ubuntu_mini.img 5G
```

Then, we can start the installation of minimal ubuntu as it will be done on a physical machine. We need to specify
how many virtual CPUs we want (_-smp_ flag), how much RAM will be dedicated to VM, for example 1Gb of RAM (-m 1024). Then, start qemu by booting form cdrom (-boot c).

```
# wget http://archive.ubuntu.com/ubuntu/dists/bionic-updates/main/installer-amd64/current/images/netboot/mini.iso
# qemu-system-x86_64 -smp 4 -hda test_ubuntu_mini.img -cdrom mini.iso -m 1024 -boot c -enable-kvm
```
If we omit _-enable-kvm_ option, we will experience very bad performance because we are not exploiting the VT-x extensions.

After installation, we can boot VM from hard disk by:

```
# qemu-system-x86_64 -hda test_ubuntu_mini.img -m 1024 -enable-kvm
```
By default, QEMU starts the virtual machine by using the default SLIRP network backend. To ensure that ping works, you need to run as root:

```
sysctl -w net.ipv4.ping_group_range='0 2147483647'
```

#### Use Ubuntu cloud images

In order to speedup installation of a new VM, you can also use a pre-installed Linux image.
For example, we want to deploy an Ubuntu 18.04 cloud image using QEMU.
Download the image from https://cloud-images.ubuntu.com/bionic/current/bionic-server-cloudimg-amd64.img.
Please, note that such cloud images use Cloud-init VM initialization. Thus, you need to configure such cloud-init parameters.
To configure cloud-init, run the following:

```
# apt-get install cloud-utils genisoimage

# cat >my-init-data <<EOF
#cloud-config
password: test
chpasswd: { expire: False }
ssh_pwauth: True
EOF

# cloud-localds my-init-data.img my-init-data
```
Assuming that we store the Ubuntu image file and init image file under /root, we can run the VM by using the following:

```
# qemu-system-x86_64 \
-drive "file=/root/bionic-server-cloudimg-amd64.img,format=qcow2" \
-drive "file=/root/user-data.img,format=raw" \
-device e1000,netdev=net0 -netdev user,id=net0 \
-m 1024 \
-smp 4 \
-enable-kvm
```

In this case, we specified the e1000 network device, still using the SLIRP network backend. If we want to use SSH to access the VM, we need to forward the SSH host traffic to SSH VM traffic using the ``hostfwd=tcp::PORT-:22``option, where PORT is the port that we chosen for SSH forwarding. In the following, we chosen port 1234:

```
# qemu-system-x86_64 \
-drive "file=/root/bionic-server-cloudimg-amd64.img,format=qcow2" \
-drive "file=/root/user-data.img,format=raw" \
-device e1000,netdev=net0 -netdev user,id=net0,hostfwd=tcp::1234-:22 \
-m 1024 \
-smp 4 \
-enable-kvm
```

## Use _virt-manager_

_virt-manager_ provides a GUI for managing virtual machines. You need to install it by:

```
# apt-get install virt-manager
```
and simply start using:

```
# virt-manager
```
The steps to follow are similar to the ones seen before for Basic usage section.

## Use _virsh_

To install a new VM by command line you can use the _virt-install_ command. The following command starts the installation of Ubuntu (as before) in a VM with 4 vCPU, 1Gb RAM, IDE disk of 5Gb, and a TAP device (backend) on network bridge _virbr0_ (default bridge). We enable also QEMU/KVM acceleration by ``--accelerate``flag.

Before starting VM installation, if you want to get some details about _virbr0_ network bridge, you can list the current network list and get info about it:
```
root@test:~# virsh net-list
 Name                 State      Autostart     Persistent
----------------------------------------------------------
 default              active     yes           yes

root@test:~# virsh net-info default
Name:           default
UUID:           f8854cf1-d499-4733-a7b6-bf97bf092938
Active:         yes
Persistent:     yes
Autostart:      yes
Bridge:         virbr0

root@test:~#
```
The virbr0, or "Virtual Bridge 0" interface is used for NAT (Network Address Translation). It is provided by the **libvirt** library by default once installed the first time.


To install the VM, run:

```
virt-install -n ubuntu_test_virsh \
--description "Test VM with Ubuntu virsh" \
--os-type=Linux \
--os-variant=ubuntu18.04 \
--ram=1024 \
--vcpus=4 \
--disk path=/root/test_ubuntu_mini_virsh.img,bus=ide,size=5  \
--cdrom /root/mini.iso \
--network bridge:virbr0
--accelerate	
```

A configuration named __VM_NAME.xml__ wille be stored at __/etc/libvirt/qemu/__ by default.

To get a list of os variants install _libosinfo-bin_, and run ``osinfo-query os``.

Once _ubuntu_test_virsh_ virtual machine is running, you can manage it in many different ways, with virsh:

```
# virsh start ubuntu_test_virsh
# virsh reboot ubuntu_test_virsh
# virsh shutdown ubuntu_test_virsh
# virsh suspend ubuntu_test_virsh
# virsh resume ubuntu_test_virsh
```

To manage snapshots:

Create snapshots
```
virsh snapshot-create-as $VM_ID $SNAPSHOT_NAME
```
```
virsh snapshot-create-as $VM_ID $SNAPSHOT_NAME $DESCRIPTION
```
List current snapshots
```
virsh snapshot-list $VM_ID
```
Restore snapshots
```
virsh snapshot-revert $VM_ID $SNAPSHOT_NAME
```
Delete snapshots
```
virsh snapshot-delete $VM_ID $SNAPSHOT_NAME
```


To delete the VM:
```
# virsh destroy ubuntu_test_virsh && virsh undefine ubuntu_test_virsh
```





