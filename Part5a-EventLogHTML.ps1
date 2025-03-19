

# Function to create or update Event Log HTML file
function Update-EventLogHTML {
    if ($script:eventLogData.Count -eq 0) {
        "<html><body><h1>No event log data available yet</h1></body></html>" | Out-File -FilePath $eventHtmlFile -Force
        return
    }
    
    $htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>Windows 11 Performance Monitor - Event Logs</title>
    <meta http-equiv="refresh" content="60">
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #0078D7; }
        h2 { color: #0078D7; margin-top: 20px; }
        .filter-container { margin: 20px 0; display: flex; flex-wrap: wrap; gap: 10px; }
        .filter-item { padding: 8px 12px; background-color: #f0f0f0; border-radius: 4px; cursor: pointer; }
        .filter-item.active { background-color: #0078D7; color: white; }
        table { border-collapse: collapse; width: 100%; margin-top: 20px; }
        th { background-color: #0078D7; color: white; text-align: left; padding: 8px; position: sticky; top: 0; }
        td { border: 1px solid #ddd; padding: 8px; }
        tr:nth-child(even) { background-color: #f2f2f2; }
        tr:hover { background-color: #ddd; }
        .error { background-color: #ffcccc; }
        .warning { background-color: #ffffcc; }
        .critical { background-color: #ff9999; }
        .information { background-color: #f0f0f0; }
        .back-button { background-color: #0078D7; color: white; padding: 10px; 
                     text-decoration: none; display: inline-block; margin-top: 10px; border-radius: 5px; }
        .timestamp { font-style: italic; color: #666; }
        .message-cell { max-width: 500px; overflow: hidden; text-overflow: ellipsis; }
        .collapsed { height: 20px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; cursor: pointer; }
        .expanded { white-space: pre-wrap; cursor: pointer; }
        .detail-row { display: none; }
        .search-box { padding: 8px; width: 300px; margin-right: 10px; margin-bottom: 10px; }
    </style>
    <script>
        function toggleMessage(id) {
            var element = document.getElementById('msg-' + id);
            if (element.classList.contains('collapsed')) {
                element.classList.remove('collapsed');
                element.classList.add('expanded');
            } else {
                element.classList.remove('expanded');
                element.classList.add('collapsed');
            }
        }
        
        function toggleDetails(id) {
            var detailRow = document.getElementById('detail-' + id);
            if (detailRow.style.display === 'none' || detailRow.style.display === '') {
                detailRow.style.display = 'table-row';
            } else {
                detailRow.style.display = 'none';
            }
        }
        
        function filterEventsByLog(logName) {
            var rows = document.querySelectorAll('.event-row');
            var filters = document.querySelectorAll('.filter-item');
            
            // Update active filter
            filters.forEach(function(filter) {
                if (filter.getAttribute('data-log') === logName) {
                    filter.classList.add('active');
                } else {
                    filter.classList.remove('active');
                }
            });
            
            // Show/hide rows based on filter
            rows.forEach(function(row) {
                if (logName === 'All' || row.getAttribute('data-log') === logName) {
                    row.style.display = 'table-row';
                } else {
                    row.style.display = 'none';
                }
                
                // Hide any expanded detail rows
                var id = row.getAttribute('data-id');
                if (id) {
                    var detailRow = document.getElementById('detail-' + id);
                    if (detailRow) {
                        detailRow.style.display = 'none';
                    }
                }
            });
        }
        
        function searchEvents() {
            var searchText = document.getElementById('event-search').value.toLowerCase();
            var rows = document.querySelectorAll('.event-row');
            
            rows.forEach(function(row) {
                var textContent = row.textContent.toLowerCase();
                if (searchText === '' || textContent.includes(searchText)) {
                    row.style.display = 'table-row';
                } else {
                    row.style.display = 'none';
                }
                
                // Hide any expanded detail rows
                var id = row.getAttribute('data-id');
                if (id) {
                    var detailRow = document.getElementById('detail-' + id);
                    if (detailRow) {
                        detailRow.style.display = 'none';
                    }
                }
            });
        }
    </script>
</head>
<body>
    <h1>Event Logs</h1>
    <a href="$([System.IO.Path]::GetFileName($htmlDashboard))" class="back-button">Back to Dashboard</a>
    <p class="timestamp">Last updated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss") | Total events: $($script:eventLogData.Count)</p>
    
    <input type="text" id="event-search" class="search-box" placeholder="Search events..." onkeyup="searchEvents()">
"@

    # Add the table header
    $htmlContent += @"
    
    <table>
        <tr>
            <th>Time</th>
            <th>Log Name</th>
            <th>ID</th>
            <th>Level</th>
            <th>Message</th>
            <th>Actions</th>
        </tr>
"@

    # Get events sorted by most recent first
    $recentEvents = $script:eventLogData | Sort-Object -Property EventTime, Timestamp -Descending | Select-Object -First 200
    
    # Add a unique ID for each event row for JavaScript interaction
    $eventCounter = 0
    
    foreach ($event in $recentEvents) {
        $eventCounter++
        $eventId = "event-$eventCounter"
        
        # Determine row class based on event level
        $rowClass = ""
        if ($event.LevelDisplayName -eq "Error") { $rowClass = ' error' }
        elseif ($event.LevelDisplayName -eq "Warning") { $rowClass = ' warning' }
        elseif ($event.LevelDisplayName -eq "Critical") { $rowClass = ' critical' }
        elseif ($event.LevelDisplayName -eq "Information") { $rowClass = ' information' }
        
        # Get a shorter display name for the log
        $displayLogName = $event.LogName
        if ($displayLogName -like "Microsoft-Windows-*") {
            $displayLogName = $displayLogName.Replace("Microsoft-Windows-", "")
        }
        if ($displayLogName.Length -gt 25) {
            $displayLogName = $displayLogName.Substring(0, 22) + "..."
        }
        
        # Format the event time - Handle null EventTime safely
        $eventTime = if ($event.EventTime -and $null -ne $event.EventTime) { 
            try {
                Get-Date -Date $event.EventTime -Format "yyyy-MM-dd HH:mm:ss" -ErrorAction SilentlyContinue
            } catch {
                $event.Timestamp
            }
        } else { 
            $event.Timestamp 
        }
        
        # Create data attributes for filtering
        $dataAttributes = "data-log=`"$($event.LogName)`" data-level=`"$($event.LevelDisplayName)`" data-id=`"$eventId`""
        
        # Handle null Message
        $messageContent = if ($event.Message) {
            $minLength = [Math]::Min(100, $event.Message.Length)
            $event.Message.Substring(0, $minLength) + $(if($event.Message.Length -gt 100){"..."})
        } else {
            "No message content"
        }
        
        $htmlContent += @"
        <tr class="event-row$rowClass" $dataAttributes>
            <td>$eventTime</td>
            <td>$displayLogName</td>
            <td>$($event.EventID)</td>
            <td>$($event.LevelDisplayName)</td>
            <td class="message-cell">
                <div id="msg-$eventId" class="collapsed" onclick="toggleMessage('$eventId')">
                    $messageContent
                </div>
            </td>
            <td>
                <button onclick="toggleDetails('$eventId')">Details</button>
            </td>
        </tr>
        <tr id="detail-$eventId" class="detail-row">
            <td colspan="6">
                <div style="padding: 15px; background-color: #f9f9f9; border: 1px solid #ddd;">
                    <h3>Event Details</h3>
                    <p><strong>Event ID:</strong> $($event.EventID)</p>
                    <p><strong>Log:</strong> $($event.LogName)</p>
                    <p><strong>Level:</strong> $($event.LevelDisplayName)</p>
                    <p><strong>Time:</strong> $eventTime</p>
                    $(if ($event.ProcessInfo) { "<p><strong>Process Info:</strong> $($event.ProcessInfo)</p>" })
                    $(if ($event.TaskName) { "<p><strong>Task Name:</strong> $($event.TaskName)</p>" })
                    <p><strong>Full Message:</strong></p>
                    <pre style="white-space: pre-wrap; background-color: #f0f0f0; padding: 10px; border: 1px solid #ddd;">$($event.Message)</pre>
                </div>
            </td>
        </tr>
"@
    }

    $htmlContent += @"
    </table>
</body>
</html>
"@

    $htmlContent | Out-File -FilePath $eventHtmlFile -Force
}
