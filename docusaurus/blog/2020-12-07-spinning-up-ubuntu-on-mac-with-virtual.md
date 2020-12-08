---
slug: spinning-up-ubuntu-on-mac-with-virtual
title: Spinning up Ubuntu VMs on the Mac using ☷virtual v0.0.2
author: Colin Black
author_title: Principal Consultant, PNDLM
author_url: https://github.com/cblackcom
author_image_url: https://avatars0.githubusercontent.com/u/6203274?s=400&v=4
tags: [ubuntu, apple silicon, arm, m1, intel]
---

This article will show you how to use **☷virtual**, based on Apple's brand-new [Virtualization.framework](https://developer.apple.com/documentation/virtualization), to quickly start and run an Ubuntu 20.04 LTS virtual machine on any Intel or Apple Silicon Mac *(excluding the DTK)* running Big Sur.

### Step 1: Install ☷virtual

First grab the latest version 0.0.2 or later.  You can either:

* clone [the repo](https://github.com/kendfinger/virtual) and compile using Xcode 12.2, or
* install using [Homebrew](https://brew.sh):

```bash
brew install kendfinger/tools/virtual

# or if you are upgrading from 0.0.1
brew upgrade kendfinger/tools/virtual
```

### Step 2: Grab a kernel and ramdisk

Aside from the normal CD-image based installers, Ubuntu offers [cloud images](https://cloud-images.ubuntu.com) which have been specifically created for use in virtual machines on top of hypervisors like **☷virtual**.

In order to boot, Virtualization.framework requires us to have a `vmlinuz` kernel executable and an `initrd` initial ramdisk separated from the image.  Conveniently, Ubuntu offers these for download separately, so just grab each of them below:

For Intel Macs:
* https://cloud-images.ubuntu.com/focal/current/unpacked/focal-server-cloudimg-amd64-vmlinuz-generic
* https://cloud-images.ubuntu.com/focal/current/unpacked/focal-server-cloudimg-amd64-initrd-generic

For Apple Silicon (ARM) Macs:
* https://cloud-images.ubuntu.com/focal/current/unpacked/focal-server-cloudimg-arm64-vmlinuz-generic
* https://cloud-images.ubuntu.com/focal/current/unpacked/focal-server-cloudimg-arm64-initrd-generic

**Important!**  Sometimes the `vmlinuz` file is compressed with gzip, and if so it won't work as-is.  Check the file you downloaded with the `file` command, and if it says something about `gzip` data, then add a `.gz` to the filename, and use `gunzip` to decompress it.  Moving on!

![prompt4](https://storage.googleapis.com/static.cblack.org/blog/virtual-20201203/prompt4.png)

### Step 3: Get a "raw" Ubuntu disk image

Ubuntu ships all of its cloud images in the popular "qcow2" format, but with Virtualization.framework you'll need it in a "raw" format.

*(Option:  Skip this step and download an image I've already converted [here](https://github.com/cblackcom/virtual-ubuntucloud-images/releases).  Make sure to `gunzip` them before use.  If you find them useful, [leave me a comment](https://github.com/cblackcom/virtual-ubuntucloud-images/issues/1) and let me know, and we'll do some work to keep them updated.)*

No fear, the conversion is a quick operation using the "qemu-img" utility.  You can get this utility on the Mac by using Homebrew (`brew install qemu`) or if you have a separate Ubuntu box handy (`sudo apt install qemu-utils`).

Now, grab the latest Ubuntu cloud image:
* For Intel Macs: https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img
* For Apple Silicon (ARM) Macs: https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-arm64.img

For clarity, I suggest renaming the downloaded file to something like `focal.qcow2`, just to make it obvious that it's the one in its original qcow2 format.

Now expand and convert the disk image to raw format.  In the below commands, the `10G` part means I want to allow the disk image to be 10 GB.  Adjust according to your preferences.  Note that this raw file will consume that entire amount of your computer's disk up front, so be sure you have it available to give away!

```bash
qemu-img resize focal.qcow2 10G
qemu-img convert -f qcow2 focal.qcow2 -O raw focal.raw
```

You won't need the qcow2 version going forward, but I personally like to keep a copy on hand in case I want to make more machines later. 

### Step 4: Get a "cloud-init" disk image

For your first boot, you'll also need a very small disk image which instructs "cloud-init" (a piece of software included with the image) on how to set up the users (and other details) on your virtual machine.

I recommend saving yourself the hassle: to get up and running quickly you can just [download this configuration image I've already created](https://raw.githubusercontent.com/cblackcom/virtual-ubuntucloud-images/master/cloud-config.raw) which sets up a default user named `virtual` with the password `password`.

If you want to create your own configuration though, I haven't found a super easy or clean way to do this on the Mac, so you'll need access to an Ubuntu machine.  First, install "cloud-image-utils" and "whois" (`sudo apt install cloud-image-utils whois`) in order to get access to the `cloud-localds` and `mkpasswd` utilities.
<!--On Mac use Homebrew to install "cdrtools" (`brew install cdrtools`), or on -->

Pick a password, then use `mkpasswd` to generate an SHA-512 hash for it:

```bash
mkpasswd --method=SHA-512 --rounds=4096
# (you will be prompted to type your selected password)
```

Create a file called `cloud-config.yaml` and customize the below to your liking, pasting your password hash as the value for the `passwd:` key.  The example below will setup a new user of `virtual` with the password of `password`, and it will have full sudo rights.

```yaml
#cloud-config
users:
  - name: virtual
    # this password is 'password'
    passwd: $6$rounds=4096$p/wwO8kiDXwYBJ1F$g1gwvobPyJVAaW/0N6AeamYHm4P0jVaZ3HDkCeStElOu0gcpbzPZ28W7QThp/p9zkMk8ZARxtvDBEucvD0smG/
    lock_passwd: false
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
chpassword: { expire: false }
ssh_pwauth: true
```

There's tons of other options you can use to configure your new machine; check out the [cloud-init documentation site](https://cloudinit.readthedocs.io/en/latest/topics/examples.html) to learn all about it.

Finally, run the command to create your configuration image:

<!--
# On Mac
mkisofs -output cloud-config.raw -volid cidata -joliet -rock cloud-config.yaml
-->

```bash
cloud-localds -v cloud-config.raw cloud-config.yaml
```

### Step 5:  First Boot! 

With that you have everything you need.  You can put together your command line arguments to boot `virtual` noting the following:

* Use `-c` to specify some kernel command line arguments:
    * `console=hvc0` will cause boot messages to output to your current terminal (useful for debugging!)
    * `root=/dev/vda` tells Linux to boot into your disk image
* Carefully (!) specify the correct filenames for `-k` (kernel), `-r` (initrd), the first `-d` which must be your Ubuntu disk image, and the second `-d` which must be your cloud-init image.  The ordering of the `-d` arguments **must** be the Ubuntu disk image first, or the machine may not boot.
* Finally specify `-n` to enable networking.

```bash
virtual run -c "console=hvc0 root=/dev/vda1" -k focal-XXX-vmlinuz -r focal-XXX-initrd -d focal.raw -d cloud-config.raw -n
```

With any luck your machine should boot, and you should see a prompt like this.  (You might need to hit enter a time or two after everything boots to see the prompt!)
![image1](https://storage.googleapis.com/static.cblack.org/blog/virtual-20201203/prompt1.png)

You should now be able to login using the credentials you chose in Step 4.

### Step 6: Note your IP and MAC Addresses

On first boot, each virtual machine you start will get its own random and unique MAC address assigned to it.  You'll need to note the address so that whenever you reboot the machine you ask virtual to assign the same MAC address so that your networking works consistently.

Before you shut the virtual machine down, you need to grab the IP and MAC addresses that have been assigned to your machine for future use.  *Be careful not to use ctrl-c as that will terminate your machine.*

From your virtual machine's prompt, run the following commands:

```bash
sudo ip -4 addr show dev enp0s1
sudo ip link show dev enp0s1
```

The output of the commands will display your virtual machine's IP address (circled first, between `inet` and `/`) and its MAC address (circled second).

![image1](https://storage.googleapis.com/static.cblack.org/blog/virtual-20201203/prompt3.png)

Copy this information down, then shutdown your machine:

```bash
sudo shutdown now
```

### Step 7: Alter your boot arguments

So now, going forward, you can reboot your virtual machine at any time using this command, noting the following:

* The command arguments are the same as Step 5, except we're **removing** the second `-d` specification, and we're adding `-a`, where you should carefully paste in the MAC address you grabbed in Step 6.
* Carefully (!) specify the correct filenames for `-k` (kernel), `-r` (initrd), and `-d` (your Ubuntu disk image).
* Finally specify `-n` to enable networking.

```bash
virtual run -a "96:ef:e3:3e:7a:47" -c "console=hvc0 root=/dev/vda1" -k focal-XXX-vmlinuz -r focal-XXX-initrd -d focal.raw -n  
```

### Step 8: SSH in

Finally, in order to get a better overall terminal experience (and to avoid accidentally hitting ctrl-c and terminating your machine), I recommend minimizing the terminal you've used to boot your machine, and instead opening a new one to SSH in to your virtual machine to perform commands.  In the example below, of course, specify the username you chose and the IP address you grabbed in Step 5.

```bash
ssh virtual@192.168.64.21
```

## Congratulations!

You now have a working Ubuntu virtual machine built on **☷virtual**.  It goes without saying you can create and run several machines simultaneously and network them together for all sorts of possibilities.  Now, get on to experimenting!

I know Kenneth is excited to announce several goals for the project in the near future.  Stay tuned to this blog for more!

Oh and also, if you want to submit feedback for this tutorial, please comment on this GitHub issue:
https://github.com/cblackcom/virtual/issues/1
