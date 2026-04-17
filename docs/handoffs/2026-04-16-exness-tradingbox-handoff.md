# Exness TradingBox Handoff

## Repository and Branch

- Repository: `https://github.com/switzenhausen-cmd/Exness_Tradingbox.git`
- Active branch: `feature/exness-tradingbox-impl`
- Worktree: `C:\Users\switz\Documents\KI_Projekte\TradingBots\Exness_TradingBox\.worktrees\exness-tradingbox-impl`

## Current EA Build

- EA source: `MQL5/Experts/Exness_TradingBox_v1_011_MT5.mq5`
- Current `#property version`: `1.011`
- Current display name: `Exness_TradingBox_v1_011_MT5`

## Deployment Target

- MT5 Experts path: `C:\Users\switz\AppData\Local\Temp\MT5_BT_Portable_Inst3\MQL5\Experts`
- Deployed files:
  - `Exness_TradingBox_v1_011_MT5.mq5`
  - `Exness_TradingBox_v1_011_MT5.ex5`
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
  - toggle button: `Start Cycle` / `Deactivate EA`
  - `Base Lot`
  - `PI Multiplier`
  - `Hedge Mult`
  - `BE Currency`
  - `ATR Mult`
  - `Trail Mode`
  - `Exit Buffer Pts`
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
  - tightened mode factors:
    - `soft = 1.00`
    - `medium = 0.65`
    - `hard = 0.35`
- Timer-driven UI refresh
- Manual deactivation:
  - clicking `Deactivate EA` closes all managed positions
  - if all closes succeed, the EA clears the frame and stays idle
  - no automatic frame rebuild happens after manual deactivation
- Buffered cycle exits:
  - BE return and cycle trail exits trigger using `Exit Buffer Pts`
  - shorter favorable windows can be captured before the raw line is touched
- Runtime CSV logging:
  - one log file per symbol under `MQL5/Files/Exness_TradingBox/`
  - `cycle_start`, `entry_initial`, `entry_hedge`, `cycle_close_attempt`, `cycle_close_success`, `order_failure`, and `close_failure`
  - each row includes current runtime inputs, frame values, basket profit, net exposure, and equity
- PowerShell deploy script that copies and compiles directly into the MT5 instance

## Current User-Controlled Parameters

- `Base Lot`
- `PI Multiplier`
- `Hedge Mult`
- `BE Currency`
- `ATR Mult`
- `Trail Mode`
- `Exit Buffer Pts`

## Known Gaps / Follow-Up Items

- No manual chart field yet for a separate SL distance in points
- No manual runtime validation on a live/open MT5 chart was performed in this session
- Runtime CSV logging is in place, but no external analysis script over the generated CSVs exists yet
- Trailing and buffered exits are basket/net-exposure based and should be behavior-tested on real symbols

## Suggested Next Steps

1. Manual chart test in MT5:
   - attach EA
   - click `Start Cycle`
   - verify frame placement
   - verify first breakout trade
   - verify opposite breakout hedge
   - verify BE activation and cycle close
   - verify ATR trailing behavior
   - verify CSV output in `MQL5/Files/Exness_TradingBox/`
2. Build an external analysis script over the generated CSVs to compare settings per symbol
3. Add any missing runtime controls the user still wants on-chart

## Recent Commits

- `5614803` `feat: add runtime logging scaffold`
- `3043a28` `feat: tighten trailing mode factors`
- `3b03abe` `feat: add buffered cycle exit triggers`
- `62cb75b` `feat: add exit buffer runtime input`

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
