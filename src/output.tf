output "vm_public_ip" {
  value       = azurerm_public_ip.pt_resources.ip_address
  description = "The Public IP address of the server instance."
}
