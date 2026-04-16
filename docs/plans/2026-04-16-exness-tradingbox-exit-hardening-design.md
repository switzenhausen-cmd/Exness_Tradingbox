# Exness TradingBox Exit Hardening Design

**Date:** 2026-04-16
**EA Target Version:** `1.010`
**Branch:** `feature/exness-tradingbox-impl`

## Goal

Tighten cycle exits so profitable windows are captured earlier and the EA closes managed positions more aggressively once an exit condition is reached.

## Problem Statement

The current EA can miss short favorable price windows because:

- basket BE exit triggers only when price returns exactly to the computed BE line
- trailing exit triggers only when price reaches the raw trail line
- `hard` trailing is still too loose for fast reversals
- the close path uses the same moderate trade deviation as normal trading

The net effect is that the chart can briefly show a good exit price, then the cycle gives back profit before the close finishes.

## Approved Direction

The fix keeps the current basket-BE and ATR-trailing model, but makes exits happen earlier and more aggressively:

1. Add one new on-chart input: `Exit Buffer Pts`
2. Apply that buffer to both basket-BE exit and trailing exit
3. Tighten the `hard` trail mode so it reacts earlier
4. Use a more aggressive close configuration than the entry path

## Design

### Exit Buffer

`Exit Buffer Pts` is measured in symbol points and shifts the effective exit trigger before the raw BE or trail line.

- For net-long cycles:
  - BE exit triggers when `Bid <= basket_be_price + buffer_price`
  - trail exit triggers when `Bid <= trail_price + buffer_price`
- For net-short cycles:
  - BE exit triggers when `Ask >= basket_be_price - buffer_price`
  - trail exit triggers when `Ask >= trail_price - buffer_price`

This keeps the underlying BE and trail calculations intact while moving the actual exit decision earlier.

### Trailing Tightening

`ATR Mult` remains the user fine-tuning control. The built-in mode factors are shifted to make `hard` materially tighter than the current implementation.

Recommended updated factors:

- `soft = 1.00`
- `medium = 0.65`
- `hard = 0.35`

This keeps the mode semantics intuitive while making `hard` useful for fast reversals.

### Close Aggression

The EA keeps using cycle-wide `PositionClose()` calls, but the close path should use a larger allowed deviation than normal order placement.

- breakout entry path keeps the current trading deviation
- cycle-close path gets its own close deviation constant

This does not change the trigger logic; it only reduces the chance that the close misses a short-lived favorable price because the execution tolerance is too narrow.

## UI Impact

Add one new input row:

- `Exit Buffer Pts`

No other new controls are required. Existing semantics stay the same:

- `ATR Mult` still affects trail distance immediately
- `BE Currency` still arms BE based on basket profit in account currency
- `PI Multiplier` still only affects newly built frames

## Files Expected To Change

- `MQL5/Experts/Exness_TradingBox_v1_001_MT5.mq5`
- `MQL5/Experts/Exness_TradingBox/TB_Config.mqh`
- `MQL5/Experts/Exness_TradingBox/TB_UI.mqh`
- `MQL5/Experts/Exness_TradingBox/TB_Trade.mqh`
- `MQL5/Experts/Exness_TradingBox/TB_Basket.mqh`
- `MQL5/Experts/Exness_TradingBox/TB_Analytics.mqh`
- `MQL5/Scripts/Exness_TradingBox_*SelfTest.mq5`

## Verification Strategy

- add a focused self-test for buffered exit-price behavior
- compile the new self-test to red first, then green
- run `.\scripts\build-and-deploy.ps1 -Compile`
- manual MT5 chart verification remains recommended after deployment

## Trade-Offs

- exits happen earlier, so some cycles will close with less peak profit
- more aggressive close deviation may worsen the final exit price in exchange for higher completion reliability
- a single shared exit buffer keeps UI simple but does not allow independent BE-vs-trail tuning
