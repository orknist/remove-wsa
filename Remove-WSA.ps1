#requires -RunAsAdministrator
<#
Removes Windows Subsystem for Android (WSA) completely:
- Kills WSA-related processes
- Removes Appx packages for current user + all users
- Removes provisioned packages (so it won't come back for new users)
- Deletes LocalAppData package folders
- Optionally attempts to remove WindowsApps leftovers (best-effort)
Does NOT remove Hyper-V / Virtual Machine Platform (keeps WSL2 intact).
#>

$ErrorActionPreference = "Stop"

function Write-Info($msg) { Write-Host "[INFO] $msg" -ForegroundColor Cyan }
function Write-Warn($msg) { Write-Host "[WARN] $msg" -ForegroundColor Yellow }
function Write-Ok($msg)   { Write-Host "[ OK ] $msg" -ForegroundColor Green }
function Write-Err($msg)  { Write-Host "[ERR ] $msg" -ForegroundColor Red }

Write-Info "Starting WSA removal..."

# 0) Gracefully shut down WSL/WSA VM context (doesn't harm WSL2)
try {
  Write-Info "Shutting down WSL (this also stops WSA VM if running)..."
  wsl --shutdown | Out-Null
  Write-Ok "wsl --shutdown executed."
} catch {
  Write-Warn "wsl --shutdown failed or wsl not available. Continuing..."
}

# 1) Kill known WSA processes (best effort)
$procNames = @(
  "WsaClient",
  "WsaService",
  "WsaSettings",
  "WsaProxy",
  "WsaSession",
  "WsaHost",
  "vmmemWSA"
)

Write-Info "Stopping WSA-related processes (best effort)..."
foreach ($p in $procNames) {
  Get-Process -Name $p -ErrorAction SilentlyContinue | ForEach-Object {
    try {
      Stop-Process -Id $_.Id -Force -ErrorAction Stop
      Write-Ok "Stopped process: $($_.Name) (PID $($_.Id))"
    } catch {
      Write-Warn "Could not stop process: $($_.Name) (PID $($_.Id))"
    }
  }
}

# 2) Remove AppX packages (current user + all users)
$pkgNamePattern = "*WindowsSubsystemForAndroid*"
Write-Info "Removing AppX packages matching: $pkgNamePattern"

$pkgsCurrent = Get-AppxPackage -Name $pkgNamePattern -ErrorAction SilentlyContinue
if ($pkgsCurrent) {
  foreach ($pkg in $pkgsCurrent) {
    Write-Info "Removing (current user): $($pkg.PackageFullName)"
    try {
      Remove-AppxPackage -Package $pkg.PackageFullName -ErrorAction Stop
      Write-Ok "Removed (current user): $($pkg.PackageFullName)"
    } catch {
      Write-Warn "Failed to remove (current user): $($pkg.PackageFullName)"
    }
  }
} else {
  Write-Info "No WSA package found for current user."
}

$pkgsAll = Get-AppxPackage -AllUsers -Name $pkgNamePattern -ErrorAction SilentlyContinue
if ($pkgsAll) {
  foreach ($pkg in $pkgsAll) {
    Write-Info "Removing (all users): $($pkg.PackageFullName)"
    try {
      Remove-AppxPackage -AllUsers -Package $pkg.PackageFullName -ErrorAction Stop
      Write-Ok "Removed (all users): $($pkg.PackageFullName)"
    } catch {
      Write-Warn "Failed to remove (all users): $($pkg.PackageFullName)"
    }
  }
} else {
  Write-Info "No WSA package found for all users."
}

# 3) Remove provisioned package (preinstalled for new users)
Write-Info "Removing provisioned (image) packages..."
$prov = Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -like "MicrosoftCorporationII.WindowsSubsystemForAndroid*" }
if ($prov) {
  foreach ($p in $prov) {
    Write-Info "Removing provisioned: $($p.PackageName)"
    try {
      Remove-AppxProvisionedPackage -Online -PackageName $p.PackageName | Out-Null
      Write-Ok "Removed provisioned: $($p.PackageName)"
    } catch {
      Write-Warn "Failed to remove provisioned: $($p.PackageName)"
    }
  }
} else {
  Write-Info "No provisioned WSA package found."
}

# 4) Delete LocalAppData leftovers for all user profiles (best-effort)
Write-Info "Deleting leftover LocalState folders (best effort)..."

# Current user
$localPackages = Join-Path $env:LOCALAPPDATA "Packages"
if (Test-Path $localPackages) {
  Get-ChildItem $localPackages -Directory -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -like "MicrosoftCorporationII.WindowsSubsystemForAndroid_*" } |
    ForEach-Object {
      try {
        Write-Info "Deleting: $($_.FullName)"
        Remove-Item $_.FullName -Recurse -Force -ErrorAction Stop
        Write-Ok "Deleted: $($_.FullName)"
      } catch {
        Write-Warn "Could not delete: $($_.FullName) (may require reboot or ownership)"
      }
    }
}

# Other users (common location)
$usersRoot = "C:\Users"
if (Test-Path $usersRoot) {
  Get-ChildItem $usersRoot -Directory -ErrorAction SilentlyContinue | ForEach-Object {
    $otherLocal = Join-Path $_.FullName "AppData\Local\Packages"
    if (Test-Path $otherLocal) {
      Get-ChildItem $otherLocal -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -like "MicrosoftCorporationII.WindowsSubsystemForAndroid_*" } |
        ForEach-Object {
          try {
            Write-Info "Deleting: $($_.FullName)"
            Remove-Item $_.FullName -Recurse -Force -ErrorAction Stop
            Write-Ok "Deleted: $($_.FullName)"
          } catch {
            Write-Warn "Could not delete: $($_.FullName) (may require reboot or ownership)"
          }
        }
    }
  }
}

# 5) OPTIONAL: Attempt to remove WindowsApps leftover folders (best-effort, can be noisy)
$RemoveWindowsAppsLeftovers = $false   # set to $true if you want to try
if ($RemoveWindowsAppsLeftovers) {
  Write-Warn "Attempting WindowsApps cleanup (best effort). This may require taking ownership and can be noisy."
  $windowsApps = "C:\Program Files\WindowsApps"
  if (Test-Path $windowsApps) {
    Get-ChildItem $windowsApps -Directory -ErrorAction SilentlyContinue |
      Where-Object { $_.Name -like "MicrosoftCorporationII.WindowsSubsystemForAndroid_*" } |
      ForEach-Object {
        try {
          Write-Info "Trying to delete WindowsApps folder: $($_.FullName)"
          Remove-Item $_.FullName -Recurse -Force -ErrorAction Stop
          Write-Ok "Deleted: $($_.FullName)"
        } catch {
          Write-Warn "Could not delete WindowsApps folder: $($_.FullName) (likely permission/ownership)."
        }
      }
  }
}

Write-Ok "WSA removal completed."
Write-Info "Recommended: reboot Windows to release any locked files."
