#ifndef __TB_FRAME_MQH__
#define __TB_FRAME_MQH__

string TB_FrameObjectName(const string suffix)
  {
   return TB_UiObjectName("FRAME_" + suffix);
  }

void TB_DeleteFrameObjects()
  {
   ObjectDelete(0,TB_FrameObjectName("MID"));
   ObjectDelete(0,TB_FrameObjectName("UPPER"));
   ObjectDelete(0,TB_FrameObjectName("LOWER"));
  }

double TB_CurrentMidPrice()
  {
   const double bid=SymbolInfoDouble(_Symbol,SYMBOL_BID);
   const double ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   return (bid + ask) * 0.5;
  }

double TB_ComputeFrameHeightPoints(const double spread_points,const double pi_multiplier)
  {
   return MathMax(1.0,MathRound(spread_points * TB_PI_VALUE * pi_multiplier));
  }

bool TB_DrawFrameLine(const string name,const double price,const color line_color)
  {
   if(ObjectFind(0,name)<0)
     {
      if(!ObjectCreate(0,name,OBJ_HLINE,0,0,price))
         return false;
     }
   ObjectSetDouble(0,name,OBJPROP_PRICE,price);
   ObjectSetInteger(0,name,OBJPROP_COLOR,line_color);
   ObjectSetInteger(0,name,OBJPROP_STYLE,STYLE_SOLID);
   ObjectSetInteger(0,name,OBJPROP_WIDTH,1);
   ObjectSetInteger(0,name,OBJPROP_BACK,false);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   return true;
  }

void TB_DrawFrameObjects(const TBCycleState &state)
  {
   if(state.frame_height_points<=0.0)
     {
      TB_DeleteFrameObjects();
      return;
     }

   TB_DrawFrameLine(TB_FrameObjectName("MID"),state.frame_mid_price,TB_FRAME_COLOR_MID);
   TB_DrawFrameLine(TB_FrameObjectName("UPPER"),state.frame_upper_price,TB_FRAME_COLOR_UP);
   TB_DrawFrameLine(TB_FrameObjectName("LOWER"),state.frame_lower_price,TB_FRAME_COLOR_DOWN);
   ChartRedraw(0);
  }

void TB_RebuildFrameAtMarket(TBCycleState &state,const TBRuntimeInputs &inputs)
  {
   const double spread_points=(double)SymbolInfoInteger(_Symbol,SYMBOL_SPREAD);
   const double frame_height_points=TB_ComputeFrameHeightPoints(spread_points,inputs.pi_multiplier);
   const double mid=TB_CurrentMidPrice();
   const double half_distance=(frame_height_points * _Point) * 0.5;

   state.is_armed=true;
   state.is_active=false;
   state.be_armed=false;
   state.trail_armed=false;
   state.leg_count=0;
   state.last_break_direction=0;
   state.last_leg_lots=0.0;
   state.basket_be_price=0.0;
   state.cycle_trail_price=0.0;
   state.frame_mid_price=mid;
   state.frame_height_points=frame_height_points;
   state.frame_upper_price=NormalizeDouble(mid + half_distance,_Digits);
   state.frame_lower_price=NormalizeDouble(mid - half_distance,_Digits);

   TB_DrawFrameObjects(state);
  }

int TB_DetectBreakoutDirection(const TBCycleState &state,const double bid,const double ask)
  {
   if(!state.is_armed || state.frame_height_points<=0.0)
      return 0;

   if(ask >= state.frame_upper_price)
      return 1;
   if(bid <= state.frame_lower_price)
      return -1;
   return 0;
  }

bool TB_CanOpenBreakForDirection(TBCycleState &state,const int breakout_direction)
  {
   if(breakout_direction==0)
      return false;
   if(state.last_break_direction==0)
      return true;
   return (state.last_break_direction!=breakout_direction);
  }

#endif
