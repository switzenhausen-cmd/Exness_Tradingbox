#ifndef __TB_LOG_MQH__
#define __TB_LOG_MQH__

double TB_ComputeCycleOpenProfitCurrency();
double TB_ComputeNetExposureLots();

string TB_SanitizeCsvField(const string value)
  {
   string sanitized=value;
   StringReplace(sanitized,";","/");
   StringReplace(sanitized,"\r"," ");
   StringReplace(sanitized,"\n"," ");
   return sanitized;
  }

string TB_BuildFailureReason(const string base_reason,
                             const uint retcode,
                             const string retcode_description)
  {
   return StringFormat("%s|retcode=%u|%s",
                       TB_SanitizeCsvField(base_reason),
                       retcode,
                       TB_SanitizeCsvField(retcode_description));
  }

string TB_LogFolderName()
  {
   return "Exness_TradingBox";
  }

string TB_BuildLogFileName(const string symbol)
  {
   return TB_LogFolderName() + "\\" + TB_EA_NAME_BASE + "_" + symbol + ".csv";
  }

string TB_BuildLogHeader()
  {
   return "timestamp;symbol;timeframe;ea_name;cycle_id;event_type;event_reason;direction;leg_index;lots;base_lot;hedge_multiplier;pi_multiplier;be_currency;atr_multiplier;exit_buffer_points;trail_mode;frame_height_points;frame_mid_price;frame_upper_price;frame_lower_price;basket_profit;net_exposure;equity";
  }

bool TB_EnsureLogHeader(const string symbol)
  {
   FolderCreate(TB_LogFolderName());
   const string path=TB_BuildLogFileName(symbol);
   const bool exists=FileIsExist(path);
   const int handle=FileOpen(path,FILE_READ|FILE_WRITE|FILE_TXT|FILE_ANSI|FILE_SHARE_READ|FILE_SHARE_WRITE);
   if(handle==INVALID_HANDLE)
      return false;

   if(!exists || FileSize(handle)==0)
     {
      FileSeek(handle,0,SEEK_SET);
      FileWriteString(handle,TB_BuildLogHeader() + "\r\n");
     }

   FileClose(handle);
   return true;
  }

long TB_NextCycleId()
  {
   static long seed=0;
   if(seed<=0)
      seed=(long)TimeLocal() * 1000;
   seed++;
   return seed;
  }

string TB_TimeframeLabel()
  {
   if(_Period==PERIOD_M1) return "M1";
   if(_Period==PERIOD_M5) return "M5";
   if(_Period==PERIOD_M15) return "M15";
   if(_Period==PERIOD_M30) return "M30";
   if(_Period==PERIOD_H1) return "H1";
   if(_Period==PERIOD_H4) return "H4";
   if(_Period==PERIOD_D1) return "D1";
   return IntegerToString((int)_Period);
  }

string TB_LogDirectionLabel(const int direction)
  {
   if(direction>0)
      return "long";
   if(direction<0)
      return "short";
   return "flat";
  }

string TB_BuildLogRow(const string event_type,
                      const string event_reason,
                      const int direction,
                      const int leg_index,
                      const double lots,
                      const TBCycleState &state,
                      const TBRuntimeInputs &inputs)
  {
   return StringFormat("%s;%s;%s;%s;%I64d;%s;%s;%s;%d;%.2f;%.2f;%.2f;%.2f;%.2f;%.2f;%.2f;%d;%.1f;%.5f;%.5f;%.5f;%.2f;%.2f;%.2f",
                       TimeToString(TimeCurrent(),TIME_DATE|TIME_SECONDS),
                       _Symbol,
                       TB_TimeframeLabel(),
                       TB_SanitizeCsvField(TB_BuildEaDisplayName()),
                       state.cycle_id,
                       TB_SanitizeCsvField(event_type),
                       TB_SanitizeCsvField(event_reason),
                       TB_SanitizeCsvField(TB_LogDirectionLabel(direction)),
                       leg_index,
                       lots,
                       inputs.base_lot,
                       inputs.hedge_multiplier,
                       inputs.pi_multiplier,
                       inputs.be_activation_currency,
                       inputs.atr_multiplier,
                       inputs.exit_buffer_points,
                       inputs.trail_mode,
                       state.frame_height_points,
                       state.frame_mid_price,
                       state.frame_upper_price,
                       state.frame_lower_price,
                       TB_ComputeCycleOpenProfitCurrency(),
                       TB_ComputeNetExposureLots(),
                       AccountInfoDouble(ACCOUNT_EQUITY));
  }

bool TB_AppendLogRow(const string symbol,const string row)
  {
   if(!TB_EnsureLogHeader(symbol))
      return false;

   const string path=TB_BuildLogFileName(symbol);
   const int handle=FileOpen(path,FILE_READ|FILE_WRITE|FILE_TXT|FILE_ANSI|FILE_SHARE_READ|FILE_SHARE_WRITE);
   if(handle==INVALID_HANDLE)
      return false;

   FileSeek(handle,0,SEEK_END);
   FileWriteString(handle,row + "\r\n");
   FileClose(handle);
   return true;
  }

bool TB_LogEvent(const string event_type,
                 const string event_reason,
                 const int direction,
                 const int leg_index,
                 const double lots,
                 const TBCycleState &state,
                 const TBRuntimeInputs &inputs)
  {
   return TB_AppendLogRow(_Symbol,TB_BuildLogRow(event_type,event_reason,direction,leg_index,lots,state,inputs));
  }

#endif
