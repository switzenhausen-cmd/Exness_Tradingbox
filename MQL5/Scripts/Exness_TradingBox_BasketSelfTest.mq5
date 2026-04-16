#property strict

#include "..\\Experts\\Exness_TradingBox\\TB_Config.mqh"
#include "..\\Experts\\Exness_TradingBox\\TB_State.mqh"
#include "..\\Experts\\Exness_TradingBox\\TB_UI.mqh"
#include "..\\Experts\\Exness_TradingBox\\TB_Basket.mqh"

void OnStart()
  {
   double net_lots=TB_ComputeNetExposureLots();
   double be_price=TB_ComputeBasketReturnPrice();
   Print(net_lots," ",be_price);
  }
