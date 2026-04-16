#ifndef __TB_ANALYTICS_MQH__
#define __TB_ANALYTICS_MQH__

#define TB_TRAIL_FACTOR_SOFT    1.00
#define TB_TRAIL_FACTOR_MEDIUM  0.65
#define TB_TRAIL_FACTOR_HARD    0.35

double TB_ReadIndicatorValue(const int handle)
  {
   if(handle==INVALID_HANDLE)
      return 0.0;

   double values[];
   ArraySetAsSeries(values,true);
   if(CopyBuffer(handle,0,0,1,values)<=0)
      return 0.0;
   return values[0];
  }

double TB_ReadAtrPoints(const int period)
  {
   const int handle=iATR(_Symbol,_Period,period);
   const double atr_price=TB_ReadIndicatorValue(handle);
   if(handle!=INVALID_HANDLE)
      IndicatorRelease(handle);
   if(_Point<=0.0)
      return 0.0;
   return atr_price / _Point;
  }

double TB_ReadEmaPrice(const int period)
  {
   const int handle=iMA(_Symbol,_Period,period,0,MODE_EMA,PRICE_CLOSE);
   const double ema_price=TB_ReadIndicatorValue(handle);
   if(handle!=INVALID_HANDLE)
      IndicatorRelease(handle);
   return ema_price;
  }

double TB_TrailModeToAtrFactor(const int mode)
  {
   if(mode==0)
      return TB_TRAIL_FACTOR_SOFT;
   if(mode==2)
      return TB_TRAIL_FACTOR_HARD;
   return TB_TRAIL_FACTOR_MEDIUM;
  }

int TB_ClassifyRegime(const double ema_fast,const double ema_slow,const double atr_points)
  {
   const double ema_distance_points=MathAbs(ema_fast-ema_slow) / _Point;
   const double range_threshold=MathMax(1.0,atr_points * 0.15);
   if(ema_distance_points<=range_threshold)
      return TB_REGIME_RANGE;
   if(ema_fast>ema_slow)
      return TB_REGIME_BULL;
   return TB_REGIME_BEAR;
  }

string TB_RegimeToString(const int regime)
  {
   if(regime==TB_REGIME_BULL)
      return "Bull";
   if(regime==TB_REGIME_BEAR)
      return "Bear";
   return "Range";
  }

double TB_ComputeVolaIndex(const double atr_points,const double frame_height_points)
  {
   if(frame_height_points<=0.0)
      return 0.0;
   return (atr_points / frame_height_points) * 100.0;
  }

bool TB_TryComputeCycleTrailPrice(const TBCycleState &state,
                                  const TBRuntimeInputs &inputs,
                                  const double net_exposure_lots,
                                  double &trail_price)
  {
   trail_price=0.0;
   if(MathAbs(net_exposure_lots)<=0.0000001)
      return false;

   const double atr_points=TB_ReadAtrPoints(TB_ATR_PERIOD);
   if(atr_points<=0.0)
      return false;

   const double trail_distance_price=atr_points * TB_TrailModeToAtrFactor(inputs.trail_mode) * inputs.atr_multiplier * _Point;
   if(trail_distance_price<=0.0)
      return false;

   if(net_exposure_lots>0.0)
     {
      const double candidate=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID) - trail_distance_price,_Digits);
      trail_price=(state.trail_armed ? MathMax(state.cycle_trail_price,candidate) : candidate);
      return true;
     }

   const double candidate=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK) + trail_distance_price,_Digits);
   trail_price=(state.trail_armed ? MathMin(state.cycle_trail_price,candidate) : candidate);
   return true;
  }

bool TB_IsMarketAtCycleTrailPrice(const double trail_price,const double net_exposure_lots)
  {
   if(trail_price<=0.0)
      return false;
   if(net_exposure_lots>0.0)
      return (SymbolInfoDouble(_Symbol,SYMBOL_BID) <= trail_price);
   if(net_exposure_lots<0.0)
      return (SymbolInfoDouble(_Symbol,SYMBOL_ASK) >= trail_price);
   return false;
  }

#endif
