# CML2 custom images
This repo contains HashiCorp Packer image definitions for custom image creation, mainly
targeting use in Cisco's CML2 simulation environment.

## Prerequisites

- [Packer 1.7.0+](https://www.packer.io/downloads) for HCL2 support

## Network Services Orchestrator (NSO)
1. [Download](http://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img) the current Ubuntu 20.04
   cloud image to [./packer_nso](./packer_nso) directory
2. Determine the current focal-server-cloudimg-amd64.img SHA256 [hash](http://cloud-images.ubuntu.com/focal/current/SHA256SUMS)
3. [Download](https://developer.cisco.com/docs/nso/#!getting-and-installing-nso) the NSO 5.5 Linux evaluation copy
    - Copy the '.signed.bin' file to [./packer_nso/installResources](./packer_nso/installResources)
4. [Download](https://developer.cisco.com/docs/nso/#!getting-and-installing-nso) the Cisco IOS, XR, NXOS, and ASA Network Element Drivers (NEDs)
    - Copy the NED '.signed.bin' files to [./packer_nso/installResources](./packer_nso/installResources)
5. Edit [./packer_nso/local-nso-5.5.pkrvars.hcl](./packer_nso/local-nso-5.5.pkrvars.hcl)
    - Update the SHA256 hash for your downloaded focal-server-cloudimg-amd64.img
    - Add the NED filenames to the ```nso_ned_list``` variable
6. Validate the Packer configuration
    ```commandline
    packer validate -var-file=local-nso-5.5.pkrvars.hcl nso.pkr.hcl
    ```
7. Build the image
    ```commandline
    packer build -var-file=local-nso-5.5.pkrvars.hcl nso.pkr.hcl
    ```

Once the build is finished, you can upload the NSO QCOW2 image from the output folder into CML and
create a new image definition using 'Ubuntu' for the underlying node definition. We strongly recommend
giving the new NSO image definition at least 8GB of memory and 4 vCPUs (a real operational deployment
of NSO would typically require more).

## Netbox
Note the script in [./packer_netbox/scripts/installNetbox.sh](./packer_netbox/scripts/installNetbox.sh) follows instructions
from [https://netbox.readthedocs.io/en/stable/installation/](https://netbox.readthedocs.io/en/stable/installation/)

1. [Download](http://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img) the current Ubuntu 20.04
   cloud image to [./packer_netbox](./packer_netbox) directory
2. Get the current focal-server-cloudimg-amd64.img SHA256 [hash](http://cloud-images.ubuntu.com/focal/current/SHA256SUMS)
3. Edit [./packer_netbox/local-netbox.pkrvars.hcl](./packer_netbox/local-netbox.pkrvars.hcl)
    - Update the SHA256 hash for your downloaded focal-server-cloudimg-amd64.img
4. Validate the Packer configuration
    ```commandline
    packer validate -var-file=local-netbox.pkrvars.hcl netbox.pkr.hcl
    ```
5. Build the image
    ```commandline
    packer build -var-file=local-netbox.pkrvars.hcl netbox.pkr.hcl
    ```

Once the build is finished, you can upload the Netbox QCOW2 image from the output folder into CML and
create a new image definition using 'Ubuntu' for the underlying node definition. We strongly recommend
giving the new Netbox image definition at least 8GB of memory and 4 vCPUs.
