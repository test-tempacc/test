# Check settings
$Path = [Environment]::GetFolderPath([Environment+SpecialFolder]::LocalApplicationData)
$Path = Join-Path -Path $Path -ChildPath "test-01"
$settings_path = Join-Path -Path $Path -ChildPath "settings.xml"
$script_path = Join-Path -Path $Path -ChildPath "window.ps1"
$settings = [xml](Get-Content -LiteralPath "$settings_path")
try {
    $MinDelay = [int]$settings.settings.delay.min
    [int]$MaxDelay = [int]$settings.settings.delay.max + 1
} catch {}

$Delay = Get-Random -Minimum $MinDelay -Maximum $MaxDelay
Start-Sleep -Seconds $Delay
Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$script_path`" -Type powershell -WindowStyle Normal"
