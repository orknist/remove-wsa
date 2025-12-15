# Remove-WSA (Windows Subsystem for Android Full Cleanup Script)

This repository provides a **single PowerShell script** to **completely remove Windows Subsystem for Android (WSA)** from Windows 11 systems.

It is intended for users who:
- Are done troubleshooting broken WSA installs
- Experience repeated crashes, instant shutdowns, or UI failures
- Have experimented with community builds (e.g. MustardChef)
- Want a **clean slate** without manually hunting leftovers

This script removes **all known WSA components** while **keeping WSL2 and Hyper-V intact**.

---

## What This Script Does

The script performs the following actions:

- Gracefully shuts down WSA / WSL VM context
- Terminates all known WSA-related processes (`WsaClient`, `vmmemWSA`, etc.)
- Removes WSA AppX packages:
  - Current user
  - All users
- Removes provisioned (image-level) WSA packages
- Deletes leftover WSA data from:
  - `%LOCALAPPDATA%\Packages`
  - Other user profiles (best-effort)
- Optionally attempts to remove WindowsApps leftovers (disabled by default)

**No Windows features are removed by default.**
Hyper-V, Virtual Machine Platform, and WSL2 are left untouched.

---

## What This Script Does NOT Do

- ❌ It does NOT remove Hyper-V
- ❌ It does NOT remove WSL2
- ❌ It does NOT modify Secure Boot, VBS, or BIOS settings
- ❌ It does NOT install or downgrade WSA

This is a **cleanup tool**, not an installer or fixer.

---

## When You Should Use This

Use this script if:

- WSA opens briefly and crashes
- Android apps close instantly
- Files app opens for 1–2 seconds and exits
- You tested multiple WSA builds (2311 / 2407 / LTS / Nightly)
- You want to stop wasting time and **fully remove WSA**

Especially useful on **Windows 11 23H2 / 24H2** systems where WSA regressions are common.

---

## Usage

### 1. Open PowerShell as Administrator

### 2. Run
```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
.\Remove-WSA.ps1