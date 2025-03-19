

# Function to create scheduled task for regular monitoring
function New-MonitoringScheduledTask {
    param(
        [string]$ScriptPath,
        [string]$TaskName = "Windows11PerformanceMonitor",
        [string]$TaskDescription = "Runs Windows 11 Performance Monitor daily to collect system metrics",
        [int]$DurationMinutes = 30
    )
    
    $executionPath = Join-Path -Path $ScriptPath -ChildPath "Part6-ScriptExecution.ps1"
    
    # Create action to run PowerShell with the script
    $action = New-ScheduledTaskAction -Execute "powershell.exe" `
              -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$executionPath`" -SamplingIntervalSeconds 10 -MonitorDurationMinutes $DurationMinutes -IncludeTaskSchedulerEvents"
    
    # Create trigger for daily execution
    $trigger = New-ScheduledTaskTrigger -Daily -At "8:00AM"
    
    # Create settings
    $settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -DontStopOnIdleEnd -AllowStartIfOnBatteries
    
    # Create the task
    try {
        Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -Description $TaskDescription -Force
        Write-Host "Scheduled task '$TaskName' created successfully" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "Failed to create scheduled task: $_" -ForegroundColor Red
        return $false
    }
}

# Function to create configuration file
function New-ConfigurationFile {
    param(
        [string]$ConfigPath = "$PSScriptRoot\config.json",
        [int]$SamplingIntervalSeconds = 5,
        [int]$MonitorDurationMinutes = 60,
        [string]$OutputFolder = "$env:USERPROFILE\Desktop\PerfMonResults",
        [bool]$IncludeTaskSchedulerEvents = $true,
        [bool]$IncludeSecurityEvents = $false,
        [bool]$OpenDashboardOnComplete = $true
    )
    
    $config = @{
        SamplingIntervalSeconds = $SamplingIntervalSeconds
        MonitorDurationMinutes = $MonitorDurationMinutes
        OutputFolder = $OutputFolder
        IncludeTaskSchedulerEvents = $IncludeTaskSchedulerEvents
        IncludeSecurityEvents = $IncludeSecurityEvents
        OpenDashboardOnComplete = $OpenDashboardOnComplete
        LastRunTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    
    try {
        $config | ConvertTo-Json | Out-File -FilePath $ConfigPath -Force
        Write-Host "Configuration file created at: $ConfigPath" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "Failed to create configuration file: $_" -ForegroundColor Red
        return $false
    }
}
