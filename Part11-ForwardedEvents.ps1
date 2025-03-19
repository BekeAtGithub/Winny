

# Function to collect forwarded events information
function Get-ForwardedEvents {
    param(
        [int]$MinutesSince = 60
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "Collecting forwarded events..." -ForegroundColor Cyan
    
    $startTime = (Get-Date).AddMinutes(-$MinutesSince)
    
    # Initialize collection array
    $collectedEvents = @()
    
    try {
        # Check if the ForwardedEvents log exists
        $logExists = Get-WinEvent -ListLog "ForwardedEvents" -ErrorAction SilentlyContinue
        
        if ($logExists) {
            # Create a filter to get events from the specified time period
            $filter = @{
                LogName = "ForwardedEvents"
                StartTime = $startTime
            }
            
            # Get the events (limited to 200 to prevent overwhelming the system)
            $events = Get-WinEvent -FilterHashtable $filter -MaxEvents 200 -ErrorAction SilentlyContinue
            
            Write-Host "Retrieved $($events.Count) forwarded events" -ForegroundColor Green
            
            foreach ($event in $events) {
                # Clean up message for display
                $message = $event.Message -replace "`r`n", " " -replace ",", ";"
                
                # Store event information
                $eventInfo = [PSCustomObject]@{
                    Timestamp = $timestamp
                    EventTime = $event.TimeCreated
                    EventID = $event.Id
                    Level = $event.LevelDisplayName
                    SourceComputer = $event.MachineName
                    ProviderName = $event.ProviderName
                    TaskCategory = $event.TaskDisplayName
                    Message = $message
                    RecordID = $event.RecordId
                }
                
                $collectedEvents += $eventInfo
            }
        }
        else {
            Write-Host "ForwardedEvents log not found." -ForegroundColor Yellow
        }
    }
    catch {
        Write-Warning "Error retrieving forwarded events: $_"
    }
    
    # Initialize the global variable if it doesn't exist
    if ($null -eq $script:forwardedEventsData) {
        $script:forwardedEventsData = @()
    }
    
    # Add to global collection
    if ($collectedEvents.Count -gt 0) {
        $script:forwardedEventsData += $collectedEvents
        Write-Host "Collected $($collectedEvents.Count) forwarded events. Total: $($script:forwardedEventsData.Count)" -ForegroundColor Cyan
    }
    else {
        Write-Host "No forwarded events collected" -ForegroundColor Yellow
    }
    
    # Update HTML file
    Update-ForwardedEventsHTML
}

# Function to create or update Forwarded Events HTML file
function Update-ForwardedEventsHTML {
    # Define the file path if not already defined
    if (-not $global:forwardedEventsHtmlFile) {
        $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
        $global:forwardedEventsHtmlFile = Join-Path -Path $outputFolder -ChildPath "ForwardedEvents_$timestamp.html"
    }
    
    # Check if we have data
    if ($null -eq $script:forwardedEventsData -or $script:forwardedEventsData.Count -eq 0) {
        "<html><body><h1>No forwarded events available</h1><p>Event forwarding might not be configured on this system, or no events have been collected yet.</p></body></html>" | 
        Out-File -FilePath $global:forwardedEventsHtmlFile -Force
        return
    }
    
    # Generate HTML
    $htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>Windows 11 Performance Monitor - Forwarded Events</title>
    <meta http-equiv="refresh" content="60">
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1, h2 { color: #0078D7; }
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
        .refresh-button { background-color: #0078D7; color: white; padding: 10px; border: none; cursor: pointer; margin-left: 10px; border-radius: 5px; }
        .timestamp { font-style: italic; color: #666; }
        .search-box { padding: 8px; width: 300px; margin-right: 10px; margin-bottom: 10px; }
        .message-cell { max-width: 500px; overflow: hidden; text-overflow: ellipsis; }
        .collapsed { height: 20px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; cursor: pointer; }
        .expanded { white-space: pre-wrap; cursor: pointer; }
        .detail-row { display: none; }
        .filter-container { margin: 20px 0; display: flex; flex-wrap: wrap; gap: 10px; }
        .filter-item { padding: 8px 12px; background-color: #f0f0f0; border-radius: 4px; cursor: pointer; }
        .filter-item.active { background-color: #0078D7; color: white; }
    </style>
    <script>
        function refreshPage() {
            location.reload();
        }
        
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
        
        function filterEventsByLevel(level) {
            var rows = document.querySelectorAll('.event-row');
            var filters = document.querySelectorAll('.filter-item');
            
            // Update active filter
            filters.forEach(function(filter) {
                if (filter.getAttribute('data-level') === level) {
                    filter.classList.add('active');
                } else {
                    filter.classList.remove('active');
                }
            });
            
            // Show/hide rows based on filter
            rows.forEach(function(row) {
                if (level === 'All' || row.getAttribute('data-level') === level) {
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
    <h1>Forwarded Events</h1>
    <a href="$([System.IO.Path]::GetFileName($htmlDashboard))" class="back-button">Back to Dashboard</a>
    <button class="refresh-button" onclick="refreshPage()">Refresh Data</button>
    
    <div class="summary">
        <p>Showing forwarded events from other computers in the network</p>
        <p class="timestamp">Last updated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss") | Total events: $($script:forwardedEventsData.Count)</p>
    </div>
    
    <input type="text" id="event-search" class="search-box" placeholder="Search events..." onkeyup="searchEvents()">
    
    <div class="filter-container">
        <div class="filter-item active" data-level="All" onclick="filterEventsByLevel('All')">All Levels</div>
        <div class="filter-item" data-level="Error" onclick="filterEventsByLevel('Error')">Error</div>
        <div class="filter-item" data-level="Warning" onclick="filterEventsByLevel('Warning')">Warning</div>
        <div class="filter-item" data-level="Information" onclick="filterEventsByLevel('Information')">Information</div>
        <div class="filter-item" data-level="Critical" onclick="filterEventsByLevel('Critical')">Critical</div>
    </div>
    
    <table>
        <tr>
            <th>Time</th>
            <th>Source Computer</th>
            <th>ID</th>
            <th>Level</th>
            <th>Provider</th>
            <th>Message</th>
            <th>Actions</th>
        </tr>
"@

    # Get events sorted by most recent first
    $recentEvents = $script:forwardedEventsData | Sort-Object -Property EventTime -Descending | Select-Object -First 200
    
    # Add a unique ID for each event row for JavaScript interaction
    $eventCounter = 0
    
    foreach ($event in $recentEvents) {
        $eventCounter++
        $eventId = "fe-$eventCounter"
        
        # Determine row class based on event level
        $rowClass = ""
        if ($event.Level -eq "Error") { $rowClass = ' error' }
        elseif ($event.Level -eq "Warning") { $rowClass = ' warning' }
        elseif ($event.Level -eq "Critical") { $rowClass = ' critical' }
        elseif ($event.Level -eq "Information") { $rowClass = ' information' }
        
        # Format the event time
        $eventTime = if ($event.EventTime) { 
            Get-Date $event.EventTime -Format "yyyy-MM-dd HH:mm:ss" 
        } else { 
            $event.Timestamp 
        }
        
        # Create data attributes for filtering
        $dataAttributes = "data-level=`"$($event.Level)`" data-id=`"$eventId`" data-computer=`"$($event.SourceComputer)`""
        
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
            <td>$($event.SourceComputer)</td>
            <td>$($event.EventID)</td>
            <td>$($event.Level)</td>
            <td>$($event.ProviderName)</td>
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
            <td colspan="7">
                <div style="padding: 15px; background-color: #f9f9f9; border: 1px solid #ddd;">
                    <h3>Event Details</h3>
                    <p><strong>Event ID:</strong> $($event.EventID)</p>
                    <p><strong>Source Computer:</strong> $($event.SourceComputer)</p>
                    <p><strong>Provider:</strong> $($event.ProviderName)</p>
                    <p><strong>Level:</strong> $($event.Level)</p>
                    <p><strong>Category:</strong> $($event.TaskCategory)</p>
                    <p><strong>Time:</strong> $eventTime</p>
                    <p><strong>Record ID:</strong> $($event.RecordID)</p>
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

    # Save HTML to file
    $htmlContent | Out-File -FilePath $global:forwardedEventsHtmlFile -Force
    
    Write-Host "Forwarded events HTML updated at: $global:forwardedEventsHtmlFile" -ForegroundColor Green
}
