param(
    [Parameter(Position = 0)]
    [string]$Message
)

$ErrorActionPreference = "Stop"
Set-Location -LiteralPath $PSScriptRoot

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw "Git tidak ditemukan di PATH."
}

$branch = git rev-parse --abbrev-ref HEAD
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($branch)) {
    throw "Folder ini bukan repository Git."
}

if ([string]::IsNullOrWhiteSpace($Message)) {
    $Message = "update: " + (Get-Date -Format "yyyy-MM-dd HH:mm")
}

git add -A
if ($LASTEXITCODE -ne 0) {
    throw "git add gagal."
}

git diff --cached --quiet
if ($LASTEXITCODE -ne 0) {
    git commit -m $Message
    if ($LASTEXITCODE -ne 0) {
        throw "git commit gagal."
    }
    Write-Host "Commit dibuat: $Message"
}
else {
    Write-Host "Tidak ada perubahan untuk di-commit."
}

git push -u origin $branch
if ($LASTEXITCODE -ne 0) {
    throw "git push gagal."
}

Write-Host "Berhasil push ke origin/$branch."
