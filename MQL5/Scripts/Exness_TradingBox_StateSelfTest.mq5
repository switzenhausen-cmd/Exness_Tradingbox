#property strict

#include "..\\Experts\\Exness_TradingBox\\TB_Config.mqh"
#include "..\\Experts\\Exness_TradingBox\\TB_State.mqh"

void OnStart()
  {
   TBCycleState state;
   TB_ResetCycleState(state);
   Print(TB_BuildEaDisplayName());
   Print(state.is_active);
  }
