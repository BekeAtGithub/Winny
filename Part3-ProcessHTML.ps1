


# Function to create or update Process HTML file
function Update-ProcessHTML {
    # Generate HTML
    $htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>Windows 11 Performance Monitor - Process Details</title>
    <meta http-equiv="refresh" content="30">
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #0078D7; }
        table { border-collapse: collapse; width: 100%; margin-top: 20px; }
        th { background-color: #0078D7; color: white; text-align: left; padding: 8px; position: sticky; top: 0; }
        td { border: 1px solid #ddd; padding: 8px; }
        tr:nth-child(even) { background-color: #f2f2f2; }
        tr:hover { background-color: #ddd; }
        .high-cpu { background-color: #ffcccc; }
        .high-memory { background-color: #ffffcc; }
        .refresh-button { background-color: #0078D7; color: white; padding: 10px; border: none; cursor: pointer; margin-top: 10px; }
        .back-button { background-color: #0078D7; color: white; padding: 10px; 
                     text-decoration: none; display: inline-block; margin-top: 10px; border-radius: 5px; margin-right: 10px; }
        .summary { margin-bottom: 20px; }
        .timestamp { font-style: italic; color: #666; }
    </style>
    <script>
        function refreshPage() {
            location.reload();
        }
    </script>
</head>
<body>
    <h1>Process Details</h1>
    <a href="$([System.IO.Path]::GetFileName($htmlDashboard))" class="back-button">Back to Dashboard</a>
    <button class="refresh-button" onclick="refreshPage()">Refresh Data</button>
    
    <div class="summary">
        <p>Showing active processes sorted by CPU usage</p>
        <p class="timestamp">Last updated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
    </div>
    
    <table>
        <tr>
            <th>Timestamp</th>
            <th>Process Name</th>
            <th>PID</th>
            <th>CPU %</th>
            <th>Memory (MB)</th>
            <th>Start Time</th>
            <th>Thread Count</th>
            <th>Handle Count</th>
        </tr>
"@

    # Get last 100 process entries to avoid overwhelming the browser
    $recentProcesses = $script:processData | Sort-Object -Property Timestamp, CPUPercent -Descending | Select-Object -First 100
    
    foreach ($item in $recentProcesses) {
        $cpuClass = if ($item.CPUPercent -gt 10) { ' class="high-cpu"' } else { '' }
        $memClass = if ($item.MemoryMB -gt 500) { ' class="high-memory"' } else { '' }
        
        $htmlContent += @"
        <tr>
            <td>$($item.Timestamp)</td>
            <td>$($item.ProcessName)</td>
            <td>$($item.PID)</td>
            <td$cpuClass>$($item.CPUPercent)</td>
            <td$memClass>$($item.MemoryMB)</td>
            <td>$($item.StartTime)</td>
            <td>$($item.ThreadCount)</td>
            <td>$($item.HandleCount)</td>
        </tr>
"@
    }

    $htmlContent += @"
    </table>
</body>
</html>
"@

    # Save HTML to file
    $htmlContent | Out-File -FilePath $processHtmlFile -Force
}
