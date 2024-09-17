# Installing the T-rex miner for mining on Leafcloud servers

This setup uses Hashicorp Packer to create a base image with the dependencies 
(in apt_install.sh) and creates a systemd service to make it run on boot.

To change settings; change the boot command in the start-mining.sh file

## Build
```
packer init .

# -var is optional to give the image a custom name
packer build -var image_name=eth-miner-a30 eth-base-img.pkr.hcl
```

## Starting servers

Since the image completely self start you can simply create them on a private network
and don't really have to log in, and you can start multiple at the same time.

For example like so:
```
openstack server create \
	--image eth-miner-a30 \
	--flavor eg1.a30x1.V8-32 \
	--network private \
	--key-name shared_leafcloud \
	--min 1 \
	--max 2 \
	a30-miner
```

## Check output

On this page you can see if the servers are giving mining output:

https://eth.2miners.com/account/3P4ZdLh6EbJUgG1LJ4ZDV1NMVi2zLhah21