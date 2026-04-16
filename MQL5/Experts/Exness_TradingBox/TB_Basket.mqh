#ifndef __TB_BASKET_MQH__
#define __TB_BASKET_MQH__

bool TB_IsBasketManagedPosition(const ulong ticket)
  {
   if(!PositionSelectByTicket(ticket))
      return false;
   if(PositionGetString(POSITION_SYMBOL)!=_Symbol)
      return false;
   if((ulong)PositionGetInteger(POSITION_MAGIC)!=TB_MAGIC_DEFAULT)
      return false;
   return true;
  }

double TB_PositionPriceProfitAtTarget(const ENUM_POSITION_TYPE position_type,
                                      const double volume,
                                      const double open_price,
                                      const double target_price)
  {
   double profit=0.0;
   if(!OrderCalcProfit((position_type==POSITION_TYPE_BUY ? ORDER_TYPE_BUY : ORDER_TYPE_SELL),
                       _Symbol,
                       volume,
                       open_price,
                       target_price,
                       profit))
      return 0.0;
   return profit;
  }

double TB_PositionCurrentCosts(const ulong ticket)
  {
   if(!PositionSelectByTicket(ticket))
      return 0.0;

   double costs=PositionGetDouble(POSITION_SWAP);
#ifdef POSITION_COMMISSION
   costs+=PositionGetDouble(POSITION_COMMISSION);
#endif
   return costs;
  }

double TB_ComputeCycleOpenProfitCurrency()
  {
   double total=0.0;
   for(int index=PositionsTotal()-1; index>=0; --index)
     {
      const ulong ticket=PositionGetTicket(index);
      if(ticket==0 || !TB_IsBasketManagedPosition(ticket))
         continue;

      total+=PositionGetDouble(POSITION_PROFIT);
      total+=PositionGetDouble(POSITION_SWAP);
#ifdef POSITION_COMMISSION
      total+=PositionGetDouble(POSITION_COMMISSION);
#endif
     }
   return total;
  }

double TB_ComputeCycleProfitAtPrice(const double target_price)
  {
   double total=0.0;
   for(int index=PositionsTotal()-1; index>=0; --index)
     {
      const ulong ticket=PositionGetTicket(index);
      if(ticket==0 || !TB_IsBasketManagedPosition(ticket))
         continue;

      const ENUM_POSITION_TYPE position_type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      const double volume=PositionGetDouble(POSITION_VOLUME);
      const double open_price=PositionGetDouble(POSITION_PRICE_OPEN);
      total+=TB_PositionPriceProfitAtTarget(position_type,volume,open_price,target_price);
      total+=TB_PositionCurrentCosts(ticket);
     }
   return total;
  }

double TB_ComputeNetExposureLots()
  {
   double total=0.0;
   for(int index=PositionsTotal()-1; index>=0; --index)
     {
      const ulong ticket=PositionGetTicket(index);
      if(ticket==0 || !TB_IsBasketManagedPosition(ticket))
         continue;

      const ENUM_POSITION_TYPE position_type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      const double volume=PositionGetDouble(POSITION_VOLUME);
      if(position_type==POSITION_TYPE_BUY)
         total+=volume;
      else if(position_type==POSITION_TYPE_SELL)
         total-=volume;
     }
   return total;
  }

double TB_ComputeEffectiveLeverage()
  {
   const double equity=AccountInfoDouble(ACCOUNT_EQUITY);
   if(equity<=0.0)
      return 0.0;

   const double contract_size=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_CONTRACT_SIZE);
   double nominal=0.0;
   for(int index=PositionsTotal()-1; index>=0; --index)
     {
      const ulong ticket=PositionGetTicket(index);
      if(ticket==0 || !TB_IsBasketManagedPosition(ticket))
         continue;

      nominal+=PositionGetDouble(POSITION_VOLUME) * contract_size * PositionGetDouble(POSITION_PRICE_CURRENT);
     }
   return nominal / equity;
  }

bool TB_IsBeActivationReached(const TBRuntimeInputs &inputs)
  {
   return (TB_ComputeCycleOpenProfitCurrency() >= inputs.be_activation_currency);
  }

bool TB_TryComputeBasketReturnPrice(double &return_price)
  {
   return_price=0.0;
   const double net_lots=TB_ComputeNetExposureLots();
   if(MathAbs(net_lots) <= 0.0000001)
      return false;

   const double current_mid=(SymbolInfoDouble(_Symbol,SYMBOL_BID) + SymbolInfoDouble(_Symbol,SYMBOL_ASK)) * 0.5;
   const double current_profit=TB_ComputeCycleProfitAtPrice(current_mid);
   const double shifted_profit=TB_ComputeCycleProfitAtPrice(current_mid + _Point);
   const double slope_per_point=shifted_profit - current_profit;
   if(MathAbs(slope_per_point) <= 0.0000001)
      return false;

   const double points_to_break_even=(-current_profit / slope_per_point);
   return_price=NormalizeDouble(current_mid + points_to_break_even * _Point,_Digits);
   return true;
  }

double TB_ComputeBasketReturnPrice()
  {
   double return_price=0.0;
   if(!TB_TryComputeBasketReturnPrice(return_price))
      return 0.0;
   return return_price;
  }

bool TB_IsMarketAtBasketReturnPrice(const double return_price)
  {
   const double net_lots=TB_ComputeNetExposureLots();
   if(net_lots>0.0)
      return (SymbolInfoDouble(_Symbol,SYMBOL_BID) <= return_price);
   if(net_lots<0.0)
      return (SymbolInfoDouble(_Symbol,SYMBOL_ASK) >= return_price);
   return false;
  }

#endif
