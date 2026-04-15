#ifndef __TB_CONFIG_MQH__
#define __TB_CONFIG_MQH__

// Core EA metadata. The visible version is incremented as implementation evolves.
#define TB_EA_NAME_BASE      "Exness_TradingBox"
#define TB_EA_VERSION_MAJOR  1
#define TB_EA_VERSION_MINOR  3
#define TB_MAGIC_DEFAULT     2026041601
#define TB_OBJ_PREFIX        "TBX_"

#define TB_UI_LEFT           12
#define TB_UI_TOP            20
#define TB_UI_ROW_HEIGHT     22
#define TB_UI_ROW_GAP        6
#define TB_UI_LABEL_WIDTH    120
#define TB_UI_INPUT_WIDTH    110
#define TB_UI_PANEL_WIDTH    280

string TB_BuildEaDisplayName()
  {
   return StringFormat("%s_v%d_%03d_MT5",TB_EA_NAME_BASE,TB_EA_VERSION_MAJOR,TB_EA_VERSION_MINOR);
  }

#endif
