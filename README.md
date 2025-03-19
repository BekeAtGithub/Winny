The Winny Jenkins - Windows Performance Toolkit
##  QUICK USAGE:


- STEP 1 : Right click "EXECUTABLE.ps1" and run as powershell - or - open powershell, navigate to this directory and just call it through cmd line

 - STEP 2 : Click Install - a powershell window will pop up, make sure to press "Y" on the first prompt, and just go through the installation options :) , for minimal problems, just use default choices - Once installed, close the window, and click "Run Monitor"

* by default this outputs to your LOCAL desktop, not your one-drive desktop , but local desktop 
give it 2-3 minutes, then look for "Dashboard_bunchofnumbers_forthedate.html"  - not exactly that title, but something like that 
then it will run for an hour or so, and you can monitor the usage the entire time 

![alt text](https://github.com/BekeAtGithub/WinnyJenkins/blob/main/2%20Step%20Instructions.png)


!! TROUBLESHOOTING

If you get an error about Unauthorized Access due to Policy like this;powershell script execution policy bypass
just run the command a little different like this;
powershell.exe -ExecutionPolicy Bypass -File ".\EXECUTE.ps1"


## For detailed Overview: 
Winny = Just a fun nickname for Windows :) 
The Winny Jenkins - Windows Performance Toolkit is a comprehensive tool to collect, monitor, and analyze detailed system performance metrics on Windows 11. The script tracks CPU usage, memory utilization, event logs, and scheduled tasks to provide insights into system performance.

## Features

- Real-time CPU and memory usage monitoring
- Detailed process information tracking
- Comprehensive event log collection from multiple sources
- Task Scheduler monitoring and analysis
- Interactive HTML dashboards with filtering and search
- Color-coded alerts for high resource usage
- Optional security event monitoring

## Requirements

- Windows 11 (should also work on Windows 10)
- PowerShell 5.1 or higher
- Administrator rights (for security event monitoring)

## Installation

### Manual Installation

Run the installation script:
open Powershell and type in the directory:
.\Part7c-MainInstallation.ps1


### Automated Installation

Run the following command in PowerShell:


iex (New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/your-repo/windows11-performance-monitor/main/Part7c-MainInstallation.ps1')


## Usage

### Quick Start

1. Run the script with default parameters:

.\Part6-ScriptExecution.ps1


2. View the HTML reports in your default browser (automatically opened when monitoring completes)

### Advanced Options

You can customize the monitoring with the following parameters:

```powershell
.\Part6-ScriptExecution.ps1 -SamplingIntervalSeconds 10 -MonitorDurationMinutes 120 -OutputFolder "C:\PerfMonResults" -IncludeTaskSchedulerEvents -IncludeSecurityEvents
```

### Parameters

- `-SamplingIntervalSeconds`: How often to sample data (default: 5 seconds)
- `-MonitorDurationMinutes`: How long to monitor (default: 60 minutes)
- `-OutputFolder`: Where to save the HTML reports (default: Desktop\PerfMonResults)
- `-IncludeTaskSchedulerEvents`: Include Task Scheduler events (default: enabled)
- `-IncludeSecurityEvents`: Include Security events (requires admin rights, default: disabled)

## File Structure

- **Part1-MainScript.ps1**: Core script setup and functions
- **Part2-EventLogCollection.ps1**: Event log and Task Scheduler data collection
- **Part3-ProcessHTML.ps1**: Process HTML report generation
- **Part4-DashboardFunction.ps1**: Main dashboard HTML generation
- **Part5a-EventLogHTML.ps1**: Event log HTML report generation
- **Part5b-TaskSchedulerHTML.ps1**: Task Scheduler HTML report generation
- **Part6-ScriptExecution.ps1**: Main execution script
- **Part7a/b/c**: Installation and configuration
- **Part8-AdvancedAnalysis.ps1**: Advanced analysis functions

## Output Files

The script generates the following HTML reports:

- `Dashboard_[timestamp].html`: Main dashboard with system overview and quick links
- `ProcessDetails_[timestamp].html`: Detailed process information
- `EventLog_[timestamp].html`: Event log data with filtering and search
- `TaskScheduler_[timestamp].html`: Task Scheduler information

## Troubleshooting

### Common Issues

1. **Security events not collected**
   - Run PowerShell as Administrator to access security logs

2. **Script execution policy error**
   - Run: `Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass`

3. **Error updating HTML files**
   - Ensure the output folder has write permissions

### Getting Help

For issues or feature requests, please contact the script author or submit an issue on GitHub.

## Advanced Analysis

For advanced analysis functions, use Part8:

```powershell
# Import analysis functions
. .\Part8-AdvancedAnalysis.ps1

# Generate performance trends report
Get-PerformanceTrends

# Export data for external analysis
Export-PerformanceData

# Compare multiple monitoring sessions
Compare-MonitoringSessions
```

## License

This script is provided as-is with no warranty. Free for personal and commercial use.
