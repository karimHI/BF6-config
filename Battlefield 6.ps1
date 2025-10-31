If (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator"))
{
    Start-Process PowerShell.exe -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"{0}`"" -f $PSCommandPath) -Verb RunAs
    Exit
}

$Host.UI.RawUI.WindowTitle = "Battlefield 6 user.cfg Creator (Administrator)"
$Host.UI.RawUI.BackgroundColor = "Black"
$Host.PrivateData.ProgressBackgroundColor = "Black"
$Host.PrivateData.ProgressForegroundColor = "White"
Clear-Host

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

Write-Host "Searching for Battlefield 6 installation directory..." -ForegroundColor Yellow

$gameName = "Battlefield 6"
$exeName = "bf6.exe"
$regPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)
$defaultSteamPath = "C:\Program Files\Steam\steamapps\common\Battlefield 6"
$installPath = $null

# 1. Try finding via registry
Write-Host "Checking registry..." -ForegroundColor Gray
foreach ($path in $regPaths) {
    $potentialPath = (Get-ItemProperty -Path $path -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -eq $gameName -and $_.InstallLocation }).InstallLocation
    if ($potentialPath) {
        # Check if bf6.exe exists in this path
        if (Test-Path (Join-Path $potentialPath $exeName)) {
            $installPath = $potentialPath
            Write-Host "Found in registry." -ForegroundColor Gray
            break 
        }
    }
}

# 2. If registry fails, check default Steam path
if (!$installPath) {
    Write-Host "Could not find in registry. Checking default Steam location..." -ForegroundColor Gray
    if (Test-Path (Join-Path $defaultSteamPath $exeName)) {
        $installPath = $defaultSteamPath
        Write-Host "Found in default Steam location." -ForegroundColor Gray
    }
}

# 3. If both auto-detections fail, ask manually
if (!$installPath) {
    Write-Host ""
    Write-Host "Could not automatically find the '$gameName' directory (missing $exeName)." -ForegroundColor Red
    Write-Host "Please paste the full path to your game's installation folder."
    Write-Host "(e.g., $defaultSteamPath)"
    Write-Host ""
    $manualPath = Read-Host -Prompt "Game Path"
    
    # Check manual path for bf6.exe
    if ($manualPath -and (Test-Path (Join-Path $manualPath $exeName))) {
        $installPath = $manualPath
    } else {
m       Write-Host ""
        Write-Host "Invalid path or '$exeName' not found in that folder. Exiting." -ForegroundColor Red
        Start-Sleep -Seconds 3
        Exit
    }
}

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
