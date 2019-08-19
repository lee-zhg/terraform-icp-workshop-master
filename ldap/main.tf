provider "ibm" {
    softlayer_username = "${var.ibm_sl_username}"
    softlayer_api_key  = "${var.ibm_sl_api_key}"
}

data "softlayer_ssh_key" "public_key" {
  label = "${var.key_name}"
}

resource "ibm_compute_vm_instance" "icpldap" {
    count       = "${var.ldap["nodes"]}"

    datacenter  = "${var.datacenter}"
    domain      = "${var.domain}"
    hostname    = "${format("${lower(var.instance_name)}-ldap%01d", count.index + 1) }"

    os_reference_code = "UBUNTU_16_64"

    cores       = "${var.ldap["cpu_cores"]}"
    memory      = "${var.ldap["memory"]}"
    disks       = ["${var.ldap["boot_size"]}"]
    local_disk  = "${var.ldap["local_disk"]}"
    network_speed         = "${var.ldap["network_speed"]}"
    hourly_billing        = "${var.ldap["hourly_billing"]}"
    private_network_only  = "${var.ldap["private_network_only"]}"
    public_vlan_id        = "${var.public_vlan_id}"
    private_vlan_id        = "${var.private_vlan_id}"

    user_metadata = "{\"value\":\"newvalue\"}"

    ssh_key_ids = ["${data.softlayer_ssh_key.public_key.id}"]
        
    provisioner "remote-exec" {
        script = "postinst.sh"
    }
}