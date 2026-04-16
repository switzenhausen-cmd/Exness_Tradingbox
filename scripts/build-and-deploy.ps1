param(
    [switch]$Compile
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
$targetRoot = "C:\Users\switz\AppData\Local\Temp\MT5_BT_Portable_Inst3\MQL5\Experts"
$targetIncludeRoot = Join-Path $targetRoot "Exness_TradingBox"
$targetEaFile = Join-Path $targetRoot "Exness_TradingBox_v1_010_MT5.mq5"
$buildDir = Join-Path $projectRoot "build"
$compileLog = Join-Path $buildDir "compile-final.log"
$metaEditor = "C:\Users\switz\AppData\Local\Temp\MT5_BT_Portable_Inst3\MetaEditor64.exe"

$required = @(
    (Join-Path $projectRoot "MQL5/Experts/Exness_TradingBox_v1_010_MT5.mq5"),
    (Join-Path $projectRoot "MQL5/Experts/Exness_TradingBox/TB_Config.mqh"),
    (Join-Path $projectRoot "MQL5/Experts/Exness_TradingBox/TB_State.mqh"),
    (Join-Path $projectRoot "MQL5/Experts/Exness_TradingBox/TB_UI.mqh"),
    (Join-Path $projectRoot "MQL5/Experts/Exness_TradingBox/TB_Frame.mqh"),
    (Join-Path $projectRoot "MQL5/Experts/Exness_TradingBox/TB_Trade.mqh"),
    (Join-Path $projectRoot "MQL5/Experts/Exness_TradingBox/TB_Basket.mqh"),
    (Join-Path $projectRoot "MQL5/Experts/Exness_TradingBox/TB_Analytics.mqh")
)

$missing = $required | Where-Object { -not (Test-Path $_) }
if($missing.Count -gt 0)
{
    throw "Missing source files: $($missing -join ', ')"
}

New-Item -ItemType Directory -Force -Path $buildDir | Out-Null
New-Item -ItemType Directory -Force -Path $targetIncludeRoot | Out-Null

Copy-Item (Join-Path $projectRoot "MQL5/Experts/Exness_TradingBox_v1_010_MT5.mq5") $targetEaFile -Force
Copy-Item (Join-Path $projectRoot "MQL5/Experts/Exness_TradingBox/*") $targetIncludeRoot -Recurse -Force

$deployed = @(
    $targetEaFile,
    (Join-Path $targetIncludeRoot "TB_Config.mqh"),
    (Join-Path $targetIncludeRoot "TB_State.mqh"),
    (Join-Path $targetIncludeRoot "TB_UI.mqh"),
    (Join-Path $targetIncludeRoot "TB_Frame.mqh"),
    (Join-Path $targetIncludeRoot "TB_Trade.mqh"),
    (Join-Path $targetIncludeRoot "TB_Basket.mqh"),
    (Join-Path $targetIncludeRoot "TB_Analytics.mqh")
)

$missingDeployed = $deployed | Where-Object { -not (Test-Path $_) }
if($missingDeployed.Count -gt 0)
{
    throw "Deployment incomplete: $($missingDeployed -join ', ')"
}

Write-Host "Source contract satisfied."
Write-Host "Deployed EA sources to $targetRoot"

if($Compile)
{
    & $metaEditor /compile:$targetEaFile /log:$compileLog
    Start-Sleep -Milliseconds 500
    if(-not (Test-Path $compileLog))
    {
        throw "Compile log missing: $compileLog"
    }
    Write-Host "Compiled deployed EA. Log: $compileLog"
}
