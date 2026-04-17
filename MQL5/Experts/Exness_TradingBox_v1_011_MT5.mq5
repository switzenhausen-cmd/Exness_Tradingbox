#property strict
#property version   "1.011"

#include <Trade/Trade.mqh>
#include "Exness_TradingBox/TB_Config.mqh"
#include "Exness_TradingBox/TB_State.mqh"
#include "Exness_TradingBox/TB_UI.mqh"
#include "Exness_TradingBox/TB_Basket.mqh"
#include "Exness_TradingBox/TB_Analytics.mqh"
#include "Exness_TradingBox/TB_Log.mqh"
#include "Exness_TradingBox/TB_Frame.mqh"
#include "Exness_TradingBox/TB_Trade.mqh"

TBCycleState   g_cycle_state;
TBRuntimeInputs g_runtime_inputs;

void TB_RefreshUiAndAnalytics()
  {
   TB_ReadChartInputs(g_runtime_inputs);
   const bool is_running=(g_cycle_state.is_armed || g_cycle_state.is_active || TB_CountManagedPositions()>0);
   const double net_exposure=TB_ComputeNetExposureLots();
   const double current_leverage=TB_ComputeEffectiveLeverage();
   const double atr_points=TB_ReadAtrPoints(TB_ATR_PERIOD);
   const double ema_fast=TB_ReadEmaPrice(TB_EMA_FAST_PERIOD);
   const double ema_slow=TB_ReadEmaPrice(TB_EMA_SLOW_PERIOD);
   const int regime=TB_ClassifyRegime(ema_fast,ema_slow,atr_points);
   const string regime_label=TB_RegimeToString(regime);
   const double vola_index=TB_ComputeVolaIndex(atr_points,g_cycle_state.frame_height_points);

   TB_SetToggleButtonState(is_running);
   TB_UpdateInfoPanel(g_cycle_state,g_runtime_inputs,net_exposure,current_leverage,regime_label,vola_index);
  }

int OnInit()
  {
   TB_ResetCycleState(g_cycle_state);
   TB_ReadChartInputs(g_runtime_inputs);
   TB_CreateChartUi();
   EventSetTimer(1);
   TB_RefreshUiAndAnalytics();
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   EventKillTimer();
   TB_DestroyChartUi();
  }

void OnTick()
  {
   const double net_exposure=TB_ComputeNetExposureLots();
   TB_ReadChartInputs(g_runtime_inputs);

   if(g_cycle_state.is_active && !g_cycle_state.be_armed && TB_IsBeActivationReached(g_runtime_inputs))
     {
      g_cycle_state.be_armed=true;
      TB_TryComputeBasketReturnPrice(g_cycle_state.basket_be_price);
     }

   if(g_cycle_state.is_active && g_cycle_state.be_armed)
     {
      TB_TryComputeBasketReturnPrice(g_cycle_state.basket_be_price);
      const int be_exit_direction=(net_exposure>0.0 ? 1 : (net_exposure<0.0 ? -1 : 0));
      if(g_cycle_state.basket_be_price>0.0 &&
         TB_IsMarketAtBufferedExitPrice(g_cycle_state.basket_be_price,
                                        g_runtime_inputs.exit_buffer_points,
                                        be_exit_direction))
        {
         if(TB_CloseEntireCycle(g_cycle_state,g_runtime_inputs,"basket_be_return"))
            TB_RebuildFrameAtMarket(g_cycle_state,g_runtime_inputs);
        }
     }

   if(g_cycle_state.is_active && g_cycle_state.be_armed && TB_ComputeCycleOpenProfitCurrency()>0.0)
     {
      double next_trail_price=0.0;
      if(TB_TryComputeCycleTrailPrice(g_cycle_state,g_runtime_inputs,net_exposure,next_trail_price))
        {
         g_cycle_state.trail_armed=true;
         g_cycle_state.cycle_trail_price=next_trail_price;
         const int trail_exit_direction=(net_exposure>0.0 ? 1 : (net_exposure<0.0 ? -1 : 0));
         if(TB_IsMarketAtBufferedExitPrice(g_cycle_state.cycle_trail_price,
                                           g_runtime_inputs.exit_buffer_points,
                                           trail_exit_direction))
           {
            if(TB_CloseEntireCycle(g_cycle_state,g_runtime_inputs,"cycle_trail"))
               TB_RebuildFrameAtMarket(g_cycle_state,g_runtime_inputs);
           }
        }
     }

   TB_RefreshUiAndAnalytics();
   TB_HandleBreakoutTrading(g_cycle_state,g_runtime_inputs);
  }

void OnTimer()
  {
   TB_RefreshUiAndAnalytics();
  }

void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
  {
   if(TB_IsStartButtonEvent(id,sparam))
     {
      TB_ReadChartInputs(g_runtime_inputs);
      const int managed_positions=TB_CountManagedPositions();
      const bool is_running=(g_cycle_state.is_armed || g_cycle_state.is_active || managed_positions>0);

      if(is_running)
        {
         bool closed_all=true;
         if(managed_positions>0)
            closed_all=TB_CloseEntireCycle(g_cycle_state,g_runtime_inputs,"manual_deactivate");

         if(closed_all && TB_CountManagedPositions()==0)
            TB_SetCycleIdle(g_cycle_state);
        }
      else
        {
         TB_RebuildFrameAtMarket(g_cycle_state,g_runtime_inputs);
        }

      TB_RefreshUiAndAnalytics();
     }
  }
