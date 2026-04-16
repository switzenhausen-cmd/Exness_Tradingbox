#property strict

#include "..\\Experts\\Exness_TradingBox\\TB_Config.mqh"
#include "..\\Experts\\Exness_TradingBox\\TB_State.mqh"
#include "..\\Experts\\Exness_TradingBox\\TB_UI.mqh"
#include "..\\Experts\\Exness_TradingBox\\TB_Analytics.mqh"

void OnStart()
  {
   Print(TB_TrailModeToAtrFactor(0));
   Print(TB_ClassifyRegime(10.0,5.0,20.0));
   Print(TB_ComputeVolaIndex(45.0,90.0));
  }
