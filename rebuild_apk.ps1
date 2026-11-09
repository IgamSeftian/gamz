$ErrorActionPreference = "Stop"

Set-Location -LiteralPath $PSScriptRoot

$apkSource = Join-Path $PSScriptRoot "build\app\outputs\flutter-apk\app-release.apk"
$apkTarget = "D:\DapoerIboe.apk"

flutter build apk --release
Copy-Item -LiteralPath $apkSource -Destination $apkTarget -Force

$apk = Get-Item -LiteralPath $apkTarget
Write-Host "APK berhasil dibuat: $($apk.FullName) ($([math]::Round($apk.Length / 1MB, 1)) MB)"
