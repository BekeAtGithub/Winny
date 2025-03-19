

# Function to create or update main HTML dashboard (updated with new components)
function Update-HTMLDashboard {
    param(
        [datetime]$StartTime,
        [datetime]$CurrentTime
    )
    
    # Get current system stats
    $cpuUsage = Get-CpuUsage
    $memoryInfo = Get-MemoryInfo
    
    # Create performance trend data
    # Initialize array if it doesn't exist
    if ($null -eq $script:performanceData) {
        $script:performanceData = @()
    }
    
    # Add new data point
    $script:performanceData += [PSCustomObject]@{
        Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        CPUUsage = $cpuUsage
        AvailableMemoryMB = $memoryInfo.AvailableMemoryMB
        CommittedMemoryMB = $memoryInfo.CommittedMemoryMB
    }
    
    # Keep only last 20 records for the dashboard
    if ($script:performanceData.Count -gt 20) {
        $script:performanceData = $script:performanceData | Select-Object -Last 20
    }
    
    # Get top CPU processes - safely handle empty arrays
    $topProcesses = @()
    if ($null -ne $script:processData -and $script:processData.Count -gt 0) {
        $topProcesses = $script:processData | Sort-Object -Property Timestamp -Descending | 
                        Select-Object -First 50 | 
                        Sort-Object -Property CPUPercent -Descending | 
                        Select-Object -First 5
    }
    
    # Safely get process count
    $processCount = 0
    if ($null -ne $script:processData -and $script:processData.Count -gt 0) {
        $latestTimestamp = ($script:processData | Sort-Object -Property Timestamp -Descending | Select-Object -First 1).Timestamp
        $processCount = ($script:processData | Where-Object { $_.Timestamp -eq $latestTimestamp }).Count
    }
    
    # Safely get event count
    $eventCount = 0
    if ($null -ne $script:eventLogData) {
        $eventCount = $script:eventLogData.Count
    }
    
    # Safely get security apps count
    $securityAppsCount = 0
    if ($null -ne $script:securityAppsData -and $script:securityAppsData.Count -gt 0) {
        $latestTimestamp = ($script:securityAppsData | Sort-Object -Property Timestamp -Descending | Select-Object -First 1).Timestamp
        $securityAppsCount = ($script:securityAppsData | Where-Object { $_.Timestamp -eq $latestTimestamp } | Select-Object -ExpandProperty ApplicationName -Unique).Count
    }
    
    # Safely get network adapters count
    $networkAdaptersCount = 0
    if ($null -ne $script:networkData -and $script:networkData.Count -gt 0) {
        $latestTimestamp = ($script:networkData | Sort-Object -Property Timestamp -Descending | Select-Object -First 1).Timestamp
        $networkAdaptersCount = ($script:networkData | Where-Object { $_.Timestamp -eq $latestTimestamp -and $_.Type -eq "Adapter" }).Count
    }
    
    # Safely get forwarded events count
    $forwardedEventsCount = 0
    if ($null -ne $script:forwardedEventsData) {
        $forwardedEventsCount = $script:forwardedEventsData.Count
    }
    
    $htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>Windows 11 Performance Monitor Dashboard</title>
    <meta http-equiv="refresh" content="30">
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #0078D7; }
        h2 { color: #0078D7; margin-top: 30px; }
        .dashboard-container { display: flex; flex-wrap: wrap; }
        .info-box { border: 1px solid #ddd; padding: 15px; margin: 10px; border-radius: 5px; flex: 1; min-width: 300px; }
        .info-box h3 { margin-top: 0; color: #0078D7; }
        table { border-collapse: collapse; width: 100%; margin-top: 20px; }
        th { background-color: #0078D7; color: white; text-align: left; padding: 8px; }
        td { border: 1px solid #ddd; padding: 8px; }
        tr:nth-child(even) { background-color: #f2f2f2; }
        tr:hover { background-color: #ddd; }
        .link-button { display: inline-block; background-color: #0078D7; color: white; padding: 10px; 
                     text-decoration: none; margin-top: 10px; border-radius: 5px; width: 100%; text-align: center; box-sizing: border-box; }
        .high { color: red; font-weight: bold; }
        .medium { color: orange; font-weight: bold; }
        .good { color: green; }
        .stats-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 10px; }
        .stat-item { padding: 10px; border: 1px solid #ddd; border-radius: 5px; }
        .timestamp { font-style: italic; color: #666; margin-top: 20px; }
    </style>
</head>
<body>
    <h1>Windows 11 Performance Monitor Dashboard</h1>
    <div class="timestamp">
        <p>Monitoring session: $(Get-Date $StartTime -Format "yyyy-MM-dd HH:mm:ss") to $(Get-Date $CurrentTime -Format "yyyy-MM-dd HH:mm:ss")</p>
        <p>Last updated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
    </div>
    
    <div class="dashboard-container">
        <div class="info-box">
            <h3>Current System Status</h3>
            <div class="stats-grid">
                <div class="stat-item">
                    <div>CPU Usage:</div>
                    <div class="$(if($cpuUsage -gt 80){"high"}elseif($cpuUsage -gt 50){"medium"}else{"good"})">
                        $cpuUsage%
                    </div>
                </div>
                <div class="stat-item">
                    <div>Available Memory:</div>
                    <div class="$(if($memoryInfo.AvailableMemoryMB -lt 1000){"high"}elseif($memoryInfo.AvailableMemoryMB -lt 2000){"medium"}else{"good"})">
                        $($memoryInfo.AvailableMemoryMB) MB
                    </div>
                </div>
                <div class="stat-item">
                    <div>Process Count:</div>
                    <div>
                        $processCount
                    </div>
                </div>
                <div class="stat-item">
                    <div>Recent Events:</div>
                    <div>
                        $eventCount
                    </div>
                </div>
            </div>
        </div>
        
        <div class="info-box">
            <h3>System Information</h3>
            <p><strong>Computer Name:</strong> $env:COMPUTERNAME</p>
            <p><strong>OS Version:</strong> $((Get-CimInstance Win32_OperatingSystem).Caption)</p>
            <p><strong>CPU:</strong> $((Get-CimInstance Win32_Processor).Name)</p>
            <p><strong>Total Memory:</strong> $([math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)) GB</p>
            <p><strong>Uptime:</strong> $(
                $uptime = (Get-Date) - (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
                "$($uptime.Days) days, $($uptime.Hours) hours, $($uptime.Minutes) minutes"
            )</p>
        </div>
        
        <div class="info-box">
            <h3>Quick Links</h3>
            <p><a href="$([System.IO.Path]::GetFileName($processHtmlFile))" class="link-button">Process Details</a></p>
            <p><a href="$([System.IO.Path]::GetFileName($eventHtmlFile))" class="link-button">Event Logs</a></p>
            <p><a href="$([System.IO.Path]::GetFileName($taskHtmlFile))" class="link-button">Task Scheduler</a></p>
            $(if ($global:securityAppsHtmlFile) { "<p><a href=`"$([System.IO.Path]::GetFileName($global:securityAppsHtmlFile))`" class=`"link-button`">Security Applications ($securityAppsCount)</a></p>" })
            $(if ($global:networkHtmlFile) { "<p><a href=`"$([System.IO.Path]::GetFileName($global:networkHtmlFile))`" class=`"link-button`">Network Information ($networkAdaptersCount)</a></p>" })
            $(if ($global:forwardedEventsHtmlFile) { "<p><a href=`"$([System.IO.Path]::GetFileName($global:forwardedEventsHtmlFile))`" class=`"link-button`">Forwarded Events ($forwardedEventsCount)</a></p>" })
        </div>
    </div>
    
    <h2>Top CPU-Consuming Processes</h2>
    <table>
        <tr>
            <th>Process Name</th>
            <th>PID</th>
            <th>CPU %</th>
            <th>Memory (MB)</th>
            <th>Thread Count</th>
        </tr>
"@

    # Only add process rows if there are processes to display
    if ($topProcesses.Count -gt 0) {
        foreach ($proc in $topProcesses) {
            $htmlContent += @"
        <tr>
            <td>$($proc.ProcessName)</td>
            <td>$($proc.PID)</td>
            <td>$($proc.CPUPercent)</td>
            <td>$($proc.MemoryMB)</td>
            <td>$($proc.ThreadCount)</td>
        </tr>
"@
        }
    }
    else {
        $htmlContent += @"
        <tr>
            <td colspan="5" style="text-align: center;">No process data available yet</td>
        </tr>
"@
    }

    $htmlContent += @"
    </table>
    
    <h2>Recent Performance</h2>
    <table>
        <tr>
            <th>Timestamp</th>
            <th>CPU Usage (%)</th>
            <th>Available Memory (MB)</th>
            <th>Committed Memory (MB)</th>
        </tr>
"@

    # Only add performance data if available
    if ($script:performanceData.Count -gt 0) {
        foreach ($perf in ($script:performanceData | Sort-Object -Property Timestamp -Descending)) {
            $htmlContent += @"
        <tr>
            <td>$($perf.Timestamp)</td>
            <td>$($perf.CPUUsage)</td>
            <td>$($perf.AvailableMemoryMB)</td>
            <td>$($perf.CommittedMemoryMB)</td>
        </tr>
"@
        }
    }
    else {
        $htmlContent += @"
        <tr>
            <td colspan="4" style="text-align: center;">No performance data available yet</td>
        </tr>
"@
    }

    $htmlContent += @"
    </table>
</body>
</html>
"@

    $htmlContent | Out-File -FilePath $htmlDashboard -Force
}
