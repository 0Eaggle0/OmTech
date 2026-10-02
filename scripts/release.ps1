# Выпуск новой версии OmTech: поднять версию -> analyze + test -> commit + tag
# -> push -> дождаться GitHub Actions -> сообщить результат.
# Запуск: release.bat [patch|minor|major] [-DryRun]
param(
    [ValidateSet('patch', 'minor', 'major')][string]$Bump = 'patch',
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot)
$repo = '0Eaggle0/OmTech'
$utf8 = New-Object Text.UTF8Encoding($false)  # без BOM

function Step($m) { Write-Host "`n==> $m" -ForegroundColor Cyan }
function Fail($m) {
    Write-Host "`n[X] $m" -ForegroundColor Red
    [console]::Beep(400, 600)
    exit 1
}
function Run($what) {
    & $what[0] $what[1..($what.Length - 1)]
    if ($LASTEXITCODE -ne 0) { Fail "Команда упала: $($what -join ' ')" }
}
function Notify($title, $text) {
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show($text, $title) | Out-Null
}

# --- Проверки репозитория ---
if ((git rev-parse --abbrev-ref HEAD) -ne 'master') { Fail 'Нужно быть на ветке master.' }
git fetch -q origin
if (git log --oneline HEAD..origin/master) { Fail 'На GitHub есть коммиты, которых нет локально. Разберись с ними сначала.' }

# --- Новая версия ---
$pubPath = "$PWD\pubspec.yaml"
$verPath = "$PWD\lib\app_version.dart"
$pub = [IO.File]::ReadAllText($pubPath)
if ($pub -notmatch '(?m)^version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)') { Fail 'Не нашёл version: в pubspec.yaml' }
$maj, $min, $pat, $build = [int]$Matches[1], [int]$Matches[2], [int]$Matches[3], [int]$Matches[4]
switch ($Bump) {
    'major' { $maj++; $min = 0; $pat = 0 }
    'minor' { $min++; $pat = 0 }
    'patch' { $pat++ }
}
$build++
$ver = "$maj.$min.$pat"
$tag = "v$ver"

$dirty = git status --porcelain
Write-Host "Текущая: $($Matches[1]).$($Matches[2]).$($Matches[3])+$($Matches[4])  ->  новая: $ver+$build" -ForegroundColor Yellow
if ($dirty) {
    Write-Host "`nНезакоммиченные изменения войдут в релиз:" -ForegroundColor Yellow
    $dirty | ForEach-Object { Write-Host "  $_" }
}
if ($DryRun) { Write-Host "`n(DryRun: ничего не меняю)"; exit 0 }

$msg = Read-Host "`nЧто нового (Enter = 'Release $tag')"
if (-not $msg) { $msg = "Release $tag" }
if ((Read-Host "Выпустить $tag? (y/n)") -ne 'y') { Fail 'Отменено.' }

# --- Версия в файлах ---
Step "Версия $ver+$build"
$pub = $pub -replace '(?m)^version:\s*\S+', "version: $ver+$build"
[IO.File]::WriteAllText($pubPath, $pub, $utf8)
$dart = [IO.File]::ReadAllText($verPath)
$dart = $dart -replace "kAppVersion = '[^']*'", "kAppVersion = '$ver'" `
              -replace 'kAppBuild = \d+', "kAppBuild = $build"
[IO.File]::WriteAllText($verPath, $dart, $utf8)

# --- Проверки кода ---
Step 'flutter analyze'
Run @('flutter', 'analyze')
Step 'flutter test'
Run @('flutter', 'test')

# --- Коммит, тег, пуш ---
Step "Коммит и тег $tag"
Run @('git', 'add', '-A')
Run @('git', 'commit', '-q', '-m', $msg)
Run @('git', 'tag', $tag)
Step 'Push на GitHub'
Run @('git', 'push', '-q', 'origin', 'master')
Run @('git', 'push', '-q', 'origin', $tag)

# --- Ждём GitHub Actions ---
Step 'Жду сборку на GitHub Actions (обычно ~10 минут)'
$headers = @{ 'User-Agent' = 'omtech-release' }
if ($env:GH_TOKEN) { $headers.Authorization = "Bearer $env:GH_TOKEN" }  # без токена лимит 60 запросов/час
$api = "https://api.github.com/repos/$repo/actions/runs?branch=$tag&per_page=1"
$deadline = (Get-Date).AddMinutes(30)
$run = $null
while ((Get-Date) -lt $deadline) {
    Start-Sleep -Seconds 30
    try { $run = (Invoke-RestMethod $api -Headers $headers).workflow_runs | Select-Object -First 1 }
    catch { Write-Host "  (GitHub не ответил: $($_.Exception.Message))"; continue }
    if (-not $run) { Write-Host '  ждём запуска...'; continue }
    Write-Host ("  {0:HH:mm:ss}  {1}" -f (Get-Date), $run.status)
    if ($run.status -eq 'completed') { break }
}

$releaseUrl = "https://github.com/$repo/releases/tag/$tag"
if ($run -and $run.conclusion -eq 'success') {
    Write-Host "`n[OK] $tag опубликован: $releaseUrl" -ForegroundColor Green
    [console]::Beep(880, 200); [console]::Beep(1320, 300)
    Notify 'OmTech' "Релиз $tag готов.`nПриложения предложат обновиться при следующем запуске."
    Start-Process $releaseUrl
} elseif ($run -and $run.status -eq 'completed') {
    Start-Process $run.html_url
    Notify 'OmTech' "Сборка $tag упала ($($run.conclusion)). Открываю лог."
    Fail "Сборка упала: $($run.html_url)"
} else {
    Start-Process "https://github.com/$repo/actions"
    Fail 'Не дождался конца сборки за 30 минут — проверь Actions вручную.'
}
