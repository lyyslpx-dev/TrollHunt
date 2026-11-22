param(
    [Parameter(Mandatory = $true)][string]$Image,
    [Parameter(Mandatory = $true)][string]$Prompt,
    [Parameter(Mandatory = $true)][string]$Out,
    [int]$Seed = 0,
    [double]$Guidance = 2.5,
    [int]$Steps = 28,
    [string]$Space = "black-forest-labs-flux-1-kontext-dev"
)

$base = "https://$Space.hf.space"
$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession

$form = @{ files = Get-Item $Image }
$upload = Invoke-RestMethod -Method Post -Uri "$base/gradio_api/upload" `
    -Form $form -WebSession $session -TimeoutSec 120 -UserAgent 'Mozilla/5.0'
$file = if ($upload -is [array]) { $upload[0] } else { $upload }
if (-not $file) { throw "upload failed" }

$data = @(
    @{ path = $file; meta = @{ _type = 'gradio.FileData' } },
    $Prompt, $Seed, $true, $Guidance, $Steps
)
$body = @{ data = $data } | ConvertTo-Json -Depth 8 -Compress

$post = Invoke-RestMethod -Method Post -Uri "$base/gradio_api/call/infer" `
    -ContentType 'application/json' -Body $body -WebSession $session `
    -TimeoutSec 120 -UserAgent 'Mozilla/5.0'
if (-not $post.event_id) { throw "no event id" }

$url = $null
for ($i = 0; $i -lt 120; $i++) {
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
