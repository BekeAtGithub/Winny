

# Modify Get-RelevantEventLogs to include debugging
function Get-RelevantEventLogs {
    param(
        [int]$MinutesSince = 5
    )
    
    $startTime = (Get-Date).AddMinutes(-$MinutesSince)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    # Debug output
    Write-Host "Starting event log collection..." -ForegroundColor Cyan
    Write-Host "Looking for events from the past $MinutesSince minutes" -ForegroundColor Cyan
    
    # Define logs to search
    $logsToSearch = @('System', 'Application')
    if ($IncludeSecurityEvents) {
        $logsToSearch += 'Security'
    }
    
    Write-Host "Searching logs: $($logsToSearch -join ', ')" -ForegroundColor Cyan
    
    # Important event IDs related to performance
    $performanceRelatedEvents = @(
        1074,  # System shutdown/restart
        6008,  # Unexpected shutdown
        41,    # System rebooted without clean shutdown
        7031,  # Service terminated unexpectedly
        7034,  # Service terminated
        6013,  # System uptime
        1001,  # Windows Error Reporting
        333,   # Task Scheduler task completed
        201,   # Task Scheduler task completed
        219    # Task Scheduler task trigger
    )
    
    $collectedEvents = @()
    
    # Add detailed logging for each log search
    foreach ($logName in $logsToSearch) {
        Write-Host "Checking log: $logName" -ForegroundColor Cyan
        try {
            $events = Get-WinEvent -LogName $logName -MaxEvents 10 -ErrorAction SilentlyContinue
            Write-Host "  Found $($events.Count) recent events in $logName" -ForegroundColor Green
            
            $filteredEvents = $events | Where-Object { 
                ($_.Id -in $performanceRelatedEvents) -or 
                ($_.LevelDisplayName -eq 'Error') -or 
                ($_.LevelDisplayName -eq 'Warning') 
            }
            
            # Debug output for event count
            Write-Host "  Found $($filteredEvents.Count) events matching criteria in $logName" -ForegroundColor Green
            
            foreach ($event in $filteredEvents) {
                $message = $event.Message -replace "`r`n", " " -replace ",", ";"
                
                # Store in memory with EventTime property
                $collectedEvents += [PSCustomObject]@{
                    Timestamp = $timestamp
                    EventTime = $event.TimeCreated
                    LogName = $event.LogName
                    EventID = $event.Id
                    ProviderName = $event.ProviderName
                    LevelDisplayName = $event.LevelDisplayName
                    Message = $message
                }
            }
            
            # Try getting some events even without filtering if none found
            if ($filteredEvents.Count -eq 0) {
                Write-Host "  Attempting broader search..." -ForegroundColor Yellow
                $events = Get-WinEvent -LogName $logName -MaxEvents 5 -ErrorAction SilentlyContinue
                if ($events.Count -gt 0) {
                    Write-Host "  Found $($events.Count) events with broader search" -ForegroundColor Green
                    
                    # Add these events to collection
                    foreach ($event in $events) {
                        $message = $event.Message -replace "`r`n", " " -replace ",", ";"
                        
                        # Store in memory
                        $collectedEvents += [PSCustomObject]@{
                            Timestamp = $timestamp
                            EventTime = $event.TimeCreated
                            LogName = $event.LogName
                            EventID = $event.Id
                            ProviderName = $event.ProviderName
                            LevelDisplayName = $event.LevelDisplayName
                            Message = $message
                        }
                    }
                }
            }
        }
        catch {
            Write-Warning "Error accessing $logName log: $_"
        }
    }
    
    # Initialize array if it doesn't exist
    if ($null -eq $script:eventLogData) {
        $script:eventLogData = @()
    }
    
    # Add to global collection
    if ($collectedEvents.Count -gt 0) {
        $script:eventLogData += $collectedEvents
        # Debug output
        Write-Host "Collected $($collectedEvents.Count) event log records. Total: $($script:eventLogData.Count)" -ForegroundColor Cyan
    }
    else {
        Write-Host "No new event log records collected" -ForegroundColor Yellow
    }
    
    # Update HTML file
    Update-EventLogHTML
}

# Modify Get-TaskSchedulerInfo with more debugging
function Get-TaskSchedulerInfo {
    Write-Host "Starting task scheduler collection..." -ForegroundColor Cyan
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    # Get only recently run or scheduled tasks
    $recentTime = (Get-Date).AddDays(-1)
    
    $collectedTasks = @()
    
    try {
        # First check if we can access scheduled tasks
        $allTasks = Get-ScheduledTask -ErrorAction Stop
        Write-Host "Found $($allTasks.Count) total scheduled tasks" -ForegroundColor Green
        
        # Filter to recent or upcoming tasks
        $scheduledTasks = $allTasks | Where-Object {
            try {
                $taskInfo = $_ | Get-ScheduledTaskInfo -ErrorAction SilentlyContinue
                $isRecent = ($taskInfo.LastRunTime -ge $recentTime) -or ($taskInfo.NextRunTime -le (Get-Date).AddHours(24))
                $isRecent 
            }
            catch {
                $false
            }
        }
        
        Write-Host "Found $($scheduledTasks.Count) recently run or soon-to-run tasks" -ForegroundColor Green
        
        foreach ($task in $scheduledTasks) {
            try {
                $taskInfo = $task | Get-ScheduledTaskInfo -ErrorAction SilentlyContinue
                
                # Store in memory with relevant information
                $collectedTasks += [PSCustomObject]@{
                    Timestamp = $timestamp
                    TaskName = $task.TaskName
                    TaskPath = $task.TaskPath
                    State = $task.State
                    Enabled = $task.Settings.Enabled
                    LastRunTime = $taskInfo.LastRunTime
                    LastResult = $taskInfo.LastTaskResult
                    NextRunTime = $taskInfo.NextRunTime
                }
            }
            catch {
                # Skip tasks that can't retrieve info
                Write-Warning "Couldn't get info for task $($task.TaskName): $_"
            }
        }
    }
    catch {
        Write-Warning "Error accessing scheduled tasks: $_"
    }
    
    # Initialize array if it doesn't exist
    if ($null -eq $script:taskSchedulerData) {
        $script:taskSchedulerData = @()
    }
    
    # Add to global collection
    if ($collectedTasks.Count -gt 0) {
        $script:taskSchedulerData += $collectedTasks
        # Debug output
        Write-Host "Collected $($collectedTasks.Count) task scheduler records. Total: $($script:taskSchedulerData.Count)" -ForegroundColor Cyan
    }
    else {
        Write-Host "No new task scheduler records collected" -ForegroundColor Yellow
    }
    
    # Update HTML file
    Update-TaskSchedulerHTML
    
    # Verify the file was created
    if (Test-Path $global:taskHtmlFile) {
        Write-Host "Task scheduler HTML file created at: $global:taskHtmlFile" -ForegroundColor Green
    } else {
        Write-Warning "Task scheduler HTML file was not created at: $global:taskHtmlFile"
    }
}
