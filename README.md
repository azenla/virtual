# virtual

Boot Linux VMs in a single command on macOS using the new [Virtualization.framework](https://developer.apple.com/documentation/virtualization)

## Requirements

- macOS Big Sur
- Xcode 12

## Usage

```bash
$ virtual -k ubuntu/vmlinuz -r ubuntu/initrd -d ubuntu/ubuntu.iso --network
Ubuntu 20.04 LTS ubuntu hvc0
ubuntu login:
```

## Credits

Huge credit to [Khaos Tian](https://github.com/KhaosT) who inspired this project by the creation of [SimpleVM](https://github.com/KhaosT/SimpleVM).
