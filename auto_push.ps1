param(
  [string]$RepoPath = $PSScriptRoot,
  [int]$DebounceSeconds = 10,
  [string]$Remote = "origin",
  [string]$Branch = "main"
)

$ErrorActionPreference = "Stop"

function Write-Log([string]$Message) {
  $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
  Write-Host "[$ts] $Message"
}

Set-Location $RepoPath

Write-Log "RepoPath: $RepoPath"
Write-Log "자동 커밋/푸시 감시 시작 (디바운스 ${DebounceSeconds}s). 종료: Ctrl+C"

# 이벤트 폭주 방지를 위한 상태
$script:Dirty = $false
$script:LastEventAt = Get-Date

function Mark-Dirty([object]$e) {
  $p = $e.SourceEventArgs.FullPath
  if ($null -ne $p -and $p -like "*\.git\*") { return }
  $script:Dirty = $true
  $script:LastEventAt = Get-Date
}

$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $RepoPath
$watcher.Filter = "*"
$watcher.IncludeSubdirectories = $true
$watcher.NotifyFilter = [System.IO.NotifyFilters]"FileName, LastWrite, DirectoryName, Size"
$watcher.EnableRaisingEvents = $true

$subs = @()
$subs += Register-ObjectEvent -InputObject $watcher -EventName Changed -Action { Mark-Dirty $event }
$subs += Register-ObjectEvent -InputObject $watcher -EventName Created -Action { Mark-Dirty $event }
$subs += Register-ObjectEvent -InputObject $watcher -EventName Deleted -Action { Mark-Dirty $event }
$subs += Register-ObjectEvent -InputObject $watcher -EventName Renamed -Action { Mark-Dirty $event }

try {
  while ($true) {
    Start-Sleep -Seconds 2

    if (-not $script:Dirty) { continue }

    $since = (New-TimeSpan -Start $script:LastEventAt -End (Get-Date)).TotalSeconds
    if ($since -lt $DebounceSeconds) { continue }

    $script:Dirty = $false

    $status = & git status --porcelain
    if (-not $status) {
      Write-Log "변경 없음"
      continue
    }

    Write-Log "변경 감지 → add/commit/push 진행"

    & git add -A

    # 스테이징이 실제로 있는지 확인
    & git diff --cached --quiet
    if ($LASTEXITCODE -eq 0) {
      Write-Log "스테이징 변경 없음(스킵)"
      continue
    }

    $msg = "auto: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    & git commit -m $msg

    try {
      & git push $Remote $Branch
      Write-Log "푸시 완료"
    } catch {
      Write-Log "푸시 실패: $($_.Exception.Message)"
      throw
    }
  }
}
finally {
  foreach ($s in $subs) { Unregister-Event -SubscriptionId $s.Id -ErrorAction SilentlyContinue }
  $watcher.EnableRaisingEvents = $false
  $watcher.Dispose()
}

