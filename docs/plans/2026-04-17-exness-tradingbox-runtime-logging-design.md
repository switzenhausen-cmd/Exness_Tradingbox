# Exness TradingBox Runtime Logging Design

**Date:** 2026-04-17
**EA Target Version:** `1.011`
**Branch:** `feature/exness-tradingbox-impl`

## Goal

Add EA-native runtime logging so every future cycle can be analyzed per instrument, per entry leg, and per exit reason together with the exact on-chart settings that were active at the time.

## Problem

The current EA only emits sparse terminal log lines for order failures and cycle close failures. That is not enough to answer questions like:

- which settings were active for a specific trade
- which symbols produced the best risk-adjusted cycles
- whether profitable exits correlated with specific `ATR Mult`, `Trail Mode`, `Exit Buffer Pts`, or `Hedge Mult`

Without structured runtime logs, later analysis is mostly guesswork.

## Approved Direction

The EA itself will log each cycle and trade event into a dedicated CSV under `MQL5/Files/Exness_TradingBox/`.

The logging scope should be:

1. cycle start
2. every initial breakout and hedge leg entry
3. cycle-close attempt and successful cycle close
4. order/close failures

## Logging Model

Each row should be one event with stable columns so external analysis scripts can aggregate the data later.

Recommended columns:

- `timestamp`
- `symbol`
- `timeframe`
- `ea_name`
- `cycle_id`
- `event_type`
- `event_reason`
- `direction`
- `leg_index`
- `lots`
- `base_lot`
- `hedge_multiplier`
- `pi_multiplier`
- `be_currency`
- `atr_multiplier`
- `exit_buffer_points`
- `trail_mode`
- `frame_height_points`
- `frame_mid_price`
- `frame_upper_price`
- `frame_lower_price`
- `basket_profit`
- `net_exposure`
- `equity`

## Cycle Identity

The EA needs a stable `cycle_id` that persists across all legs of the same cycle and changes only when:

- a new frame/cycle is started
- the EA is re-armed after idle state
- a full cycle closes and a new cycle begins

This is the key that allows future analysis to group entries, hedges, and exits into one lifecycle.

## File Strategy

Use one CSV per symbol, for example:

`MQL5/Files/Exness_TradingBox/Exness_TradingBox_XAUUSDm.csv`

This keeps the file count manageable and makes later aggregation straightforward.

## Minimal Scope

Only add the logging needed for later analytics. Do not add:

- tick-by-tick logs
- chart rendering for logs
- in-EA report generation

Those belong in separate analysis tooling later.

## Verification

Add a self-test for the CSV line formatting and compile the EA after wiring the logging into the runtime.

## Expected Outcome

After this change, future trade history can be analyzed exactly instead of inferred indirectly from terminal journals.

## Implementation Status

Implemented on branch `feature/exness-tradingbox-impl` with EA version `1.011`.

Current emitted events:

- `cycle_start`
- `entry_initial`
- `entry_hedge`
- `cycle_close_attempt`
- `cycle_close_success`
- `order_failure`
- `close_failure`
