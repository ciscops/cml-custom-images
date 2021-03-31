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
    - extract tar.gz files from signed bin NED files
    ```
    e.g. sh ncs-5.3-cisco-nx-5.13.1.1.signed.bin
    ```  
    - copy extracted x.tar.gz files to ./packer_nso/installResources
    - ./packer_nso/installResources should look something like this:
    ```
    (venv) (base) installResources % ls -1
    ncs-5.5-cisco-asa-6.12.4.tar.gz
    ncs-5.5-cisco-ios-6.69.1.tar.gz
    ncs-5.5-cisco-iosxr-7.33.1.tar.gz
    ncs-5.5-cisco-nx-5.21.4.tar.gz
    nso-5.5.linux.x86_64.installer.bin
    requirements.txt
    ```
4. Find NED IDs in tar.gz files. Note the ID of the NED is the directory created upon tar file extraction.
    ```   
    For Example
    % tar -tvf ncs-5.5-cisco-asa-6.12.4.tar.gz
    ...
    -rw-r--r-- jenkins/users   1412 2021-01-20 11:28 cisco-asa-cli-6.12/package-meta-data.xml
    ...
   
   cisco-asa-cli-6.12 is the NED ID
    ```   

5. Edit local-nso-5.5.pkrvars.hcl
    - Add SHA256 hash for your downloaded focal-server-cloudimg-amd64.img
    - Add NED filenames without tar.gz file extension
    - Add NED IDs

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