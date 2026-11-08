param(
    [ValidateSet('Editor', 'Run', 'Test', 'Export')]
    [string]$Action = 'Editor',
    [ValidateSet('Windows', 'Web', 'Android', 'iOS')]
    [string]$Target = 'Web',
    [switch]$Release
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path $PSScriptRoot -Parent
$Version = (Get-Content (Join-Path $Root '.godot-version') -Raw).Trim()
$Executable = $env:GODOT_BIN
if (-not $Executable) {
    $Executable = Join-Path $Root ".tools/godot/Godot_v$Version-stable_win64_console.exe"
}
if (-not (Test-Path $Executable -PathType Leaf)) {
    throw 'Godot not found. Run tools/setup.ps1 on Windows, or set GODOT_BIN to your Godot executable.'
}
$InstalledVersion = & $Executable --version
if ($LASTEXITCODE -ne 0 -or $InstalledVersion -notlike "$Version.stable.*") {
    throw "Expected Godot $Version stable. Run tools/setup.ps1 or update GODOT_BIN."
}

function Invoke-Godot([string[]]$GodotArguments) {
    $Output = & $Executable --path $Root @GodotArguments 2>&1
    $ExitCode = $LASTEXITCODE
    $Output | ForEach-Object { Write-Host $_ }
    if ($ExitCode -ne 0 -or ($Output -match '^(SCRIPT ERROR:|ERROR:)')) {
        throw "Godot failed: $($GodotArguments -join ' ') (exit $ExitCode)."
    }
}

switch ($Action) {
    'Editor' {
        Start-Process -FilePath $Executable -ArgumentList @('--path', "`"$Root`"", '--editor')
    }
    'Run' {
        Invoke-Godot @('--headless', '--editor', '--import')
        Start-Process -FilePath $Executable -ArgumentList @('--path', "`"$Root`"")
    }
    'Test' {
        Invoke-Godot @('--headless', '--editor', '--import')
        Invoke-Godot @('--headless', '--script', 'res://tests/smoke.gd')
    }
    'Export' {
        if ($Target -eq 'iOS' -and [Environment]::OSVersion.Platform -eq 'Win32NT') {
            throw 'Native iOS export requires macOS and Xcode. Use the Web export on iPhone until a Mac is available.'
        }
        $Outputs = @{
            Windows = 'build/windows/TinyRitual.exe'
            Web = 'build/web/index.html'
            Android = 'build/android/TinyRitual.apk'
            iOS = 'build/ios/TinyRitual.zip'
        }
        $OutputPath = Join-Path $Root $Outputs[$Target]
        New-Item -ItemType Directory -Force -Path (Split-Path $OutputPath -Parent) | Out-Null
        New-Item -ItemType File -Force -Path (Join-Path $Root 'build/.gdignore') | Out-Null
        Invoke-Godot @('--headless', '--editor', '--import')
        $Mode = '--export-release'
        if ($Target -in @('Android', 'iOS') -and -not $Release) { $Mode = '--export-debug' }
        Invoke-Godot @('--headless', $Mode, $Target, $OutputPath)
        Write-Host "Exported $Target to $OutputPath"
    }
}