# Exness TradingBox Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a new MT5 Expert Advisor with chart-based controls, fixed per-cycle PI frame breakout entries, unlimited hedge progression, basket break-even protection, ATR-based cycle trailing, versioned deployment, and git-backed change tracking.

**Architecture:** Mirror the MT5 directory structure inside the repository, keep the EA entry file versioned and thin, move the business logic into focused `.mqh` modules, and use a PowerShell build/deploy script to copy the current source set into the portable MT5 instance before compilation. Because MQL5 has weak native unit-test support, use compile-first contracts plus lightweight pure-function self-check helpers where possible, then finish each task with a clean compile and a targeted manual chart verification.

**Tech Stack:** MQL5, MT5 standard library `Trade\Trade.mqh`, `CTrade`, PowerShell, Git

---

### Task 1: Scaffold repository, build script, and MT5 source tree

**Files:**
- Create: `.gitignore`
- Create: `MQL5/Experts/Exness_TradingBox_v1_001_MT5.mq5`
- Create: `MQL5/Experts/Exness_TradingBox/TB_Config.mqh`
- Create: `MQL5/Experts/Exness_TradingBox/TB_State.mqh`
- Create: `MQL5/Experts/Exness_TradingBox/TB_UI.mqh`
- Create: `MQL5/Experts/Exness_TradingBox/TB_Frame.mqh`
- Create: `MQL5/Experts/Exness_TradingBox/TB_Trade.mqh`
- Create: `MQL5/Experts/Exness_TradingBox/TB_Basket.mqh`
- Create: `MQL5/Experts/Exness_TradingBox/TB_Analytics.mqh`
- Create: `scripts/build-and-deploy.ps1`
- Modify: `docs/chatlogs/2026-04-16-session.md`

**Step 1: Write the failing scaffold contract**

Create `scripts/build-and-deploy.ps1` with a contract check that expects the main EA file and all listed module files to exist before copying to MT5:

```powershell
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
if($missing.Count -gt 0) {
  throw "Missing source files: $($missing -join ', ')"
}
```

**Step 2: Run the scaffold contract to verify it fails**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build-and-deploy.ps1
```

Expected: FAIL with `Missing source files: ...`

**Step 3: Create the minimal source tree**

Add:

```mql5
#property strict
#property version   "1.001"
#include <Trade/Trade.mqh>
#include "Exness_TradingBox/TB_Config.mqh"
#include "Exness_TradingBox/TB_State.mqh"
#include "Exness_TradingBox/TB_UI.mqh"
#include "Exness_TradingBox/TB_Frame.mqh"
#include "Exness_TradingBox/TB_Trade.mqh"
#include "Exness_TradingBox/TB_Basket.mqh"
#include "Exness_TradingBox/TB_Analytics.mqh"

int OnInit() { return(INIT_SUCCEEDED); }
void OnDeinit(const int reason) {}
void OnTick() {}
```

and placeholder include guards like:

```mql5
#ifndef __TB_CONFIG_MQH__
#define __TB_CONFIG_MQH__
// placeholder
#endif
```

Set `.gitignore` to ignore `build/`, `*.ex5`, `*.log`, `.vs/`, and temporary editor artifacts.

**Step 4: Run the scaffold contract again**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build-and-deploy.ps1
```

Expected: PASS of existence checks, then controlled no-op or copy step

**Step 5: Commit**

```bash
git add .gitignore MQL5 scripts/build-and-deploy.ps1 docs/chatlogs/2026-04-16-session.md
git commit -m "chore: scaffold Exness TradingBox MT5 project"
```

### Task 2: Add version/config constants and cycle state model

**Files:**
- Modify: `MQL5/Experts/Exness_TradingBox_v1_001_MT5.mq5`
- Modify: `MQL5/Experts/Exness_TradingBox/TB_Config.mqh`
- Modify: `MQL5/Experts/Exness_TradingBox/TB_State.mqh`
- Create: `MQL5/Scripts/Exness_TradingBox_StateSelfTest.mq5`
- Modify: `docs/chatlogs/2026-04-16-session.md`

**Step 1: Write the failing state contract**

In `Exness_TradingBox_StateSelfTest.mq5`, reference state helpers that do not yet exist:

```mql5
#include "..\\Experts\\Exness_TradingBox\\TB_Config.mqh"
#include "..\\Experts\\Exness_TradingBox\\TB_State.mqh"

void OnStart()
  {
   TBCycleState state;
   TB_ResetCycleState(state);
   Print(TB_BuildEaDisplayName());
   Print(state.is_active);
  }
```

**Step 2: Compile the self-test to verify it fails**

Run:

```powershell
& 'C:\Users\switz\AppData\Local\Temp\MT5_BT_Portable_Inst3\MetaEditor64.exe' /compile:'C:\Users\switz\Documents\KI_Projekte\TradingBots\Exness_TradingBox\MQL5\Scripts\Exness_TradingBox_StateSelfTest.mq5' /log:'C:\Users\switz\Documents\KI_Projekte\TradingBots\Exness_TradingBox\build\state-selftest.log'
```

Expected: FAIL with missing identifiers like `TBCycleState`

**Step 3: Implement minimal config and state**

Add:

```mql5
#define TB_EA_NAME_BASE "Exness_TradingBox"
#define TB_EA_VERSION_MAJOR 1
#define TB_EA_VERSION_MINOR 1

enum TBCycleRegime
  {
   TB_REGIME_RANGE=0,
   TB_REGIME_BULL=1,
   TB_REGIME_BEAR=2
  };

struct TBCycleState
  {
   bool     is_armed;
   bool     is_active;
   bool     be_armed;
   int      leg_count;
   int      last_break_direction;
   double   frame_mid_price;
   double   frame_upper_price;
   double   frame_lower_price;
   double   frame_height_points;
   double   last_leg_lots;
  };

void TB_ResetCycleState(TBCycleState &state)
  {
   ZeroMemory(state);
   state.last_break_direction=0;
  }
```

and:

```mql5
string TB_BuildEaDisplayName()
  {
   return StringFormat("%s_v%d_%03d_MT5",TB_EA_NAME_BASE,TB_EA_VERSION_MAJOR,TB_EA_VERSION_MINOR);
  }
```

**Step 4: Recompile the self-test**

Run the same `MetaEditor64.exe /compile` command.

Expected: PASS

**Step 5: Commit**

```bash
git add MQL5 docs/chatlogs/2026-04-16-session.md
git commit -m "feat: add version metadata and cycle state model"
```

### Task 3: Build chart UI controls and the non-overlapping info panel

**Files:**
- Modify: `MQL5/Experts/Exness_TradingBox_v1_001_MT5.mq5`
- Modify: `MQL5/Experts/Exness_TradingBox/TB_Config.mqh`
- Modify: `MQL5/Experts/Exness_TradingBox/TB_UI.mqh`
- Modify: `MQL5/Experts/Exness_TradingBox/TB_State.mqh`
- Modify: `docs/chatlogs/2026-04-16-session.md`

**Step 1: Write the failing UI compile contract**

Call missing UI functions from the main EA:

```mql5
int OnInit()
  {
   TB_CreateChartUi();
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   TB_DestroyChartUi();
  }
```

**Step 2: Compile the main EA to verify it fails**

Run:

```powershell
& 'C:\Users\switz\AppData\Local\Temp\MT5_BT_Portable_Inst3\MetaEditor64.exe' /compile:'C:\Users\switz\Documents\KI_Projekte\TradingBots\Exness_TradingBox\MQL5\Experts\Exness_TradingBox_v1_001_MT5.mq5' /log:'C:\Users\switz\Documents\KI_Projekte\TradingBots\Exness_TradingBox\build\compile-ui.log'
```

Expected: FAIL with missing UI functions

**Step 3: Implement minimal chart UI**

Add a typed runtime settings struct and create objects for:

```mql5
struct TBRuntimeInputs
  {
   double base_lot;
   double pi_multiplier;
   double hedge_multiplier;
   double be_activation_currency;
   double atr_multiplier;
   int    trail_mode;
  };
```

Create:

```mql5
bool TB_CreateChartUi();
void TB_DestroyChartUi();
bool TB_ReadChartInputs(TBRuntimeInputs &inputs);
void TB_UpdateInfoPanel(const TBCycleState &state,const TBRuntimeInputs &inputs);
```

Use deterministic anchors, fixed row heights, fixed column widths, and a single prefix such as:

```mql5
#define TB_OBJ_PREFIX "TBX_"
```

**Step 4: Compile and manually verify**

Run the compile command above.

Expected: PASS

Manual check:
- attach EA to a chart
- confirm the `Start` button and edit fields render without overlap
- confirm repeated chart refreshes do not duplicate objects

**Step 5: Commit**

```bash
git add MQL5 docs/chatlogs/2026-04-16-session.md
git commit -m "feat: add chart controls and info panel skeleton"
```

### Task 4: Implement frame calculation, drawing, and breakout lock logic

**Files:**
- Modify: `MQL5/Experts/Exness_TradingBox_v1_001_MT5.mq5`
- Modify: `MQL5/Experts/Exness_TradingBox/TB_Frame.mqh`
- Modify: `MQL5/Experts/Exness_TradingBox/TB_State.mqh`
- Create: `MQL5/Scripts/Exness_TradingBox_FrameSelfTest.mq5`
- Modify: `docs/chatlogs/2026-04-16-session.md`

**Step 1: Write the failing frame contract**

In the frame self-test, reference helpers that compute the rounded frame height:

```mql5
#include "..\\Experts\\Exness_TradingBox\\TB_Frame.mqh"

void OnStart()
  {
   double points = TB_ComputeFrameHeightPoints(18.4,2.0);
   Print(points);
  }
```

**Step 2: Compile the frame self-test to verify it fails**

Run:

```powershell
& 'C:\Users\switz\AppData\Local\Temp\MT5_BT_Portable_Inst3\MetaEditor64.exe' /compile:'C:\Users\switz\Documents\KI_Projekte\TradingBots\Exness_TradingBox\MQL5\Scripts\Exness_TradingBox_FrameSelfTest.mq5' /log:'C:\Users\switz\Documents\KI_Projekte\TradingBots\Exness_TradingBox\build\frame-selftest.log'
```

Expected: FAIL with missing `TB_ComputeFrameHeightPoints`

**Step 3: Implement frame helpers**

Add:

```mql5
double TB_ComputeFrameHeightPoints(const double spread_points,const double pi_multiplier)
  {
   return MathMax(1.0,MathRound(spread_points * M_PI * pi_multiplier));
  }
```

plus:

```mql5
void TB_RebuildFrameAtMarket(TBCycleState &state,const TBRuntimeInputs &inputs);
void TB_DrawFrameObjects(const TBCycleState &state);
int  TB_DetectBreakoutDirection(const TBCycleState &state,const double bid,const double ask);
bool TB_CanOpenBreakForDirection(TBCycleState &state,const int breakout_direction);
```

`TB_CanOpenBreakForDirection` must reject duplicate execution on the same side until the opposite side breaks.

**Step 4: Compile and manually verify**

Run both self-test compile and main EA compile.

Expected: PASS

Manual check:
- click `Start`
- confirm the frame centers on the current price
- confirm frame height equals rounded `spread * PI * multiplier`
- confirm upper/lower/mid lines redraw cleanly after cycle reset

**Step 5: Commit**

```bash
git add MQL5 docs/chatlogs/2026-04-16-session.md
git commit -m "feat: add frame calculation and breakout lock logic"
```

### Task 5: Implement order execution and unlimited hedge progression

**Files:**
- Modify: `MQL5/Experts/Exness_TradingBox_v1_001_MT5.mq5`
- Modify: `MQL5/Experts/Exness_TradingBox/TB_Trade.mqh`
- Modify: `MQL5/Experts/Exness_TradingBox/TB_State.mqh`
- Modify: `MQL5/Experts/Exness_TradingBox/TB_UI.mqh`
- Modify: `docs/chatlogs/2026-04-16-session.md`

**Step 1: Write the failing trade compile contract**

Wire the main tick loop to missing trade functions:

```mql5
void OnTick()
  {
   TB_HandleBreakoutTrading();
  }
```

**Step 2: Compile to verify it fails**

Run:

```powershell
& 'C:\Users\switz\AppData\Local\Temp\MT5_BT_Portable_Inst3\MetaEditor64.exe' /compile:'C:\Users\switz\Documents\KI_Projekte\TradingBots\Exness_TradingBox\MQL5\Experts\Exness_TradingBox_v1_001_MT5.mq5' /log:'C:\Users\switz\Documents\KI_Projekte\TradingBots\Exness_TradingBox\build\compile-trade.log'
```

Expected: FAIL with missing `TB_HandleBreakoutTrading`

**Step 3: Implement minimal trade engine**

Add:

```mql5
CTrade g_trade;

bool TB_OpenInitialBreakTrade(TBCycleState &state,const int direction,const TBRuntimeInputs &inputs);
bool TB_OpenHedgeLeg(TBCycleState &state,const int direction,const TBRuntimeInputs &inputs);
double TB_ComputeNextLegLots(const TBCycleState &state,const TBRuntimeInputs &inputs);
bool TB_CloseEntireCycle(const string reason);
```

Lot progression must follow:

```mql5
double TB_ComputeNextLegLots(const TBCycleState &state,const TBRuntimeInputs &inputs)
  {
   if(state.leg_count<=0)
      return inputs.base_lot;
   return state.last_leg_lots * inputs.hedge_multiplier;
  }
```

Log failures with `Print()` including `trade.ResultRetcode()` and `trade.ResultRetcodeDescription()`.

**Step 4: Compile and manually verify**

Run the compile command above.

Expected: PASS

Manual check:
- first upper break opens exactly one long
- first lower break opens exactly one short
- opposite break after initial entry opens a hedge leg
- repeated ticks at the same side do not open duplicates

**Step 5: Commit**

```bash
git add MQL5 docs/chatlogs/2026-04-16-session.md
git commit -m "feat: add breakout orders and hedge progression"
```

### Task 6: Implement basket math, net exposure, and break-even return logic

**Files:**
- Modify: `MQL5/Experts/Exness_TradingBox_v1_001_MT5.mq5`
- Modify: `MQL5/Experts/Exness_TradingBox/TB_Basket.mqh`
- Modify: `MQL5/Experts/Exness_TradingBox/TB_Trade.mqh`
- Modify: `MQL5/Experts/Exness_TradingBox/TB_UI.mqh`
- Create: `MQL5/Scripts/Exness_TradingBox_BasketSelfTest.mq5`
- Modify: `docs/chatlogs/2026-04-16-session.md`

**Step 1: Write the failing basket contract**

In the basket self-test, reference missing helpers:

```mql5
#include "..\\Experts\\Exness_TradingBox\\TB_Basket.mqh"

void OnStart()
  {
   double net_lots = TB_ComputeNetExposureLots();
   double be_price = TB_ComputeBasketReturnPrice();
   Print(net_lots, " ", be_price);
  }
```

**Step 2: Compile the basket self-test to verify it fails**

Run:

```powershell
& 'C:\Users\switz\AppData\Local\Temp\MT5_BT_Portable_Inst3\MetaEditor64.exe' /compile:'C:\Users\switz\Documents\KI_Projekte\TradingBots\Exness_TradingBox\MQL5\Scripts\Exness_TradingBox_BasketSelfTest.mq5' /log:'C:\Users\switz\Documents\KI_Projekte\TradingBots\Exness_TradingBox\build\basket-selftest.log'
```

Expected: FAIL with missing basket helpers

**Step 3: Implement basket calculations**

Add functions:

```mql5
double TB_ComputeCycleOpenProfitCurrency();
double TB_ComputeNetExposureLots();
double TB_ComputeEffectiveLeverage();
bool   TB_IsBeActivationReached(const TBRuntimeInputs &inputs);
bool   TB_TryComputeBasketReturnPrice(double &return_price);
```

Use actual open positions for `_Symbol` and the EA magic number, and include:

```mql5
profit = POSITION_PROFIT + POSITION_SWAP + POSITION_COMMISSION;
```

Then in the main tick loop:

```mql5
if(TB_IsBeActivationReached(inputs))
   state.be_armed = true;

if(state.be_armed && TB_IsMarketAtBasketReturnPrice())
   TB_CloseEntireCycle("basket_be_return");
```

**Step 4: Compile and manually verify**

Run both compile commands.

Expected: PASS

Manual check:
- BE does not arm while basket PnL is below the configured currency threshold
- once threshold is exceeded, BE arms
- return to the basket BE line closes all cycle positions together
- info panel shows net exposure and current leverage updating live

**Step 5: Commit**

```bash
git add MQL5 docs/chatlogs/2026-04-16-session.md
git commit -m "feat: add basket break-even and exposure metrics"
```

### Task 7: Implement ATR analytics, regime, vola index, and cycle trailing

**Files:**
- Modify: `MQL5/Experts/Exness_TradingBox_v1_001_MT5.mq5`
- Modify: `MQL5/Experts/Exness_TradingBox/TB_Analytics.mqh`
- Modify: `MQL5/Experts/Exness_TradingBox/TB_Basket.mqh`
- Modify: `MQL5/Experts/Exness_TradingBox/TB_UI.mqh`
- Modify: `MQL5/Experts/Exness_TradingBox/TB_Trade.mqh`
- Create: `MQL5/Scripts/Exness_TradingBox_AnalyticsSelfTest.mq5`
- Modify: `docs/chatlogs/2026-04-16-session.md`

**Step 1: Write the failing analytics contract**

In the self-test, reference missing helpers:

```mql5
#include "..\\Experts\\Exness_TradingBox\\TB_Analytics.mqh"

void OnStart()
  {
   Print(TB_TrailModeToAtrFactor(0));
   Print(TB_ClassifyRegime(10.0,5.0,20.0));
   Print(TB_ComputeVolaIndex(45.0,90.0));
  }
```

**Step 2: Compile the analytics self-test to verify it fails**

Run:

```powershell
& 'C:\Users\switz\AppData\Local\Temp\MT5_BT_Portable_Inst3\MetaEditor64.exe' /compile:'C:\Users\switz\Documents\KI_Projekte\TradingBots\Exness_TradingBox\MQL5\Scripts\Exness_TradingBox_AnalyticsSelfTest.mq5' /log:'C:\Users\switz\Documents\KI_Projekte\TradingBots\Exness_TradingBox\build\analytics-selftest.log'
```

Expected: FAIL with missing analytics helpers

**Step 3: Implement analytics and trailing**

Add:

```mql5
double TB_ReadAtrPoints(const int period);
double TB_TrailModeToAtrFactor(const int mode);
int    TB_ClassifyRegime(const double ema_fast,const double ema_slow,const double atr_points);
double TB_ComputeVolaIndex(const double atr_points,const double frame_height_points);
bool   TB_TryComputeCycleTrailPrice(const TBCycleState &state,const TBRuntimeInputs &inputs,double &trail_price);
```

Map modes approximately as:

```mql5
double TB_TrailModeToAtrFactor(const int mode)
  {
   if(mode==0) return 1.35; // soft
   if(mode==2) return 0.70; // hard
   return 1.00;             // medium
  }
```

Only arm or tighten the trail when the basket is already profitable beyond BE.

**Step 4: Compile and manually verify**

Run both compile commands.

Expected: PASS

Manual check:
- regime flips between bull, bear, and range based on EMA state
- vola index equals `ATR(14) / frame_height * 100`
- `soft`, `medium`, and `hard` visibly change the trail distance
- the whole profitable cycle closes when price reaches the trail

**Step 5: Commit**

```bash
git add MQL5 docs/chatlogs/2026-04-16-session.md
git commit -m "feat: add cycle trailing, regime, and vola analytics"
```

### Task 8: Integrate timer loop, deployment, compile verification, and release hygiene

**Files:**
- Modify: `MQL5/Experts/Exness_TradingBox_v1_001_MT5.mq5`
- Modify: `scripts/build-and-deploy.ps1`
- Modify: `docs/chatlogs/2026-04-16-session.md`
- Modify: `docs/plans/2026-04-16-exness-tradingbox-design.md`

**Step 1: Write the failing deployment contract**

Update `scripts/build-and-deploy.ps1` to assert that deployment produced the expected files under:

```text
C:\Users\switz\AppData\Local\Temp\MT5_BT_Portable_Inst3\MQL5\Experts
```

before the copy logic exists.

**Step 2: Run the deployment contract to verify it fails**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build-and-deploy.ps1 -Compile
```

Expected: FAIL with missing deployed EA file or missing include directory

**Step 3: Implement final integration**

In the main EA:

```mql5
int OnInit()
  {
   EventSetTimer(1);
   TB_CreateChartUi();
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   EventKillTimer();
   TB_DestroyChartUi();
  }

void OnTimer()
  {
   TB_RefreshUiAndAnalytics();
  }
```

In `scripts/build-and-deploy.ps1`:

```powershell
$targetRoot = "C:\Users\switz\AppData\Local\Temp\MT5_BT_Portable_Inst3\MQL5\Experts"
Copy-Item ".\MQL5\Experts\Exness_TradingBox_v1_001_MT5.mq5" $targetRoot -Force
Copy-Item ".\MQL5\Experts\Exness_TradingBox" "$targetRoot\Exness_TradingBox" -Recurse -Force
& 'C:\Users\switz\AppData\Local\Temp\MT5_BT_Portable_Inst3\MetaEditor64.exe' /compile:"$targetRoot\Exness_TradingBox_v1_001_MT5.mq5" /log:"$PWD\build\compile-final.log"
```

Also add a guard note in docs that `git push` is blocked until a remote is configured, because `git remote -v` is currently empty.

**Step 4: Run final build and verify**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build-and-deploy.ps1 -Compile
git status --short
git log --oneline -5
```

Expected:
- deployed source present in MT5 portable instance
- compile log indicates success
- working tree contains only expected version or docs changes

Manual check:
- attach EA to a chart in the portable MT5 instance
- click `Start`
- open an initial break
- force an opposite break for hedge creation
- verify BE activation and trail close behavior on a test symbol

**Step 5: Commit**

```bash
git add MQL5 scripts docs
git commit -m "feat: integrate Exness TradingBox EA and deploy workflow"
```

## Notes

- Keep the main EA filename versioned and bump the visible EA version on each implementation change.
- Update `docs/chatlogs/2026-04-16-session.md` before each commit so the repo contains the current session history.
- Do not attempt `git push` until a remote is configured.
- If the versioned main filename changes mid-implementation, update the build script and all compile commands in the same task.
