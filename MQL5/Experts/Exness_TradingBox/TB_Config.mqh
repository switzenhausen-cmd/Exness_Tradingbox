#ifndef __TB_CONFIG_MQH__
#define __TB_CONFIG_MQH__

// Core EA metadata. The visible version is incremented as implementation evolves.
#define TB_EA_NAME_BASE      "Exness_TradingBox"
#define TB_EA_VERSION_MAJOR  1
#define TB_EA_VERSION_MINOR  8
#define TB_MAGIC_DEFAULT     2026041601
#define TB_OBJ_PREFIX        "TBX_"
#define TB_PI_VALUE          3.14159265358979323846
#define TB_DEFAULT_DEVIATION_POINTS 30
#define TB_ATR_PERIOD        14
#define TB_EMA_FAST_PERIOD   21
#define TB_EMA_SLOW_PERIOD   55

#define TB_UI_LEFT           12
#define TB_UI_TOP            20
#define TB_UI_ROW_HEIGHT     22
#define TB_UI_ROW_GAP        6
#define TB_UI_LABEL_WIDTH    120
#define TB_UI_INPUT_WIDTH    110
#define TB_UI_PANEL_WIDTH    280
#define TB_FRAME_COLOR_MID   clrSilver
#define TB_FRAME_COLOR_UP    clrLimeGreen
#define TB_FRAME_COLOR_DOWN  clrTomato

string TB_BuildEaDisplayName()
  {
   return StringFormat("%s_v%d_%03d_MT5",TB_EA_NAME_BASE,TB_EA_VERSION_MAJOR,TB_EA_VERSION_MINOR);
  }

#endif
