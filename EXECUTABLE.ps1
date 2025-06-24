function Show-WinnyJenkinsGUI {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    # Create the main form 
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Winny Jenkins - Windows 11 Performance Monitor Toolkit"
    $form.Size = New-Object System.Drawing.Size(500, 300)
    $form.StartPosition = "CenterScreen"
    $form.BackColor = [System.Drawing.Color]::FromArgb(240, 240, 240)
    $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $form.MaximizeBox = $false

    # Add title label
    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Location = New-Object System.Drawing.Point(20, 20)
    $titleLabel.Size = New-Object System.Drawing.Size(460, 30)
    $titleLabel.Text = "Winny Jenkins"
    $titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
    $titleLabel.ForeColor = [System.Drawing.Color]::FromArgb(0, 120, 215)
    $form.Controls.Add($titleLabel)

    # Add subtitle label
    $subtitleLabel = New-Object System.Windows.Forms.Label
    $subtitleLabel.Location = New-Object System.Drawing.Point(20, 50)
    $subtitleLabel.Size = New-Object System.Drawing.Size(460, 20)
    $subtitleLabel.Text = "Windows 11 Performance Monitor"
    $subtitleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Italic)
    $subtitleLabel.ForeColor = [System.Drawing.Color]::FromArgb(80, 80, 80)
    $form.Controls.Add($subtitleLabel)

    # Add description
    $descriptionLabel = New-Object System.Windows.Forms.Label
    $descriptionLabel.Location = New-Object System.Drawing.Point(20, 80)
    $descriptionLabel.Size = New-Object System.Drawing.Size(460, 40)
    $descriptionLabel.Text = "The Winny Jenkins - Here to Win the day. ;) "
    $descriptionLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $form.Controls.Add($descriptionLabel)

    # Create Install button
    $installButton = New-Object System.Windows.Forms.Button
    $installButton.Location = New-Object System.Drawing.Point(50, 140)
    $installButton.Size = New-Object System.Drawing.Size(180, 50)
    $installButton.Text = "Install Monitor"
    $installButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $installButton.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 215)
    $installButton.ForeColor = [System.Drawing.Color]::White
    $installButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $form.Controls.Add($installButton)

    # Create Run button
    $runButton = New-Object System.Windows.Forms.Button
    $runButton.Location = New-Object System.Drawing.Point(270, 140)
    $runButton.Size = New-Object System.Drawing.Size(180, 50)
    $runButton.Text = "Run Monitor"
    $runButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $runButton.BackColor = [System.Drawing.Color]::FromArgb(0, 153, 0)
    $runButton.ForeColor = [System.Drawing.Color]::White
    $runButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $form.Controls.Add($runButton)

    # Add status label
    $statusLabel = New-Object System.Windows.Forms.Label
    $statusLabel.Location = New-Object System.Drawing.Point(20, 210)
    $statusLabel.Size = New-Object System.Drawing.Size(460, 20)
    $statusLabel.Text = "Ready"
    $statusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $statusLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $form.Controls.Add($statusLabel)

    # Add version information
    $versionLabel = New-Object System.Windows.Forms.Label
    $versionLabel.Location = New-Object System.Drawing.Point(20, 240)
    $versionLabel.Size = New-Object System.Drawing.Size(460, 20)
    $versionLabel.Text = "Version 1.0"
    $versionLabel.Font = New-Object System.Drawing.Font("Segoe UI", 8)
    $versionLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $versionLabel.ForeColor = [System.Drawing.Color]::Gray
    $form.Controls.Add($versionLabel)

    # Get the script path
    $scriptPath = $PSScriptRoot
    if ([string]::IsNullOrEmpty($scriptPath)) {
        $scriptPath = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
    }

    # Install button click event with improved script execution
    $installButton.Add_Click({
        $statusLabel.Text = "Installing performance monitor..."
        $statusLabel.ForeColor = [System.Drawing.Color]::FromArgb(0, 120, 215)
        $form.Refresh()
        
        try {
            $installScriptPath = Join-Path -Path $scriptPath -ChildPath "Part7c-MainInstallation.ps1"
            if (Test-Path $installScriptPath) {
                # Get the absolute path
                $absolutePath = (Resolve-Path $installScriptPath).Path
                $workingDirectory = Split-Path -Parent -Path $absolutePath
                
                # Start the installation process in a new window with explicit working directory
                Start-Process powershell.exe -ArgumentList "-NoExit -ExecutionPolicy Bypass -Command `"Set-Location '$workingDirectory'; & '$absolutePath'`"" -Wait
                $statusLabel.Text = "Installation completed successfully"
                $statusLabel.ForeColor = [System.Drawing.Color]::Green
            }
            else {
                $statusLabel.Text = "Installation script not found at: $installScriptPath"
                $statusLabel.ForeColor = [System.Drawing.Color]::Red
                
                # Display directory contents for debugging
                $folderContents = Get-ChildItem -Path $scriptPath -Filter "*.ps1" | Select-Object -ExpandProperty Name
                $statusLabel.Text += "`nFiles in directory: $($folderContents -join ', ')"
            }
        }
        catch {
            $statusLabel.Text = "Installation failed: $_"
            $statusLabel.ForeColor = [System.Drawing.Color]::Red
        }
    })

    # Run button click event with improved script execution
    $runButton.Add_Click({
        $statusLabel.Text = "Running performance monitor..."
        $statusLabel.ForeColor = [System.Drawing.Color]::FromArgb(0, 153, 0)
        $form.Refresh()
        
        try {
            $runScriptPath = Join-Path -Path $scriptPath -ChildPath "Part6-ScriptExecution.ps1"
            if (Test-Path $runScriptPath) {
                # Get the absolute path
                $absolutePath = (Resolve-Path $runScriptPath).Path
                $workingDirectory = Split-Path -Parent -Path $absolutePath
                
                # Start the execution process in a new window with explicit working directory
                Start-Process powershell.exe -ArgumentList "-NoExit -ExecutionPolicy Bypass -Command `"Set-Location '$workingDirectory'; & '$absolutePath'`"" -Wait
                $statusLabel.Text = "Performance monitor executed successfully"
                $statusLabel.ForeColor = [System.Drawing.Color]::Green
            }
            else {
                $statusLabel.Text = "Execution script not found at: $runScriptPath"
                $statusLabel.ForeColor = [System.Drawing.Color]::Red
                
                # Display directory contents for debugging
                $folderContents = Get-ChildItem -Path $scriptPath -Filter "*.ps1" | Select-Object -ExpandProperty Name
                $statusLabel.Text += "`nFiles in directory: $($folderContents -join ', ')"
                $statusLabel.Text += "`nCurrent directory: $scriptPath"
            }
        }
        catch {
            $statusLabel.Text = "Execution failed: $_"
            $statusLabel.ForeColor = [System.Drawing.Color]::Red
        }
    })

    # Show the form
    $form.ShowDialog()
}

# Call the function to start the application
Show-WinnyJenkinsGUI
