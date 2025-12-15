# Remove-WSA

Minimal PowerShell script to **completely uninstall Windows Subsystem for Android (WSA)** from Windows 11.

Removes:
- WSA AppX packages (current user + all users)
- Provisioned WSA packages
- Running WSA processes
- Leftover local data under user profiles

Does **not** remove:
- Hyper-V
- Virtual Machine Platform
- WSL2

---

## Usage

1. Save the script as `Remove-WSA.ps1`
2. Open **PowerShell as Administrator**
3. Run:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
.\Remove-WSA.ps1
```

4. Reboot (recommended)

---

## License

MIT
