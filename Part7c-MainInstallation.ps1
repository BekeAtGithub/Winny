

# First, source the required function files
$scriptPath = $PSScriptRoot
. "$scriptPath\Part7a-InstallationFunctions.ps1"
. "$scriptPath\Part7b-ConfigurationFunctions.ps1"

# Function to update script execution file with new parameters
function Update-ScriptExecutionFile {
    param(
        [string]$ScriptPath
    )
    
    Write-Host "Updating script execution file with new parameters..." -ForegroundColor Cyan
    
    $scriptContent = Get-Content -Path $ScriptPath -Raw
    
    # Check if the script already has the updated parameters
    if ($scriptContent -match "IncludeSecurityApps|IncludeNetworkInfo|IncludeForwardedEvents") {
        Write-Host "Script already has updated parameters" -ForegroundColor Yellow
        return
    }
    
    # Find the function call to Start-PerformanceMonitoring and update it
    $pattern = "Start-PerformanceMonitoring\s+-SamplingIntervalSeconds\s+\`$interval\s+\n*\s+-MonitorDurationMinutes\s+\`$duration\s+\n*\s+-OutputFolder\s+\`$outputFolder\s+\n*\s+-IncludeTaskSchedulerEvents:\`$includeTaskScheduler\s+\n*\s+-IncludeSecurityEvents:\`$includeSecurity"
    
    $replacement = @"
Start-PerformanceMonitoring -SamplingIntervalSeconds `$interval `
                           -MonitorDurationMinutes `$duration `
                           -OutputFolder `$outputFolder `
                           -IncludeTaskSchedulerEvents:`$includeTaskScheduler `
                           -IncludeSecurityEvents:`$includeSecurity `
                           -IncludeSecurityApps:`$true `
                           -IncludeNetworkInfo:`$true `
                           -IncludeForwardedEvents:`$true
"@
    
    $updatedContent = $scriptContent -replace $pattern, $replacement
    
    # Also update the parameter prompts
    $paramPrompt = "# Ask for new parameters\n"
    $paramPrompt += "`$securityApps = Read-Host `"Include Security Applications monitoring? (Y/N, default: Y)`"\n"
    $paramPrompt += "`$includeSecurityApps = (`$securityApps -ne `"N`")\n\n"
    $paramPrompt += "`$networkInfo = Read-Host `"Include Network Information monitoring? (Y/N, default: Y)`"\n"
    $paramPrompt += "`$includeNetworkInfo = (`$networkInfo -ne `"N`")\n\n"
    $paramPrompt += "`$forwardedEvents = Read-Host `"Include Forwarded Events monitoring? (Y/N, default: Y)`"\n"
    $paramPrompt += "`$includeForwardedEvents = (`$forwardedEvents -ne `"N`")\n\n"
    
    # Find position to insert new parameters
    $insertPosition = $updatedContent.IndexOf('$includeSecurity = ($security -eq "Y")')
    $insertPosition = $updatedContent.IndexOf("`n", $insertPosition) + 1
    
    $updatedContent = $updatedContent.Insert($insertPosition, $paramPrompt)
    
    # Update the Start-PerformanceMonitoring call to include new parameters
    $finalPattern = "Start-PerformanceMonitoring -SamplingIntervalSeconds `$interval `\n\s++-MonitorDurationMinutes `$duration `\n\s++-OutputFolder `$outputFolder `\n\s++-IncludeTaskSchedulerEvents:`$includeTaskScheduler `\n\s++-IncludeSecurityEvents:`$includeSecurity `\n\s++-IncludeSecurityApps:`$true `\n\s++-IncludeNetworkInfo:`$true `\n\s++-IncludeForwardedEvents:`$true"
    
    $finalReplacement = @"
Start-PerformanceMonitoring -SamplingIntervalSeconds `$interval `
                           -MonitorDurationMinutes `$duration `
                           -OutputFolder `$outputFolder `
                           -IncludeTaskSchedulerEvents:`$includeTaskScheduler `
                           -IncludeSecurityEvents:`$includeSecurity `
                           -IncludeSecurityApps:`$includeSecurityApps `
                           -IncludeNetworkInfo:`$includeNetworkInfo `
                           -IncludeForwardedEvents:`$includeForwardedEvents
"@
    
    $finalContent = $updatedContent -replace $finalPattern, $finalReplacement
    
    # Save the updated script
    $finalContent | Out-File -FilePath $ScriptPath -Force
    Write-Host "Updated $ScriptPath with new parameters" -ForegroundColor Green
}

# Function to add new module loading to Part6-ScriptExecution.ps1
function Add-NewModuleLoading {
    param(
        [string]$ScriptPath
    )
    
    Write-Host "Adding new module loading code to script execution file..." -ForegroundColor Cyan
    
    $scriptContent = Get-Content -Path $ScriptPath -Raw
    
    # Check if the script already has the updates
    if ($scriptContent -match "Part9-SecurityApplications|Part10-NetworkMonitoring|Part11-ForwardedEvents") {
        Write-Host "Script already has the new module loading" -ForegroundColor Yellow
        return
    }
    
    # Find the last module loading section
    $pattern = "# 6. Load Part1 \(MainScript\) last.*?exit\s+\}"
    
    # Create new module loading sections
    $newModulesSection = @"

# 7. Load Part9 (SecurityApplications)
`$part9Path = Join-Path -Path `$scriptFolder -ChildPath "Part9-SecurityApplications.ps1"
if (Test-Path `$part9Path) {
    try {
        . `$part9Path
        Write-Host "Successfully loaded Part9-SecurityApplications.ps1" -ForegroundColor Green
    }
    catch {
        Write-Host "Error loading Part9-SecurityApplications.ps1: `$_" -ForegroundColor Yellow
        # Continue even if this fails
    }
}
else {
    Write-Host "Part9-SecurityApplications.ps1 not found at `$part9Path" -ForegroundColor Yellow
    # Continue even if the file doesn't exist
}

# 8. Load Part10 (NetworkMonitoring)
`$part10Path = Join-Path -Path `$scriptFolder -ChildPath "Part10-NetworkMonitoring.ps1"
if (Test-Path `$part10Path) {
    try {
        . `$part10Path
        Write-Host "Successfully loaded Part10-NetworkMonitoring.ps1" -ForegroundColor Green
    }
    catch {
        Write-Host "Error loading Part10-NetworkMonitoring.ps1: `$_" -ForegroundColor Yellow
        # Continue even if this fails
    }
}
else {
    Write-Host "Part10-NetworkMonitoring.ps1 not found at `$part10Path" -ForegroundColor Yellow
    # Continue even if the file doesn't exist
}

# 9. Load Part11 (ForwardedEvents)
`$part11Path = Join-Path -Path `$scriptFolder -ChildPath "Part11-ForwardedEvents.ps1"
if (Test-Path `$part11Path) {
    try {
        . `$part11Path
        Write-Host "Successfully loaded Part11-ForwardedEvents.ps1" -ForegroundColor Green
    }
    catch {
        Write-Host "Error loading Part11-ForwardedEvents.ps1: `$_" -ForegroundColor Yellow
        # Continue even if this fails
    }
}
else {
    Write-Host "Part11-ForwardedEvents.ps1 not found at `$part11Path" -ForegroundColor Yellow
    # Continue even if the file doesn't exist
}
"@
    
    # Find insertion point (after the last module loading section)
    $match = [regex]::Match($scriptContent, $pattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)
    if ($match.Success) {
        $insertionIndex = $match.Index + $match.Length
        $updatedContent = $scriptContent.Insert($insertionIndex, $newModulesSection)
        
        # Save the updated script
        $updatedContent | Out-File -FilePath $ScriptPath -Force
        Write-Host "Updated $ScriptPath with new module loading" -ForegroundColor Green
    }
    else {
        Write-Host "Could not find insertion point in $ScriptPath" -ForegroundColor Red
    }
}

# Main installation function (updated to include new components)
function Install-WindowsPerformanceMonitor {
    param(
        [string]$InstallPath = "$env:USERPROFILE\Documents\WindowsPerformanceMonitor",
        [switch]$CreateShortcut = $true,
        [switch]$CreateScheduledTask = $false,
        [switch]$SetDefaultConfig = $true
    )
    
    Write-Host "Installing Windows 11 Performance Monitor..." -ForegroundColor Cyan
    
    # Check and install required modules
    if (-not (Install-RequiredModules)) {
        Write-Host "Installation failed due to missing modules." -ForegroundColor Red
        return
    }
    
    # Create installation directory if it doesn't exist
    if (-not (Test-Path -Path $InstallPath)) {
        try {
            New-Item -Path $InstallPath -ItemType Directory -Force | Out-Null
            Write-Host "Created installation directory: $InstallPath" -ForegroundColor Green
        }
        catch {
            Write-Host "Failed to create installation directory: $_" -ForegroundColor Red
            return
        }
    }
    
    # Copy script files to installation directory
    $scriptFiles = @(
        "Part1-MainScript.ps1",
        "Part2-EventLogCollection.ps1",
        "Part3-ProcessHTML.ps1",
        "Part4-DashboardFunction.ps1",
        "Part5a-EventLogHTML.ps1",
        "Part5b-TaskSchedulerHTML.ps1",
        "Part6-ScriptExecution.ps1",
        "Part7a-InstallationFunctions.ps1",
        "Part7b-ConfigurationFunctions.ps1",
        "Part7c-MainInstallation.ps1",
        "Part8-AdvancedAnalysis.ps1"
    )
    
    # Add new component script files
    $newScriptFiles = @(
        "Part9-SecurityApplications.ps1",
        "Part10-NetworkMonitoring.ps1",
        "Part11-ForwardedEvents.ps1"
    )
    
    # Add new files to the script files array
    $scriptFiles += $newScriptFiles
    
    foreach ($file in $scriptFiles) {
        $sourcePath = Join-Path -Path $PSScriptRoot -ChildPath $file
        $destinationPath = Join-Path -Path $InstallPath -ChildPath $file
        
        if (Test-Path $sourcePath) {
            try {
                Copy-Item -Path $sourcePath -Destination $destinationPath -Force
                Write-Host "Copied $file to installation directory" -ForegroundColor Green
            }
            catch {
                Write-Host "Failed to copy $file : $_" -ForegroundColor Red
            }
        }
        else {
            Write-Host "Source file not found: $sourcePath" -ForegroundColor Yellow
        }
    }
    
    # Update the script execution file
    $executionScriptPath = Join-Path -Path $InstallPath -ChildPath "Part6-ScriptExecution.ps1"
    if (Test-Path $executionScriptPath) {
        # Update the script execution file with new parameters
        Update-ScriptExecutionFile -ScriptPath $executionScriptPath
        
        # Add new module loading code
        Add-NewModuleLoading -ScriptPath $executionScriptPath
    }
    
    # Create default configuration
    if ($SetDefaultConfig) {
        New-ConfigurationFile -ConfigPath "$InstallPath\config.json"
    }
    
    # Create desktop shortcut
    if ($CreateShortcut) {
        New-MonitoringShortcut -ScriptPath $InstallPath
    }
    
    # Create scheduled task
    if ($CreateScheduledTask) {
        New-MonitoringScheduledTask -ScriptPath $InstallPath
    }
    
    Write-Host "Windows 11 Performance Monitor installation completed successfully!" -ForegroundColor Cyan
    Write-Host "To run the monitor, use the desktop shortcut or navigate to $InstallPath and run Part6-ScriptExecution.ps1" -ForegroundColor Green
}

# Execute installation if script is run directly
if ($MyInvocation.Line -match 'Part7c-MainInstallation.ps1') {
    Write-Host "Windows 11 Performance Monitor - Installation" -ForegroundColor Cyan
    Write-Host "This script will install the Windows 11 Performance Monitor on your system." -ForegroundColor Yellow
    
    $installPrompt = Read-Host "Continue with installation? (Y/N)"
    if ($installPrompt -eq "Y") {
        $installPath = Read-Host "Enter installation path (default: $env:USERPROFILE\Documents\WindowsPerformanceMonitor)"
        if ([string]::IsNullOrWhiteSpace($installPath)) {
            $installPath = "$env:USERPROFILE\Documents\WindowsPerformanceMonitor"
        }
        
        $shortcutPrompt = Read-Host "Create desktop shortcut? (Y/N, default: Y)"
        $createShortcut = ($shortcutPrompt -ne "N")
        
        $taskPrompt = Read-Host "Create scheduled task for daily monitoring? (Y/N, default: N)"
        $createTask = ($taskPrompt -eq "Y")
        
        Install-WindowsPerformanceMonitor -InstallPath $installPath -CreateShortcut:$createShortcut -CreateScheduledTask:$createTask
    }
    else {
        Write-Host "Installation canceled." -ForegroundColor Yellow
    }
}
