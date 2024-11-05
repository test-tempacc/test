param (
    $Type
)

[Console]::Title = "Critical Process"
[console]::CursorVisible = $false
Clear-Host

Function Halt {
    param (
      [string]$Message = "Press any key to continue . . . "
    )

    $cursor = [console]::CursorVisible
    [console]::CursorVisible = $false
    Write-Host "$Message" -NoNewline
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    [console]::CursorVisible = $cursor
    Write-Host
    }
  
# Check settings
$settings_path = [Environment]::GetFolderPath([Environment+SpecialFolder]::LocalApplicationData)
$settings_path = Join-Path -Path $settings_path -ChildPath ".troll"
$settings_path = Join-Path -Path $settings_path -ChildPath "settings.xml"
$settings = [xml](Get-Content -LiteralPath "$settings_path")
if ($null -eq $Type) { $Type = $settings.settings.bartype }

# Reasons
$reasons = @{
    0 = @("Updating Drivers...", "Driver update complete.`nYour computer will restart now.", "DarkGreen", "White", "/r", "Updating")
    1 = @("Starting quick scan...", "A virus has been detected (Trojan:Spy/Win32.KeyLogger).`nYour computer will shutdown now.", "Red", "White", "/s", "Quaranting")
    2 = @("Starting quick scan...", "A virus has been detected (Trojan:PSW/LdPinch).`nYour computer will shutdown now.", "Red", "White", "/s", "Quaranting")
    3 = @("Downloading more RAM...", "Installation failed to complete.`nYour computer will shutdown now to prevent data loss.", "Red", "White", "/s", "Downloading")
    4 = @("System Overheat Detected.", "Cooling system failure.`nShutting down to prevent damage.", "Red", "White", "/s", "Resolving")
    5 = @("Installing New Features...", "Feature installation complete.`nYour computer will restart now.", "DarkGreen", "White", "/r", "Installing")
    6 = @("Critical System Update in Progress...", "Update complete.`nRebooting to apply changes.", "DarkGreen", "White", "/r", "Updating")
    7 = @("Network Security Breach Detected!", "Unauthorized access detected.`nShutting down for safety.", "Red", "White", "/s", "Securing system")
    8 = @("Memory Usage at 99%!", "Optimising performance by shutting down unnecessary processes.", "DarkGreen", "White", "/s", "Optimising")
    9 = @("Your computer is experiencing a critical error! (0x1F).", "System will shutdown to prevent further issues.", "Red", "White", "/s", "Troubleshooting")
    10 = @("Unexpected Error Occurred.", "Shutting down to prevent data loss.", "Red", "White", "/s", "Troubleshooting")
    }

# Randomly select a reason
$reason_rng = (Get-Random -Minimum 0 -Maximum $reasons.Count)
$reason = $reasons[$reason_rng]

if ($Type -ieq "powershell") {
    for ($loop = 1; $loop -le 100; $loop++ ) {
        Write-Progress -Activity "$($reason[0]) Don't close this window." -Status "$($reason[5]) - $loop% Complete" -PercentComplete $loop
        Start-Sleep -Milliseconds (Get-Random -Minimum 250 -Maximum 1000) } 
    Write-Host "`n`n`n`n`n`n" }
    
else {
    $size = 20
    $division = 100 / $size

    $out = "[" + (" " * $size) + "] 0%"
    Write-Host "`n$($reason[0])" 
    Write-Host "Don't turn off your PC or close this window. This may take a while.`n" -BackgroundColor Red -ForegroundColor White
    Write-Host "$out" -NoNewline
    Start-Sleep -Milliseconds (Get-Random -Minimum 750 -Maximum 2000)

    for ($loop = 1; $loop -le 100; $loop++ ) {
        $filled = [int][math]::Floor($loop / $division)
        $space = $size - $filled

        $out = "[" + ("=" * $filled) + (" " * $space) + "] $loop%"
        Write-Host "`r$out" -NoNewline
        Start-Sleep -Milliseconds (Get-Random -Minimum 250 -Maximum 1000) }
        Write-Host "" }

if ($Type -ieq "powershell") {
    # Keep the last progress update visible
    Write-Progress -Activity "$($reason[0]). Done." -Status "100% Complete" -PercentComplete 100
    Start-Sleep -Milliseconds 500 }

Start-Sleep -Milliseconds 250
Write-Host "`n$($reason[1])." -BackgroundColor $reason[2] -ForegroundColor $reason[3]
Start-Sleep -Milliseconds (Get-Random -Minimum 250 -Maximum 500)
Write-Host "Make sure to save all your work before the computer shuts down.`n"

Start-Sleep -Milliseconds 2500
shutdown.exe $reason[4] /c "$($reason[1])" /d p:4:1 /t 30
shutdown.exe /a

# Keep the final progress update visible and allow exit with any key
Halt -Message "Press any key to exit . . . "
Clear-Host
