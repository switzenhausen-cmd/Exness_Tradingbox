#ifndef __TB_UI_MQH__
#define __TB_UI_MQH__

struct TBRuntimeInputs
  {
   double base_lot;
   double pi_multiplier;
   double hedge_multiplier;
   double be_activation_currency;
   double atr_multiplier;
   int    trail_mode;
  };

string TB_UiObjectName(const string suffix)
  {
   return TB_OBJ_PREFIX + suffix;
  }

int TB_UiRowTop(const int row_index)
  {
   return TB_UI_TOP + row_index * (TB_UI_ROW_HEIGHT + TB_UI_ROW_GAP);
  }

void TB_DeleteChartUiObjects()
  {
   const int total=ObjectsTotal(0,0,-1);
   for(int index=total-1; index>=0; --index)
     {
      string name=ObjectName(0,index,0,-1);
      if(StringFind(name,TB_OBJ_PREFIX,0)==0)
         ObjectDelete(0,name);
     }
  }

bool TB_CreateLabel(const string name,const string text,const int x,const int y,const int width)
  {
   if(!ObjectCreate(0,name,OBJ_LABEL,0,0,0))
      return false;
   ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,name,OBJPROP_XSIZE,width);
   ObjectSetInteger(0,name,OBJPROP_YSIZE,TB_UI_ROW_HEIGHT);
   ObjectSetInteger(0,name,OBJPROP_COLOR,clrWhite);
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,9);
   ObjectSetString(0,name,OBJPROP_FONT,"Consolas");
   ObjectSetString(0,name,OBJPROP_TEXT,text);
   return true;
  }

bool TB_CreateEdit(const string name,const string value,const int x,const int y)
  {
   if(!ObjectCreate(0,name,OBJ_EDIT,0,0,0))
      return false;
   ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,name,OBJPROP_XSIZE,TB_UI_INPUT_WIDTH);
   ObjectSetInteger(0,name,OBJPROP_YSIZE,TB_UI_ROW_HEIGHT);
   ObjectSetInteger(0,name,OBJPROP_BGCOLOR,clrBlack);
   ObjectSetInteger(0,name,OBJPROP_COLOR,clrWhite);
   ObjectSetInteger(0,name,OBJPROP_BORDER_COLOR,clrSilver);
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,9);
   ObjectSetString(0,name,OBJPROP_FONT,"Consolas");
   ObjectSetString(0,name,OBJPROP_TEXT,value);
   return true;
  }

bool TB_CreateButton(const string name,const string text,const int x,const int y,const int width)
  {
   if(!ObjectCreate(0,name,OBJ_BUTTON,0,0,0))
      return false;
   ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,name,OBJPROP_XSIZE,width);
   ObjectSetInteger(0,name,OBJPROP_YSIZE,TB_UI_ROW_HEIGHT + 2);
   ObjectSetInteger(0,name,OBJPROP_BGCOLOR,clrDarkSlateGray);
   ObjectSetInteger(0,name,OBJPROP_COLOR,clrWhite);
   ObjectSetInteger(0,name,OBJPROP_BORDER_COLOR,clrSilver);
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,9);
   ObjectSetString(0,name,OBJPROP_FONT,"Consolas");
   ObjectSetString(0,name,OBJPROP_TEXT,text);
   return true;
  }

double TB_ParseDoubleInput(const string name,const double fallback)
  {
   string raw=ObjectGetString(0,name,OBJPROP_TEXT);
   double parsed=StringToDouble(raw);
   if(parsed<=0.0)
      return fallback;
   return parsed;
  }

int TB_ParseTrailModeInput(const string name,const int fallback)
  {
   string raw=ObjectGetString(0,name,OBJPROP_TEXT);
   StringTrimLeft(raw);
   StringTrimRight(raw);
   string normalized=raw;
   StringToLower(normalized);
   if(normalized=="soft" || normalized=="0")
      return 0;
   if(normalized=="hard" || normalized=="2")
      return 2;
   if(normalized=="medium" || normalized=="1")
      return 1;
   return fallback;
  }

bool TB_CreateChartUi()
  {
   TB_DeleteChartUiObjects();

   const int base_left=TB_UI_LEFT;
   const int label_left=base_left;
   const int input_left=base_left + TB_UI_LABEL_WIDTH + 8;
   const int info_left=input_left + TB_UI_INPUT_WIDTH + 28;

   bool ok=true;
   ok = ok && TB_CreateButton(TB_UiObjectName("START"),"Start Cycle",base_left,TB_UiRowTop(0),TB_UI_LABEL_WIDTH + TB_UI_INPUT_WIDTH + 8);

   ok = ok && TB_CreateLabel(TB_UiObjectName("LBL_LOT"),"Base Lot",label_left,TB_UiRowTop(1),TB_UI_LABEL_WIDTH);
   ok = ok && TB_CreateEdit(TB_UiObjectName("INP_LOT"),"0.10",input_left,TB_UiRowTop(1));
   ok = ok && TB_CreateLabel(TB_UiObjectName("LBL_PI"),"PI Multiplier",label_left,TB_UiRowTop(2),TB_UI_LABEL_WIDTH);
   ok = ok && TB_CreateEdit(TB_UiObjectName("INP_PI"),"2.00",input_left,TB_UiRowTop(2));
   ok = ok && TB_CreateLabel(TB_UiObjectName("LBL_HEDGE"),"Hedge Mult",label_left,TB_UiRowTop(3),TB_UI_LABEL_WIDTH);
   ok = ok && TB_CreateEdit(TB_UiObjectName("INP_HEDGE"),"2.00",input_left,TB_UiRowTop(3));
   ok = ok && TB_CreateLabel(TB_UiObjectName("LBL_BE"),"BE Currency",label_left,TB_UiRowTop(4),TB_UI_LABEL_WIDTH);
   ok = ok && TB_CreateEdit(TB_UiObjectName("INP_BE"),"10.00",input_left,TB_UiRowTop(4));
   ok = ok && TB_CreateLabel(TB_UiObjectName("LBL_ATR"),"ATR Mult",label_left,TB_UiRowTop(5),TB_UI_LABEL_WIDTH);
   ok = ok && TB_CreateEdit(TB_UiObjectName("INP_ATR"),"1.00",input_left,TB_UiRowTop(5));
   ok = ok && TB_CreateLabel(TB_UiObjectName("LBL_MODE"),"Trail Mode",label_left,TB_UiRowTop(6),TB_UI_LABEL_WIDTH);
   ok = ok && TB_CreateEdit(TB_UiObjectName("INP_MODE"),"medium",input_left,TB_UiRowTop(6));

   ok = ok && TB_CreateLabel(TB_UiObjectName("INFO_NAME"),"EA: " + TB_BuildEaDisplayName(),info_left,TB_UiRowTop(0),TB_UI_PANEL_WIDTH);
   ok = ok && TB_CreateLabel(TB_UiObjectName("INFO_NET"),"Net Exposure: 0.00",info_left,TB_UiRowTop(1),TB_UI_PANEL_WIDTH);
   ok = ok && TB_CreateLabel(TB_UiObjectName("INFO_REGIME"),"Regime: Range",info_left,TB_UiRowTop(2),TB_UI_PANEL_WIDTH);
   ok = ok && TB_CreateLabel(TB_UiObjectName("INFO_VOLA"),"Vola Index: 0.00",info_left,TB_UiRowTop(3),TB_UI_PANEL_WIDTH);
   ok = ok && TB_CreateLabel(TB_UiObjectName("INFO_LEVERAGE"),"Current Leverage: 0.00",info_left,TB_UiRowTop(4),TB_UI_PANEL_WIDTH);
   ok = ok && TB_CreateLabel(TB_UiObjectName("INFO_SPREAD"),"Spread: 0.00",info_left,TB_UiRowTop(5),TB_UI_PANEL_WIDTH);
   ok = ok && TB_CreateLabel(TB_UiObjectName("INFO_FRAME"),"Frame Height: 0.00",info_left,TB_UiRowTop(6),TB_UI_PANEL_WIDTH);

   ChartRedraw(0);
   return ok;
  }

void TB_DestroyChartUi()
  {
   TB_DeleteChartUiObjects();
   ChartRedraw(0);
  }

bool TB_ReadChartInputs(TBRuntimeInputs &inputs)
  {
   inputs.base_lot=TB_ParseDoubleInput(TB_UiObjectName("INP_LOT"),0.10);
   inputs.pi_multiplier=TB_ParseDoubleInput(TB_UiObjectName("INP_PI"),2.00);
   inputs.hedge_multiplier=TB_ParseDoubleInput(TB_UiObjectName("INP_HEDGE"),2.00);
   inputs.be_activation_currency=TB_ParseDoubleInput(TB_UiObjectName("INP_BE"),10.00);
   inputs.atr_multiplier=TB_ParseDoubleInput(TB_UiObjectName("INP_ATR"),1.00);
   inputs.trail_mode=TB_ParseTrailModeInput(TB_UiObjectName("INP_MODE"),1);
   return true;
  }

bool TB_IsStartButtonEvent(const int id,const string &sparam)
  {
   return (id==CHARTEVENT_OBJECT_CLICK && sparam==TB_UiObjectName("START"));
  }

void TB_UpdateInfoPanel(const TBCycleState &state,
                        const TBRuntimeInputs &inputs,
                        const double net_exposure_lots,
                        const double current_leverage,
                        const string regime_label,
                        const double vola_index)
  {
   ObjectSetString(0,TB_UiObjectName("INFO_NAME"),OBJPROP_TEXT,"EA: " + TB_BuildEaDisplayName());
   ObjectSetString(0,TB_UiObjectName("INFO_NET"),OBJPROP_TEXT,StringFormat("Net Exposure: %.2f",net_exposure_lots));
   ObjectSetString(0,TB_UiObjectName("INFO_REGIME"),OBJPROP_TEXT,"Regime: " + regime_label);
   ObjectSetString(0,TB_UiObjectName("INFO_VOLA"),OBJPROP_TEXT,StringFormat("Vola Index: %.2f",vola_index));
   ObjectSetString(0,TB_UiObjectName("INFO_LEVERAGE"),OBJPROP_TEXT,StringFormat("Current Leverage: %.2f",current_leverage));
   ObjectSetString(0,TB_UiObjectName("INFO_SPREAD"),OBJPROP_TEXT,StringFormat("Spread: %.1f",SymbolInfoInteger(_Symbol,SYMBOL_SPREAD) * 1.0));
   ObjectSetString(0,TB_UiObjectName("INFO_FRAME"),OBJPROP_TEXT,StringFormat("Frame Height: %.1f",state.frame_height_points));
   ObjectSetString(0,TB_UiObjectName("LBL_MODE"),OBJPROP_TEXT,StringFormat("Trail Mode (%d)",inputs.trail_mode));
  }

#endif
