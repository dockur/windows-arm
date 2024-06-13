<h1 align="center">Windows ARM64<br />
<div align="center">
<a href="https://github.com/dockur/windows-arm"><img src="https://github.com/dockur/windows-arm/raw/master/.github/logo.png" title="Logo" style="max-width:100%;" width="128" /></a>
</div>
<div align="center">

[![Build]][build_url]
[![Version]][tag_url]
[![Size]][tag_url]
[![Package]][pkg_url]
[![Pulls]][hub_url]

</div></h1>

Windows for ARM in a Docker container, for devices like the Raspberry Pi 5 and many others.

*Note: for KVM acceleration you need a Linux-based operating system, as it's not available on MacOS unfortunately.*

## Features ✨

 - Multi-language
 - ISO downloader
 - KVM acceleration
 - Web-based viewer

## Video 📺

[![Youtube](https://img.youtube.com/vi/xhGYobuG508/0.jpg)](https://www.youtube.com/watch?v=xhGYobuG508)

## Usage  🐳

Via Docker Compose:

```yaml
services:
  windows:
    container_name: windows
    image: dockurr/windows-arm
    environment:
      VERSION: "win11"
    devices:
      - /dev/kvm
    cap_add:
      - NET_ADMIN
    ports:
      - 8006:8006
      - 3389:3389/tcp
      - 3389:3389/udp
    stop_grace_period: 2m
```

Via Docker CLI:

```bash
docker run -it --rm -p 8006:8006 --device=/dev/kvm --cap-add NET_ADMIN --stop-timeout 120 dockurr/windows-arm
```

Via Kubernetes:

```shell
kubectl apply -f kubernetes.yml
```

## FAQ 💬

### How do I use it?

  Very simple! These are the steps:
  
  - Start the container and connect to [port 8006](http://localhost:8006) using your web browser.

  - Sit back and relax while the magic happens, the whole installation will be performed fully automatic.

  - Once you see the desktop, your Windows installation is ready for use.
  
  Enjoy your brand new machine, and don't forget to star this repo!

### How do I select the Windows version?

  By default, Windows 11 will be installed. But you can add the `VERSION` environment variable to your compose file, in order to specify an alternative Windows version to be downloaded:

  ```yaml
  environment:
    VERSION: "win11"
  ```

  Select from the values below:
  
  | **Value** | **Version**           | **Platform** | **Size** |
  |---|---|---|---|
  | `win11`   | Windows 11 Pro        | ARM64        | 4.9 GB   |
  | `win11e`  | Windows 11 Enterprise | ARM64        | 4.8 GB   |
  | `win10`   | Windows 10 Pro        | ARM64        | 3.5 GB   |
  | `ltsc10`  | Windows 10 LTSC       | ARM64        | 4.1 GB   |  
  | `win10e`  | Windows 10 Enterprise | ARM64        | 3.4 GB   |

> [!TIP]
> To install x86 and x64 versions of Windows,  use [dockur/windows](https://github.com/dockur/windows/).

### How do I select the Windows language?

  By default, the English version of Windows will be downloaded. But you can add the `LANGUAGE` environment variable to your compose file, in order to specify an alternative language:

  ```yaml
  environment:
    LANGUAGE: "French"
  ```

  You can choose between: 🇦🇪 Arabic, 🇧🇬 Bulgarian, 🇨🇳 Chinese, 🇭🇷 Croatian, 🇨🇿 Czech, 🇩🇰 Danish, 🇳🇱 Dutch, 🇬🇧 English, 🇪🇪 Estionian, 🇫🇮 Finnish, 🇫🇷 French, 🇩🇪 German, 🇬🇷 Greek, 🇮🇱 Hebrew, 🇭🇺 Hungarian, 🇮🇹 Italian, 🇯🇵 Japanese, 🇰🇷 Korean, 🇱🇻 Latvian, 🇱🇹 Lithuanian, 🇳🇴 Norwegian, 🇵🇱 Polish, 🇵🇹 Portuguese, 🇷🇴 Romanian, 🇷🇺 Russian, 🇷🇸 Serbian, 🇸🇰 Slovak, 🇸🇮 Slovenian, 🇪🇸 Spanish, 🇸🇪 Swedish, 🇹🇭 Thai, 🇹🇷 Turkish and 🇺🇦 Ukrainian.

### How do I select the keyboard layout?

  If you want to use a keyboard layout or locale that is not the default for your selected language, you can add the `KEYBOARD` and `REGION` variables with a culture code, like this:

  ```yaml
  environment:
    REGION: "en-US"
    KEYBOARD: "en-US"
  ```

> [!NOTE]  
>  Changing these values will have no effect after the installation already has been performed. Use the control panel inside Windows in that case.

### How do I change the storage location?

  To change the storage location, include the following bind mount in your compose file:

  ```yaml
  volumes:
    - /var/win:/storage
  ```

  Replace the example path `/var/win` with the desired storage folder.

### How do I change the size of the disk?

  To expand the default size of 64 GB, add the `DISK_SIZE` setting to your compose file and set it to your preferred capacity:

  ```yaml
  environment:
    DISK_SIZE: "256G"
  ```
  
> [!TIP]
> This can also be used to resize the existing disk to a larger capacity without any data loss.

### How do I share files with the host?

  Open 'File Explorer' and click on the 'Network' section, you will see a computer called `host.lan`. Double-click it and it will show a folder called `Data`, which can be binded to any folder on your host via the compose file:

  ```yaml
  volumes:
    -  /home/user/example:/shared
  ```

The example folder `/home/user/example` will be available as ` \\host.lan\Data`.

> [!TIP]
> You can map this path to a drive letter in Windows, for easier access.

### How do I install a custom image?

  In order to download an unsupported ISO image that is not selectable from the list above, specify the URL of that ISO in the `VERSION` environment variable, for example:
  
  ```yaml
  environment:
    VERSION: "https://example.com/win.iso"
  ```

  Alternatively, you can also skip the download and use a local file instead, by binding it in your compose file in this way:
  
  ```yaml
  volumes:
    - /home/user/example.iso:/custom.iso
  ```

  Replace the example path `/home/user/example.iso` with the filename of your desired ISO file, the value of `VERSION` will be ignored in this case.

### How do I run a script after installation?

  To run your own script after installation, you can create a file called `install.bat` and place it in a folder together with any additional files it needs (software to be installed for example). Then bind that folder in your compose file like this:

  ```yaml
  volumes:
    -  /home/user/example:/oem
  ```

  The example folder `/home/user/example` will be copied to `C:\OEM` during installation and the containing `install.bat` will be executed during the last step.

### How do I perform a manual installation?

  It's best to stick to the automatic installation, as it adjusts various settings to prevent common issues when running Windows inside a virtual environment.

  However, if you insist on performing the installation manually, add the following environment variable to your compose file:

  ```yaml
  environment:
    MANUAL: "Y"
  ```

### How do I change the amount of CPU or RAM?

  By default, the container will be allowed to use a maximum of 2 CPU cores and 4 GB of RAM.

  If you want to adjust this, you can specify the desired amount using the following environment variables:

  ```yaml
  environment:
    RAM_SIZE: "8G"
    CPU_CORES: "4"
  ```

### How do I configure the username and password?

  By default, a user called `Docker` is created during the installation, with an empty password.

  If you want to use different credentials, you can change them in your compose file:

  ```yaml
  environment:
    USERNAME: "bill"
    PASSWORD: "gates"
  ```

### How do I connect using RDP?

  The web-viewer is mainly meant to be used during installation, as its picture quality is low, and it has no audio or clipboard for example.

  So for a better experience you can connect using any Microsoft Remote Desktop client to the IP of the container, using the username `Docker` and by leaving the password empty.

  There is a RDP client for [Android](https://play.google.com/store/apps/details?id=com.microsoft.rdc.androidx) available from the Play Store and one for [iOS](https://apps.apple.com/nl/app/microsoft-remote-desktop/id714464092?l=en-GB) in the Apple Store. For Linux you can use [FreeRDP](https://www.freerdp.com/) and on Windows just type `mstsc` in the search box.

### How do I assign an individual IP address to the container?

  By default, the container uses bridge networking, which shares the IP address with the host. 

  If you want to assign an individual IP address to the container, you can create a macvlan network as follows:

  ```bash
  docker network create -d macvlan \
      --subnet=192.168.0.0/24 \
      --gateway=192.168.0.1 \
      --ip-range=192.168.0.100/28 \
      -o parent=eth0 vlan
  ```
  
  Be sure to modify these values to match your local subnet. 

  Once you have created the network, change your compose file to look as follows:

  ```yaml
  services:
    windows:
      container_name: windows
      ..<snip>..
      networks:
        vlan:
          ipv4_address: 192.168.0.100

  networks:
    vlan:
      external: true
  ```
 
  An added benefit of this approach is that you won't have to perform any port mapping anymore, since all ports will be exposed by default.

> [!IMPORTANT]  
> This IP address won't be accessible from the Docker host due to the design of macvlan, which doesn't permit communication between the two. If this is a concern, you need to create a [second macvlan](https://blog.oddbit.com/post/2018-03-12-using-docker-macvlan-networks/#host-access) as a workaround.

### How can Windows acquire an IP address from my router?

  After configuring the container for macvlan (see above), it is possible for Windows to become part of your home network by requesting an IP from your router, just like a real PC.

  To enable this mode, add the following lines to your compose file:

  ```yaml
  environment:
    DHCP: "Y"
  devices:
    - /dev/vhost-net
  device_cgroup_rules:
    - 'c *:* rwm'
  ```

> [!NOTE]  
> In this mode, the container and Windows will each have their own separate IPs.

### How do I add multiple disks?

  To create additional disks, modify your compose file like this:
  
  ```yaml
  environment:
    DISK2_SIZE: "32G"
    DISK3_SIZE: "64G"
  volumes:
    - /home/example:/storage2
    - /mnt/data/example:/storage3
  ```

### How do I pass-through a disk?

  It is possible to pass-through disk devices directly by adding them to your compose file in this way:

  ```yaml
  devices:
    - /dev/sdb:/disk1
    - /dev/sdc:/disk2
  ```

  Use `/disk1` if you want it to become your main drive, and use `/disk2` and higher to add them as secondary drives.

### How do I pass-through a USB device?

  To pass-through a USB device, first lookup its vendor and product id via the `lsusb` command, then add them to your compose file like this:

  ```yaml
  environment:
    ARGUMENTS: "-device usb-host,vendorid=0x1234,productid=0x1234"
  devices:
    - /dev/bus/usb
  ```
  
> [!IMPORTANT]
> In case the device is a USB disk drive, please wait until after the installation is completed before connecting it. Otherwise the installation may fail, as the order of the disks can get rearranged.

### How do I verify if my system supports KVM?

  To verify that your system supports KVM, run the following commands:

  ```bash
  sudo apt install cpu-checker
  sudo kvm-ok
  ```

  If you receive an error from `kvm-ok` indicating that KVM acceleration can't be used, please check whether:

  - the virtualization extensions (`Intel VT-x` or `AMD SVM`) are enabled in your BIOS.

  - you are running an operating system that supports them, like Linux or Windows 11 (macOS and Windows 10 do not unfortunately).

  - you enabled "nested virtualization" if you are running the container inside a virtual machine.

  - you are not using a cloud provider, as most of them do not allow nested virtualization for their VPS's.

  If you didn't receive any error from `kvm-ok` at all, but the container still complains that `/dev/kvm` is missing, it might help to add `privileged: true` to your compose file (or `--privileged` to your `run` command), to rule out any permission issue.

### Is this project legal?

  Yes, this project contains only open-source code and does not distribute any copyrighted material. Any product keys found in the code are just generic placeholders provided by Microsoft for trial purposes. So under all applicable laws, this project will be considered legal.

## Stars 🌟
[![Stars](https://starchart.cc/dockur/windows-arm.svg?variant=adaptive)](https://starchart.cc/dockur/windows-arm)

## Disclaimer ⚖️

*The product names, logos, brands, and other trademarks referred to within this project are the property of their respective trademark holders. This project is not affiliated, sponsored, or endorsed by Microsoft Corporation.*

[build_url]: https://github.com/dockur/windows-arm/
[hub_url]: https://hub.docker.com/r/dockurr/windows-arm/
[tag_url]: https://hub.docker.com/r/dockurr/windows-arm/tags
[pkg_url]: https://github.com/dockur/windows-arm/pkgs/container/windows-arm

[Build]: https://github.com/dockur/windows-arm/actions/workflows/build.yml/badge.svg
[Size]: https://img.shields.io/docker/image-size/dockurr/windows-arm/latest?color=066da5&label=size
[Pulls]: https://img.shields.io/docker/pulls/dockurr/windows-arm.svg?style=flat&label=pulls&logo=docker
[Version]: https://img.shields.io/docker/v/dockurr/windows-arm/latest?arch=amd64&sort=semver&color=066da5
[Package]: https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fraw.githubusercontent.com%2Fipitio%2Fghcr-pulls%2Fmaster%2Findex.json&query=%24%5B%3F(%40.owner%3D%3D%22dockur%22%20%26%26%20%40.repo%3D%3D%22windows-arm%22%20%26%26%20%40.image%3D%3D%22windows-arm%22)%5D.pulls&logo=github&style=flat&color=066da5&label=pulls
