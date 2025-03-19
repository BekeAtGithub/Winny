

# Function to collect security application information
function Get-SecurityApplications {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "Collecting security applications information..." -ForegroundColor Cyan
    
    # Initialize collection array
    $collectedSecurityApps = @()
    
    # Custom security application process names for your environment
    $securityAppMappings = @{
        # Nessus Tenable
        "nessus" = @{Name = "Nessus Tenable"; Vendor = "Tenable"; Category = "Vulnerability Scanner"}
        "nessusd" = @{Name = "Nessus Tenable Service"; Vendor = "Tenable"; Category = "Vulnerability Scanner"}
        "tenable" = @{Name = "Tenable Service"; Vendor = "Tenable"; Category = "Vulnerability Scanner"}
        
        # SentinelOne
        "SentinelAgent" = @{Name = "SentinelOne Agent"; Vendor = "SentinelOne"; Category = "EDR"}
        "SentinelService" = @{Name = "SentinelOne Service"; Vendor = "SentinelOne"; Category = "EDR"}
        "SentinelUI" = @{Name = "SentinelOne UI"; Vendor = "SentinelOne"; Category = "EDR"}
        "s1healthservice" = @{Name = "SentinelOne Health Service"; Vendor = "SentinelOne"; Category = "EDR"}
        
        # Windows Defender/Security
        "MsMpEng" = @{Name = "Windows Defender Antivirus"; Vendor = "Microsoft"; Category = "Antivirus"}
        "MsSense" = @{Name = "Windows Defender Advanced Threat Protection"; Vendor = "Microsoft"; Category = "EDR"}
        "SecurityHealthService" = @{Name = "Windows Security Health Service"; Vendor = "Microsoft"; Category = "Security"}
        "wscsvc" = @{Name = "Windows Security Center"; Vendor = "Microsoft"; Category = "Security"}
        "MSASCui" = @{Name = "Windows Security UI"; Vendor = "Microsoft"; Category = "Security"}
        "MSASCuiL" = @{Name = "Windows Security Notification"; Vendor = "Microsoft"; Category = "Security"}
        "MpCmdRun" = @{Name = "Windows Defender Command Line"; Vendor = "Microsoft"; Category = "Antivirus"}
        "NisSrv" = @{Name = "Windows Defender Antimalware"; Vendor = "Microsoft"; Category = "Antivirus"}
        
        # Darktrace
        "darktrace" = @{Name = "Darktrace"; Vendor = "Darktrace"; Category = "Network Detection"}
        "dtupdate" = @{Name = "Darktrace Updater"; Vendor = "Darktrace"; Category = "Network Detection"}
        "dt-service" = @{Name = "Darktrace Service"; Vendor = "Darktrace"; Category = "Network Detection"}
        
        # ManageEngine Endpoint Central
        "DesktopCentral_Agent" = @{Name = "ManageEngine Endpoint Central"; Vendor = "ManageEngine"; Category = "Endpoint Management"}
        "DCAgent" = @{Name = "ManageEngine Endpoint Central Agent"; Vendor = "ManageEngine"; Category = "Endpoint Management"}
        "MEPMAgent" = @{Name = "ManageEngine Patch Management"; Vendor = "ManageEngine"; Category = "Patch Management"}
        
        # CrowdStrike
        "CSFalcon" = @{Name = "CrowdStrike Falcon"; Vendor = "CrowdStrike"; Category = "EDR"}
        "CSFalconService" = @{Name = "CrowdStrike Falcon Service"; Vendor = "CrowdStrike"; Category = "EDR"}
        "CSFalconContainer" = @{Name = "CrowdStrike Falcon Container"; Vendor = "CrowdStrike"; Category = "EDR"}
        
        # Velociraptor
        "velociraptor" = @{Name = "Velociraptor"; Vendor = "Velociraptor"; Category = "Digital Forensics"}
        "Velociraptor.exe" = @{Name = "Velociraptor Client"; Vendor = "Velociraptor"; Category = "Digital Forensics"}
        
        # WebThreat Defense
        "WTD" = @{Name = "WebThreat Defense"; Vendor = "WebThreat"; Category = "Web Security"}
        "WTDService" = @{Name = "WebThreat Defense Service"; Vendor = "WebThreat"; Category = "Web Security"}
        "WebThreatDefense" = @{Name = "WebThreat Defense"; Vendor = "WebThreat"; Category = "Web Security"}
    }
    
    # Process name patterns to search for (partial matches)
    $processPatterns = @(
        "nessus", "tenable", 
        "sentinel", "s1", 
        "MsMpEng", "MsSense", "Security", "defender", "NisSrv",
        "darktrace", 
        "ManageEngine", "DesktopCentral", "EndpointCentral", "MEPMAgent", 
        "falcon", "crowdstrike", 
        "velociraptor", 
        "WTD", "WebThreat"
    )
    
    # Get all processes
    $allProcesses = Get-Process
    
    # Find security-related processes using pattern matching
    $processes = $allProcesses | Where-Object { 
        $process = $_
        $processPatterns | Where-Object { $process.Name -like "*$_*" }
    }
    
    Write-Host "Found $($processes.Count) processes that might be security-related" -ForegroundColor Cyan
    
    # Windows Defender status (special handling)
    try {
        Write-Host "Checking Windows Defender status..." -ForegroundColor Cyan
        $defenderStatus = Get-MpComputerStatus -ErrorAction SilentlyContinue
        
        if ($defenderStatus) {
            $defenderInfo = [PSCustomObject]@{
                Timestamp = $timestamp
                ApplicationName = "Windows Defender"
                ProcessName = "MsMpEng"
                Status = if ($defenderStatus.AntivirusEnabled) { "Running" } else { "Disabled" }
                Version = $defenderStatus.AntivirusSignatureVersion
                LastUpdated = $defenderStatus.AntivirusSignatureLastUpdated
                RealTimeProtection = $defenderStatus.RealTimeProtectionEnabled
                CPUUsage = ($processes | Where-Object { $_.Name -eq "MsMpEng" } | Measure-Object -Property CPU -Sum).Sum
                MemoryUsage = ($processes | Where-Object { $_.Name -eq "MsMpEng" } | Measure-Object -Property WorkingSet -Sum).Sum / 1MB
                Category = "Antivirus"
                Vendor = "Microsoft"
            }
            
            $collectedSecurityApps += $defenderInfo
            Write-Host "Added Windows Defender with status: $($defenderInfo.Status)" -ForegroundColor Green
        }
    }
    catch {
        Write-Warning "Error retrieving Windows Defender status: $_"
    }
    
    # Process each security application
    foreach ($process in $processes) {
        try {
            # Get process details
            $cpuUsage = [math]::Round($process.CPU, 2)
            $memoryMB = [math]::Round($process.WorkingSet / 1MB, 2)
            
            # Find matching security app from our mappings
            $matchedApp = $null
            $exactMatch = $securityAppMappings[$process.Name]
            
            if ($exactMatch) {
                $matchedApp = $exactMatch
                $appName = $exactMatch.Name
                $vendor = $exactMatch.Vendor
                $category = $exactMatch.Category
            } else {
                # Try fuzzy matching
                foreach ($key in $securityAppMappings.Keys) {
                    if ($process.Name -like "*$key*") {
                        $matchedApp = $securityAppMappings[$key]
                        $appName = $matchedApp.Name
                        $vendor = $matchedApp.Vendor
                        $category = $matchedApp.Category
                        break
                    }
                }
            }
            
            # If no match found, try to get file details
            if ($null -eq $matchedApp) {
                # Try to get product details from the process path
                try {
                    $processModule = $process.MainModule
                    if ($processModule) {
                        $executablePath = $processModule.FileName
                        $fileVersionInfo = Get-ItemProperty $executablePath -ErrorAction SilentlyContinue
                        if ($fileVersionInfo) {
                            $appName = $fileVersionInfo.VersionInfo.ProductName
                            $fileVersion = $fileVersionInfo.VersionInfo.FileVersion
                            $vendor = $fileVersionInfo.VersionInfo.CompanyName
                            $category = "Security"
                        } else {
                            $appName = $process.Name
                            $fileVersion = "Unknown"
                            $vendor = "Unknown"
                            $category = "Security"
                        }
                    } else {
                        $appName = $process.Name
                        $fileVersion = "Unknown"
                        $vendor = "Unknown"
                        $category = "Security"
                    }
                }
                catch {
                    $appName = $process.Name
                    $fileVersion = "Unknown"
                    $vendor = "Unknown"
                    $category = "Security"
                }
            } else {
                # Get file version if possible
                try {
                    $processModule = $process.MainModule
                    if ($processModule) {
                        $executablePath = $processModule.FileName
                        $fileVersionInfo = Get-ItemProperty $executablePath -ErrorAction SilentlyContinue
                        if ($fileVersionInfo) {
                            $fileVersion = $fileVersionInfo.VersionInfo.FileVersion
                        } else {
                            $fileVersion = "Unknown"
                        }
                    } else {
                        $fileVersion = "Unknown"
                    }
                }
                catch {
                    $fileVersion = "Unknown"
                }
            }
            
            # Skip if this is Windows Defender (we already added it above) 
            if ($process.Name -eq "MsMpEng" -and $appName -eq "Windows Defender Antivirus") {
                continue
            }
            
            # Create security app object
            $securityApp = [PSCustomObject]@{
                Timestamp = $timestamp
                ApplicationName = $appName
                ProcessName = $process.Name
                Status = "Running"
                Version = $fileVersion
                LastUpdated = $null
                RealTimeProtection = $true
                CPUUsage = $cpuUsage
                MemoryUsage = $memoryMB
                Category = $category
                Vendor = $vendor
                PID = $process.Id
                ThreadCount = $process.Threads.Count
                HandleCount = $process.HandleCount
            }
            
            $collectedSecurityApps += $securityApp
            Write-Host "Added security application: $appName (Process: $($process.Name))" -ForegroundColor Green
        }
        catch {
            Write-Warning "Error processing security application $($process.Name): $_"
        }
    }
    
    # Check for specific services that might not have running processes
    $securityServices = @(
        @{Name = "Windows Defender"; ServiceName = "WinDefend"; Vendor = "Microsoft"; Category = "Antivirus"},
        @{Name = "SentinelOne"; ServiceName = "SentinelAgent"; Vendor = "SentinelOne"; Category = "EDR"},
        @{Name = "CrowdStrike Falcon"; ServiceName = "CSFalconService"; Vendor = "CrowdStrike"; Category = "EDR"},
        @{Name = "Nessus"; ServiceName = "Tenable Nessus"; Vendor = "Tenable"; Category = "Vulnerability Scanner"},
        @{Name = "ManageEngine Endpoint Central"; ServiceName = "DesktopCentralAgent"; Vendor = "ManageEngine"; Category = "Endpoint Management"},
        @{Name = "Windows Security Center"; ServiceName = "wscsvc"; Vendor = "Microsoft"; Category = "Security"},
        @{Name = "Windows Antimalware Service"; ServiceName = "WdNisSvc"; Vendor = "Microsoft"; Category = "Antivirus"},
        @{Name = "Darktrace"; ServiceName = "Darktrace"; Vendor = "Darktrace"; Category = "Network Detection"},
        @{Name = "Velociraptor"; ServiceName = "Velociraptor"; Vendor = "Velociraptor"; Category = "Digital Forensics"},
        @{Name = "WebThreat Defense"; ServiceName = "WebThreatDefense"; Vendor = "WebThreat"; Category = "Web Security"}
    )
    
    try {
        Write-Host "Checking for security-related services..." -ForegroundColor Cyan
        foreach ($secService in $securityServices) {
            $service = Get-Service -Name $secService.ServiceName -ErrorAction SilentlyContinue
            
            if ($service) {
                # Check if we already have this app in our collection from process detection
                $existing = $collectedSecurityApps | Where-Object { $_.ApplicationName -eq $secService.Name }
                
                if (-not $existing) {
                    $serviceInfo = [PSCustomObject]@{
                        Timestamp = $timestamp
                        ApplicationName = $secService.Name
                        ProcessName = $secService.ServiceName
                        Status = $service.Status
                        Version = "Service: $($service.DisplayName)"
                        LastUpdated = $null
                        RealTimeProtection = ($service.Status -eq "Running")
                        CPUUsage = 0 # Can't get from service directly
                        MemoryUsage = 0 # Can't get from service directly
                        Category = $secService.Category
                        Vendor = $secService.Vendor
                        PID = 0
                        ThreadCount = 0
                        HandleCount = 0
                    }
                    
                    $collectedSecurityApps += $serviceInfo
                    Write-Host "Added security service: $($secService.Name) - Status: $($service.Status)" -ForegroundColor Green
                }
            }
        }
    }
    catch {
        Write-Warning "Error checking security services: $_"
    }
    
    # Initialize the global variable if it doesn't exist
    if ($null -eq $script:securityAppsData) {
        $script:securityAppsData = @()
    }
    
    # Add to global collection
    if ($collectedSecurityApps.Count -gt 0) {
        $script:securityAppsData += $collectedSecurityApps
        Write-Host "Collected $($collectedSecurityApps.Count) security application records. Total: $($script:securityAppsData.Count)" -ForegroundColor Cyan
    }
    else {
        Write-Host "No security applications found" -ForegroundColor Yellow
    }
    
    # Update HTML file
    Update-SecurityAppsHTML
}

# Function to create or update Security Applications HTML file
function Update-SecurityAppsHTML {
    # Define the file path if not already defined
    if (-not $global:securityAppsHtmlFile) {
        $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
        $global:securityAppsHtmlFile = Join-Path -Path $outputFolder -ChildPath "SecurityApps_$timestamp.html"
    }
    
    # Check if we have data
    if ($null -eq $script:securityAppsData -or $script:securityAppsData.Count -eq 0) {
        "<html><body><h1>No security applications data available yet</h1></body></html>" | Out-File -FilePath $global:securityAppsHtmlFile -Force
        return
    }
    
    # Generate HTML with more details for your specific security tools
    $htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>Windows 11 Performance Monitor - Security Applications</title>
    <meta http-equiv="refresh" content="30">
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1, h2 { color: #0078D7; }
        .tabs { margin-top: 20px; overflow: hidden; border: 1px solid #ccc; background-color: #f1f1f1; }
        .tabs button { background-color: inherit; float: left; border: none; outline: none; cursor: pointer; padding: 14px 16px; transition: 0.3s; }
        .tabs button:hover { background-color: #ddd; }
        .tabs button.active { background-color: #0078D7; color: white; }
        .tabcontent { display: none; padding: 20px; border: 1px solid #ccc; border-top: none; }
        table { border-collapse: collapse; width: 100%; margin-top: 20px; }
        th { background-color: #0078D7; color: white; text-align: left; padding: 8px; position: sticky; top: 0; }
        td { border: 1px solid #ddd; padding: 8px; }
        tr:nth-child(even) { background-color: #f2f2f2; }
        tr:hover { background-color: #ddd; }
        .high-cpu { background-color: #ffcccc; }
        .high-memory { background-color: #ffffcc; }
        .disabled { background-color: #f0f0f0; color: #999; }
        .status-running { color: green; font-weight: bold; }
        .status-stopped { color: red; font-weight: bold; }
        .back-button { background-color: #0078D7; color: white; padding: 10px; 
                     text-decoration: none; display: inline-block; margin-top: 10px; border-radius: 5px; margin-right: 10px; }
        .refresh-button { background-color: #0078D7; color: white; padding: 10px; border: none; cursor: pointer; border-radius: 5px; }
        .summary { margin-bottom: 20px; }
        .timestamp { font-style: italic; color: #666; }
        .search-box { padding: 8px; width: 300px; margin-right: 10px; margin-bottom: 10px; }
        .status-card { border: 1px solid #ddd; border-radius: 5px; padding: 15px; margin-bottom: 15px; display: inline-block; width: 30%; margin-right: 1%; }
        .status-card h3 { margin-top: 0; }
        .status-overview { margin-bottom: 30px; }
        .detail-row { font-size: 14px; margin-bottom: 5px; }
        .vendor-logo { height: 24px; margin-right: 10px; vertical-align: middle; }
    </style>
    <script>
        function refreshPage() {
            location.reload();
        }
        
        function searchApps() {
            var searchText = document.getElementById('app-search').value.toLowerCase();
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
        
        function openTab(evt, tabName) {
            var i, tabcontent, tablinks;
            tabcontent = document.getElementsByClassName("tabcontent");
            for (i = 0; i < tabcontent.length; i++) {
                tabcontent[i].style.display = "none";
            }
            tablinks = document.getElementsByClassName("tablinks");
            for (i = 0; i < tablinks.length; i++) {
                tablinks[i].className = tablinks[i].className.replace(" active", "");
            }
            document.getElementById(tabName).style.display = "block";
            evt.currentTarget.className += " active";
        }
    </script>
</head>
<body>
    <h1>Security Applications</h1>
    <a href="$([System.IO.Path]::GetFileName($htmlDashboard))" class="back-button">Back to Dashboard</a>
    <button class="refresh-button" onclick="refreshPage()">Refresh Data</button>
    
    <div class="summary">
        <p>Monitoring security applications and their performance</p>
        <p class="timestamp">Last updated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
    </div>
    
    <div class="tabs">
        <button class="tablinks active" onclick="openTab(event, 'Overview')">Overview</button>
        <button class="tablinks" onclick="openTab(event, 'DetailedList')">Detailed List</button>
        <button class="tablinks" onclick="openTab(event, 'Performance')">Performance</button>
    </div>
    
    <div id="Overview" class="tabcontent" style="display: block;">
        <h2>Security Applications Overview</h2>
        <div class="status-overview">
"@

    # Get distinct applications from the most recent timestamp
    $latestTimestamp = ($script:securityAppsData | Sort-Object -Property Timestamp -Descending | Select-Object -First 1).Timestamp
    $latestApps = $script:securityAppsData | Where-Object { $_.Timestamp -eq $latestTimestamp }
    
    # Group by vendor
    $vendorGroups = $latestApps | Group-Object -Property Vendor
    
    # Add status cards for each vendor
    foreach ($vendor in $vendorGroups) {
        $runningCount = ($vendor.Group | Where-Object { $_.Status -eq "Running" }).Count
        $stoppedCount = ($vendor.Group | Where-Object { $_.Status -ne "Running" }).Count
        $totalApps = $vendor.Group.Count
        
        $htmlContent += @"
            <div class="status-card">
                <h3>$($vendor.Name)</h3>
                <div class="detail-row">Applications: $totalApps</div>
                <div class="detail-row">Running: <span class="status-running">$runningCount</span></div>
                <div class="detail-row">Stopped/Disabled: <span class="status-stopped">$stoppedCount</span></div>
                <div class="detail-row">Products: $($vendor.Group.ApplicationName -join ", ")</div>
            </div>
"@
    }
    
    $htmlContent += @"
        </div>
        
        <h2>Security Status Summary</h2>
        <table>
            <tr>
                <th>Protection Type</th>
                <th>Status</th>
                <th>Products</th>
            </tr>
"@

    # Group by category
    $categoryGroups = $latestApps | Group-Object -Property Category
    
    foreach ($category in $categoryGroups) {
        $status = if (($category.Group | Where-Object { $_.Status -eq "Running" }).Count -gt 0) {
            '<span class="status-running">Protected</span>'
        } else {
            '<span class="status-stopped">Not Protected</span>'
        }
        
        $products = ($category.Group | Select-Object -ExpandProperty ApplicationName -Unique) -join ", "
        
        $htmlContent += @"
            <tr>
                <td>$($category.Name)</td>
                <td>$status</td>
                <td>$products</td>
            </tr>
"@
    }
    
    $htmlContent += @"
        </table>
    </div>
    
    <div id="DetailedList" class="tabcontent">
        <h2>Security Applications Detailed List</h2>
        <input type="text" id="app-search" class="search-box" placeholder="Search applications..." onkeyup="searchApps()">
        
        <table>
            <tr>
                <th>Application</th>
                <th>Status</th>
                <th>CPU Usage</th>
                <th>Memory (MB)</th>
                <th>Version</th>
                <th>Vendor</th>
                <th>Category</th>
                <th>PID</th>
            </tr>
"@

    # Add all applications to the detailed list
    foreach ($app in $latestApps) {
        # Determine row class based on status and resource usage
        $rowClass = ""
        $statusClass = if ($app.Status -eq "Running") { ' class="status-running"' } else { ' class="status-stopped"' }
        
        if ($app.Status -eq "Stopped" -or $app.Status -eq "Disabled") { 
            $rowClass = ' class="disabled"'
        }
        elseif ($app.CPUUsage -gt 10) { 
            $rowClass = ' class="high-cpu"'
        }
        elseif ($app.MemoryUsage -gt 300) { 
            $rowClass = ' class="high-memory"'
        }
        
        $htmlContent += @"
            <tr$rowClass>
                <td>$($app.ApplicationName)</td>
                <td$statusClass>$($app.Status)</td>
                <td>$($app.CPUUsage)</td>
                <td>$($app.MemoryUsage)</td>
                <td>$($app.Version)</td>
                <td>$($app.Vendor)</td>
                <td>$($app.Category)</td>
                <td>$($app.PID)</td>
            </tr>
"@
    }

    $htmlContent += @"
        </table>
    </div>
    
    <div id="Performance" class="tabcontent">
        <h2>Security Applications Performance</h2>
        <p>This view shows the resource usage of your security applications.</p>
        
        <table>
            <tr>
                <th>Application</th>
                <th>CPU Usage</th>
                <th>Memory (MB)</th>
                <th>Thread Count</th>
                <th>Handle Count</th>
                <th>Impact</th>
            </tr>
"@

    # Add performance data sorted by resource usage
    foreach ($app in ($latestApps | Sort-Object -Property CPUUsage -Descending)) {
        # Skip non-running applications
        if ($app.Status -ne "Running") {
            continue
        }
        
        # Determine performance impact
        $impact = "Low"
        $impactClass = ""
        
        if ($app.CPUUsage -gt 15 -or $app.MemoryUsage -gt 500) {
            $impact = "High"
            $impactClass = ' class="high-cpu"'
        }
        elseif ($app.CPUUsage -gt 5 -or $app.MemoryUsage -gt 200) {
            $impact = "Medium"
            $impactClass = ' class="high-memory"'
        }
        
        $htmlContent += @"
            <tr$impactClass>
                <td>$($app.ApplicationName) ($($app.Vendor))</td>
                <td>$($app.CPUUsage)%</td>
                <td>$($app.MemoryUsage) MB</td>
                <td>$($app.ThreadCount)</td>
                <td>$($app.HandleCount)</td>
                <td>$impact</td>
            </tr>
"@
    }

    $htmlContent += @"
        </table>
    </div>
</body>
</html>
"@

    # Save HTML to file
    $htmlContent | Out-File -FilePath $global:securityAppsHtmlFile -Force
    
    Write-Host "Security applications HTML updated at: $global:securityAppsHtmlFile" -ForegroundColor Green
}
