#requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Ipa,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Pck,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Out
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.IO.Compression | Out-Null
Add-Type -AssemblyName System.IO.Compression.FileSystem | Out-Null

function Fail([string]$Message) {
    Write-Host ""
    Write-Host "[错误] $Message" -ForegroundColor Red
    exit 1
}

function Get-FullPath([string]$Path) {
    if ([System.IO.Path]::IsPathRooted($Path)) {
        return [System.IO.Path]::GetFullPath($Path)
    }
    return [System.IO.Path]::GetFullPath((Join-Path (Get-Location).Path $Path))
}

function Get-PckInfo {
    param(
        [Parameter(Mandatory = $true)]
        [System.IO.Stream]$Stream,
        [Parameter(Mandatory = $true)]
        [string]$Label
    )

    $header = New-Object byte[] 24
    $offset = 0
    while ($offset -lt $header.Length) {
        $read = $Stream.Read($header, $offset, $header.Length - $offset)
        if ($read -le 0) {
            break
        }
        $offset += $read
    }
    if ($offset -lt $header.Length) {
        Fail "$Label 太小，无法读取 Godot PCK 头。"
    }

    $magic = [System.Text.Encoding]::ASCII.GetString($header, 0, 4)
    if ($magic -ne 'GDPC') {
        Fail "$Label 不是有效的 Godot PCK（magic='$magic'，应为 'GDPC'）。"
    }

    $packFormat = [System.BitConverter]::ToUInt32($header, 4)
    $major = [System.BitConverter]::ToUInt32($header, 8)
    $minor = [System.BitConverter]::ToUInt32($header, 12)
    $patch = [System.BitConverter]::ToUInt32($header, 16)

    return [pscustomobject]@{
        Format  = $packFormat
        Version = "$major.$minor.$patch"
    }
}

$ipaPath = Get-FullPath $Ipa
$pckPath = Get-FullPath $Pck
$outPath = Get-FullPath $Out

if (-not (Test-Path -LiteralPath $ipaPath -PathType Leaf)) {
    Fail "底包 IPA 不存在：$ipaPath"
}
if ([System.IO.Path]::GetExtension($ipaPath) -ne '.ipa') {
    Fail "底包扩展名必须是 .ipa：$ipaPath"
}
if (-not (Test-Path -LiteralPath $pckPath -PathType Leaf)) {
    Fail "新 PCK 不存在：$pckPath"
}
if ([System.IO.Path]::GetExtension($pckPath) -ne '.pck') {
    Fail "PCK 扩展名必须是 .pck：$pckPath"
}

$pckLeaf = [System.IO.Path]::GetFileName($pckPath)
if ($pckLeaf -cne 'game.pck') {
    Fail "PCK 文件名必须是 game.pck（当前为 '$pckLeaf'）。iOS 包内的入口固定为 game.pck。"
}

if ([System.IO.Path]::GetExtension($outPath) -ne '.ipa') {
    Fail "输出文件扩展名必须是 .ipa：$outPath"
}
if (Test-Path -LiteralPath $outPath -PathType Container) {
    Fail "输出路径是一个目录，不是文件：$outPath"
}

$outDir = [System.IO.Path]::GetDirectoryName($outPath)
if (-not (Test-Path -LiteralPath $outDir -PathType Container)) {
    New-Item -ItemType Directory -Path $outDir -Force | Out-Null
}

$newPckStream = [System.IO.File]::OpenRead($pckPath)
try {
    $newInfo = Get-PckInfo -Stream $newPckStream -Label "新 PCK ($pckLeaf)"
}
finally {
    $newPckStream.Dispose()
}

$pckEntries = @()
$appName = $null
$oldInfo = $null
$entryName = $null
$entryCount = 0

$sourceZip = [System.IO.Compression.ZipFile]::OpenRead($ipaPath)
try {
    $entryCount = $sourceZip.Entries.Count
    $pckEntries = @(
        $sourceZip.Entries |
            Where-Object { $_.FullName -cmatch '^Payload/[^/]+\.app/game\.pck$' }
    )

    if ($pckEntries.Count -eq 0) {
        Fail "底包内没有找到 Payload/*.app/game.pck。请确认这是 Godot iOS 导出的 IPA。"
    }
    if ($pckEntries.Count -gt 1) {
        $names = ($pckEntries | ForEach-Object { $_.FullName }) -join ', '
        Fail "底包内找到多个 game.pck，无法确定替换目标：$names"
    }

    $entryName = $pckEntries[0].FullName
    $appName = ($entryName -split '/')[1]

    $oldPckStream = $pckEntries[0].Open()
    try {
        $oldInfo = Get-PckInfo -Stream $oldPckStream -Label "底包内 $entryName"
    }
    finally {
        $oldPckStream.Dispose()
    }
}
finally {
    $sourceZip.Dispose()
}

if ($oldInfo.Version -ne $newInfo.Version) {
    Fail "Godot 版本不一致：底包为 $($oldInfo.Version)，新 PCK 为 $($newInfo.Version)。请使用与底包相同的 Godot 4.7.2 导出。"
}
if ($oldInfo.Format -ne $newInfo.Format) {
    Fail "PCK 格式版本不一致：底包为 $($oldInfo.Format)，新 PCK 为 $($newInfo.Format)。"
}
if ($newInfo.Version -ne '4.7.2') {
    Fail "新 PCK 的引擎版本为 $($newInfo.Version)，本项目固定使用 Godot 4.7.2。"
}

Write-Host "底包 App : $appName"
Write-Host "替换条目 : $entryName"
Write-Host "PCK 版本 : $($oldInfo.Version) -> $($newInfo.Version)（格式 v$($newInfo.Format)）"

$tempOut = Join-Path $outDir ('.pack-' + [System.Guid]::NewGuid().ToString('N') + '.ipa')
Copy-Item -LiteralPath $ipaPath -Destination $tempOut -Force

try {
    $updateZip = [System.IO.Compression.ZipFile]::Open(
        $tempOut,
        [System.IO.Compression.ZipArchiveMode]::Update
    )
    try {
        $targets = @($updateZip.Entries | Where-Object { $_.FullName -ceq $entryName })
        if ($targets.Count -ne 1) {
            Fail "更新时无法唯一定位 $entryName。"
        }

        $oldLength = $targets[0].Length
        $targets[0].Delete()

        $newEntry = $updateZip.CreateEntry(
            $entryName,
            [System.IO.Compression.CompressionLevel]::Optimal
        )
        $pckItem = Get-Item -LiteralPath $pckPath
        $newEntry.LastWriteTime = [System.DateTimeOffset]$pckItem.LastWriteTime

        $input = [System.IO.File]::OpenRead($pckPath)
        $output = $newEntry.Open()
        try {
            $input.CopyTo($output)
        }
        finally {
            $output.Dispose()
            $input.Dispose()
        }
    }
    finally {
        $updateZip.Dispose()
    }

    $checkZip = [System.IO.Compression.ZipFile]::OpenRead($tempOut)
    try {
        if ($checkZip.Entries.Count -ne $entryCount) {
            Fail "打包后条目数量变化（$entryCount -> $($checkZip.Entries.Count)），已中止。"
        }

        $verifyEntries = @($checkZip.Entries | Where-Object { $_.FullName -ceq $entryName })
        if ($verifyEntries.Count -ne 1) {
            Fail "打包后找不到 $entryName。"
        }

        $expectedLength = (Get-Item -LiteralPath $pckPath).Length
        if ($verifyEntries[0].Length -ne $expectedLength) {
            Fail "打包后 PCK 大小不正确（$($verifyEntries[0].Length) != $expectedLength）。"
        }
    }
    finally {
        $checkZip.Dispose()
    }

    if (Test-Path -LiteralPath $outPath) {
        [System.IO.File]::Replace($tempOut, $outPath, $null)
    }
    else {
        [System.IO.File]::Move($tempOut, $outPath)
    }
}
finally {
    if (Test-Path -LiteralPath $tempOut) {
        Remove-Item -LiteralPath $tempOut -Force
    }
}

$outSizeMb = (Get-Item -LiteralPath $outPath).Length / 1MB
Write-Host ""
Write-Host "完成：$outPath" -ForegroundColor Green
Write-Host ("体积：{0:N1} MB" -f $outSizeMb)
Write-Host "旧 PCK：$oldLength bytes，新 PCK：$expectedLength bytes"
Write-Host "未修改 Mach-O，未重签名；用 TrollStore 安装。"
