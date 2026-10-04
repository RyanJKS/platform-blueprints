mock_provider "azurerm" {
  mock_resource "azurerm_user_assigned_identity" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/paymentsuksdevid"
    }
  }
}

variables {
  settings = {
    name_prefix = "paymentsuksdev"
    region_long = "uksouth"
  }
  resource_group_name = "rg-test"
}

run "no_credentials_by_default" {
  command = plan

  assert {
    condition     = length(azurerm_federated_identity_credential.this) == 0 && length(output.federated_identity_credential_ids) == 0
    error_message = "Omitting federated_identity_credentials must preserve identity-only behavior."
  }
}

run "multiple_credentials" {
  command = apply

  variables {
    federated_identity_credentials = {
      aks-workload = {
        issuer  = "https://uksouth.oic.prod-aks.azure.com/tenant/issuer/"
        subject = "system:serviceaccount:payments:api"
      }
      github-actions = {
        issuer   = "https://token.actions.githubusercontent.com"
        subject  = "repo:example/payments:environment:production"
        audience = ["api://CustomTokenExchange"]
      }
    }
  }

  assert {
    condition = (
      toset(keys(azurerm_federated_identity_credential.this)) == toset(["aks-workload", "github-actions"]) &&
      alltrue([
        for name, credential in azurerm_federated_identity_credential.this :
        credential.name == name &&
        credential.user_assigned_identity_id == output.id &&
        credential.issuer == var.federated_identity_credentials[name].issuer &&
        credential.subject == var.federated_identity_credentials[name].subject
      ]) &&
      azurerm_federated_identity_credential.this["aks-workload"].audience == tolist(["api://AzureADTokenExchange"]) &&
      azurerm_federated_identity_credential.this["github-actions"].audience == tolist(["api://CustomTokenExchange"])
    )
    error_message = "Each credential must trust its own issuer, subject, and audience and attach to the managed identity."
  }

  assert {
    condition = (
      toset(keys(output.federated_identity_credential_ids)) == toset(["aks-workload", "github-actions"]) &&
      alltrue([
        for name, credential in azurerm_federated_identity_credential.this :
        output.federated_identity_credential_ids[name] == credential.id
      ])
    )
    error_message = "Credential IDs must be available through outputs keyed by credential name."
  }
}

run "reject_empty_issuer" {
  command = plan
  variables {
    federated_identity_credentials = {
      invalid = {
        issuer  = " "
        subject = "system:serviceaccount:payments:api"
      }
    }
  }
  expect_failures = [var.federated_identity_credentials]
}

run "reject_null_subject" {
  command = plan
  variables {
    federated_identity_credentials = {
      invalid = {
        issuer  = "https://token.actions.githubusercontent.com"
        subject = null
      }
    }
  }
  expect_failures = [var.federated_identity_credentials]
}

run "reject_empty_audience" {
  command = plan
  variables {
    federated_identity_credentials = {
      invalid = {
        issuer   = "https://token.actions.githubusercontent.com"
        subject  = "repo:example/payments:environment:production"
        audience = []
      }
    }
  }
  expect_failures = [var.federated_identity_credentials]
}

run "reject_multiple_audiences" {
  command = plan
  variables {
    federated_identity_credentials = {
      invalid = {
        issuer   = "https://token.actions.githubusercontent.com"
        subject  = "repo:example/payments:environment:production"
        audience = ["api://AzureADTokenExchange", "api://OtherTokenExchange"]
      }
    }
  }
  expect_failures = [var.federated_identity_credentials]
}
