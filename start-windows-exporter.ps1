# Запуск windows_exporter на :9182 (если служба не установлена).
# Запуск от администратора: msiexec /i windows_exporter-0.31.6-amd64.msi /qn — тогда этот скрипт не нужен.

$ErrorActionPreference = "Stop"
$dir = Split-Path -Parent $MyInvocation.MyCommand.Path
$exe = Join-Path $dir "windows_exporter.exe"
if (-not (Test-Path $exe)) {
    Write-Error "Нет файла $exe — скачай с https://github.com/prometheus-community/windows_exporter/releases"
}
$existing = Get-NetTCPConnection -LocalPort 9182 -ErrorAction SilentlyContinue
if ($existing) {
    Write-Host "Порт 9182 уже занят — exporter, скорее всего, уже запущен."
    exit 0
}
Start-Process -FilePath $exe -ArgumentList "--web.listen-address=:9182" -WindowStyle Hidden
Write-Host "windows_exporter запущен на http://127.0.0.1:9182/metrics"
