#property strict
#property version   "1.006"

#include <Trade/Trade.mqh>
#include "Exness_TradingBox/TB_Config.mqh"
#include "Exness_TradingBox/TB_State.mqh"
#include "Exness_TradingBox/TB_UI.mqh"
#include "Exness_TradingBox/TB_Frame.mqh"
#include "Exness_TradingBox/TB_Trade.mqh"
#include "Exness_TradingBox/TB_Basket.mqh"
#include "Exness_TradingBox/TB_Analytics.mqh"

TBCycleState   g_cycle_state;
TBRuntimeInputs g_runtime_inputs;

int OnInit()
  {
   TB_ResetCycleState(g_cycle_state);
   TB_ReadChartInputs(g_runtime_inputs);
   TB_CreateChartUi();
   TB_UpdateInfoPanel(g_cycle_state,g_runtime_inputs,0.0,0.0);
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   TB_DestroyChartUi();
  }

void OnTick()
  {
   TB_ReadChartInputs(g_runtime_inputs);
   const double net_exposure=TB_ComputeNetExposureLots();
   const double current_leverage=TB_ComputeEffectiveLeverage();

   if(g_cycle_state.is_active && !g_cycle_state.be_armed && TB_IsBeActivationReached(g_runtime_inputs))
     {
      g_cycle_state.be_armed=true;
      TB_TryComputeBasketReturnPrice(g_cycle_state.basket_be_price);
     }

   if(g_cycle_state.is_active && g_cycle_state.be_armed)
     {
      TB_TryComputeBasketReturnPrice(g_cycle_state.basket_be_price);
      if(g_cycle_state.basket_be_price>0.0 && TB_IsMarketAtBasketReturnPrice(g_cycle_state.basket_be_price))
        {
         if(TB_CloseEntireCycle("basket_be_return"))
            TB_RebuildFrameAtMarket(g_cycle_state,g_runtime_inputs);
        }
     }

   TB_UpdateInfoPanel(g_cycle_state,g_runtime_inputs,net_exposure,current_leverage);
   TB_HandleBreakoutTrading(g_cycle_state,g_runtime_inputs);
  }

void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
  {
   if(TB_IsStartButtonEvent(id,sparam))
     {
      TB_ReadChartInputs(g_runtime_inputs);
      TB_RebuildFrameAtMarket(g_cycle_state,g_runtime_inputs);
      TB_UpdateInfoPanel(g_cycle_state,g_runtime_inputs,TB_ComputeNetExposureLots(),TB_ComputeEffectiveLeverage());
     }
  }
