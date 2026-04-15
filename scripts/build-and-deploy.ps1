param(
    [switch]$Compile
)

$ErrorActionPreference = "Stop"

$required = @(
    "MQL5/Experts/Exness_TradingBox_v1_001_MT5.mq5",
    "MQL5/Experts/Exness_TradingBox/TB_Config.mqh",
    "MQL5/Experts/Exness_TradingBox/TB_State.mqh",
    "MQL5/Experts/Exness_TradingBox/TB_UI.mqh",
    "MQL5/Experts/Exness_TradingBox/TB_Frame.mqh",
    "MQL5/Experts/Exness_TradingBox/TB_Trade.mqh",
    "MQL5/Experts/Exness_TradingBox/TB_Basket.mqh",
    "MQL5/Experts/Exness_TradingBox/TB_Analytics.mqh"
)

$missing = $required | Where-Object { -not (Test-Path $_) }
if($missing.Count -gt 0)
{
    throw "Missing source files: $($missing -join ', ')"
}

Write-Host "Source contract satisfied."
