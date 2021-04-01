# cml-custom-images
This repo contains HashiCorp Packer image definitions for custom qcow2 image creation.

## Network Services Orchestrator (NSO)
1. Download current http://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img to packer_nso directory
2. Get current focal-server-cloudimg-amd64.img SHA256 hash from http://cloud-images.ubuntu.com/focal/current/SHA256SUMS

3. Download NSO 5.5 Linux evaluation copy from: https://developer.cisco.com/docs/nso/#!getting-and-installing-nso
    -  Extract installer binary
   ```
    sh nso-5.3.darwin.x86_64.signed.bin
   ```
    - copy the 'x.installer.bin' file to ./packer_nso/installResources
4. Download IOS, XR, NXOS, and ASA Network Element Drivers (NEDs) from: https://developer.cisco.com/docs/nso/#!getting-and-installing-nso
    - copy the NED 'X.signed.bin' files to ./packer_nso/installResources

5. Edit local-nso-5.5.pkrvars.hcl
    - Add SHA256 hash for your downloaded focal-server-cloudimg-amd64.img
    - Add NED filenames to nso_ned_list

6. Validate Packer configuration
    ```
    packer validate -var-file=local-nso-5.5.pkrvars.hcl nso.pkr.hcl
    ```
7. Build Image
    ```
    packer build -var-file=local-nso-5.5.pkrvars.hcl nso.pkr.hcl
    ```

Now you can upload the nso .qcow2 file from your output folder into CML

## Netbox
./packer_netbox/scripts/installNetbox.sh follows instructions from https://netbox.readthedocs.io/en/stable/installation/
1. Download current http://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img to packer_nso directory
2. Get current focal-server-cloudimg-amd64.img SHA256 hash from http://cloud-images.ubuntu.com/focal/current/SHA256SUMS
3. Edit local-netbox.pkrvars.hcl
    - Add SHA256 hash for your downloaded focal-server-cloudimg-amd64.img

4. Validate Packer configuration
    ```
    packer validate -var-file=local-netbox.pkrvars.hcl nso.pkr.hcl
    ```
5. Build Image
    ```
    packer build -var-file=local-netbox.pkrvars.hcl nso.pkr.hcl
    ```

Now you can upload the Netbox .qcow2 file from your output folder into CML