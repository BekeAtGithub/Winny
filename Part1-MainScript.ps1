# Main Script - Winny Jenkins - Windows Performance Toolkit

# Function to collect detailed process information
function Get-ProcessDetails {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $processes = Get-Process | Where-Object { $_.CPU -gt 0 } | Sort-Object -Property CPU -Descending
    
    $totalCPU = ($processes | Measure-Object -Property CPU -Sum).Sum
    if ($totalCPU -eq 0) { $totalCPU = 1 } # Prevent division by zero
    
    $collectedProcesses = @()
    
    foreach ($process in $processes) {
        $cpuPercent = [math]::Round(($process.CPU / $totalCPU) * 100, 2)
        $memoryMB = [math]::Round($process.WorkingSet / 1MB, 2)
        
        try {
            $cmdLine = (Get-CimInstance -ClassName Win32_Process -Filter "ProcessId = $($process.Id)").CommandLine
        }
        catch {
            $cmdLine = "Unable to retrieve"
        }
        
        # Store data in memory
        $collectedProcesses += [PSCustomObject]@{
            Timestamp = $timestamp
            ProcessName = $process.Name
            PID = $process.Id
            CPUPercent = $cpuPercent
            MemoryMB = $memoryMB
            StartTime = $process.StartTime
            ThreadCount = $process.Threads.Count
            HandleCount = $process.HandleCount
            CommandLine = $cmdLine
        }
    }
    
    # Add to global collection - ensure script: scope is used
    if ($null -eq $script:processData) {
        $script:processData = @()
    }
    $script:processData += $collectedProcesses
    
    # Debug output
    Write-Host "Collected $(($collectedProcesses).Count) process records. Total: $($script:processData.Count)" -ForegroundColor Cyan
    
    # Update HTML file with latest data
    Update-ProcessHTML
}

# Function to get CPU usage
function Get-CpuUsage {
    $cpuUsage = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples.CookedValue
    return [math]::Round($cpuUsage, 2)
}

# Function to get memory info
function Get-MemoryInfo {
    $memoryData = Get-CimInstance Win32_OperatingSystem
    $availableMemoryMB = [math]::Round($memoryData.FreePhysicalMemory / 1KB, 2)
    $totalMemoryMB = [math]::Round($memoryData.TotalVisibleMemorySize / 1KB, 2)
    $committedMemoryMB = $totalMemoryMB - $availableMemoryMB
    
    return @{
        AvailableMemoryMB = $availableMemoryMB
        TotalMemoryMB = $totalMemoryMB
        CommittedMemoryMB = $committedMemoryMB
        PercentFree = [math]::Round(($availableMemoryMB / $totalMemoryMB) * 100, 2)
    }
}

# Main performance monitoring function
function Start-PerformanceMonitoring {
    param(
        [int]$SamplingIntervalSeconds = 5,
        [int]$MonitorDurationMinutes = 60,
        [string]$OutputFolder = "$env:USERPROFILE\Desktop\PerfMonResults",
        [bool]$IncludeTaskSchedulerEvents = $true,
        [bool]$IncludeSecurityEvents = $false,
        [bool]$OpenDashboardOnComplete = $true
    )
    
    # Create output folder if it doesn't exist
    if (-not (Test-Path -Path $OutputFolder)) {
        New-Item -Path $OutputFolder -ItemType Directory | Out-Null
    }
    
    # Record start time
    $startTime = Get-Date
    Write-Host "Starting Windows 11 Performance Monitoring at $($startTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Cyan
    Write-Host "Data will be collected for $MonitorDurationMinutes minutes at $SamplingIntervalSeconds second intervals" -ForegroundColor Cyan
    Write-Host "Output folder: $OutputFolder" -ForegroundColor Cyan
    
    # Check for global variables that might be set by the wrapper function
    $includeSecurityApps = if ($null -ne $global:IncludeSecurityApps) { $global:IncludeSecurityApps } else { $false }
    $includeNetworkInfo = if ($null -ne $global:IncludeNetworkInfo) { $global:IncludeNetworkInfo } else { $false }
    $includeForwardedEvents = if ($null -ne $global:IncludeForwardedEvents) { $global:IncludeForwardedEvents } else { $false }
    
    Write-Host "Security Apps Monitoring: $includeSecurityApps" -ForegroundColor Cyan
    Write-Host "Network Information Monitoring: $includeNetworkInfo" -ForegroundColor Cyan
    Write-Host "Forwarded Events Monitoring: $includeForwardedEvents" -ForegroundColor Cyan
    
    # Calculate number of iterations based on duration and interval
    $iterations = [math]::Ceiling(($MonitorDurationMinutes * 60) / $SamplingIntervalSeconds)
    
    # Main monitoring loop
    for ($i = 0; $i -lt $iterations; $i++) {
        $currentTime = Get-Date
        $elapsedMinutes = ($currentTime - $startTime).TotalMinutes
        $remainingMinutes = $MonitorDurationMinutes - $elapsedMinutes
        
        # Calculate progress percentage
        $progressPercentage = [math]::Min(100, [math]::Round(($elapsedMinutes / $MonitorDurationMinutes) * 100, 0))
        
        # Show progress
        Write-Progress -Activity "Windows 11 Performance Monitoring" -Status "Collecting data - $progressPercentage% complete" -PercentComplete $progressPercentage
        
        # Collect process data every iteration
        Get-ProcessDetails
        
        # Collect other data at specific intervals to reduce system load
        
        # Every 6 iterations for event logs (or about 30 seconds with default 5 second interval)
        if ($i % 6 -eq 0) {
            if (Get-Command -Name Get-RelevantEventLogs -ErrorAction SilentlyContinue) {
                Get-RelevantEventLogs -MinutesSince 5
            }
            
            if ($IncludeTaskSchedulerEvents -and (Get-Command -Name Get-TaskSchedulerInfo -ErrorAction SilentlyContinue)) {
                Get-TaskSchedulerInfo
            }
        }
        
        # Every 12 iterations for security applications (about 1 minute)
        if ($includeSecurityApps -and $i % 12 -eq 0) {
            if (Get-Command -Name Get-SecurityApplications -ErrorAction SilentlyContinue) {
                Get-SecurityApplications
            }
            else {
                Write-Host "Security Applications monitoring function not found" -ForegroundColor Yellow
            }
        }
        
        # Every 12 iterations for network info (about 1 minute)
        if ($includeNetworkInfo -and $i % 12 -eq 0) {
            if (Get-Command -Name Get-NetworkInformation -ErrorAction SilentlyContinue) {
                Get-NetworkInformation
            }
            else {
                Write-Host "Network Information monitoring function not found" -ForegroundColor Yellow
            }
        }
        
        # Every 30 iterations for forwarded events (about 2.5 minutes)
        if ($includeForwardedEvents -and $i % 30 -eq 0) {
            if (Get-Command -Name Get-ForwardedEvents -ErrorAction SilentlyContinue) {
                Get-ForwardedEvents -MinutesSince 10
            }
            else {
                Write-Host "Forwarded Events monitoring function not found" -ForegroundColor Yellow
            }
        }
        
        # Update the dashboard HTML
        if (Get-Command -Name Update-HTMLDashboard -ErrorAction SilentlyContinue) {
            Update-HTMLDashboard -StartTime $startTime -CurrentTime $currentTime
        }
        
        # Display current status
        Write-Host "Collected data at $($currentTime.ToString('HH:mm:ss')) - CPU: $(Get-CpuUsage)% - Available Memory: $((Get-MemoryInfo).AvailableMemoryMB) MB - Remaining: $([math]::Round($remainingMinutes, 1)) minutes" -ForegroundColor Green
        
        # Wait for the next iteration if not the last one
        if ($i -lt $iterations - 1) {
            Start-Sleep -Seconds $SamplingIntervalSeconds
        }
    }
    
    # Monitoring complete
    $endTime = Get-Date
    $duration = $endTime - $startTime
    Write-Host "Performance monitoring completed at $($endTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Cyan
    Write-Host "Actual duration: $([math]::Round($duration.TotalMinutes, 2)) minutes" -ForegroundColor Cyan
    Write-Host "Collected data points:" -ForegroundColor Cyan
    Write-Host "  - Processes: $($script:processData.Count)" -ForegroundColor Cyan
    
    if ($null -ne $script:eventLogData) {
        Write-Host "  - Event logs: $($script:eventLogData.Count)" -ForegroundColor Cyan
    }
    
    if ($null -ne $script:taskSchedulerData) {
        Write-Host "  - Task scheduler: $($script:taskSchedulerData.Count)" -ForegroundColor Cyan
    }
    
    if ($includeSecurityApps -and $null -ne $script:securityAppsData) {
        Write-Host "  - Security applications: $($script:securityAppsData.Count)" -ForegroundColor Cyan
    }
    
    if ($includeNetworkInfo -and $null -ne $script:networkData) {
        Write-Host "  - Network information: $($script:networkData.Count)" -ForegroundColor Cyan
    }
    
    if ($includeForwardedEvents -and $null -ne $script:forwardedEventsData) {
        Write-Host "  - Forwarded events: $($script:forwardedEventsData.Count)" -ForegroundColor Cyan
    }
    
    # Make sure all HTML files are updated one last time
    if (Get-Command -Name Update-HTMLDashboard -ErrorAction SilentlyContinue) {
        Update-HTMLDashboard -StartTime $startTime -CurrentTime $endTime
    }
    
    if (Get-Command -Name Update-ProcessHTML -ErrorAction SilentlyContinue) {
        Update-ProcessHTML
    }
    
    if (Get-Command -Name Update-EventLogHTML -ErrorAction SilentlyContinue) {
        Update-EventLogHTML
    }
    
    if ($IncludeTaskSchedulerEvents -and (Get-Command -Name Update-TaskSchedulerHTML -ErrorAction SilentlyContinue)) {
        Update-TaskSchedulerHTML
    }
    
    if ($includeSecurityApps -and (Get-Command -Name Update-SecurityAppsHTML -ErrorAction SilentlyContinue)) {
        Update-SecurityAppsHTML
    }
    
    if ($includeNetworkInfo -and (Get-Command -Name Update-NetworkHTML -ErrorAction SilentlyContinue)) {
        Update-NetworkHTML
    }
    
    if ($includeForwardedEvents -and (Get-Command -Name Update-ForwardedEventsHTML -ErrorAction SilentlyContinue)) {
        Update-ForwardedEventsHTML
    }
    
    # Display HTML dashboard location
    Write-Host "HTML dashboard is available at: $global:htmlDashboard" -ForegroundColor Green
    
    # Open the dashboard in the default browser if requested
    if ($OpenDashboardOnComplete -and (Test-Path -Path $global:htmlDashboard)) {
        Start-Process $global:htmlDashboard
    }
}
