# Split-Accelerator (ALZ)

Minimal helper that splits a single ALZ deployment into **platform_connectivity** and **platform_management**, refactors module paths, cleans cross-wires, and tweaks providers.

## Prereqs

- PowerShell 7+
- A checked-out ALZ repo (e.g. `alz-mgmt`)

## Install / Import

```powershell
Import-Module ./src/Split-Accelerator.psd1 -Force
```

## Quick Start

**Dry run**

```powershell
Split-Accelerator ../path/to/alz-mgmt/ -WhatIf -Verbose
```

**Execute**

```powershell
Split-Accelerator ../path/to/alz-mgmt/ -Confirm:$false [-Force] [-Verbose]
```

## What it does (in order)

- Creates `platform_connectivity/` and `platform_management/` and moves baseline files.
- Renames `modules/` → `accelerator-modules/`; creates `custom-modules/`.
- Rewrites Terraform `source = "./modules/..."`
  → `source = "../accelerator-modules/..."` with correct relative paths.
- Adds symlinks to `platform-landing-zone.auto.tfvars` into both platform dirs.
- **Connectivity clean:** removes lines containing `var.management_*` and `module.management_resources`.
- **Management clean:** removes lines containing
  `var.connectivity_type`, `module.resource_groups`,
  `var.connectivity_resource_groups`, `var.hub_and_spoke_networks_settings`,
  `var.hub_virtual_networks`, `var.virtual_wan_settings`, `var.virtual_hubs`,
  `var.connectivity_tags`, `module.hub_and_spoke_vnet`, `module.virtual_wan`.
- Trims `management_group_settings = merge(...)` and
  `management_resource_settings = merge(...)` from `platform_connectivity/locals.tf`.
- Simplifies `variable "starter_locations"` in `platform_management/variables.tf`
  (removes connectivity-dependent validation).
- Sets `subscription_id` in each platform’s `terraform.tf` provider:

  - connectivity → `var.subscription_ids["connectivity"]`
  - management → `var.subscription_ids["management"]`

## Notes

- Idempotent: safe to re-run; skips missing files; continues on errors.
- Use `-Verbose` to see what changed; use `-WhatIf` to preview.
- On Windows, creating symlinks may require admin or Developer Mode.
