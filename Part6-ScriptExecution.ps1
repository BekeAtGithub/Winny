

# Add debugging
Write-Host "Script started" -ForegroundColor Cyan

# This file contains the code to execute the monitoring script
# All script parts are directly dot-sourced in the right order

# Check if running as administrator
function Test-Administrator {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Set up parameters
Write-Host "Asking for parameters..." -ForegroundColor Cyan
$interval = Read-Host "Enter sampling interval in seconds (default: 5)"
if ([string]::IsNullOrWhiteSpace($interval)) { $interval = 5 }

$duration = Read-Host "Enter monitoring duration in minutes (default: 60)"
if ([string]::IsNullOrWhiteSpace($duration)) { $duration = 60 }

$outputFolder = Read-Host "Enter output folder path (default: Desktop\PerfMonResults)"
if ([string]::IsNullOrWhiteSpace($outputFolder)) { $outputFolder = "$env:USERPROFILE\Desktop\PerfMonResults" }

$taskScheduler = Read-Host "Include Task Scheduler events? (Y/N, default: Y)"
$includeTaskScheduler = ($taskScheduler -ne "N")

$security = Read-Host "Include Security events? (Y/N, default: N)"
$includeSecurity = ($security -eq "Y")

# Ask for new parameters
$securityApps = Read-Host "Include Security Applications monitoring? (Y/N, default: Y)"
$includeSecurityApps = ($securityApps -ne "N")

$networkInfo = Read-Host "Include Network Information monitoring? (Y/N, default: Y)"
$includeNetworkInfo = ($networkInfo -ne "N")

$forwardedEvents = Read-Host "Include Forwarded Events monitoring? (Y/N, default: Y)"
$includeForwardedEvents = ($forwardedEvents -ne "N")

# Check for administrator privileges if security events are requested
if ($includeSecurity -and -not (Test-Administrator)) {
    Write-Warning "Security event monitoring requires administrator privileges. Run PowerShell as Administrator to collect security events."
    $includeSecurityPrompt = Read-Host "Continue without security events? (Y/N)"
    if ($includeSecurityPrompt -ne "Y") {
        Write-Host "Monitoring canceled. Please restart PowerShell as Administrator to monitor security events."
        exit
    }
    $includeSecurity = $false
}

# Initialize global variables to ensure they're accessible across all scripts
$global:performanceData = @()
$global:processData = @()
$global:eventLogData = @()
$global:taskSchedulerData = @()
$global:securityAppsData = @()
$global:networkData = @()
$global:forwardedEventsData = @()

# Define file paths for HTML outputs
$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$global:htmlDashboard = Join-Path -Path $outputFolder -ChildPath "Dashboard_$timestamp.html"
$global:processHtmlFile = Join-Path -Path $outputFolder -ChildPath "ProcessDetails_$timestamp.html"
$global:eventHtmlFile = Join-Path -Path $outputFolder -ChildPath "EventLog_$timestamp.html"
$global:taskHtmlFile = Join-Path -Path $outputFolder -ChildPath "TaskScheduler_$timestamp.html"
$global:securityAppsHtmlFile = Join-Path -Path $outputFolder -ChildPath "SecurityApps_$timestamp.html"
$global:networkHtmlFile = Join-Path -Path $outputFolder -ChildPath "Network_$timestamp.html"
$global:forwardedEventsHtmlFile = Join-Path -Path $outputFolder -ChildPath "ForwardedEvents_$timestamp.html"

# Create output folder if it doesn't exist
if (-not (Test-Path -Path $outputFolder)) {
    New-Item -Path $outputFolder -ItemType Directory | Out-Null
    Write-Host "Created output folder: $outputFolder" -ForegroundColor Green
}

# FIX - Ensure $scriptFolder is properly set
$scriptFolder = $PSScriptRoot
Write-Host "Script folder path: $scriptFolder" -ForegroundColor Cyan

# Directly source each script part in the correct order
# 1. First load Part3 (ProcessHTML)
$part3Path = Join-Path -Path $scriptFolder -ChildPath "Part3-ProcessHTML.ps1"
Write-Host "Attempting to load: $part3Path" -ForegroundColor Cyan
if (Test-Path $part3Path) {
    try {
        . $part3Path
        Write-Host "Successfully loaded Part3-ProcessHTML.ps1" -ForegroundColor Green
    }
    catch {
        Write-Host "Error loading Part3-ProcessHTML.ps1: $_" -ForegroundColor Red
        exit
    }
}
else {
    Write-Host "Part3-ProcessHTML.ps1 not found at $part3Path" -ForegroundColor Red
    exit
}

# 2. Load Part5a (EventLogHTML)
$part5aPath = Join-Path -Path $scriptFolder -ChildPath "Part5a-EventLogHTML.ps1"
Write-Host "Attempting to load: $part5aPath" -ForegroundColor Cyan
if (Test-Path $part5aPath) {
    try {
        . $part5aPath
        Write-Host "Successfully loaded Part5a-EventLogHTML.ps1" -ForegroundColor Green
    }
    catch {
        Write-Host "Error loading Part5a-EventLogHTML.ps1: $_" -ForegroundColor Red
        exit
    }
}
else {
    Write-Host "Part5a-EventLogHTML.ps1 not found at $part5aPath" -ForegroundColor Yellow
}

# 3. Load Part5b (TaskSchedulerHTML)
$part5bPath = Join-Path -Path $scriptFolder -ChildPath "Part5b-TaskSchedulerHTML.ps1"
Write-Host "Attempting to load: $part5bPath" -ForegroundColor Cyan
if (Test-Path $part5bPath) {
    try {
        . $part5bPath
        Write-Host "Successfully loaded Part5b-TaskSchedulerHTML.ps1" -ForegroundColor Green
    }
    catch {
        Write-Host "Error loading Part5b-TaskSchedulerHTML.ps1: $_" -ForegroundColor Red
        exit
    }
}
else {
    Write-Host "Part5b-TaskSchedulerHTML.ps1 not found at $part5bPath" -ForegroundColor Yellow
}

# 4. Load Part4 (DashboardFunction)
$part4Path = Join-Path -Path $scriptFolder -ChildPath "Part4-DashboardFunction.ps1"
Write-Host "Attempting to load: $part4Path" -ForegroundColor Cyan
if (Test-Path $part4Path) {
    try {
        . $part4Path
        Write-Host "Successfully loaded Part4-DashboardFunction.ps1" -ForegroundColor Green
    }
    catch {
        Write-Host "Error loading Part4-DashboardFunction.ps1: $_" -ForegroundColor Red
        exit
    }
}
else {
    Write-Host "Part4-DashboardFunction.ps1 not found at $part4Path" -ForegroundColor Red
    exit
}

# 5. Load Part2 (EventLogCollection)
$part2Path = Join-Path -Path $scriptFolder -ChildPath "Part2-EventLogCollection.ps1"
Write-Host "Attempting to load: $part2Path" -ForegroundColor Cyan
if (Test-Path $part2Path) {
    try {
        . $part2Path
        Write-Host "Successfully loaded Part2-EventLogCollection.ps1" -ForegroundColor Green
    }
    catch {
        Write-Host "Error loading Part2-EventLogCollection.ps1: $_" -ForegroundColor Red
        exit
    }
}
else {
    Write-Host "Part2-EventLogCollection.ps1 not found at $part2Path" -ForegroundColor Red
    exit
}

# 6. Load Part1 (MainScript) last
$part1Path = Join-Path -Path $scriptFolder -ChildPath "Part1-MainScript.ps1"
Write-Host "Attempting to load: $part1Path" -ForegroundColor Cyan
if (Test-Path $part1Path) {
    try {
        . $part1Path
        Write-Host "Successfully loaded Part1-MainScript.ps1" -ForegroundColor Green
    }
    catch {
        Write-Host "Error loading Part1-MainScript.ps1: $_" -ForegroundColor Red
        exit
    }
}
else {
    Write-Host "Part1-MainScript.ps1 not found at $part1Path" -ForegroundColor Red
    exit
}

# 7. Load Part9 (SecurityApplications)
$part9Path = Join-Path -Path $scriptFolder -ChildPath "Part9-SecurityApplications.ps1"
Write-Host "Attempting to load: $part9Path" -ForegroundColor Cyan
if (Test-Path $part9Path) {
    try {
        . $part9Path
        Write-Host "Successfully loaded Part9-SecurityApplications.ps1" -ForegroundColor Green
    }
    catch {
        Write-Host "Error loading Part9-SecurityApplications.ps1: $_" -ForegroundColor Yellow
        # Continue even if this fails
    }
}
else {
    Write-Host "Part9-SecurityApplications.ps1 not found at $part9Path" -ForegroundColor Yellow
    # Continue even if the file doesn't exist
}

# 8. Load Part10 (NetworkMonitoring)
$part10Path = Join-Path -Path $scriptFolder -ChildPath "Part10-NetworkMonitoring.ps1"
Write-Host "Attempting to load: $part10Path" -ForegroundColor Cyan
if (Test-Path $part10Path) {
    try {
        . $part10Path
        Write-Host "Successfully loaded Part10-NetworkMonitoring.ps1" -ForegroundColor Green
    }
    catch {
        Write-Host "Error loading Part10-NetworkMonitoring.ps1: $_" -ForegroundColor Yellow
        # Continue even if this fails
    }
}
else {
    Write-Host "Part10-NetworkMonitoring.ps1 not found at $part10Path" -ForegroundColor Yellow
    # Continue even if the file doesn't exist
}

# 9. Load Part11 (ForwardedEvents)
$part11Path = Join-Path -Path $scriptFolder -ChildPath "Part11-ForwardedEvents.ps1"
Write-Host "Attempting to load: $part11Path" -ForegroundColor Cyan
if (Test-Path $part11Path) {
    try {
        . $part11Path
        Write-Host "Successfully loaded Part11-ForwardedEvents.ps1" -ForegroundColor Green
    }
    catch {
        Write-Host "Error loading Part11-ForwardedEvents.ps1: $_" -ForegroundColor Yellow
        # Continue even if this fails
    }
}
else {
    Write-Host "Part11-ForwardedEvents.ps1 not found at $part11Path" -ForegroundColor Yellow
    # Continue even if the file doesn't exist
}

# Check if Start-PerformanceMonitoring exists
Write-Host "Checking if Start-PerformanceMonitoring function exists..." -ForegroundColor Cyan
if (Get-Command -Name Start-PerformanceMonitoring -ErrorAction SilentlyContinue) {
    Write-Host "Function found, calling through wrapper function..." -ForegroundColor Green
    
    # Create a wrapper function that accepts our new parameters but calls the original function
    function Start-EnhancedMonitoring {
        param(
            [int]$SamplingIntervalSeconds = 5,
            [int]$MonitorDurationMinutes = 60,
            [string]$OutputFolder = "$env:USERPROFILE\Desktop\PerfMonResults",
            [bool]$IncludeTaskSchedulerEvents = $true,
            [bool]$IncludeSecurityEvents = $false,
            [bool]$IncludeSecurityApps = $true,
            [bool]$IncludeNetworkInfo = $true,
            [bool]$IncludeForwardedEvents = $true
        )
        
        Write-Host "Starting monitoring with enhanced parameters support" -ForegroundColor Cyan
        Write-Host "Security Apps: $IncludeSecurityApps" -ForegroundColor Cyan
        Write-Host "Network Info: $IncludeNetworkInfo" -ForegroundColor Cyan
        Write-Host "Forwarded Events: $IncludeForwardedEvents" -ForegroundColor Cyan
        
        # Store parameters in global variables so our extension modules can access them
        $global:IncludeSecurityApps = $IncludeSecurityApps
        $global:IncludeNetworkInfo = $IncludeNetworkInfo
        $global:IncludeForwardedEvents = $IncludeForwardedEvents
        
        # Call the original function with only the parameters it supports
        Start-PerformanceMonitoring -SamplingIntervalSeconds $SamplingIntervalSeconds `
                                   -MonitorDurationMinutes $MonitorDurationMinutes `
                                   -OutputFolder $OutputFolder `
                                   -IncludeTaskSchedulerEvents:$IncludeTaskSchedulerEvents `
                                   -IncludeSecurityEvents:$IncludeSecurityEvents
    }
    
    # Call our wrapper function instead
    Start-EnhancedMonitoring -SamplingIntervalSeconds $interval `
                            -MonitorDurationMinutes $duration `
                            -OutputFolder $outputFolder `
                            -IncludeTaskSchedulerEvents:$includeTaskScheduler `
                            -IncludeSecurityEvents:$includeSecurity `
                            -IncludeSecurityApps:$includeSecurityApps `
                            -IncludeNetworkInfo:$includeNetworkInfo `
                            -IncludeForwardedEvents:$includeForwardedEvents
}
else {
    Write-Host "Critical error: Start-PerformanceMonitoring function not found after loading all scripts" -ForegroundColor Red
    # List all functions available to help diagnose the issue
    Write-Host "Available functions:" -ForegroundColor Yellow
    Get-Command -CommandType Function | Where-Object { $_.Name -like "*Performance*" } | Format-Table -Property Name
}
