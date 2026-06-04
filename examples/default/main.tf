terraform {
  required_version = "~> 1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.21"
    }
    msgraph = {
      source  = "microsoft/msgraph"
      version = "~> 0.2"
    }
    modtm = {
      source  = "azure/modtm"
      version = "~> 0.3"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "msgraph" {
}


## Section to provide a random Azure region for the resource group
# This allows us to randomize the region for the resource group.
module "regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "~> 0.1"
}

# This allows us to randomize the region for the resource group.
resource "random_integer" "region_index" {
  max = length(module.regions.regions) - 1
  min = 0
}
## End of section to provide a random Azure region for the resource group

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "~> 0.3"
}

# This is required for resource modules
resource "azurerm_resource_group" "this" {
  location = module.regions.regions[random_integer.region_index.result].name
  name     = module.naming.resource_group.name_unique
}

# This is the module call
# Do not specify location here due to the randomization above.
# Leaving location as `null` will cause the module to use the resource group location
# with a data source.
module "test" {
  source = "../../"
  pim_groups = {
    pim_contributor = {
      display_name  = "e2e-pim-contributor"
      description   = "PIM enabled group for Contributor access"
      mail_nickname = "e2epimcontrib"
    }
  }

  pim_approval_groups = {
    approvers = {
      display_name  = "e2e-pim-approvers"
      description   = "Approval group for PIM elevation"
      mail_nickname = "e2epimapprovers"
    }
  }

  pim_group_approval_group_memberships = {
    approval_membership = {
      pim_group_key      = "pim_contributor"
      approval_group_key = "approvers"
    }
  }

  pim_group_role_assignments = {
    contributor_on_rg = {
      pim_group_key              = "pim_contributor"
      scope                      = azurerm_resource_group.this.id
      role_definition_id_or_name = "Contributor"
    }
  }

  pim_group_eligibility_requests = {
    sample_eligibility = {
      pim_group_key = "pim_contributor"
      principal_id  = "00000000-0000-0000-0000-000000000000"
      action        = "adminAssign"
      access_id     = "member"
      justification = "E2E sample eligibility assignment"
      schedule_info = {
        expiration = {
          type = "noExpiration"
        }
      }
    }
  }

  access_package_catalogs = {
    default = {
      display_name = "e2e-identity-catalog"
      description  = "E2E catalog"
    }
  }

  access_packages = {
    pim_access = {
      catalog_key  = "default"
      display_name = "e2e-pim-access-package"
      description  = "E2E package for PIM group access"
    }
  }

  access_package_assignment_policies = {
    pim_policy = {
      access_package_key             = "pim_access"
      approval_group_key             = "approvers"
      display_name                   = "e2e-pim-policy"
      description                    = "E2E policy requiring approval"
      requestor_scope_type           = "AllExistingDirectoryMemberUsers"
      approval_stage_timeout_in_days = 14
      approval_group_description     = "E2E approvers"
      expiration = {
        type     = "afterDuration"
        duration = "P90D"
      }
      review_settings = {
        isEnabled = false
      }
      questions = []
    }
  }
}
