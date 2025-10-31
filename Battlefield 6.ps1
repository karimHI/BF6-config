If (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator"))
{
    Write-Host "Administrator access required. Relaunching..." -ForegroundColor Yellow
    Start-Process PowerShell.exe -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"{0}`"" -f $PSCommandPath) -Verb RunAs
    Exit
}

$Host.UI.RawUI.WindowTitle = "Battlefield 6 user.cfg Creator (Administrator)"
$Host.UI.RawUI.BackgroundColor = "Black"
$Host.PrivateData.ProgressBackgroundColor = "Black"
$Host.PrivateData.ProgressForegroundColor = "White"
Clear-Host

# --- Config Content ---
$cfgContent = @"
PerfOverlay.DrawFps 1
GameTime.MaxVariableFps 0
RenderDevice.VSyncEnable 0
RenderDevice.TripleBufferingEnable 0
RenderDevice.RenderAheadLimit 1
RenderDevice.ForceRenderAheadLimit 1
RenderDevice.RawInputEnable 1
PostProcess.Quality 0
WorldRender.MeshQuality 0
WorldRender.EffectQuality 0
WorldRender.TerrainQuality 0
WorldRender.UndergrowthQuality 0
WorldRender.EnlightenEnable 0
WorldRender.SkyLightEnable 0
WorldRender.DeferredCsPathEnable 0
WorldRender.SpotLightShadowmapEnable 0
WorldRender.SpotLightShadowmapResolution 0
WorldRender.TransparencyShadowmapsEnable 0
WorldRender.PlanarReflectionEnable 0
WorldRender.MotionBlurEnable 0
PostProcess.DynamicAOEnable 0
WorldRender.SSAOEnable 0
WorldRender.FxaaEnable 0
WorldRender.HdrEnable 0
WorldRender.TonemapEnable 1
WorldRender.SunFlareEnable 0
WorldRender.DofEnable 0
Thread.ProcessorCount 6
Thread.MaxProcessorCount 12
Thread.MinFreeProcessorCount 0
Thread.JobThreadPriority 0
RenderDevice.AllowDynamicResolution 0
RenderDevice.VRamUseForStreamingEnable 1
"@

# --- Improved Game Detection ---

$gameName = "Battlefield 6"
$exeName = "bf6.exe"
$installPath = $null

Write-Host "Searching for $gameName ($exeName)..." -ForegroundColor Yellow

# Method 1: Search Registry (Flexible Match)
Write-Host "Checking registry..." -ForegroundColor Gray
$regPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)
$regEntries = Get-ItemProperty -Path $regPaths -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like "*$gameName*" -and $_.InstallLocation }

foreach ($entry in $regEntries) {
    $potentialPath = $entry.InstallLocation
    if (Test-Path (Join-Path $potentialPath $exeName)) {
        $installPath = $potentialPath
        Write-Host "Found via Registry." -ForegroundColor Green
        break
    }
}

# Method 2: Check Common Steam Directories
if (!$installPath) {
    Write-Host "Registry search failed. Checking common Steam locations..." -ForegroundColor Gray
    $defaultSteamPaths = @(
        "C:\Program Files\Steam\steamapps\common\$gameName",
        "C:\Program Files (x86)\Steam\steamapps\common\$gameName"
    )
    
    foreach ($path in $defaultSteamPaths) {
        if (Test-Path (Join-Path $path $exeName)) {
            $installPath = $path
            Write-Host "Found in default Steam folder." -ForegroundColor Green
            break
        }
    }
}

# Method 3: Manual Entry (with validation loop)
if (!$installPath) {
    Write-Host ""
    Write-Host "Could not automatically find '$gameName'." -ForegroundColor Red
    Write-Host "Please paste the full path to your game's installation folder."
    Write-Host "(Press ENTER to quit)"
    Write-Host ""
    
    while ($true) {
        $manualPath = Read-Host -Prompt "Game Path"
        
        # Allow user to quit
        if ([string]::IsNullOrEmpty($manualPath)) {
            Write-Host "No path provided. Exiting." -ForegroundColor Red
            Start-Sleep -Seconds 3
            Exit
        }
        
        # Check if the provided path is valid (contains bf6.exe)
        if (Test-Path (Join-Path $manualPath $exeName)) {
            $installPath = $manualPath
  T         Write-Host "Manual path accepted." -ForegroundColor Green
            break
        } else {
            Write-Host "Error: '$exeName' not found in that folder. Try again." -ForegroundColor Red
        }
    }
}

# --- File Creation ---
$cfgFilePath = Join-Path $installPath "user.cfg"

try {
    Write-Host ""
    Write-Host "Game found at: $installPath" -ForegroundColor Cyan
    Write-Host "Creating file: $cfgFilePath" -ForegroundColor Cyan
    
    Set-Content -Path $cfgFilePath -Value $cfgContent -Encoding Ascii -Force
    
    Write-Host ""
    Write-Host "Successfully created user.cfg with your settings!" -ForegroundColor Green
} catch {
    Write-Host ""
    Write-Host "An error occurred while writing the file:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}

Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

Exit
