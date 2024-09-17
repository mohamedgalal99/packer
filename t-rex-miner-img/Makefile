
build:
	packer build -var image_name=eth-miner-a30 eth-base-img.pkr.hcl 

create-a30x1:
	for i in {1..8}; \
	do \
		openstack server create \
		--os-cloud leafcloud-vast \
		--image eth-miner-a30 \
		--flavor miner.eg1.a30x1.v4:6 \
		--network private \
		--key-name shared_leafcloud \
		--boot-from-volume 10 \
		a30-miner-1x-$$i; \
	done

create-a30x4:
	for i in {1..4}; \
	do \
		openstack server create \
		--os-cloud leafcloud-vast \
		--image eth-miner-a30 \
		--flavor miner.eg1.a30x4.v4:6 \
		--network private \
		--key-name shared_leafcloud \
		a30-miner-4x-$$i; \
	done


create-v100x2:
	for i in {1..4}; \
	do \
		openstack server create \
		--os-cloud leafcloud-vast \
		--image eth-miner-a30 \
		--flavor miner.eg1.v100x2.v4:6 \
		--network private \
		--key-name shared_leafcloud \
		v100-miner-2x-$$i; \
	done

list:
	os server list --project vast-ai --sort-column Name --sort-ascending
