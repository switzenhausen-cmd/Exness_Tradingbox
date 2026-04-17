# Exness TradingBox Runtime Logging Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add EA-native CSV logging for cycle starts, leg entries, cycle exits, and order failures while bumping the visible EA version to `1.011`.

**Architecture:** Keep logging isolated in a dedicated helper module so trade logic only emits structured events with current runtime values and cycle state. A stable `cycle_id` will live in EA state, and each emitted CSV row will include both market context and the active chart settings.

**Tech Stack:** MQL5, MT5 file I/O, `Trade\Trade.mqh`, PowerShell, Git

---

### Task 1: Add logging module scaffolding and version bump

**Files:**
- Modify: `MQL5/Experts/Exness_TradingBox/TB_Config.mqh`
- Modify: `MQL5/Experts/Exness_TradingBox/TB_State.mqh`
- Modify: `MQL5/Experts/Exness_TradingBox_v1_010_MT5.mq5`
- Create: `MQL5/Experts/Exness_TradingBox/TB_Log.mqh`
- Create: `MQL5/Scripts/Exness_TradingBox_LogSelfTest.mq5`
- Modify: `scripts/build-and-deploy.ps1`

**Step 1: Write the failing test**

Create `MQL5/Scripts/Exness_TradingBox_LogSelfTest.mq5` that references missing logging helpers and cycle id state.

**Step 2: Run test to verify it fails**

Compile the self-test with `MetaEditor64.exe` and confirm missing identifiers such as `TB_BuildLogFileName`, `TB_EnsureLogHeader`, or `state.cycle_id`.

**Step 3: Write minimal implementation**

- bump visible version from `1.010` to `1.011`
- add `cycle_id` to `TBCycleState`
- add `TB_Log.mqh` with:
  - log file name builder
  - header writer
  - CSV escaping helper if needed
- include the new module in the main EA and build script

**Step 4: Run test to verify it passes**

Recompile the new self-test and confirm `0 errors, 0 warnings`.

**Step 5: Commit**

```bash
git add MQL5 scripts
git commit -m "feat: add runtime logging scaffold"
```

### Task 2: Emit structured cycle-start and entry events

**Files:**
- Modify: `MQL5/Experts/Exness_TradingBox/TB_Frame.mqh`
- Modify: `MQL5/Experts/Exness_TradingBox/TB_Trade.mqh`
- Modify: `MQL5/Experts/Exness_TradingBox/TB_Log.mqh`
- Modify: `MQL5/Experts/Exness_TradingBox_v1_010_MT5.mq5`

**Step 1: Write the failing test**

Extend the self-test to reference a missing row formatter for cycle/entry events.

**Step 2: Run test to verify it fails**

Compile the self-test and confirm the formatter/helper is missing.

**Step 3: Write minimal implementation**

- assign a fresh `cycle_id` whenever a new frame/cycle is created
- write a `cycle_start` event when the frame is armed
- write `entry_initial` and `entry_hedge` events when orders succeed
- include current runtime inputs and frame values in each row

**Step 4: Run test to verify it passes**

Compile the self-test and the main EA.

**Step 5: Commit**

```bash
git add MQL5
git commit -m "feat: log cycle starts and leg entries"
```

### Task 3: Emit cycle-close and failure events

**Files:**
- Modify: `MQL5/Experts/Exness_TradingBox/TB_Trade.mqh`
- Modify: `MQL5/Experts/Exness_TradingBox/TB_Log.mqh`
- Modify: `MQL5/Experts/Exness_TradingBox_v1_010_MT5.mq5`

**Step 1: Write the failing test**

Reference missing close/failure log helpers from the self-test or compile contract.

**Step 2: Run test to verify it fails**

Compile and confirm the new close logging helper is missing.

**Step 3: Write minimal implementation**

- log `cycle_close_attempt`
- log `cycle_close_success`
- log `order_failure`
- log `close_failure`
- include `event_reason` such as `basket_be_return`, `cycle_trail`, `manual_deactivate`

**Step 4: Run test to verify it passes**

Compile self-test and full EA.

**Step 5: Commit**

```bash
git add MQL5
git commit -m "feat: log cycle exits and failures"
```

### Task 4: Verify file output through deploy compile and docs

**Files:**
- Modify: `docs/chatlogs/2026-04-16-session.md`
- Modify: `docs/handoffs/2026-04-16-exness-tradingbox-handoff.md`
- Modify: `docs/plans/2026-04-17-exness-tradingbox-runtime-logging-design.md`

**Step 1: Write the failing doc contract**

Update docs to expect runtime CSV logging before documentation is aligned.

**Step 2: Run verification to confirm pending updates**

Inspect `git diff -- docs`.

**Step 3: Write minimal implementation**

Document:

- version `1.011`
- new runtime CSV logging behavior
- target folder under `MQL5/Files/Exness_TradingBox/`
- recommended next step: external analysis script over the generated CSVs

**Step 4: Run test to verify it passes**

Run:

```powershell
& '.\scripts\build-and-deploy.ps1' -Compile
git status --short
git log --oneline -5
```

Expected: deploy compile succeeds with `0 errors, 0 warnings`.

**Step 5: Commit**

```bash
git add docs
git commit -m "docs: record runtime logging support"
```
