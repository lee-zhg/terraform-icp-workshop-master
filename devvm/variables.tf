##### SoftLayer Access Credentials ######
variable "ibm_sl_username" { default = "" }
variable "ibm_sl_api_key" { default = "" }

variable "key_name" {
  description = "Name or reference of SSH key to provision softlayer instances with"
  default = "timrosl_ssh_key"
}

variable "key_file" {
  description = "Path to private key on for above public key"
  default = "/Users/timro/.ssh/timrosl_ssh_key"
}

##### Common VM specifications ######
variable "datacenter" { default = "dal12" }
variable "domain" { default = "icp.demo" }
variable "public_vlan_id" { default = "2340143"}
variable "private_vlan_id" { default = "2340145"}

##### ICP settings #####

# Name of the ICP installation, will be used as basename for VMs
variable "instance_name" { default = "gmicp" }

##### ICP Instance details ######
variable "devvm" {
  type = "map"
  default = {
    nodes       = "1"
    cpu_cores   = "8"
    boot_size   = "100" // GB
    local_disk  = false
    memory      = "16384"
    network_speed= "100"
    private_network_only=false
    hourly_billing=true
  }

}
