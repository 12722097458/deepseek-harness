#!/usr/bin/env pwsh

<#
  Windows PowerShell launcher for the source-checkout Web UI.

  The Web profile consumes generated Host, Client, and Vite artifacts. The
  launcher builds those artifacts before starting the server unless -SkipBuild
  is supplied, then prints the exact tokenized URL that must be opened in a
  browser.
#>

[CmdletBinding()]
param(
  [Alias('NoBuild')]
  [switch]$SkipBuild,

  [ValidateRange(1, 65535)]
  [int]$Port = 3080,

  [switch]$OpenBrowser
)

$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path -Parent $PSScriptRoot

function Invoke-Pnpm {
  param(
    [Parameter(Mandatory = $true)]
    [string[]]$Arguments
  )

  & pnpm @Arguments
  if ($LASTEXITCODE -ne 0) {
    throw "pnpm $($Arguments -join ' ') 失败，退出码：$LASTEXITCODE"
  }
}

function Stop-PortListeners {
  param(
    [Parameter(Mandatory = $true)]
    [int]$Port
  )

  $connections = @(Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue)
  $processIds = @($connections | Select-Object -ExpandProperty OwningProcess -Unique | Where-Object { $_ -gt 0 })
  foreach ($processId in $processIds) {
    Write-Host "正在终止占用端口 $Port 的进程 PID=$processId。"
    Stop-Process -Id $processId -Force -ErrorAction Stop
  }
}

try {
  Set-Location -LiteralPath $repositoryRoot

  if (-not (Test-Path -LiteralPath (Join-Path $repositoryRoot 'package.json') -PathType Leaf)) {
    throw "找不到仓库根目录 package.json：$repositoryRoot"
  }
  if (-not (Get-Command pnpm -ErrorAction SilentlyContinue)) {
    throw '找不到 pnpm。请先启用 Corepack，并确认 pnpm 已加入 PATH。'
  }

  Write-Host "仓库目录：$repositoryRoot"
  Write-Host "Web 服务地址：127.0.0.1:$Port"

  if ($SkipBuild) {
    $requiredArtifacts = @(
      'apps/cli/lib/bin.js',
      'apps/web/dist/index.html',
      'packages/client/ui-agent-preset/lib/client.js'
    )
    $missingArtifacts = @($requiredArtifacts | Where-Object {
      -not (Test-Path -LiteralPath (Join-Path $repositoryRoot $_) -PathType Leaf)
    })
    if ($missingArtifacts.Count -gt 0) {
      throw "已跳过构建，但缺少构建产物：$($missingArtifacts -join ', ')。请移除 -SkipBuild 后重试。"
    }
    Write-Host '已使用现有构建产物。'
  } else {
    Write-Host '开始构建 Host、Client 和 Web 产物，请等待构建完成。'
    Invoke-Pnpm -Arguments @('run', 'build')
    Write-Host '构建完成。'
  }

  Stop-PortListeners -Port $Port
  Write-Host '正在启动 Web 服务。按 Ctrl+C 可停止服务。'
  Write-Host '启动成功后，请在浏览器打开脚本打印的“前端打开地址”。'

  $webArguments = @('dsh', 'web', '--no-open', '--port', [string]$Port)
  & pnpm @webArguments 2>&1 | ForEach-Object {
    $line = $_.ToString()
    if ($line -match '^dsh web: (https?://\S+)$') {
      $frontendUrl = $Matches[1]
      Write-Host ''
      Write-Host "前端已启动，请在浏览器打开：$frontendUrl" -ForegroundColor Green
      if ($OpenBrowser) {
        Start-Process $frontendUrl
      }
    }
    Write-Host $line
  }

  if ($LASTEXITCODE -ne 0) {
    throw "Web 服务退出，退出码：$LASTEXITCODE"
  }
} catch {
  Write-Error "[start-web] $($_.Exception.Message)"
  exit 1
}
