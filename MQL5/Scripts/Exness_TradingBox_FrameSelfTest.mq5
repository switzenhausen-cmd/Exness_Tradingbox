#property strict

#include "..\\Experts\\Exness_TradingBox\\TB_Config.mqh"
#include "..\\Experts\\Exness_TradingBox\\TB_State.mqh"
#include "..\\Experts\\Exness_TradingBox\\TB_UI.mqh"
#include "..\\Experts\\Exness_TradingBox\\TB_Frame.mqh"

void OnStart()
  {
   double points=TB_ComputeFrameHeightPoints(18.4,2.0);
   Print(points);
  }
