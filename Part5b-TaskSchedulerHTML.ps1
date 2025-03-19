

# Function to create or update Task Scheduler HTML file
function Update-TaskSchedulerHTML {
    if ($script:taskSchedulerData.Count -eq 0) {
        "<html><body><h1>No task scheduler data available yet</h1></body></html>" | Out-File -FilePath $taskHtmlFile -Force
        return
    }
    
    $htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>Windows 11 Performance Monitor - Task Scheduler</title>
    <meta http-equiv="refresh" content="60">
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #0078D7; }
        table { border-collapse: collapse; width: 100%; margin-top: 20px; }
        th { background-color: #0078D7; color: white; text-align: left; padding: 8px; position: sticky; top: 0; }
        td { border: 1px solid #ddd; padding: 8px; }
        tr:nth-child(even) { background-color: #f2f2f2; }
        tr:hover { background-color: #ddd; }
        .failed { background-color: #ffcccc; }
        .running { background-color: #ccffcc; }
        .disabled { background-color: #f0f0f0; color: #999; }
        .back-button { background-color: #0078D7; color: white; padding: 10px; 
                     text-decoration: none; display: inline-block; margin-top: 10px; border-radius: 5px; }
        .timestamp { font-style: italic; color: #666; }
        .search-box { padding: 8px; width: 300px; margin-right: 10px; margin-bottom: 10px; }
    </style>
    <script>
        function searchTasks() {
            var searchText = document.getElementById('task-search').value.toLowerCase();
            var rows = document.querySelectorAll('table tr');
            
            // Skip header row
            for (var i = 1; i < rows.length; i++) {
                var row = rows[i];
                var textContent = row.textContent.toLowerCase();
                if (searchText === '' || textContent.includes(searchText)) {
                    row.style.display = '';
                } else {
                    row.style.display = 'none';
                }
            }
        }
    </script>
</head>
<body>
    <h1>Task Scheduler Information</h1>
    <a href="$([System.IO.Path]::GetFileName($htmlDashboard))" class="back-button">Back to Dashboard</a>
    <p class="timestamp">Last updated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
    
    <input type="text" id="task-search" class="search-box" placeholder="Search tasks..." onkeyup="searchTasks()">
    
    <table>
        <tr>
            <th>State</th>
            <th>Task Name</th>
            <th>Task Path</th>
            <th>Last Run Time</th>
            <th>Last Result</th>
            <th>Next Run Time</th>
        </tr>
"@

    foreach ($task in ($script:taskSchedulerData | Sort-Object -Property State, TaskPath, TaskName)) {
        # Determine row class based on task state
        $rowClass = ""
        if ($task.LastResult -ne "0" -and $task.LastResult -ne "") { 
            $rowClass = ' class="failed"'
        }
        elseif ($task.State -eq "Running") { 
            $rowClass = ' class="running"'
        }
        elseif ($task.Enabled -eq $false) { 
            $rowClass = ' class="disabled"'
        }
        
        # Format the last run time
        $lastRunTime = if ($task.LastRunTime -and $task.LastRunTime -ne [DateTime]::MinValue) {
            Get-Date $task.LastRunTime -Format "yyyy-MM-dd HH:mm:ss"
        } else {
            "Never"
        }
        
        # Format the next run time
        $nextRunTime = if ($task.NextRunTime -and $task.NextRunTime -ne [DateTime]::MinValue) {
            Get-Date $task.NextRunTime -Format "yyyy-MM-dd HH:mm:ss"
        } else {
            "Not scheduled"
        }
        
        $htmlContent += @"
        <tr$rowClass>
            <td>$($task.State)</td>
            <td>$($task.TaskName)</td>
            <td>$($task.TaskPath)</td>
            <td>$lastRunTime</td>
            <td>$($task.LastResult)</td>
            <td>$nextRunTime</td>
        </tr>
"@
    }

    $htmlContent += @"
    </table>
</body>
</html>
"@

    $htmlContent | Out-File -FilePath $taskHtmlFile -Force
}
