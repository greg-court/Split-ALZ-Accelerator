# Split-Accelerator (ALZ)

A tiny PowerShell helper that takes a single ALZ deployment and turns it into **platform_connectivity** and **platform_management**—then tidies references so each can run cleanly.

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

## What it does (high level)

- Splits the repo into **platform_connectivity** and **platform_management**.
- Refactors module layout and updates module source paths.
- Links shared config where needed.
- Cleans cross-references so each platform is self-contained.
- Normalizes provider settings per platform.
- Applies a few opinionated, minimal config simplifications.

## Notes

- **Idempotent**: safe to re-run; skips missing files; continues on errors.
- **Preview first** with `-WhatIf`; add `-Verbose` for details.
- **Windows symlinks** may require admin or Developer Mode.
- This tool reorganizes files; it does **not** run Terraform.
