# Deploy IBM Cloud Private Workshop Environment to IBM Cloud with Terraform

## Requirements

* [Terraform](https://www.terraform.io/downloads.html)
* [IBM Cloud provider for Terraform](https://ibm-cloud.github.io/tf-ibm-docs/#using-terraform-with-the-ibm-cloud-provider)
* [Softlayer CLI](https://softlayer-api-python-client.readthedocs.io/en/latest/install/)
* [Softlayer API Key](https://knowledgelayer.softlayer.com/procedure/retrieve-your-api-key)

## Deploy

You will need to collect some information from the Softlayer admin page before you can proceeed. Here's how to get those details:

_Softlayer username and API key_

* Go to the [Softlayer Control page](https://control.softlayer.com/)
* Look at the top right and note which account you're logged in as.  You may have more than one account. IBMers will likely have at least a default personal account and an account from their organization. Pick one that has rights to provision capacity in Softlayer.
* Now go [edit your user profile](https://control.softlayer.com/account/user/profile).
* Scroll down to the bottom and look for the section _API Access Information_
* You will have an "API Username" "Authentication key". The "API Username" will be something like 9999999_shortname@us.ibm.com.
* Copy both of these values into a local text file.  You will need them when you configure the Terraform script.  If you don't have an authentication key, [follow these instructions](https://knowledgelayer.softlayer.com/procedure/generate-api-key)
* Next, go look at your [devices in Softlayer](https://control.softlayer.com/devices)
* Pick a device and look at the details.
* Halfway down the list of details, you will see the _Network_ section in two columns. The public subnet VLAN is on the left, the private subnet VLAN is on the right.
* The subnet will have a name like `wdc01.fcr05a.918`. The first substring identifies the data center. In this case it's data center 01 in Washington DC. Take note of that data center identifier and store it in the same place where you put you Softlayer user ID and API key.
* Next, click on the _public_ VLAN link.  You'll go to a page such as [https://control.softlayer.com/network/vlans/2262109](https://control.softlayer.com/network/vlans/2262109)
* That long number at the end of the URL is the public VLAN ID. Record that number.
* Click the Back button on your browser to get back to the device summary page.
* Click on the _private_ VLAN link and perform the same data collection.
* Record the ID of the private VLAN
* You should now have your Softlayer user ID, API key, data center ID, public VLAN ID, and private VLAN ID.
* You're done with the Softlayer admin page. Go ahead and close the browser.

_SSH Keys_

* Go back to the a command line and change directory to where you cloned the git repository.
* The root of the git repo is `deploy-ibm-cloud-private`. From there, cd to `terraform/ibmcloud`
* Now you will create an ssh key pair and register it with Softlayer.
* The name you give the key in Softlayer has to be unique. This can be tricky if you are using a shared account.  You can't just call it `ssh-key`.
* For now, use your IBM shortname to make the key ID unique. For the following steps, replace _shortname_ with your own actual shortname.
* On the command line, enter
```bash
ssh-keygen -f shortname_ssh_key -P ""
```

* You will end up with two files in the current directory, `shortname_ssh_key` (the private key) and `shortname_ssh_key.pub` (the public key)
* Next, you'll register the public key with Softlayer by executing
```bash
slcli sshkey add -f shortname_ssh_key.pub shortname_ssh_key
```

* Assuming you're successful, you should see a message saying `SSH key added` followed by the hex signature.
* Finally, you will take all of the above information and put it into the `variables.tf` file. Populate the fields as per this table:

variable name | data
--------------|-------------
key_name  | shortname_ssh_key
key_file | full path to the private key file
datacenter  | data center ID, e.g. wdc01
public_vlan_id | 7-digit public VLAN ID
private_vlan_id | 7-digit public VLAN ID

* By default, variables.tf sets the ICP version to 3.1.2, adjust this if desired. Save your changes to variables.tf and proceed.

* configure terraform environment variables with the SL username and api key from above:

```bash
  export TF_VAR_ibm_sl_username="$VALUE"
  export TF_VAR_ibm_sl_api_key="$VALUE"
```

Initialize Terraform:

```bash
$ cd terraform/ibmcloud
$ terraform init
Initializing modules...
- module.icpprovision
  Getting source "github.com/ibm-cloud-architecture/terraform-module-icp-deploy?ref=2.3.7"

Initializing provider plugins...
- Checking for available provider plugins on https://releases.hashicorp.com...
- Downloading plugin for provider "null" (1.0.0)...
- Downloading plugin for provider "tls" (1.2.0)...

The following providers do not have any version constraints in configuration,
so the latest version was installed.

To prevent automatic upgrades to new major versions that may contain breaking
changes, it is recommended to add version = "..." constraints to the
corresponding provider blocks in configuration, with the constraint strings
suggested below.

* provider.ibm: version = "~> 0.14"
* provider.null: version = "~> 1.0"
* provider.tls: version = "~> 1.2"

Terraform has been successfully initialized!
```

_Note: If you see the following error `Error retrieving SSH key: SOAP-ENV:Client: Bad Request (HTTP 200)` comment out the line
beginning with `endpoint_url` from `~/.softlayer`._

Next start the ICP deploy / install (answer 'yes' when prompted):

```
$ terraform apply
data.softlayer_ssh_key.public_key: Refreshing state...

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  + create
...
...
module.icpprovision.null_resource.icp-install (remote-exec): PLAY RECAP *********************************************************************
module.icpprovision.null_resource.icp-install (remote-exec): 169.62.86.XXX              : ok=99   changed=54   unreachable=0    failed=0
module.icpprovision.null_resource.icp-install (remote-exec): 169.62.86.XXX              : ok=98   changed=54   unreachable=0    failed=0
module.icpprovision.null_resource.icp-install (remote-exec): 169.62.86.XXX              : ok=150  changed=91   unreachable=0    failed=0
module.icpprovision.null_resource.icp-install (remote-exec): 169.62.86.XXX              : ok=98   changed=54   unreachable=0    failed=0
module.icpprovision.null_resource.icp-install (remote-exec): 169.62.86.XXX              : ok=146  changed=92   unreachable=0    failed=0
module.icpprovision.null_resource.icp-install (remote-exec): localhost                  : ok=248  changed=155  unreachable=0    failed=0

module.icpprovision.null_resource.icp-install (remote-exec): POST DEPLOY MESSAGE ************************************************************

module.icpprovision.null_resource.icp-install (remote-exec): The Dashboard URL: https://169.62.86.XXX:8443, default username/password is admin/admin
...
module.icpprovision.null_resource.icp-install (remote-exec): Playbook run took 0 days, 0 hours, 29 minutes, 35 seconds

module.icpprovision.null_resource.icp-install: Creation complete after 29m39s (ID: 5488852745900281561)
...
module.icpprovision.null_resource.icp-worker-scaler (remote-exec): 169.62.86.XXX is still here
module.icpprovision.null_resource.icp-worker-scaler (remote-exec): 169.62.86.XXX is still here
module.icpprovision.null_resource.icp-worker-scaler: Creation complete after 3s (ID: 350935943102654483)

Apply complete! Resources: 18 added, 0 changed, 0 destroyed.
```

wait a few minutes then check you can access the provided URL from above. If it fails you may just need to wait a while longer for it to come online.

See [Workshop setup readme](/README.md) for next steps.
