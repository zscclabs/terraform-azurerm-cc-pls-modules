################################################################################
# Create a private test VM in a spoke workload subnet to validate access to
# Cloud Connector through the spoke Private Endpoint.
# The VM is kept private:
#   - no public IP
#   - NIC NSG denies all inbound from Internet and all outbound to Internet;
#     only VNet traffic (the Private Endpoint) and the Azure platform IP are allowed
#   - access is via `az vm run-command` (Azure guest agent) or SSH through the
#     optional spoke Azure Bastion (VNet-internal); nothing is exposed to Internet
################################################################################

locals {
  resource_label = "${var.name_prefix}-testvm-${var.spoke_name}-${var.resource_tag}"
  ssh_public_key = var.create_ssh_key ? tls_private_key.vm_key[0].public_key_openssh : var.ssh_public_key
}


################################################################################
# Generate a per-VM SSH key pair when create_ssh_key is true. Password auth is disabled
################################################################################
resource "tls_private_key" "vm_key" {
  count     = var.create_ssh_key ? 1 : 0
  algorithm = "ED25519"
}


################################################################################
# Create NSG for the test VM NIC
################################################################################
resource "azurerm_network_security_group" "vm_nsg" {
  name                = "${local.resource_label}-nsg"
  location            = var.location
  resource_group_name = var.resource_group

  security_rule {
    name                       = "Deny_Internet_Inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  # Azure platform (guest agent / run-command, DNS, metadata)
  security_rule {
    name                       = "Allow_AzurePlatform_Outbound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "168.63.129.16/32"
  }

  # Private Endpoint to Cloud Connector lives in the same VNet
  security_rule {
    name                       = "Allow_VNet_Outbound"
    priority                   = 200
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "Deny_Internet_Outbound"
    priority                   = 4000
    direction                  = "Outbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "Internet"
  }

  tags = var.global_tags

  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}


################################################################################
# Create private NIC (no public IP)
################################################################################
resource "azurerm_network_interface" "vm_nic" {
  name                = "${local.resource_label}-nic"
  location            = var.location
  resource_group_name = var.resource_group

  ip_configuration {
    name                          = "${local.resource_label}-nic-conf"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
  }

  tags = var.global_tags

  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}

resource "azurerm_network_interface_security_group_association" "vm_nic_nsg" {
  network_interface_id      = azurerm_network_interface.vm_nic.id
  network_security_group_id = azurerm_network_security_group.vm_nsg.id
}


################################################################################
# Create test VM
################################################################################
resource "azurerm_linux_virtual_machine" "test_vm" {
  name                            = local.resource_label
  location                        = var.location
  resource_group_name             = var.resource_group
  size                            = var.vm_size
  admin_username                  = var.admin_username
  disable_password_authentication = true
  network_interface_ids           = [azurerm_network_interface.vm_nic.id]
  secure_boot_enabled             = true
  vtpm_enabled                    = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = local.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  # Managed boot diagnostics enables Serial Console without any public endpoint
  boot_diagnostics {}

  custom_data = base64encode(templatefile("${path.module}/templates/cloud-init.yaml.tftpl", {
    proxy_fqdn      = var.proxy_fqdn
    proxy_port      = var.proxy_port
    tcp_check_ports = var.tcp_check_ports
  }))

  tags = var.global_tags

  lifecycle {
    ignore_changes = [
      tags,
      custom_data,
    ]

    precondition {
      condition     = var.create_ssh_key || var.ssh_public_key != null
      error_message = "Set ssh_public_key when create_ssh_key is false."
    }
  }

  depends_on = [azurerm_network_interface_security_group_association.vm_nic_nsg]
}
