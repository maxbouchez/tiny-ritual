param([ValidateRange(1024, 65535)][int]$Port = 8060)

$ErrorActionPreference = 'Stop'
$Root = Join-Path (Split-Path $PSScriptRoot -Parent) 'build/web'
if (-not (Test-Path (Join-Path $Root 'index.html'))) {
    throw 'Export the web build first: ./tools/godot.ps1 -Action Export -Target Web'
}
$MimeTypes = @{
    '.html' = 'text/html; charset=utf-8'
    '.js' = 'application/javascript'
    '.wasm' = 'application/wasm'
    '.pck' = 'application/octet-stream'
    '.png' = 'image/png'
    '.svg' = 'image/svg+xml'
    '.ico' = 'image/x-icon'
    '.json' = 'application/json'
    '.webmanifest' = 'application/manifest+json'
    '.css' = 'text/css'
}
$Listener = New-Object System.Net.HttpListener
$Listener.Prefixes.Add("http://localhost:$Port/")
try {
    $Listener.Start()
    Write-Host "Preview ready at http://localhost:$Port/ (Ctrl+C to stop)"
    while ($Listener.IsListening) {
        $Context = $Listener.GetContext()
        $Response = $Context.Response
        try {
            if ($Context.Request.HttpMethod -notin @('GET', 'HEAD')) {
                $Response.StatusCode = 405
                $Response.Headers['Allow'] = 'GET, HEAD'
                continue
            }
            $Name = [Uri]::UnescapeDataString($Context.Request.Url.AbsolutePath).TrimStart('/')
            if (-not $Name) { $Name = 'index.html' }
            if ($Name -notmatch '^[a-zA-Z0-9][a-zA-Z0-9_.-]*$') {
                $Response.StatusCode = 404
                continue
            }
            $Path = Join-Path $Root $Name
            if (-not (Test-Path $Path -PathType Leaf)) {
                $Response.StatusCode = 404
                continue
            }
            $ContentType = $MimeTypes[[IO.Path]::GetExtension($Path)]
            if (-not $ContentType) { $ContentType = 'application/octet-stream' }
            $Response.ContentType = $ContentType
            $Response.Headers['Cache-Control'] = 'no-store'
            $Response.Headers['X-Content-Type-Options'] = 'nosniff'
            $Content = [IO.File]::ReadAllBytes($Path)
            $Response.ContentLength64 = $Content.Length
            if ($Context.Request.HttpMethod -eq 'GET') {
                $Response.OutputStream.Write($Content, 0, $Content.Length)
            }
        }
        catch {
            Write-Warning $_.Exception.Message
        }
        finally {
            $Response.Close()
        }
    }
}
finally {
    $Listener.Close()
}