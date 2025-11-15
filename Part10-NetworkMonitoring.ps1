

# Function to collect network information.
function Get-NetworkInformation {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "Collecting network information..." -ForegroundColor Cyan
    
    # Initialize collection array
    $collectedNetworkInfo = @()
    
    # Get network adapters
    try {
        $networkAdapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
        
        foreach ($adapter in $networkAdapters) {
            # Get IP configuration
            $ipConfig = $adapter | Get-NetIPConfiguration
            $ipAddresses = $ipConfig.IPv4Address.IPAddress -join ", "
            $gateway = $ipConfig.IPv4DefaultGateway.NextHop
            
            # Get interface statistics
            $stats = $adapter | Get-NetAdapterStatistics
            $receivedBytes = if ($stats.ReceivedBytes) { [math]::Round($stats.ReceivedBytes / 1MB, 2) } else { 0 }
            $sentBytes = if ($stats.SentBytes) { [math]::Round($stats.SentBytes / 1MB, 2) } else { 0 }
            
            # Create adapter object
            $adapterInfo = [PSCustomObject]@{
                Timestamp = $timestamp
                Name = $adapter.Name
                InterfaceDescription = $adapter.InterfaceDescription
                Status = $adapter.Status
                LinkSpeed = $adapter.LinkSpeed
                MediaType = $adapter.MediaType
                MACAddress = $adapter.MacAddress
                IPAddresses = $ipAddresses
                Gateway = $gateway
                ReceivedMB = $receivedBytes
                SentMB = $sentBytes
                DNS = ($ipConfig.DNSServer | Where-Object { $_.AddressFamily -eq 2 } | Select-Object -ExpandProperty ServerAddresses) -join ", "
                Type = "Adapter"
            }
            
            $collectedNetworkInfo += $adapterInfo
        }
    }
    catch {
        Write-Warning "Error retrieving network adapter information: $_"
    }
    
    # Get active TCP connections (limit to 50 most recent)
    try {
        $connections = Get-NetTCPConnection -State Established,Listen | 
                      Select-Object -First 50 | 
                      Sort-Object -Property State,RemotePort
        
        foreach ($conn in $connections) {
            # Try to get process info
            $process = $null
            try {
                $process = Get-Process -Id $conn.OwningProcess -ErrorAction SilentlyContinue
            } catch {}
            
            $processName = if ($process) { $process.Name } else { "Unknown" }
            
            # Create connection object
            $connInfo = [PSCustomObject]@{
                Timestamp = $timestamp
                LocalAddress = $conn.LocalAddress
                LocalPort = $conn.LocalPort
                RemoteAddress = $conn.RemoteAddress
                RemotePort = $conn.RemotePort
                State = $conn.State
                ProcessId = $conn.OwningProcess
                ProcessName = $processName
                Type = "Connection"
            }
            
            $collectedNetworkInfo += $connInfo
        }
    }
    catch {
        Write-Warning "Error retrieving TCP connection information: $_"
    }
    
    # Get network interface performance
    try {
        $netPerf = Get-Counter -Counter "\Network Interface(*)\Bytes Total/sec" -ErrorAction SilentlyContinue
        if ($netPerf) {
            foreach ($counterInstance in $netPerf.CounterSamples) {
                # Extract interface name from counter path
                if ($counterInstance.InstanceName -ne "_Total") {
                    $interfaceName = $counterInstance.InstanceName
                    $bytesPerSec = [math]::Round($counterInstance.CookedValue, 2)
                    
                    # Create performance object
                    $perfInfo = [PSCustomObject]@{
                        Timestamp = $timestamp
                        Name = $interfaceName
                        BytesPerSec = $bytesPerSec
                        ThroughputMbps = [math]::Round(($bytesPerSec * 8) / 1MB, 2)
                        Type = "Performance"
                    }
                    
                    $collectedNetworkInfo += $perfInfo
                }
            }
        }
    }
    catch {
        Write-Warning "Error retrieving network performance information: $_"
    }
    
    # Initialize the global variable if it doesn't exist
    if ($null -eq $script:networkData) {
        $script:networkData = @()
    }
    
    # Add to global collection
    if ($collectedNetworkInfo.Count -gt 0) {
        $script:networkData += $collectedNetworkInfo
        Write-Host "Collected $($collectedNetworkInfo.Count) network information records. Total: $($script:networkData.Count)" -ForegroundColor Cyan
    }
    else {
        Write-Host "No network information collected" -ForegroundColor Yellow
    }
    
    # Update HTML file
    Update-NetworkHTML
}

# Function to create or update Network HTML file
function Update-NetworkHTML {
    # Define the file path if not already defined
    if (-not $global:networkHtmlFile) {
        $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
        $global:networkHtmlFile = Join-Path -Path $outputFolder -ChildPath "Network_$timestamp.html"
    }
    
    # Check if we have data
    if ($null -eq $script:networkData -or $script:networkData.Count -eq 0) {
        "<html><body><h1>No network data available yet</h1></body></html>" | Out-File -FilePath $global:networkHtmlFile -Force
        return
    }
    
    # Generate HTML
    $htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>Windows 11 Performance Monitor - Network Information</title>
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
        .high-traffic { background-color: #ffcccc; }
        .back-button { background-color: #0078D7; color: white; padding: 10px; 
                     text-decoration: none; display: inline-block; margin-top: 10px; border-radius: 5px; margin-right: 10px; }
        .refresh-button { background-color: #0078D7; color: white; padding: 10px; border: none; cursor: pointer; border-radius: 5px; }
        .summary { margin-bottom: 20px; }
        .timestamp { font-style: italic; color: #666; }
        .search-box { padding: 8px; width: 300px; margin-right: 10px; margin-bottom: 10px; }
        .adapter-card { border: 1px solid #ddd; border-radius: 5px; padding: 15px; margin-bottom: 15px; }
        .adapter-card h3 { margin-top: 0; color: #0078D7; }
        .adapter-details { display: grid; grid-template-columns: 1fr 1fr; gap: 10px; }
        .detail-item { margin-bottom: 5px; }
        .detail-label { font-weight: bold; }
    </style>
    <script>
        function refreshPage() {
            location.reload();
        }
        
        function searchConnections() {
            var searchText = document.getElementById('connection-search').value.toLowerCase();
            var rows = document.querySelectorAll('#Connections table tr');
            
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
    <h1>Network Information</h1>
    <a href="$([System.IO.Path]::GetFileName($htmlDashboard))" class="back-button">Back to Dashboard</a>
    <button class="refresh-button" onclick="refreshPage()">Refresh Data</button>
    
    <div class="summary">
        <p>Monitoring network activity and connections</p>
        <p class="timestamp">Last updated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
    </div>
    
    <div class="tabs">
        <button class="tablinks active" onclick="openTab(event, 'Adapters')">Network Adapters</button>
        <button class="tablinks" onclick="openTab(event, 'Performance')">Network Performance</button>
        <button class="tablinks" onclick="openTab(event, 'Connections')">Active Connections</button>
    </div>
"@

    # Get the most recent timestamp
    $latestTimestamp = ($script:networkData | Sort-Object -Property Timestamp -Descending | Select-Object -First 1).Timestamp
    
    # Network Adapters Tab
    $htmlContent += @"
    <div id="Adapters" class="tabcontent" style="display: block;">
        <h2>Network Adapters</h2>
"@

    # Get the latest adapter data
    $adapters = $script:networkData | Where-Object { $_.Type -eq "Adapter" -and $_.Timestamp -eq $latestTimestamp }
    
    foreach ($adapter in $adapters) {
        $htmlContent += @"
        <div class="adapter-card">
            <h3>$($adapter.Name) - $($adapter.InterfaceDescription)</h3>
            <div class="adapter-details">
                <div class="detail-item">
                    <span class="detail-label">Status:</span> $($adapter.Status)
                </div>
                <div class="detail-item">
                    <span class="detail-label">Media Type:</span> $($adapter.MediaType)
                </div>
                <div class="detail-item">
                    <span class="detail-label">MAC Address:</span> $($adapter.MACAddress)
                </div>
                <div class="detail-item">
                    <span class="detail-label">Link Speed:</span> $($adapter.LinkSpeed)
                </div>
                <div class="detail-item">
                    <span class="detail-label">IP Addresses:</span> $($adapter.IPAddresses)
                </div>
                <div class="detail-item">
                    <span class="detail-label">Gateway:</span> $($adapter.Gateway)
                </div>
                <div class="detail-item">
                    <span class="detail-label">DNS Servers:</span> $($adapter.DNS)
                </div>
                <div class="detail-item">
                    <span class="detail-label">Data Received:</span> $($adapter.ReceivedMB) MB
                </div>
                <div class="detail-item">
                    <span class="detail-label">Data Sent:</span> $($adapter.SentMB) MB
                </div>
            </div>
        </div>
"@
    }
    
    $htmlContent += @"
    </div>
"@

    # Network Performance Tab
    $htmlContent += @"
    <div id="Performance" class="tabcontent">
        <h2>Network Performance</h2>
        <table>
            <tr>
                <th>Interface</th>
                <th>Throughput (Mbps)</th>
                <th>Bytes/sec</th>
            </tr>
"@

    # Get the latest performance data
    $performances = $script:networkData | Where-Object { $_.Type -eq "Performance" -and $_.Timestamp -eq $latestTimestamp }
    
    foreach ($perf in $performances) {
        # Add high-traffic class for interfaces with high throughput
        $rowClass = if ($perf.ThroughputMbps -gt 50) { ' class="high-traffic"' } else { '' }
        
        $htmlContent += @"
            <tr$rowClass>
                <td>$($perf.Name)</td>
                <td>$($perf.ThroughputMbps)</td>
                <td>$($perf.BytesPerSec)</td>
            </tr>
"@
    }
    
    $htmlContent += @"
        </table>
    </div>
"@

    # Connections Tab
    $htmlContent += @"
    <div id="Connections" class="tabcontent">
        <h2>Active Network Connections</h2>
        <input type="text" id="connection-search" class="search-box" placeholder="Search connections..." onkeyup="searchConnections()">
        
        <table>
            <tr>
                <th>Process</th>
                <th>PID</th>
                <th>Local Address</th>
                <th>Local Port</th>
                <th>Remote Address</th>
                <th>Remote Port</th>
                <th>State</th>
            </tr>
"@

    # Get the latest connection data
    $connections = $script:networkData | Where-Object { $_.Type -eq "Connection" -and $_.Timestamp -eq $latestTimestamp }
    
    foreach ($conn in $connections) {
        $htmlContent += @"
            <tr>
                <td>$($conn.ProcessName)</td>
                <td>$($conn.ProcessId)</td>
                <td>$($conn.LocalAddress)</td>
                <td>$($conn.LocalPort)</td>
                <td>$($conn.RemoteAddress)</td>
                <td>$($conn.RemotePort)</td>
                <td>$($conn.State)</td>
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
    $htmlContent | Out-File -FilePath $global:networkHtmlFile -Force
    
    Write-Host "Network information HTML updated at: $global:networkHtmlFile" -ForegroundColor Green
}
