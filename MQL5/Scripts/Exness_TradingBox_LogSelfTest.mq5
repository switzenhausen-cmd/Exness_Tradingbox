#property strict

#include "..\\Experts\\Exness_TradingBox\\TB_Config.mqh"
#include "..\\Experts\\Exness_TradingBox\\TB_State.mqh"
#include "..\\Experts\\Exness_TradingBox\\TB_UI.mqh"
#include "..\\Experts\\Exness_TradingBox\\TB_Basket.mqh"
#include "..\\Experts\\Exness_TradingBox\\TB_Log.mqh"

void OnStart()
  {
   TBCycleState state;
   TBRuntimeInputs inputs;
   TB_ResetCycleState(state);
   inputs.base_lot=0.10;
   state.cycle_id=42;
   Print(state.cycle_id);
   Print(inputs.base_lot);
   Print(TB_BuildLogFileName("XAUUSDm"));
   Print(TB_EnsureLogHeader("XAUUSDm"));
   Print(TB_BuildLogRow("entry_initial","unit_test",1,1,0.10,state,inputs));
   Print(TB_BuildFailureReason("manual_deactivate",10030,"unit_test"));
  }
