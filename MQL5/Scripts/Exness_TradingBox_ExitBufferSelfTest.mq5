#property strict

#include "..\\Experts\\Exness_TradingBox\\TB_Config.mqh"
#include "..\\Experts\\Exness_TradingBox\\TB_State.mqh"
#include "..\\Experts\\Exness_TradingBox\\TB_UI.mqh"
#include "..\\Experts\\Exness_TradingBox\\TB_Basket.mqh"

void OnStart()
  {
   TBRuntimeInputs inputs;
   inputs.exit_buffer_points=12.0;
   Print(inputs.exit_buffer_points);
   Print(TB_ApplyExitBufferPrice(1.10000,12.0,1));
  }
