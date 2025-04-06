## aerthOS builder

[![aerthOS website](https://img.shields.io/badge/aerthOS-Website-white?labelColor=black&style=for-the-badge)](https://aerth.github.io/aerthos)
[![source git](https://img.shields.io/badge/GitHub-link-white?labelColor=black&style=for-the-badge)](https://github.com/aerth/aerthos)
[![GitHub release (latest by date)](https://img.shields.io/github/v/release/aerth/aerthos?labelColor=black&style=for-the-badge)](https://github.com/aerth/aerthos/releases/latest)
[![GitHub all releases](https://img.shields.io/github/downloads/aerth/aerthos/total?labelColor=black&style=for-the-badge)](https://github.com/aerth/aerthos/releases)
[![GitHub commits since latest release](https://img.shields.io/github/commits-since/aerth/aerthos/latest?labelColor=black&style=for-the-badge)](https://github.com/aerth/aerthos/commits/master/)
[![GitHub pull requests](https://img.shields.io/github/issues-pr/aerth/aerthos?labelColor=black&style=for-the-badge)](https://github.com/aerth/aerthos/pulls)
[![GitHub issues](https://img.shields.io/github/issues/aerth/aerthos?labelColor=black&style=for-the-badge)](https://github.com/aerth/aerthos/issues)

![GitHub commit activity](https://img.shields.io/github/commit-activity/m/aerth/aerthos?labelColor=black&style=for-the-badge)
![GitHub last commit](https://img.shields.io/github/last-commit/aerth/aerthos?labelColor=black&style=for-the-badge)
![GitHub contributors](https://img.shields.io/github/contributors/aerth/aerthos?labelColor=black&style=for-the-badge)
![GitHub forks](https://img.shields.io/github/forks/aerth/aerthos?labelColor=black&style=for-the-badge)
![GitHub stars](https://img.shields.io/github/stars/aerth/aerthos?labelColor=black&style=for-the-badge)
![GitHub watchers](https://img.shields.io/github/watchers/aerth/aerthos?labelColor=black&style=for-the-badge)
![GitHub repo size](https://img.shields.io/github/repo-size/aerth/aerthos?labelColor=black&style=for-the-badge)
![GitHub language count](https://img.shields.io/github/languages/count/aerth/aerthos?labelColor=black&style=for-the-badge)

[![GitHub Discussions](https://img.shields.io/github/discussions/aerth/aerthos?labelColor=black&style=for-the-badge)](https://github.com/aerth/aerthos/discussions)

### about aerthOS Live

fast powerful Live OS for building software.

XFCE desktop on Debian trixie.

occupies two USB slots: "aerthos w/persistence" and "your yubikey"

### requirements

16GB (or bigger) USB stick, will be erased. this will need to be plugged in at all times. faster the better. 

**Recommended**: yubikey for u2f (eg: login, sudo, git, gpg, ssh, etc, keepassxc secret service)

**Recommended**: additional partition for project workspaces (see below)

### usage

Lots of apt source repositories are setup and ready to go.

A ton of software is installed by default. In future releases, packages will be able to be selected via dialog menu.

### workspace partitions

There are some limitations regarding the persistence partition and (re)building the aerthOS Live ISO.  You can build the **aerthOS Live ISO** from a mounted workspace partition, one with plenty of space that lives on your NVME or SSD.

Workspace partitions **should not be** a USB drive.

After creating, you can add workspace partitions to the bottom of /etc/fstab, for example:

`UUID=7ba8c09a-7f5b-427b-a300-2a2956fea576 /y ext4 defaults 0 2`

## BUILDING

build the iso (`tmp/live-build/aerthOSLive-amd64.hybrid.iso`)

```
sudo make
```

to flash to a disk

```
sudo ./flash.bash flash sdx
```

to remove all the generated files (over 10GB)

```
sudo make clean
```
