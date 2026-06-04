output "pim_groups" {
  description = "Map of created PIM-enabled Entra ID groups."
  value       = { for k, v in msgraph_resource.pim_group : k => { id = v.id, display_name = var.pim_groups[k].display_name } }
}

output "pim_approval_groups" {
  description = "Map of created approval groups."
  value       = { for k, v in msgraph_resource.approval_group : k => { id = v.id, display_name = var.pim_approval_groups[k].display_name } }
}

output "pim_group_role_assignments" {
  description = "Map of scoped RBAC assignments created for PIM groups."
  value       = { for k, v in azurerm_role_assignment.pim_group_scoped : k => v.id }
}

# output "pim_group_eligibility_requests" {
#   description = "Map of created direct eligibility requests for PIM groups."
#   value       = { for k, v in msgraph_resource.pim_group_eligibility_request : k => v.id }
# }

output "access_package_catalogs" {
  description = "Map of created access package catalogs."
  value       = { for k, v in msgraph_resource.access_package_catalog : k => v.id }
}

output "access_packages" {
  description = "Map of created access packages."
  value       = { for k, v in msgraph_resource.access_package : k => v.id }
}

output "access_package_assignment_policies" {
  description = "Map of created access package assignment policies."
  value       = { for k, v in msgraph_resource.access_package_assignment_policy : k => v.id }
}
