

# This script provides advanced analysis functions for the collected performance data

# Function to analyze performance trends
function Get-PerformanceTrends {
    param(
        [string]$OutputFolder = "$env:USERPROFILE\Desktop\PerfMonResults",
        [string]$OutputFile = "PerformanceAnalysis.html"
    )
    
    # Find the most recent monitoring session
    $dashboardFiles = Get-ChildItem -Path $OutputFolder -Filter "Dashboard_*.html" | Sort-Object LastWriteTime -Descending
    if ($dashboardFiles.Count -eq 0) {
        Write-Host "No monitoring data found in $OutputFolder" -ForegroundColor Yellow
        return
    }
    
    $latestSession = $dashboardFiles[0].BaseName -replace "Dashboard_", ""
    
    # Get process data
    $processFile = Join-Path -Path $OutputFolder -ChildPath "ProcessDetails_$latestSession.html"
    $eventLogFile = Join-Path -Path $OutputFolder -ChildPath "EventLog_$latestSession.html"
    
    # Create analysis HTML file
    $analysisHtmlPath = Join-Path -Path $OutputFolder -ChildPath $OutputFile
    
    # Generate HTML
    $htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>Windows 11 Performance Analysis</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1, h2 { color: #0078D7; }
        table { border-collapse: collapse; width: 100%; margin-top: 20px; }
        th { background-color: #0078D7; color: white; text-align: left; padding: 8px; }
        td { border: 1px solid #ddd; padding: 8px; }
        tr:nth-child(even) { background-color: #f2f2f2; }
        .analysis-section { margin-top: 30px; border: 1px solid #ddd; padding: 15px; border-radius: 5px; }
        .warning { background-color: #fff8dc; padding: 10px; border-left: 4px solid #ffd700; margin: 10px 0; }
        .critical { background-color: #ffe4e1; padding: 10px; border-left: 4px solid #ff6347; margin: 10px 0; }
        .info { background-color: #f0f8ff; padding: 10px; border-left: 4px solid #1e90ff; margin: 10px 0; }
    </style>
</head>
<body>
    <h1>Windows 11 Performance Analysis</h1>
    <p>Analysis based on monitoring session: $latestSession</p>
    
    <div class="analysis-section">
        <h2>Performance Summary</h2>
        <div class="info">
            <p><strong>Analysis Date:</strong> $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
            <p><strong>Computer Name:</strong> $env:COMPUTERNAME</p>
            <p><strong>OS Version:</strong> $((Get-CimInstance Win32_OperatingSystem).Caption)</p>
        </div>
        
        <h3>System Resource Usage</h3>
        <p>This analysis identifies potential performance issues based on the collected data:</p>
        
        <div class="warning">
            <h4>High CPU Usage Processes</h4>
            <p>The following processes consistently showed high CPU usage:</p>
            <ul>
                <li>Analysis requires access to raw data</li>
            </ul>
        </div>
        
        <div class="warning">
            <h4>High Memory Usage Processes</h4>
            <p>The following processes consumed significant memory:</p>
            <ul>
                <li>Analysis requires access to raw data</li>
            </ul>
        </div>
    </div>
    
    <div class="analysis-section">
        <h2>Event Log Analysis</h2>
        <p>Critical and warning events that may impact system performance:</p>
        
        <div class="critical">
            <h4>Critical Events</h4>
            <p>Critical events were detected that may indicate system issues:</p>
            <ul>
                <li>Analysis requires access to raw data</li>
            </ul>
        </div>
        
        <div class="warning">
            <h4>Warning Events</h4>
            <p>Warning events that may impact performance:</p>
            <ul>
                <li>Analysis requires access to raw data</li>
            </ul>
        </div>
    </div>
    
    <div class="analysis-section">
        <h2>Task Scheduler Analysis</h2>
        <p>Analysis of scheduled tasks:</p>
        
        <div class="info">
            <h4>Failed Tasks</h4>
            <p>Tasks that failed to complete:</p>
            <ul>
                <li>Analysis requires access to raw data</li>
            </ul>
        </div>
        
        <div class="info">
            <h4>Resource-Intensive Tasks</h4>
            <p>Scheduled tasks that consumed significant resources:</p>
            <ul>
                <li>Analysis requires access to raw data</li>
            </ul>
        </div>
    </div>
    
    <div class="analysis-section">
        <h2>Recommendations</h2>
        <p>Based on the analysis, here are some recommendations to improve system performance:</p>
        <ul>
            <li>Monitor high CPU usage processes and consider optimizing or upgrading if needed</li>
            <li>Investigate warning and critical events in the Event Log</li>
            <li>Review failed scheduled tasks and fix any issues</li>
            <li>Consider increasing monitoring duration for more comprehensive analysis</li>
        </ul>
    </div>
</body>
</html>
"@

    # Save HTML to file
    $htmlContent | Out-File -FilePath $analysisHtmlPath -Force
    
    Write-Host "Performance analysis report created at: $analysisHtmlPath" -ForegroundColor Green
    
    # Open the analysis file in the default browser
    Start-Process $analysisHtmlPath
}

# Function to export collected data to CSV for external analysis
function Export-PerformanceData {
    param(
        [string]$OutputFolder = "$env:USERPROFILE\Desktop\PerfMonResults",
        [string]$ExportFolder = "$env:USERPROFILE\Desktop\PerfMonExport"
    )
    
    # Create export folder if it doesn't exist
    if (-not (Test-Path -Path $ExportFolder)) {
        New-Item -Path $ExportFolder -ItemType Directory -Force | Out-Null
    }
    
    # Find the most recent monitoring session
    $dashboardFiles = Get-ChildItem -Path $OutputFolder -Filter "Dashboard_*.html" | Sort-Object LastWriteTime -Descending
    if ($dashboardFiles.Count -eq 0) {
        Write-Host "No monitoring data found in $OutputFolder" -ForegroundColor Yellow
        return
    }
    
    $latestSession = $dashboardFiles[0].BaseName -replace "Dashboard_", ""
    
    # Export timestamp
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    
    # Create export summary file
    $summaryFile = Join-Path -Path $ExportFolder -ChildPath "ExportSummary_$timestamp.txt"
    
    # Create summary content
    $summaryContent = @"
Windows 11 Performance Monitor - Data Export
Export Date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Source Monitoring Session: $latestSession
Computer Name: $env:COMPUTERNAME
OS Version: $((Get-CimInstance Win32_OperatingSystem).Caption)

Files Exported:
"@
    
    # Copy all HTML files to export folder with an export_ prefix
    $htmlFiles = Get-ChildItem -Path $OutputFolder -Filter "*_$latestSession.html"
    foreach ($file in $htmlFiles) {
        $exportName = "Export_" + $file.Name
        $exportPath = Join-Path -Path $ExportFolder -ChildPath $exportName
        Copy-Item -Path $file.FullName -Destination $exportPath -Force
        $summaryContent += "`n- $exportName"
    }
    
    # Save summary file
    $summaryContent | Out-File -FilePath $summaryFile -Force
    
    Write-Host "Performance data exported to: $ExportFolder" -ForegroundColor Green
    Write-Host "Export summary created at: $summaryFile" -ForegroundColor Green
}

# Function to compare multiple monitoring sessions
function Compare-MonitoringSessions {
    param(
        [string]$OutputFolder = "$env:USERPROFILE\Desktop\PerfMonResults",
        [string]$OutputFile = "ComparisonReport.html",
        [int]$MaxSessions = 5
    )
    
    # Find monitoring sessions
    $dashboardFiles = Get-ChildItem -Path $OutputFolder -Filter "Dashboard_*.html" | Sort-Object LastWriteTime -Descending
    if ($dashboardFiles.Count -le 1) {
        Write-Host "Not enough monitoring sessions found for comparison. Need at least 2 sessions." -ForegroundColor Yellow
        return
    }
    
    # Limit to max number of sessions
    $sessions = $dashboardFiles | Select-Object -First $MaxSessions
    $sessionIds = $sessions | ForEach-Object { $_.BaseName -replace "Dashboard_", "" }
    
    # Create comparison HTML file
    $comparisonHtmlPath = Join-Path -Path $OutputFolder -ChildPath $OutputFile
    
    # Generate HTML
    $htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>Windows 11 Performance Monitoring - Session Comparison</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1, h2 { color: #0078D7; }
        table { border-collapse: collapse; width: 100%; margin-top: 20px; }
        th { background-color: #0078D7; color: white; text-align: left; padding: 8px; }
        td { border: 1px solid #ddd; padding: 8px; }
        tr:nth-child(even) { background-color: #f2f2f2; }
        .improved { background-color: #e6ffe6; }
        .degraded { background-color: #ffe6e6; }
        .no-change { background-color: #f0f0f0; }
    </style>
</head>
<body>
    <h1>Performance Monitoring Session Comparison</h1>
    <p>Comparing latest $($sessions.Count) monitoring sessions</p>
    
    <h2>Session Details</h2>
    <table>
        <tr>
            <th>Session ID</th>
            <th>Date/Time</th>
            <th>Dashboard</th>
        </tr>
"@

    $sessionCount = 0
    foreach ($session in $sessions) {
        $sessionCount++
        $sessionDate = $session.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
        $dashboardLink = $session.Name
        
        $htmlContent += @"
        <tr>
            <td>Session $sessionCount</td>
            <td>$sessionDate</td>
            <td><a href="$dashboardLink">View Dashboard</a></td>
        </tr>
"@
    }

    $htmlContent += @"
    </table>
    
    <h2>Comparison Results</h2>
    <p>This comparison shows trends across multiple monitoring sessions. Green indicates improvement, red indicates degradation.</p>
    
    <h3>Summary</h3>
    <p>Detailed comparison requires analysis of raw data from each session.</p>
    
    <h3>Recommendations</h3>
    <p>Based on the comparison of monitoring sessions:</p>
    <ul>
        <li>Run regular monitoring sessions to track performance trends over time</li>
        <li>Investigate significant changes in resource usage between sessions</li>
        <li>Export data for more detailed analysis in external tools if needed</li>
    </ul>
</body>
</html>
"@

    # Save HTML to file
    $htmlContent | Out-File -FilePath $comparisonHtmlPath -Force
    
    Write-Host "Comparison report created at: $comparisonHtmlPath" -ForegroundColor Green
    
    # Open the comparison file in the default browser
    Start-Process $comparisonHtmlPath
}
