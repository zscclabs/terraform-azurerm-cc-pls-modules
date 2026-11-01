################################################################################
# Single SSH key pair for all spoke test VMs, written to a local pem file
################################################################################
resource "tls_private_key" "key" {
  algorithm = "ED25519"
}

resource "local_file" "private_key" {
  content         = tls_private_key.key.private_key_openssh
  filename        = "../${var.name_prefix}-key-${random_string.suffix.result}.pem"
  file_permission = "0600"
}


################################################################################
# Generate ssh_config for the private test VMs. There is no jump host VM in the
# spokes: each hop goes through that spoke's Azure Bastion (Standard/Premium)
# via a ProxyCommand that opens a short-lived `az network bastion tunnel`
################################################################################
locals {
  # Only spokes whose Bastion supports native client tunneling
  ssh_spokes = {
    for k, vm in module.spoke_test_vm : k => vm
    if contains(["Standard", "Premium"], coalesce(try(module.spoke_network[k].bastion_sku, null), "none"))
  }
  ssh_ports = { for i, k in sort(keys(local.ssh_spokes)) : k => 2201 + i }

  # Same layout as the Cloud Connector repo's ssh_config (Host workload-N / HostName / User /
  # IdentityFile / StrictHostKeyChecking). The ProxyJump through a bastion VM is replaced by a
  # ProxyCommand through the spoke's Azure Bastion, since the spokes have no jump host VM.
  # HostKeyAlias keeps known_hosts entries apart: every spoke VM can have the same private IP.
  ssh_config_contents = join("\n", [
    for k in sort(keys(local.ssh_spokes)) : <<SSH_CONFIG
    Host workload-${k}
      HostName ${local.ssh_spokes[k].private_ip}
      User azureuser
      IdentityFile ${basename(local_file.private_key.filename)}
      StrictHostKeyChecking no
      HostKeyAlias ${local.ssh_spokes[k].vm_name}
      ProxyCommand ./bastion-proxy.sh ${module.spoke_network[k].bastion_name} ${module.spoke_network[k].resource_group_name} ${local.ssh_spokes[k].vm_id} ${local.ssh_ports[k]}
SSH_CONFIG
  ])
}

resource "local_file" "bastion_proxy" {
  content         = file("${path.module}/templates/bastion-proxy.sh.tftpl")
  filename        = "../bastion-proxy.sh"
  file_permission = "0755"
}

resource "local_file" "ssh_config" {
  content  = local.ssh_config_contents
  filename = "../ssh_config"
}
