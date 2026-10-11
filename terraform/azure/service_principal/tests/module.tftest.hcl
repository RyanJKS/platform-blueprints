mock_provider "azuread" {
  mock_resource "azuread_application" {
    defaults = {
      id        = "/applications/00000000-0000-0000-0000-000000000001"
      client_id = "00000000-0000-0000-0000-000000000001"
    }
  }

  mock_resource "azuread_service_principal" {
    defaults = {
      id        = "/servicePrincipals/00000000-0000-0000-0000-000000000002"
      object_id = "00000000-0000-0000-0000-000000000002"
    }
  }

  mock_resource "azuread_service_principal_password" {
    defaults = {
      value = "mock-service-principal-password"
    }
  }
}

mock_provider "azurerm" {}

variables {
  name = "platform-deploy"
}

run "no_secret_by_default" {
  command = apply

  assert {
    condition = (
      azuread_application.this.display_name == var.name
      && length(azuread_application.this.web) == 0
      && length(azuread_application_federated_identity_credential.this) == 0
      && length(output.federated_identity_credential_ids) == 0
      && azuread_service_principal.this.client_id == output.client_id
      && length(azuread_service_principal_password.this) == 0
      && length(azurerm_key_vault_secret.client_id) == 0
      && length(azurerm_key_vault_secret.client_secret) == 0
      && output.client_id_secret_id == null
      && output.client_secret_secret_id == null
    )
    error_message = "The default configuration must create the identity without a password or Key Vault secrets."
  }
}

run "store_credentials" {
  command = apply

  variables {
    create_secret = true
    key_vault_id  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/platform/providers/Microsoft.KeyVault/vaults/platform-vault"
  }

  assert {
    condition = (
      length(azuread_service_principal_password.this) == 1
      && azuread_service_principal_password.this[0].service_principal_id == output.id
      && azurerm_key_vault_secret.client_id[0].name == "platform-deploy-client-id"
      && azurerm_key_vault_secret.client_secret[0].name == "platform-deploy-client-secret"
      && azurerm_key_vault_secret.client_id[0].value == output.client_id
      && azurerm_key_vault_secret.client_secret[0].value == "mock-service-principal-password"
      && azurerm_key_vault_secret.client_id[0].key_vault_id == var.key_vault_id
      && azurerm_key_vault_secret.client_secret[0].key_vault_id == var.key_vault_id
      && output.client_id_secret_id == azurerm_key_vault_secret.client_id[0].id
      && output.client_secret_secret_id == azurerm_key_vault_secret.client_secret[0].id
    )
    error_message = "Enabling create_secret must store the matching client ID and generated password under the requested names in the supplied vault."
  }
}

run "vault_required_for_secret" {
  command = plan

  variables {
    create_secret = true
  }

  expect_failures = [azuread_application.this]
}

run "invalid_secret_name" {
  command = plan

  variables {
    name          = "platform deploy"
    create_secret = true
    key_vault_id  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/platform/providers/Microsoft.KeyVault/vaults/platform-vault"
  }

  expect_failures = [azuread_application.this]
}

run "disable_secret" {
  command = apply

  variables {
    create_secret = false
  }

  assert {
    condition = (
      length(azuread_service_principal_password.this) == 0
      && length(azurerm_key_vault_secret.client_id) == 0
      && length(azurerm_key_vault_secret.client_secret) == 0
      && output.client_id_secret_id == null
      && output.client_secret_secret_id == null
    )
    error_message = "Disabling create_secret must remove the managed password and both vault secrets."
  }
}

run "sso_and_federated_credentials" {
  command = apply

  variables {
    redirect_uris = [
      "https://argocd.example.com/auth/callback",
      "https://argocd.example.com/api/dex/callback",
    ]
    federated_identity_credentials = {
      "argocd-controller" = {
        issuer  = "https://oidc.example.com/cluster/"
        subject = "system:serviceaccount:argocd:argocd-application-controller"
      }
      "github-deploy" = {
        issuer      = "https://token.actions.githubusercontent.com"
        subject     = "repo:example/platform:ref:refs/heads/main"
        audiences   = ["api://AzureADTokenExchange"]
        description = "Deploy from the platform repository"
      }
    }
  }

  assert {
    condition     = azuread_application.this.web[0].redirect_uris == var.redirect_uris
    error_message = "Redirect URIs must configure web sign-in callbacks on the application."
  }

  assert {
    condition = (
      toset(keys(azuread_application_federated_identity_credential.this)) == toset(keys(var.federated_identity_credentials))
      && alltrue([
        for name, credential in azuread_application_federated_identity_credential.this :
        credential.application_id == azuread_application.this.id &&
        credential.display_name == name &&
        credential.issuer == var.federated_identity_credentials[name].issuer &&
        credential.subject == var.federated_identity_credentials[name].subject &&
        credential.audiences == var.federated_identity_credentials[name].audiences &&
        (var.federated_identity_credentials[name].description == null || credential.description == var.federated_identity_credentials[name].description) &&
        output.federated_identity_credential_ids[name] == credential.id
      ])
      && azuread_application_federated_identity_credential.this["argocd-controller"].audiences == tolist(["api://AzureADTokenExchange"])
      && length(azuread_service_principal_password.this) == 0
    )
    error_message = "Federated credentials must attach to the application with independent trust settings and the default token-exchange audience, without requiring a password."
  }
}

run "remove_sso_and_federation" {
  command = apply

  assert {
    condition = (
      length(azuread_application.this.web) == 0
      && length(azuread_application_federated_identity_credential.this) == 0
      && length(output.federated_identity_credential_ids) == 0
    )
    error_message = "Empty defaults must remove configured redirect URIs and federated credentials."
  }
}

run "reject_empty_redirect_uri" {
  command = plan

  variables {
    redirect_uris = [""]
  }

  expect_failures = [var.redirect_uris]
}

run "reject_empty_federated_subject" {
  command = plan

  variables {
    federated_identity_credentials = {
      "argocd-controller" = {
        issuer  = "https://oidc.example.com/cluster/"
        subject = ""
      }
    }
  }

  expect_failures = [var.federated_identity_credentials]
}

run "reject_multiple_federated_audiences" {
  command = plan

  variables {
    federated_identity_credentials = {
      "argocd-controller" = {
        issuer    = "https://oidc.example.com/cluster/"
        subject   = "system:serviceaccount:argocd:argocd-application-controller"
        audiences = ["api://AzureADTokenExchange", "another-audience"]
      }
    }
  }

  expect_failures = [var.federated_identity_credentials]
}
