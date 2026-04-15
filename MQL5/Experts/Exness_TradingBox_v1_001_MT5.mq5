#property strict
#property version   "1.001"

#include <Trade/Trade.mqh>
#include "Exness_TradingBox/TB_Config.mqh"
#include "Exness_TradingBox/TB_State.mqh"
#include "Exness_TradingBox/TB_UI.mqh"
#include "Exness_TradingBox/TB_Frame.mqh"
#include "Exness_TradingBox/TB_Trade.mqh"
#include "Exness_TradingBox/TB_Basket.mqh"
#include "Exness_TradingBox/TB_Analytics.mqh"

int OnInit()
  {
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
  }

void OnTick()
  {
  }
