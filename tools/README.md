## Pre-requisites for building the packages yourself

- Docker(if you want to build the .deb packages)

## Build the .deb packages on your ubuntu machine

```
docker build -t deb-builder:18.04 -f tools/ubuntu-18.04.Dockerfile .;
docker run -it -w /elastos-supernode-setup -v /Users/kpachhai/dev/src/github.com/noderators/elastos-supernode-setup:/elastos-supernode-setup -e USER=501 -e GROUP=20 --rm deb-builder:18.04 /elastos-supernode-setup/tools/build_packages.sh
```
