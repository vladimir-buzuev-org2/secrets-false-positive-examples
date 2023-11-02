
#
# Azure Creds
#

locals {
  azure_workspaces = {
    for k, v in var.workspaces : k => v
    if v.creds == "azure"
  }
}
