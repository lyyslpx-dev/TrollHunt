param(
    [Parameter(Mandatory = $true)][string]$Prompt,
    [Parameter(Mandatory = $true)][string]$Out,
    [int]$Width = 1024,
    [int]$Height = 576,
    [int]$Seed = 0,
    [int]$Steps = 4,
    [double]$Guidance = 3.5,
    [switch]$WithGuidance,
    [string]$Space = "black-forest-labs-flux-1-schnell"
)

$base = "https://$Space.hf.space"
if ($WithGuidance) {
    $body = @{ data = @($Prompt, $Seed, $true, $Width, $Height, $Guidance, $Steps) } | ConvertTo-Json -Compress
} else {
    $body = @{ data = @($Prompt, $Seed, $true, $Width, $Height, $Steps) } | ConvertTo-Json -Compress
}
$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession

$post = Invoke-RestMethod -Method Post -Uri "$base/gradio_api/call/infer" `
    -ContentType 'application/json' -Body $body -WebSession $session `
    -TimeoutSec 90 -UserAgent 'Mozilla/5.0'
if (-not $post.event_id) { throw "no event id" }

$url = $null
for ($i = 0; $i -lt 80; $i++) {
    Start-Sleep -Seconds 2
    $get = Invoke-WebRequest -Uri ("$base/gradio_api/call/infer/" + $post.event_id) `
        -WebSession $session -TimeoutSec 300 -UserAgent 'Mozilla/5.0'
    if ($get.Content -match 'event: error') { throw "space error: $($get.Content)" }
    if ($get.Content -match '"url":\s*"([^"]+)"') {
        $url = $Matches[1]
        break
    }
}
if (-not $url) { throw "timeout waiting for image" }

& curl.exe -L --path-as-is -sS -A 'Mozilla/5.0' -o $Out $url
if (-not (Test-Path $Out)) { throw "download failed" }
Write-Output ("OK {0} {1}KB" -f $Out, [math]::Round((Get-Item $Out).Length / 1KB, 0))
