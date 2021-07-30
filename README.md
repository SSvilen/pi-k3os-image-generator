# PiCl k3os image generator for Windows

This repository is based on the [@sgielen](https://github.com/sgielen)`s great project ([link](https://github.com/sgielen/picl-k3os-image-generator)). So all credits go to the creators and the contributors of that project.<br>
This project can be used to generate images for k3os compatible with various armv8 (aarch64) devices using Windows, PowerShell, WSL, Docker (you must have WSL2 with Docker Desktop set to use it as an engine) :

- Raspberry Pi model 3B+
- Raspberry Pi model 4

## Getting Started

- Install Raspberry PI Imager.
- Create a configuration file which you would like to apply to your Raspberry Pi.
- For Raspberry Pi devices, you can choose which firmware to use for the build by setting parameter `$RaspberryFirmwareVersion`
  - If unset, the script uses a known good version (set as default value for `$RaspberryFirmwareVersion` Parameter)
  - Set to `latest`, which instructs the script to always pull the latest version available in the raspberry pi firmware repo
  - Set to a specific version, which instructs the script to use that version
- Run the script with the parameters required. For more information run

  ```powershell
  Get-Help .\Build-K3OSImage.ps1
  ```

- Insert the SD cards into the devices, minding correct image type per device type, of course. On first boot, they will resize their root filesystems to the size of the SD card.After this, they will reboot.
- On subsequent boots, k3os will run automatically with the correct per-device config.yaml.

## Performing updates

When you want to simply change the config.yaml of your devices, you don't need to reprovision the SD cards. Instead, you can
run `sudo mount -o remount,rw /k3os/system` on the running systems and make the changes to `/k3os/system/config.yaml`, then
reboot. Make sure to keep the config.yaml up-to-date with the respective yaml in your checkout of this repository, in case
you do need to provision a new image, though!

When new versions of k3os come out, or there are changes to this repository that you want to perform onto your devices, it's
easiest to create a new image and flash it onto the device. However, depending on where your cluster data is stored, this may
mean you need to reapply cluster configs to your master. This is a TODO, as I'd like to make this easier.

## Troubleshooting

If your device should be supported, but has problems coming up, attach a screen and check what happens during boot. Normally,
on initial boot, you should see the Linux kernel booting, some messages appearing regarding the resizing of the root FS, then
a reboot; on subsequent boots, you should see OpenRC starting, then the k3os logo and a prompt to login.

At all times, check whether your power supply is sufficient if you're having problems. Raspberry Pis and similar devices are
known to experience weird issues when the power supply cannot provide sufficient power or an improper (data/no charge) cable
is used. Double-check this, or try another one, even if you think the problem is unlikely to be caused by this.

If you don't see Linux kernel messages appearing at all, but the device is supported, check whether you formatted your SD card properly, or check if you can run Raspbian or Armbian on the device.

If you see Linux appearing but there is an error during resizing, something may be up with your SD card. Change the
init.resizefs to include the line "exec busybox ash" before where you expect the error occurs, and run the steps manually
until you find the culprit.

If resizing works but after reboot you cannot get start k3os, use the same trick: include the line "exec busybox ash" in
the normal init script and try to start k3os manually. You may need to load additional kernel modules.

Anytime you think the scripts or documentation could be improved, please file an issue or a PR and we'll be happy to help.

The initial code was written by Dennis Brentjes and Sjors Gielen, with many
[contributors since then](https://github.com/sgielen/picl-k3os-image-generator/graphs/contributors),
thanks to all. Further contributions welcome!

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
