output "vm_id" {
  description = "Test VM ID"
  value       = azurerm_linux_virtual_machine.test_vm.id
}

output "vm_name" {
  description = "Test VM name"
  value       = azurerm_linux_virtual_machine.test_vm.name
}

output "private_ip" {
  description = "Test VM private IP"
  value       = azurerm_network_interface.vm_nic.private_ip_address
}

output "run_test_command" {
  description = "Command to run the proxy test on the VM via Azure run-command"
  value       = "az vm run-command invoke -g ${var.resource_group} -n ${azurerm_linux_virtual_machine.test_vm.name} --command-id RunShellScript --scripts '/usr/local/bin/proxy-test' --query 'value[0].message' -o tsv"
}

output "ssh_private_key" {
  description = "Generated SSH private key (null when ssh_public_key was supplied)"
  value       = try(tls_private_key.vm_key[0].private_key_openssh, null)
  sensitive   = true
}
