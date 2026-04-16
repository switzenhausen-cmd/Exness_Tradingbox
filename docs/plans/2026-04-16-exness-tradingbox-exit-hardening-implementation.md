# Exness TradingBox Exit Hardening Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add an earlier buffered cycle-exit trigger, a materially tighter hard trailing mode, and a more aggressive cycle-close path while bumping the visible EA version to `1.010`.

**Architecture:** Keep the current cycle model intact and make the change at the edges: runtime inputs/UI gain one new `Exit Buffer Pts` control, analytics and basket helpers compute buffered effective exit lines, and trade closing gets a dedicated aggressive deviation path. This isolates the new behavior without changing frame construction, hedge progression, or basket-profit arming semantics.

**Tech Stack:** MQL5, MT5 standard library `Trade\Trade.mqh`, `CTrade`, PowerShell, Git

---

### Task 1: Add version bump and runtime input contract for exit buffering

**Files:**
- Modify: `MQL5/Experts/Exness_TradingBox/TB_Config.mqh`
- Modify: `MQL5/Experts/Exness_TradingBox/TB_UI.mqh`
- Modify: `MQL5/Experts/Exness_TradingBox_v1_001_MT5.mq5`
- Create: `MQL5/Scripts/Exness_TradingBox_ExitBufferSelfTest.mq5`

**Step 1: Write the failing test**

Create `MQL5/Scripts/Exness_TradingBox_ExitBufferSelfTest.mq5` that references a new runtime field and a helper that do not exist yet:

```mql5
#property strict

#include "..\\Experts\\Exness_TradingBox\\TB_Config.mqh"
#include "..\\Experts\\Exness_TradingBox\\TB_UI.mqh"
#include "..\\Experts\\Exness_TradingBox\\TB_Basket.mqh"

void OnStart()
  {
   TBRuntimeInputs inputs;
   inputs.exit_buffer_points=12.0;
   Print(inputs.exit_buffer_points);
   Print(TB_ApplyExitBufferPrice(1.10000,12.0,1));
  }
```

**Step 2: Run test to verify it fails**

Run:

```powershell
& 'C:\Users\switz\AppData\Local\Temp\MT5_BT_Portable_Inst3\MetaEditor64.exe' /compile:'C:\Users\switz\Documents\KI_Projekte\TradingBots\Exness_TradingBox\.worktrees\exness-tradingbox-impl\MQL5\Scripts\Exness_TradingBox_ExitBufferSelfTest.mq5' /log:'C:\Users\switz\Documents\KI_Projekte\TradingBots\Exness_TradingBox\.worktrees\exness-tradingbox-impl\build\exit-buffer-selftest.log'
```

Expected: FAIL with missing `exit_buffer_points` and `TB_ApplyExitBufferPrice`

**Step 3: Write minimal implementation**

- bump `TB_EA_VERSION_MINOR` to `10`
- bump `#property version` in the main EA to `1.010`
- extend `TBRuntimeInputs`:

```mql5
double exit_buffer_points;
```

- add one UI row:

```mql5
TB_CreateLabel(TB_UiObjectName("LBL_EXIT_BUFFER"),"Exit Buffer Pts",label_left,TB_UiRowTop(6),TB_UI_LABEL_WIDTH);
TB_CreateEdit(TB_UiObjectName("INP_EXIT_BUFFER"),"5.0",input_left,TB_UiRowTop(6));
```

- shift the trail mode row and info rows down by one slot as needed
- parse the new field in `TB_ReadChartInputs()`

**Step 4: Run test to verify it passes**

Run the same compile command as in Step 2.

Expected: PASS with `0 errors, 0 warnings`

**Step 5: Commit**

```bash
git add MQL5/Experts/Exness_TradingBox/TB_Config.mqh MQL5/Experts/Exness_TradingBox/TB_UI.mqh MQL5/Experts/Exness_TradingBox_v1_001_MT5.mq5 MQL5/Scripts/Exness_TradingBox_ExitBufferSelfTest.mq5
git commit -m "feat: add exit buffer runtime input"
```

### Task 2: Add buffered exit-line helpers for basket and trail triggers

**Files:**
- Modify: `MQL5/Experts/Exness_TradingBox/TB_Basket.mqh`
- Modify: `MQL5/Experts/Exness_TradingBox/TB_Analytics.mqh`
- Modify: `MQL5/Experts/Exness_TradingBox_v1_001_MT5.mq5`
- Modify: `MQL5/Scripts/Exness_TradingBox_ExitBufferSelfTest.mq5`

**Step 1: Write the failing test**

Extend `Exness_TradingBox_ExitBufferSelfTest.mq5` to reference exact buffered prices:

```mql5
void OnStart()
  {
   Print(TB_ApplyExitBufferPrice(1.10000,10.0,1));
   Print(TB_ApplyExitBufferPrice(1.10000,10.0,-1));
  }
```

**Step 2: Run test to verify it fails**

Run the same self-test compile command.

Expected: FAIL with missing `TB_ApplyExitBufferPrice`

**Step 3: Write minimal implementation**

In basket or shared helper code, add:

```mql5
double TB_ApplyExitBufferPrice(const double raw_price,const double buffer_points,const int net_direction)
  {
   const double buffer_price=buffer_points * _Point;
   if(net_direction>0)
      return NormalizeDouble(raw_price + buffer_price,_Digits);
   if(net_direction<0)
      return NormalizeDouble(raw_price - buffer_price,_Digits);
   return raw_price;
  }
```

Update the main tick loop so:

- basket-BE exit uses the buffered effective line, not the raw line
- trail exit uses the buffered effective line, not the raw line

Keep the stored raw basket/trail prices for display or internal state if helpful.

**Step 4: Run test to verify it passes**

Run the self-test compile again.

Expected: PASS with `0 errors, 0 warnings`

**Step 5: Commit**

```bash
git add MQL5/Experts/Exness_TradingBox/TB_Basket.mqh MQL5/Experts/Exness_TradingBox/TB_Analytics.mqh MQL5/Experts/Exness_TradingBox_v1_001_MT5.mq5 MQL5/Scripts/Exness_TradingBox_ExitBufferSelfTest.mq5
git commit -m "feat: add buffered cycle exit triggers"
```

### Task 3: Tighten trailing mode factors

**Files:**
- Modify: `MQL5/Experts/Exness_TradingBox/TB_Analytics.mqh`
- Modify: `MQL5/Scripts/Exness_TradingBox_AnalyticsSelfTest.mq5`

**Step 1: Write the failing test**

Change the analytics self-test expectations to reflect the tighter factors:

```mql5
void OnStart()
  {
   Print(TB_TrailModeToAtrFactor(0)); // expect 1.00
   Print(TB_TrailModeToAtrFactor(1)); // expect 0.65
   Print(TB_TrailModeToAtrFactor(2)); // expect 0.35
  }
```

**Step 2: Run test to verify it fails**

Run:

```powershell
& 'C:\Users\switz\AppData\Local\Temp\MT5_BT_Portable_Inst3\MetaEditor64.exe' /compile:'C:\Users\switz\Documents\KI_Projekte\TradingBots\Exness_TradingBox\.worktrees\exness-tradingbox-impl\MQL5\Scripts\Exness_TradingBox_AnalyticsSelfTest.mq5' /log:'C:\Users\switz\Documents\KI_Projekte\TradingBots\Exness_TradingBox\.worktrees\exness-tradingbox-impl\build\analytics-selftest.log'
```

Expected: PASS compilation but runtime print values would not match the intended factors until implementation is updated. Because this is compile-only infrastructure, treat the factor change as a contract update and then recompile the main EA for verification.

**Step 3: Write minimal implementation**

Update:

```mql5
if(mode==0) return 1.00;
if(mode==2) return 0.35;
return 0.65;
```

**Step 4: Run test to verify it passes**

Run the main build:

```powershell
& '.\scripts\build-and-deploy.ps1' -Compile
```

Expected: `Result: 0 errors, 0 warnings`

**Step 5: Commit**

```bash
git add MQL5/Experts/Exness_TradingBox/TB_Analytics.mqh MQL5/Scripts/Exness_TradingBox_AnalyticsSelfTest.mq5
git commit -m "feat: tighten trailing mode factors"
```

### Task 4: Separate aggressive close configuration for cycle exits

**Files:**
- Modify: `MQL5/Experts/Exness_TradingBox/TB_Config.mqh`
- Modify: `MQL5/Experts/Exness_TradingBox/TB_Trade.mqh`
- Modify: `MQL5/Experts/Exness_TradingBox_v1_001_MT5.mq5`

**Step 1: Write the failing test**

Add a compile contract by referencing a missing close-configuration helper from `TB_CloseEntireCycle()`:

```mql5
void TB_ConfigureCloseTradeContext();
```

Call it inside `TB_CloseEntireCycle()`.

**Step 2: Run test to verify it fails**

Run:

```powershell
& '.\scripts\build-and-deploy.ps1' -Compile
```

Expected: FAIL with missing `TB_ConfigureCloseTradeContext`

**Step 3: Write minimal implementation**

Add a separate constant such as:

```mql5
#define TB_CLOSE_DEVIATION_POINTS 80
```

and helper:

```mql5
void TB_ConfigureCloseTradeContext()
  {
   g_tb_trade.SetExpertMagicNumber(TB_MAGIC_DEFAULT);
   g_tb_trade.SetDeviationInPoints(TB_CLOSE_DEVIATION_POINTS);
  }
```

Use `TB_ConfigureCloseTradeContext()` inside `TB_CloseEntireCycle()` while keeping `TB_ConfigureTradeContext()` for entries.

**Step 4: Run test to verify it passes**

Run the same build command as in Step 2.

Expected: `Result: 0 errors, 0 warnings`

**Step 5: Commit**

```bash
git add MQL5/Experts/Exness_TradingBox/TB_Config.mqh MQL5/Experts/Exness_TradingBox/TB_Trade.mqh MQL5/Experts/Exness_TradingBox_v1_001_MT5.mq5
git commit -m "feat: make cycle close path more aggressive"
```

### Task 5: Update project docs and verify final integrated build

**Files:**
- Modify: `docs/chatlogs/2026-04-16-session.md`
- Modify: `docs/handoffs/2026-04-16-exness-tradingbox-handoff.md`
- Modify: `docs/plans/2026-04-16-exness-tradingbox-design.md`

**Step 1: Write the failing doc contract**

Add notes in the handoff checklist that refer to `Exit Buffer Pts` and the tighter `hard` trail before the code/documentation is updated elsewhere.

**Step 2: Run verification to confirm docs are now stale**

Run:

```bash
git diff -- docs
```

Expected: shows pending documentation updates

**Step 3: Write minimal implementation**

Document:

- new `Exit Buffer Pts` chart input
- target version `1.010`
- tighter trail-mode behavior
- aggressive close-path note
- recommended manual chart verification for early exit behavior

**Step 4: Run test to verify it passes**

Run:

```powershell
& '.\scripts\build-and-deploy.ps1' -Compile
git status --short
git log --oneline -5
```

Expected:

- build ends with `0 errors, 0 warnings`
- working tree shows only intended doc/code changes before commit

**Step 5: Commit**

```bash
git add docs
git commit -m "docs: record exit hardening behavior"
```

## Notes

- Keep the main filename unchanged unless there is a separate versioning decision for file names.
- Manual MT5 chart verification is still required for real-time exit timing behavior.
- The earlier buffered exit is expected to trade some peak-profit capture for higher exit reliability.
