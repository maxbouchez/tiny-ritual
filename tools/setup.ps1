param([switch]$Templates)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$Root = Split-Path $PSScriptRoot -Parent
$Version = (Get-Content (Join-Path $Root '.godot-version') -Raw).Trim()
if ($Version -notmatch '^\d+\.\d+\.\d+$') {
    throw 'Invalid .godot-version. Expected a stable version such as 4.7.2.'
}
if ($env:OS -ne 'Windows_NT' -or -not [Environment]::Is64BitOperatingSystem) {
    throw 'This bootstrap is for 64-bit Windows. On other systems, install the pinned Godot version manually.'
}

$Tools = Join-Path $Root '.tools'
$Cache = Join-Path $Tools 'downloads'
New-Item -ItemType Directory -Force -Path $Cache | Out-Null
$Release = Invoke-RestMethod "https://api.github.com/repos/godotengine/godot/releases/tags/$Version-stable"

function Get-VerifiedAsset([string]$Name) {
    $Asset = @($Release.assets | Where-Object { $_.name -eq $Name })
    if ($Asset.Count -ne 1 -or $Asset[0].digest -notmatch '^sha256:[a-f0-9]{64}$') {
        throw "No SHA-256 verified release asset found for $Name."
    }
    $Path = Join-Path $Cache $Name
    if (-not (Test-Path $Path)) {
        Write-Host "Downloading $Name ($([Math]::Round($Asset[0].size / 1MB)) MB)..."
        Invoke-WebRequest -UseBasicParsing -Uri $Asset[0].browser_download_url -OutFile "$Path.partial"
        Move-Item "$Path.partial" $Path -Force
    }
    $ExpectedHash = $Asset[0].digest.Substring(7)
    if ((Get-FileHash $Path -Algorithm SHA256).Hash -ne $ExpectedHash) {
        Remove-Item $Path
        throw "Checksum mismatch for $Name. Download removed; rerun setup."
    }
    return $Path
}

$EditorArchive = Get-VerifiedAsset "Godot_v$Version-stable_win64.exe.zip"
$EditorDirectory = Join-Path $Tools 'godot'
Expand-Archive -Path $EditorArchive -DestinationPath $EditorDirectory -Force
$Executable = Join-Path $EditorDirectory "Godot_v$Version-stable_win64_console.exe"
& $Executable --version
if ($LASTEXITCODE -ne 0) { throw 'Godot could not start.' }

if ($Templates) {
    $TemplateArchive = Get-VerifiedAsset "Godot_v$Version-stable_export_templates.tpz"
    $TemplateDirectory = Join-Path ([Environment]::GetFolderPath('ApplicationData')) "Godot/export_templates/$Version.stable"
    $ExtractDirectory = Join-Path $Tools 'template-extract'
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    if (Test-Path $ExtractDirectory) { Remove-Item $ExtractDirectory -Recurse -Force }
    [System.IO.Compression.ZipFile]::ExtractToDirectory($TemplateArchive, $ExtractDirectory)
    New-Item -ItemType Directory -Path $TemplateDirectory -Force | Out-Null
    Copy-Item (Join-Path $ExtractDirectory 'templates/*') $TemplateDirectory -Recurse -Force
    Remove-Item $ExtractDirectory -Recurse -Force
    Write-Host "Export templates installed at $TemplateDirectory"
}

Write-Host "Godot $Version is ready at $EditorDirectory"