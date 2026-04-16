#property strict

#include "..\\Experts\\Exness_TradingBox\\TB_Config.mqh"
#include "..\\Experts\\Exness_TradingBox\\TB_State.mqh"
#include "..\\Experts\\Exness_TradingBox\\TB_UI.mqh"
#include "..\\Experts\\Exness_TradingBox\\TB_Frame.mqh"

void OnStart()
  {
   TBCycleState state;
   TB_ResetCycleState(state);
   state.is_armed=true;
   state.is_active=true;
   state.frame_height_points=42.0;
   state.frame_mid_price=1.12345;

   TB_SetCycleIdle(state);

   Print(state.is_armed," ",state.is_active," ",state.frame_height_points," ",state.frame_mid_price);
  }
