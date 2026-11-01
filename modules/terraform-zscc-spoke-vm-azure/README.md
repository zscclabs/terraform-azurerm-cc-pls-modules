# Zscaler Cloud Connector / Azure Spoke Test VM Module

Creates a **private** Ubuntu 22.04 test VM in a spoke workload subnet. It checks that Cloud Connector is reachable
through the spoke Private Endpoint.

## How the VM stays private

| Control | Setting |
| --- | --- |
| Public IP | none |
| Subnet | `default_outbound_access_enabled = false` (set by the spoke network module), with no NAT gateway or route table |
| NIC NSG inbound | `Deny_Internet_Inbound`. Azure defaults allow only VNet and Azure LB traffic |
| NIC NSG outbound | Allows `168.63.129.16` (Azure platform: guest agent, DNS) and `VirtualNetwork` (the Private Endpoint). Denies `Internet` |
| Login | SSH key only (password auth disabled). `create_ssh_key = true` generates a per-VM key; otherwise pass `ssh_public_key` (the example shares one key across all VMs) |
| Access | `az vm run-command` (via the guest agent), or SSH through the optional spoke Azure Bastion. No inbound ports are open to the Internet. Serial Console is enabled (managed boot diagnostics) but needs a password user, so it is break-glass only |
| Hardening | Trusted Launch (Secure Boot + vTPM) |

The only way the VM can reach the internet is the Zscaler explicit proxy at the Private Endpoint.

## Proxy test

cloud-init installs `/usr/local/bin/proxy-test`, which checks:
1. `proxy_fqdn` resolves to the PE IP
2. TCP connects to the PE on `tcp_check_ports` (default 80, 443), checking the Private Link path. The CC health listener does not answer on the LB VIP with floating IP, so it cannot be used here
3. Direct internet is **blocked** (privacy check)
4. Internet works through the explicit proxy (`proxy-test <port>`, or `proxy_port`)

It exits non-zero if any check fails. Run it with the `run_test_command` output:

```bash
az vm run-command invoke -g <rg> -n <vm> --command-id RunShellScript \
  --scripts '/usr/local/bin/proxy-test 8080' --query 'value[0].message' -o tsv
```

When `proxy_port` is set, the VM also gets system-wide (`/etc/profile.d`) and apt proxy settings.

## Outputs

`vm_id`, `vm_name`, `private_ip`, `run_test_command`, `ssh_private_key` (sensitive)
