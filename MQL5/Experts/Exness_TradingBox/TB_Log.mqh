#ifndef __TB_LOG_MQH__
#define __TB_LOG_MQH__

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

#endif
