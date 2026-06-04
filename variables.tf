variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
  nullable    = false
}

variable "pim_groups" {
  type = map(object({
    display_name  = string
    description   = optional(string, null)
    mail_nickname = string
    visibility    = optional(string, "Hidden")
  }))
  default     = {}
  description = <<DESCRIPTION
Map of PIM-enabled Entra ID groups to create using Microsoft Graph.

- `display_name` - The display name of the group.
- `description` - Optional description for the group.
- `mail_nickname` - The mail nickname for the group.
- `visibility` - Group visibility. For role-assignable groups this should remain `Hidden`.
DESCRIPTION
  nullable    = false
}

variable "pim_approval_groups" {
  type = map(object({
    display_name  = string
    description   = optional(string, null)
    mail_nickname = string
  }))
  default     = {}
  description = <<DESCRIPTION
Map of approval groups used for PIM/access package approval workflows.

- `display_name` - The display name of the approval group.
- `description` - Optional description for the approval group.
- `mail_nickname` - The mail nickname for the approval group.
DESCRIPTION
  nullable    = false
}

variable "pim_group_approval_group_memberships" {
  type = map(object({
    pim_group_key      = string
    approval_group_key = string
  }))
  default     = {}
  description = <<DESCRIPTION
Optional map of nested memberships to associate approval groups with PIM-enabled groups.

- `pim_group_key` - Key in `var.pim_groups`.
- `approval_group_key` - Key in `var.pim_approval_groups`.
DESCRIPTION
  nullable    = false
}

variable "pim_group_role_assignments" {
  type = map(object({
    pim_group_key                          = string
    scope                                  = string
    role_definition_id_or_name             = string
    condition                              = optional(string, null)
    condition_version                      = optional(string, null)
    delegated_managed_identity_resource_id = optional(string, null)
  }))
  default     = {}
  description = <<DESCRIPTION
Scoped RBAC role assignments for PIM-enabled groups.

- `pim_group_key` - Key in `var.pim_groups`.
- `scope` - Scope for role assignment (subscription, resource group, or resource).
- `role_definition_id_or_name` - Built-in/custom role definition ID or name.
- `condition` - Optional condition expression.
- `condition_version` - Optional condition version.
- `delegated_managed_identity_resource_id` - Optional delegated managed identity ID.
DESCRIPTION
  nullable    = false
}

variable "pim_group_eligibility_requests" {
  type = map(object({
    pim_group_key = string
    principal_id  = string
    action        = optional(string, "adminAssign")
    access_id     = optional(string, "member")
    justification = optional(string, "Assigned by Terraform")
    schedule_info = optional(any, {
      startDateTime = null
      expiration = {
        type = "noExpiration"
      }
    })
  }))
  default     = {}
  description = <<DESCRIPTION
Optional direct eligibility requests to grant principals eligibility to PIM-enabled groups.

- `pim_group_key` - Key in `var.pim_groups`.
- `principal_id` - Object ID of the principal.
- `action` - Request action, defaults to `adminAssign`.
- `access_id` - Access ID, typically `member` or `owner`.
- `justification` - Request justification.
- `schedule_info` - Graph API scheduleInfo payload.
DESCRIPTION
  nullable    = false
}

variable "access_package_catalogs" {
  type = map(object({
    display_name = string
    description  = optional(string, null)
  }))
  default     = {}
  description = <<DESCRIPTION
Optional access package catalogs to create.

- `display_name` - Catalog display name.
- `description` - Optional catalog description.
DESCRIPTION
  nullable    = false
}

variable "access_packages" {
  type = map(object({
    catalog_key  = string
    display_name = string
    description  = optional(string, null)
  }))
  default     = {}
  description = <<DESCRIPTION
Optional access packages to create.

- `catalog_key` - Key in `var.access_package_catalogs`.
- `display_name` - Access package display name.
- `description` - Optional package description.
DESCRIPTION
  nullable    = false
}

variable "access_package_assignment_policies" {
  type = map(object({
    access_package_key             = string
    approval_group_key             = string
    display_name                   = string
    description                    = optional(string, null)
    requestor_scope_type           = optional(string, "AllExistingDirectoryMemberUsers")
    approval_stage_timeout_in_days = optional(number, 14)
    approval_group_description     = optional(string, "Approval group")
    expiration = optional(any, {
      type     = "afterDuration"
      duration = "P90D"
    })
    review_settings = optional(any, {
      isEnabled = false
    })
    questions = optional(list(any), [])
  }))
  default     = {}
  description = <<DESCRIPTION
Optional assignment policies for access packages to enforce approval using an approval group.

- `access_package_key` - Key in `var.access_packages`.
- `approval_group_key` - Key in `var.pim_approval_groups`.
- `display_name` - Policy display name.
- `description` - Optional policy description.
- `requestor_scope_type` - Requestor scope type.
- `approval_stage_timeout_in_days` - Timeout in days for the approval stage.
- `approval_group_description` - Description shown for the approver group.
- `expiration` - Expiration payload.
- `review_settings` - Review settings payload.
- `questions` - Optional request questions.
DESCRIPTION
  nullable    = false
}
