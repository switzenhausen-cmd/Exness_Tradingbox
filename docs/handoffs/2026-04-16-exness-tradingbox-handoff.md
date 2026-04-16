# Exness TradingBox Handoff

## Repository and Branch

- Repository: `https://github.com/switzenhausen-cmd/Exness_Tradingbox.git`
- Active branch: `feature/exness-tradingbox-impl`
- Worktree: `C:\Users\switz\Documents\KI_Projekte\TradingBots\Exness_TradingBox\.worktrees\exness-tradingbox-impl`

## Current EA Build

- EA source: `MQL5/Experts/Exness_TradingBox_v1_001_MT5.mq5`
- Current `#property version`: `1.008`
- Current display name: `Exness_TradingBox_v1_008_MT5`

## Deployment Target

- MT5 Experts path: `C:\Users\switz\AppData\Local\Temp\MT5_BT_Portable_Inst3\MQL5\Experts`
- Deployed files:
  - `Exness_TradingBox_v1_001_MT5.mq5`
  - `Exness_TradingBox_v1_001_MT5.ex5`
  - include folder `Exness_TradingBox\`

## Verified Status

Latest verified command:

```powershell
& '.\scripts\build-and-deploy.ps1' -Compile
```

Latest result:

```text
Result: 0 errors, 0 warnings
```

Relevant log:

- `build/compile-final.log`

## Implemented Features

- Chart UI with:
  - `Start Cycle`
  - `Base Lot`
  - `PI Multiplier`
  - `Hedge Mult`
  - `BE Currency`
  - `ATR Mult`
  - `Trail Mode`
- Info panel with:
  - EA name
  - net exposure
  - regime
  - vola index
  - current leverage
  - spread
  - frame height
- Frame build:
  - centered on current price
  - frame height = rounded `spread * pi * PI multiplier`
- Breakout logic:
  - upper break opens long
  - lower break opens short
  - duplicate same-side retriggers blocked
- Hedge progression:
  - previous positions stay open
  - next lot = previous lot * hedge multiplier
- Basket logic:
  - BE activation by basket profit in account currency
  - dynamic basket return price
  - cycle closes on return to basket BE line
- Trailing:
  - ATR-based
  - `soft`, `medium`, `hard`
  - basket-level trailing based on net exposure direction
- Timer-driven UI refresh
- PowerShell deploy script that copies and compiles directly into the MT5 instance

## Current User-Controlled Parameters

- `Base Lot`
- `PI Multiplier`
- `Hedge Mult`
- `BE Currency`
- `ATR Mult`
- `Trail Mode`

## Known Gaps / Follow-Up Items

- No manual chart field yet for a separate SL distance in points
- No manual runtime validation on a live/open MT5 chart was performed in this session
- Trailing is basket/net-exposure based and should be behavior-tested on real symbols
- The file name is still `Exness_TradingBox_v1_001_MT5.mq5`, while the display/version property is `1.008`

## Suggested Next Steps

1. Manual chart test in MT5:
   - attach EA
   - click `Start Cycle`
   - verify frame placement
   - verify first breakout trade
   - verify opposite breakout hedge
   - verify BE activation and cycle close
   - verify ATR trailing behavior
2. Decide whether the source filename should also be version-bumped to match display versioning
3. Add any missing runtime controls the user still wants on-chart

## Recent Commits

- `61a4f0c` `feat: add analytics, trailing, and deploy automation`
- `85102cc` `feat: add frame logic, breakout trading, and basket be`
- `69ef0e4` `feat: add state model and chart UI skeleton`
- `497b978` `chore: scaffold Exness TradingBox MT5 project`

## Resume Commands

Open worktree:

```powershell
Set-Location 'C:\Users\switz\Documents\KI_Projekte\TradingBots\Exness_TradingBox\.worktrees\exness-tradingbox-impl'
```

Verify branch:

```powershell
git branch --show-current
```

Build and deploy:

```powershell
& '.\scripts\build-and-deploy.ps1' -Compile
```
