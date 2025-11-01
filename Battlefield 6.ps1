# 1. Administrator Check
If (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator"))
{
    # Relaunches the script as Administrator if not already
    Start-Process PowerShell.exe -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"{0}`"" -f $PSCommandPath) -Verb RunAs
    Exit
}

# 2. Console Setup
$Host.UI.RawUI.WindowTitle = "Battlefield user.cfg Creator (Administrator)"
$Host.UI.RawUI.BackgroundColor = "Black"
$Host.PrivateData.ProgressBackgroundColor = "Black"
$Host.PrivateData.ProgressForegroundColor = "White"
Clear-Host

# 3. Ask for Core Count
Write-Host "Please enter the number of PHYSICAL cores your CPU has (e.g., 6, 8, 12):" -ForegroundColor Cyan
$CoreCountInput = Read-Host -Prompt "Number of Cores (X)"

# Basic validation to make sure it's a number
if ($CoreCountInput -notmatch "^\d+$" -or [int]$CoreCountInput -le 0) {
    Write-Host ""
    Write-Host "Invalid input. Please enter a positive number." -ForegroundColor Red
    Start-Sleep -Seconds 3
    Exit
}

# 4. Set X and Y Variables
$CoreCount = [int]$CoreCountInput   # This is your X
$ThreadCount = $CoreCount * 2       # This is your Y (X * 2)

Write-Host ""
Write-Host "OK. Using $CoreCount cores (X) and $ThreadCount threads (Y) for the config." -ForegroundColor Green
Start-Sleep -Seconds 2
Clear-Host

# 5. --- UPDATED: Config File Content ---
# This now ONLY contains the thread settings you specified.
$cfgContent = @"
Thread.ProcessorCount $CoreCount
Thread.MaxProcessorCount $CoreCount
Thread.MinFreeProcessorCount $CoreCount
Thread.JobThreadPriority 0
Thread.MaxWorkerThreadCount $ThreadCount
"@

# 6. Find Game Installation Path
Write-Host "Searching for Battlefield 6 installation directory..." -ForegroundColor Yellow

$gameName = "Battlefield 6"
$regPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

$installPath = $null

foreach ($path in $regPaths) {
    $installPath = (Get-ItemProperty -Path $path -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -eq $gameName -and $_.InstallLocation }).InstallLocation
    if ($installPath) { break }
}

# 7. Ask for Path if Not Found
if (!$installPath -or !(Test-Path $installPath)) {
    Write-Host ""
    Write-Host "Could not automatically find the '$gameName' directory." -ForegroundColor Red
    Write-Host "Please paste the full path to your game's installation folder."
    Write-Host "(e.g., C:\Program Files\Steam\steamapps\common\Battlefield 6)"
    Write-Host ""
    $installPath = Read-Host -Prompt "Game Path"
    
    if (!$installPath -or !(Test-Path $installPath)) {
        Write-Host ""
        Write-Host "Invalid path. Exiting." -ForegroundColor Red
        Start-Sleep -Seconds 3
        Exit
    }
}

# 8. Write the user.cfg File
$cfgFilePath = Join-Path $installPath "user.cfg"

try {
    Write-Host ""
    Write-Host "Game found at: $installPath" -ForegroundColor Cyan
    Write-Host "Creating file: $cfgFilePath" -ForegroundColor Cyan
    
    Set-Content -Path $cfgFilePath -Value $cfgContent -Encoding Ascii -Force
    
    Write-Host ""
    Write-Host "Successfully created user.cfg with your custom thread settings!" -ForegroundColor Green
} catch {
    Write-Host ""
    Write-Host "An error occurred while writing the file:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}

# 9. Exit
Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
Exit
