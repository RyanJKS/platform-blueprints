resource "tls_private_key" "aks" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "random_password" "aks_windows" {
  length = 32

  upper   = true
  lower   = true
  numeric = true
  special = true

  min_upper   = 2
  min_lower   = 2
  min_numeric = 2
  min_special = 2

  override_special = "!@#%_-"
}

resource "azurerm_key_vault_secret" "aks_ssh_private_key" {
  name         = "${local.name}-ssh-private-key"
  key_vault_id = var.key_vault_id

  value = base64encode(
    tls_private_key.aks.private_key_openssh
  )

  content_type = "text/plain; encoding=base64"
}

resource "azurerm_key_vault_secret" "aks_ssh_public_key" {
  name         = "${local.name}-ssh-public-key"
  key_vault_id = var.key_vault_id
  value        = tls_private_key.aks.public_key_openssh
  content_type = "text/plain"
}

resource "azurerm_key_vault_secret" "aks_windows_password" {
  name         = "${local.name}-windows-admin-password"
  key_vault_id = var.key_vault_id
  value        = random_password.aks_windows.result
  content_type = "text/plain"
}
