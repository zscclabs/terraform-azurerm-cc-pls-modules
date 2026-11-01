output "pls_id" {
  description = "Private Link Service ID"
  value       = module.cc_pls.pls_id
}

output "pls_alias" {
  description = "Private Link Service alias"
  value       = module.cc_pls.pls_alias
}

output "pls_nat_ips_command" {
  description = "Command to list the PLS NAT IPs (source IPs Cloud Connector sees for all spoke traffic)"
  value       = "az network nic show --ids $(az network private-link-service show --ids ${module.cc_pls.pls_id} --query 'networkInterfaces[0].id' -o tsv) --query 'ipConfigurations[].privateIPAddress' -o tsv"
}

output "pls_nat_subnet_cidr" {
  description = "CIDR of the PLS NAT subnet created in the load balancer VNet"
  value       = module.cc_pls.nat_subnet_cidr
}

output "spoke_endpoints" {
  description = "Per-spoke Private Endpoint IP and proxy FQDN"
  value = {
    for k, pe in module.spoke_pe : k => {
      pe_ip              = pe.pe_ip
      proxy_fqdn         = pe.proxy_fqdn
      vnet_id            = try(module.spoke_network[k].vnet_id, null)
      workload_subnet_id = try(module.spoke_network[k].workload_subnet_id, null)
    }
  }
}

output "test_vms" {
  description = "Private test VMs and the command to run the proxy test on each"
  value = {
    for k, vm in module.spoke_test_vm : k => {
      vm_name        = vm.vm_name
      private_ip     = vm.private_ip
      run_test       = vm.run_test_command
      bastion_access = try(module.spoke_network[k].bastion_sku, null) == "Developer" ? "Azure portal > ${vm.vm_name} > Connect > Bastion (Developer SKU: portal only)" : null
      bastion_ssh = !contains(["Standard", "Premium"], coalesce(try(module.spoke_network[k].bastion_sku, null), "none")) ? null : join(" ", [
        "az network bastion ssh -n ${module.spoke_network[k].bastion_name} -g ${module.spoke_network[k].resource_group_name}",
        "--target-resource-id ${vm.vm_id} --auth-type ssh-key --username azureuser --ssh-key ${abspath(local_file.private_key.filename)}",
      ])
    }
  }
}

output "ssh_private_key_file" {
  description = "Private key file shared by all test VMs"
  value       = abspath(local_file.private_key.filename)
}

output "ssh_commands" {
  description = "SSH to each test VM through its spoke Bastion (run from the examples directory)"
  value       = { for k in keys(local.ssh_spokes) : k => "ssh -F ssh_config workload-${k}" }
}
