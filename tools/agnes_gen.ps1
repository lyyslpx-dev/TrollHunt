param(
    [Parameter(Mandatory = $true)][string]$Prompt,
    [Parameter(Mandatory = $true)][string]$Out,
    [string]$Size = "1024x1024",
    [string]$Model = "agnes-image-2.5-flash",
    [int]$Retries = 3
)

$keyPath = "C:\Users\Administrator\.codex\secrets\agnes_api_key.txt"
if (-not (Test-Path $keyPath)) { throw "missing api key" }
$key = (Get-Content -LiteralPath $keyPath -Raw).Trim()
$headers = @{ Authorization = "Bearer $key"; 'Content-Type' = 'application/json' }

$body = @{
    model = $Model
    prompt = $Prompt
    size = $Size
    n = 1
} | ConvertTo-Json -Compress

for ($try = 1; $try -le $Retries; $try++) {
    try {
        $response = Invoke-RestMethod -Method Post `
            -Uri "https://apihub.agnes-ai.com/v1/images/generations" `
            -Headers $headers -Body $body -TimeoutSec 180 -UserAgent 'Mozilla/5.0'
        $url = $response.data[0].url
        if (-not $url) { throw "no url in response" }

        & curl.exe -L -sS --ssl-no-revoke -A 'Mozilla/5.0' -o $Out $url
        if (-not (Test-Path $Out)) { throw "download failed" }
        $kb = [math]::Round((Get-Item $Out).Length / 1KB, 0)
        if ($kb -lt 20) { throw "file too small: $kb KB" }
        Write-Output ("OK {0} {1}KB" -f $Out, $kb)
        return
    } catch {
        if ($try -eq $Retries) { throw }
        Start-Sleep -Seconds (4 * $try)
    }
}
