
# Creates one or more PIM-enabled Entra ID groups (role-assignable security groups).
resource "msgraph_resource" "pim_group" {
  for_each = var.pim_groups

  url         = "groups"
  api_version = "v1.0"
  body = {
    displayName        = each.value.display_name
    description        = each.value.description
    mailEnabled        = false
    mailNickname       = each.value.mail_nickname
    securityEnabled    = true
    isAssignableToRole = true
    visibility         = each.value.visibility
  }
}

resource "msgraph_resource" "approval_group" {
  for_each = var.pim_approval_groups

  url         = "groups"
  api_version = "v1.0"
  body = {
    displayName     = each.value.display_name
    description     = each.value.description
    mailEnabled     = false
    mailNickname    = each.value.mail_nickname
    securityEnabled = true
  }
}

# Optional relationship: assign the approval group to the PIM-enabled group as a nested member.
resource "msgraph_resource" "pim_group_approval_group_membership" {
  for_each = var.pim_group_approval_group_memberships

  url         = "groups/${msgraph_resource.pim_group[each.value.pim_group_key].id}/members/$ref"
  api_version = "v1.0"
  body = {
    "@odata.id" = "https://graph.microsoft.com/v1.0/groups/${msgraph_resource.approval_group[each.value.approval_group_key].id}"
  }
}

# Optional direct eligibility grants to PIM-enabled groups.
resource "msgraph_resource" "pim_group_eligibility_request" {
  for_each = var.pim_group_eligibility_requests

  url         = "identityGovernance/privilegedAccess/group/eligibilityScheduleRequests"
  api_version = "beta"
  body = {
    action        = each.value.action
    accessId      = each.value.access_id
    principalId   = each.value.principal_id
    groupId       = msgraph_resource.pim_group[each.value.pim_group_key].id
    justification = each.value.justification
    scheduleInfo  = each.value.schedule_info
  }
}

# Assign scoped RBAC (subscription/resource-group/resource) to each PIM-enabled group.
resource "azurerm_role_assignment" "pim_group_scoped" {
  for_each = var.pim_group_role_assignments

  principal_id                           = msgraph_resource.pim_group[each.value.pim_group_key].id
  scope                                  = each.value.scope
  condition                              = each.value.condition
  condition_version                      = each.value.condition_version
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
  principal_type                         = "Group"
  role_definition_id                     = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : null
  role_definition_name                   = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? null : each.value.role_definition_id_or_name
  skip_service_principal_aad_check       = false
}

resource "msgraph_resource" "access_package_catalog" {
  for_each = var.access_package_catalogs

  url         = "identityGovernance/entitlementManagement/catalogs"
  api_version = "v1.0"
  body = {
    displayName = each.value.display_name
    description = each.value.description
  }
}

resource "msgraph_resource" "access_package" {
  for_each = var.access_packages

  url         = "identityGovernance/entitlementManagement/accessPackages"
  api_version = "beta"
  body = {
    catalogId   = msgraph_resource.access_package_catalog[each.value.catalog_key].id
    displayName = each.value.display_name
    description = each.value.description
  }
}

# Optional access package assignment policies to gate elevation with approval groups.
resource "msgraph_resource" "access_package_assignment_policy" {
  for_each = var.access_package_assignment_policies

  url           = "identityGovernance/entitlementManagement/accessPackageAssignmentPolicies"
  api_version   = "beta"
  update_method = "PUT"
  body = {
    accessPackageId = msgraph_resource.access_package[each.value.access_package_key].id
    displayName     = each.value.display_name
    description     = each.value.description
    expiration      = each.value.expiration
    requestorSettings = {
      scopeType = each.value.requestor_scope_type
    }
    requestApprovalSettings = {
      isApprovalRequired = true
      approvalStages = [
        {
          approvalStageTimeOutInDays = each.value.approval_stage_timeout_in_days
          primaryApprovers = [
            {
              "@odata.type" = "#microsoft.graph.groupMembers"
              groupId       = msgraph_resource.approval_group[each.value.approval_group_key].id
              description   = each.value.approval_group_description
            }
          ]
        }
      ]
    }
    reviewSettings = each.value.review_settings
    questions      = each.value.questions
  }
}
