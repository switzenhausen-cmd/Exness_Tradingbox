#ifndef __TB_TRADE_MQH__
#define __TB_TRADE_MQH__

#include <Trade/Trade.mqh>

CTrade g_tb_trade;

void TB_ConfigureTradeContext()
  {
   g_tb_trade.SetExpertMagicNumber(TB_MAGIC_DEFAULT);
   g_tb_trade.SetDeviationInPoints(TB_DEFAULT_DEVIATION_POINTS);
  }

bool TB_IsManagedPosition(const ulong ticket)
  {
   if(!PositionSelectByTicket(ticket))
      return false;
   if(PositionGetString(POSITION_SYMBOL)!=_Symbol)
      return false;
   if((ulong)PositionGetInteger(POSITION_MAGIC)!=TB_MAGIC_DEFAULT)
      return false;
   return true;
  }

int TB_CountManagedPositions()
  {
   int count=0;
   for(int index=PositionsTotal()-1; index>=0; --index)
     {
      const ulong ticket=PositionGetTicket(index);
      if(ticket==0)
         continue;
      if(TB_IsManagedPosition(ticket))
         ++count;
     }
   return count;
  }

double TB_NormalizeLots(const double requested_lots)
  {
   const double min_lot=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
   const double max_lot=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MAX);
   const double step=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);

   double lots=MathMax(min_lot,MathMin(max_lot,requested_lots));
   if(step>0.0)
      lots=MathFloor(lots / step) * step;
   lots=NormalizeDouble(lots,2);
   return MathMax(min_lot,lots);
  }

double TB_ComputeNextLegLots(const TBCycleState &state,const TBRuntimeInputs &inputs)
  {
   if(state.leg_count<=0)
      return TB_NormalizeLots(inputs.base_lot);
   return TB_NormalizeLots(state.last_leg_lots * inputs.hedge_multiplier);
  }

void TB_LogTradeFailure(const string action)
  {
   Print(action,
         " failed. retcode=",
         g_tb_trade.ResultRetcode(),
         " desc=",
         g_tb_trade.ResultRetcodeDescription());
  }

bool TB_OpenTradeByDirection(const int direction,const double lots,const string comment)
  {
   TB_ConfigureTradeContext();

   if(direction>0)
     {
      if(g_tb_trade.Buy(lots,_Symbol,0.0,0.0,0.0,comment))
         return true;
      TB_LogTradeFailure("Buy");
      return false;
     }

   if(g_tb_trade.Sell(lots,_Symbol,0.0,0.0,0.0,comment))
      return true;
   TB_LogTradeFailure("Sell");
   return false;
  }

bool TB_OpenInitialBreakTrade(TBCycleState &state,const int direction,const TBRuntimeInputs &inputs)
  {
   const double lots=TB_ComputeNextLegLots(state,inputs);
   if(!TB_OpenTradeByDirection(direction,lots,"TB initial break"))
      return false;

   state.is_active=true;
   state.last_break_direction=direction;
   state.leg_count=1;
   state.last_leg_lots=lots;
   return true;
  }

bool TB_OpenHedgeLeg(TBCycleState &state,const int direction,const TBRuntimeInputs &inputs)
  {
   const double lots=TB_ComputeNextLegLots(state,inputs);
   if(!TB_OpenTradeByDirection(direction,lots,"TB hedge leg"))
      return false;

   state.is_active=true;
   state.last_break_direction=direction;
   state.leg_count++;
   state.last_leg_lots=lots;
   state.be_armed=false;
   state.trail_armed=false;
   return true;
  }

bool TB_CloseEntireCycle(const string reason)
  {
   bool all_closed=true;
   TB_ConfigureTradeContext();
   for(int index=PositionsTotal()-1; index>=0; --index)
     {
      const ulong ticket=PositionGetTicket(index);
      if(ticket==0)
         continue;
      if(!TB_IsManagedPosition(ticket))
         continue;
      if(!g_tb_trade.PositionClose(ticket))
        {
         Print("Close cycle failed for ",ticket," reason=",reason,
               " retcode=",g_tb_trade.ResultRetcode(),
               " desc=",g_tb_trade.ResultRetcodeDescription());
         all_closed=false;
        }
     }
   return all_closed;
  }

void TB_HandleBreakoutTrading(TBCycleState &state,const TBRuntimeInputs &inputs)
  {
   if(!state.is_armed || state.frame_height_points<=0.0)
      return;

   const double bid=SymbolInfoDouble(_Symbol,SYMBOL_BID);
   const double ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   const int breakout_direction=TB_DetectBreakoutDirection(state,bid,ask);
   if(!TB_CanOpenBreakForDirection(state,breakout_direction))
      return;

   if(TB_CountManagedPositions()<=0)
      TB_OpenInitialBreakTrade(state,breakout_direction,inputs);
   else
      TB_OpenHedgeLeg(state,breakout_direction,inputs);
  }

#endif
