

# Function to check and install required modules
function Install-RequiredModules {
    $requiredModules = @(
        # No external modules currently required, but can be added here if needed
    )
    
    $modulesToInstall = @()
    
    foreach ($module in $requiredModules) {
        if (-not (Get-Module -ListAvailable -Name $module)) {
            $modulesToInstall += $module
        }
    }
    
    if ($modulesToInstall.Count -gt 0) {
        Write-Host "Installing required modules: $($modulesToInstall -join ', ')" -ForegroundColor Yellow
        
        foreach ($module in $modulesToInstall) {
            try {
                Install-Module -Name $module -Scope CurrentUser -Force -AllowClobber
                Write-Host "Successfully installed module: $module" -ForegroundColor Green
            }
            catch {
                Write-Host "Failed to install module: $module. Error: $_" -ForegroundColor Red
                return $false
            }
        }
    }
    
    return $true
}

# Function to create shortcut
function New-MonitoringShortcut {
    param(
        [string]$ScriptPath,
        [string]$ShortcutPath = "$env:USERPROFILE\Desktop\Windows11PerformanceMonitor.lnk"
    )
    
    try {
        $WshShell = New-Object -ComObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut($ShortcutPath)
        $Shortcut.TargetPath = "powershell.exe"
        $Shortcut.Arguments = "-ExecutionPolicy Bypass -File `"$ScriptPath\Part6-ScriptExecution.ps1`""
        $Shortcut.WorkingDirectory = $ScriptPath
        $Shortcut.IconLocation = "powershell.exe,0"
        $Shortcut.Description = "Windows 11 Performance Monitor"
        $Shortcut.Save()
        
        Write-Host "Shortcut created at: $ShortcutPath" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "Failed to create shortcut: $_" -ForegroundColor Red
        return $false
    }
}
