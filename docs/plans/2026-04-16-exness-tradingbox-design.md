# Exness TradingBox Design

**Date:** 2026-04-16
**EA Name:** `Exness_TradingBox_v1_000_MT5`
**Platform:** MetaTrader 5 / MQL5
**Deploy Target:** `C:\Users\switz\AppData\Local\Temp\MT5_BT_Portable_Inst3\MQL5\Experts`

## Goal

Build a new MT5 Expert Advisor from scratch that trades breakout cycles around a price-centered frame, manages unlimited hedge legs with a configurable lot multiplier, and closes the full cycle only through basket break-even protection or ATR-based trailing while exposing all controls directly on the chart.

## Core Trading Model

### Cycle start

- The EA starts trading only after a one-time click on a chart button.
- On start, the EA builds a frame centered around the current market price.
- The frame height is calculated once per cycle as:
  - current spread in points
  - multiplied by `PI`
  - multiplied by a user-configurable PI multiplier from a chart edit field
- The resulting frame height is rounded to whole points.
- The frame remains fixed for the full cycle.

### Breakout entries

- If price breaks the upper frame line, the EA opens a long position with the base lot from the chart.
- If price breaks the lower frame line, the EA opens a short position with the base lot from the chart.
- A breakout guard prevents repeated execution when price oscillates around the same frame line.
- A new trade is allowed only when the opposite frame side is broken.

### Hedge progression

- If price reverses and breaks the opposite frame side before the cycle closes, the EA opens a hedge trade.
- All previous positions remain open.
- Each new hedge leg uses:
  - `new_lot = previous_leg_lot * hedge_multiplier`
- The number of hedge legs is intentionally unlimited.

### Cycle exit

- The cycle closes only when the total basket is profitable.
- There is no static stop loss for losing basket states.
- Protection is provided by the hedge structure until the basket becomes profitable.

## Break-Even Logic

### Activation

- Basket BE protection is activated only when the total open cycle profit, after spread, commission, and swap, exceeds a user-defined threshold in account currency.

### Exit behavior

- Once BE protection is active, the EA calculates a shared basket return price.
- If market price returns to that basket BE price, the EA closes every position in the cycle at once.
- No additional BE profit buffer is required.
- The basket BE return line is the only non-trailing cycle protection once activation has occurred.

## Trailing Stop Logic

- Trailing is ATR-based.
- The user controls:
  - trailing mode: `soft`, `medium`, `hard`
  - ATR multiplier
- Mode controls the effective aggressiveness of the trail distance.
- The trail applies to the full cycle, not to single positions.
- The trail becomes meaningful only when the cycle is in profit and the trail level protects profit above the shared basket BE state.
- When the trail is hit, the EA closes every position in the cycle at once.

## Cycle Reset

- Whenever a full cycle is closed, whether by BE return or ATR trail, the EA immediately recalculates a new frame centered on the current price.
- Trading continues automatically with the new cycle after reset.

## Risk and Position Controls

- Base lot is controlled through a chart edit field.
- Hedge lot multiplier is controlled through a chart edit field.
- PI frame multiplier is controlled through a chart edit field.
- BE activation threshold is controlled through a chart edit field in account currency.
- There is no max-leg limit.
- Take profit is handled only through basket BE return and ATR trailing.

## Chart UI

The EA uses direct chart controls and not only standard MT5 inputs.

### Interactive controls

- Start button
- Edit field: base lot
- Edit field: PI multiplier
- Edit field: hedge multiplier
- Edit field: BE activation threshold in account currency
- Edit field: ATR multiplier
- Mode selector or button set for `soft`, `medium`, `hard`

### Read-only info panel

- EA name including visible version
- Net exposure summary from long and short positions
- Regime
- Vola index
- Current leverage
- Spread
- Current frame height

### Layout rules

- All visible chart objects must be placed without overlap.
- Object naming must use a stable EA-specific prefix.
- UI layout must remain readable on repeated redraws.

## Analytics Definitions

### Regime

- `Bull`: fast EMA above slow EMA
- `Bear`: fast EMA below slow EMA
- `Range`: EMA distance small relative to ATR

### Vola Index

- `Vola Index = ATR(14) / frame_height * 100`
- It is shown as a dimensionless percentage-like ratio.

### Current Leverage

- `current leverage = total nominal exposure / equity`
- This is the live effective leverage, not the static broker account leverage.

## Technical Architecture

The EA is built as a modular MT5 project with one main `.mq5` file and local `.mqh` modules.

### Planned modules

- `Exness_TradingBox_v1_000_MT5.mq5`
  - lifecycle wiring: `OnInit`, `OnTick`, `OnTimer`, `OnDeinit`
- `TB_Config.mqh`
  - constants, defaults, object prefixes, version metadata
- `TB_State.mqh`
  - cycle state, leg state, breakout lock state, BE/trailing state
- `TB_UI.mqh`
  - chart controls, parsing, update loop, non-overlapping placement
- `TB_Frame.mqh`
  - frame calculation, line drawing, price reset behavior
- `TB_Trade.mqh`
  - `CTrade` wrapper, order execution, close-all cycle logic, logging
- `TB_Basket.mqh`
  - basket PnL, BE return price, exposure, leverage calculations
- `TB_Analytics.mqh`
  - ATR, regime, vola index, trail distance helpers

## Error Handling

- Failed order placement, modification, and close operations must be logged using `Print()`.
- UI parsing failures should fall back to last valid values and log the issue.
- Any basket close failure should keep the cycle state intact and retry on later ticks.

## Deployment and Versioning

- The repository is created fresh in the project folder.
- Every change increments the visible EA version in the name.
- After each change, files are deployed to:
  - `C:\Users\switz\AppData\Local\Temp\MT5_BT_Portable_Inst3\MQL5\Experts`
- Every change is committed to git.
- A repo-local session chat log is maintained because GitHub does not automatically store the live terminal chat.

## Constraints and Clarifications

- The EA is built from scratch and does not extend the existing `OpeningBreakoutEA...` file.
- The previous EA may be read as a behavioral reference only.
- The complete cycle remains open across hedge flips until the basket can be closed profitably.
- BE activation is based on basket profit in account currency.
- BE exit is based on the calculated basket return price.
- No separate BE exit profit buffer is required.

## Initial Success Criteria

- EA compiles cleanly in MT5.
- Start button initializes a centered frame with rounded point height.
- First breakout opens exactly one initial position.
- Opposite break opens a hedge leg with multiplied lot without closing older legs.
- Basket BE activates only after the configured currency profit threshold is exceeded.
- Return to shared basket BE price closes all positions in the cycle.
- ATR trailing can close the full profitable cycle.
- After a full close, the frame resets around current price automatically.
- Chart UI remains readable and non-overlapping.
