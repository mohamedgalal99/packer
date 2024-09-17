# packer
This packer used to update packes on leafcloud openstack, those images already installed and we create new images from them with latest updates 
- AlmaLinux-9.3
- Debian-12
- Debian-11
- CentOS-Stream-9
- AlmaLinux-8.9
- Rocky-8.9
- Ubuntu-22.04
- CentOS-Stream-8
- Ubuntu-20.04
- Rocky-9.3
- Ubuntu-24.04

`variables.pkrvars.hcl` is encrypted using Production key, you need to decrypt before running validation and build 

To install openstack  and ansible plugin 
```
packer init plugins.pkr.hcl
```

To validate one of files
```
packer validate -var-file=variables.pkrvars.hcl ubuntu2004.pkr.hcl
```

To build an image
```
packer build -var-file=variables.pkrvars.hcl ubuntu2004.pkr.hcl
```

To build all images at once
```
packer build -var-file=variables.pkrvars.hcl .
```
