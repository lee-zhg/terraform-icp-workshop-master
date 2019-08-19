provider "ibm" {
    softlayer_username = "${var.ibm_sl_username}"
    softlayer_api_key  = "${var.ibm_sl_api_key}"
}

data "softlayer_ssh_key" "public_key" {
  label = "${var.key_name}"
}

resource "ibm_compute_vm_instance" "icpmaster" {
    count       = "${var.master["nodes"]}"

    datacenter  = "${var.datacenter}"
    domain      = "${var.domain}"
    hostname    = "${format("${lower(var.instance_name)}-master%01d", count.index + 1) }"

    os_reference_code = "UBUNTU_16_64"

    cores       = "${var.master["cpu_cores"]}"
    memory      = "${var.master["memory"]}"
    disks       = ["${var.master["root_size"]}","${var.master["disk_size"]}"]
    local_disk  = "${var.master["local_disk"]}"
    network_speed         = "${var.master["network_speed"]}"
    hourly_billing        = "${var.master["hourly_billing"]}"
    private_network_only  = "${var.master["private_network_only"]}"
    public_vlan_id        = "${var.public_vlan_id}"
    private_vlan_id        = "${var.private_vlan_id}"

    user_metadata = "{\"value\":\"newvalue\"}"

    ssh_key_ids = ["${data.softlayer_ssh_key.public_key.id}"]
        
    provisioner "remote-exec" {
        script = "scripts/postinst-master.sh"
    }

    provisioner "remote-exec" {
        inline = [
            "apt-get update",
            "apt-get install -y moreutils"
        ]
    }
}

resource "ibm_compute_vm_instance" "icpmanagement" {
    count       = "${var.management["nodes"]}"

    datacenter  = "${var.datacenter}"
    domain      = "${var.domain}"
    hostname    = "${format("${lower(var.instance_name)}-management%01d", count.index + 1) }"

    os_reference_code = "UBUNTU_16_64"

    cores       = "${var.management["cpu_cores"]}"
    memory      = "${var.management["memory"]}"
    disks       = ["${var.management["root_size"]}","${var.management["disk_size"]}"]
    local_disk  = "${var.management["local_disk"]}"
    network_speed         = "${var.management["network_speed"]}"
    hourly_billing        = "${var.management["hourly_billing"]}"
    private_network_only  = "${var.management["private_network_only"]}"
    public_vlan_id        = "${var.public_vlan_id}"
    private_vlan_id        = "${var.private_vlan_id}"

    user_metadata = "{\"value\":\"newvalue\"}"

    ssh_key_ids = ["${data.softlayer_ssh_key.public_key.id}"]
        
    provisioner "remote-exec" {
        script = "scripts/postinst-mgmt.sh"
    }

    provisioner "remote-exec" {
        inline = [
            "apt-get update",
            "apt-get install -y moreutils"
        ]
    }
}

resource "ibm_compute_vm_instance" "icpworker" {
    count       = "${var.worker["nodes"]}"

    datacenter  = "${var.datacenter}"
    domain      = "${var.domain}"
    hostname    = "${format("${lower(var.instance_name)}-worker%01d", count.index + 1) }"

    os_reference_code = "UBUNTU_16_64"

    cores       = "${var.worker["cpu_cores"]}"
    memory      = "${var.worker["memory"]}"
    disks       = ["${var.worker["root_size"]}","${var.worker["disk_size"]}"]
    local_disk  = "${var.worker["local_disk"]}"
    network_speed         = "${var.worker["network_speed"]}"
    hourly_billing        = "${var.worker["hourly_billing"]}"
    private_network_only  = "${var.worker["private_network_only"]}"
    public_vlan_id        = "${var.public_vlan_id}"
    private_vlan_id        = "${var.private_vlan_id}"

    user_metadata = "{\"value\":\"newvalue\"}"

    ssh_key_ids = ["${data.softlayer_ssh_key.public_key.id}"]

    provisioner "remote-exec" {
        script = "scripts/postinst.sh"
    }

    provisioner "remote-exec" {
        inline = [
            "apt-get update",
            "apt-get install -y nfs-common moreutils"
        ]
    }
}

resource "ibm_compute_vm_instance" "icpproxy" {
    count       = "${var.proxy["nodes"]}"

    datacenter  = "${var.datacenter}"
    domain      = "${var.domain}"
    hostname    = "${format("${lower(var.instance_name)}-proxy%01d", count.index + 1) }"

    os_reference_code = "UBUNTU_16_64"

    cores       = "${var.proxy["cpu_cores"]}"
    memory      = "${var.proxy["memory"]}"
    disks       = ["${var.proxy["root_size"]}","${var.proxy["disk_size"]}"]
    local_disk  = "${var.proxy["local_disk"]}"
    network_speed         = "${var.proxy["network_speed"]}"
    hourly_billing        = "${var.proxy["hourly_billing"]}"
    private_network_only  = "${var.proxy["private_network_only"]}"
    public_vlan_id        = "${var.public_vlan_id}"
    private_vlan_id        = "${var.private_vlan_id}"

    user_metadata = "{\"value\":\"newvalue\"}"

    ssh_key_ids = ["${data.softlayer_ssh_key.public_key.id}"]

    provisioner "remote-exec" {
        script = "scripts/postinst.sh"
    }

    provisioner "remote-exec" {
        inline = [
            "apt-get update",
            "apt-get install -y moreutils"
        ]
    }
}

module "icpprovision" {
    source = "github.com/timroster/terraform-module-icp-deploy?ref=v3.1.2-alpha"

    icp-master = ["${ibm_compute_vm_instance.icpmaster.ipv4_address}"]
    icp-management = ["${ibm_compute_vm_instance.icpmanagement.ipv4_address}"]
    icp-worker = ["${ibm_compute_vm_instance.icpworker.*.ipv4_address}"]
    icp-proxy = ["${ibm_compute_vm_instance.icpproxy.*.ipv4_address}"]

    icp-inception = "${var.icp_inception}"

    /* Workaround for terraform issue #10857
     When this is fixed, we can work this out autmatically */

    cluster_size  = "${var.master["nodes"] + var.management["nodes"] + var.worker["nodes"] + var.proxy["nodes"]}"

    # Because SoftLayer private network uses 10.0.0.0/8 range,
    # we will override default ICP network configuration
    # to be sure to avoid conflict. Allow override of default admin password.
    icp_configuration = {
      "network_cidr"              = "192.168.0.0/16"
      "service_cluster_ip_range"  = "172.16.0.1/24"
      "default_admin_password"    = "${var.default_admin_password}"
      "password_rules" = ["^(.{10,})$"]
    }

    # We will let terraform generate a new ssh keypair
    # for boot master to communicate with worker and proxy nodes
    # during ICP deployment
    generate_key = true

    # SSH user and key for terraform to connect to newly created SoftLayer resources
    # ssh_key is the private key corresponding to the public keyname specified in var.key_name
    ssh_user  = "root"
    ssh_key_base64 = "${base64encode(file("${var.key_file}"))}"

}
