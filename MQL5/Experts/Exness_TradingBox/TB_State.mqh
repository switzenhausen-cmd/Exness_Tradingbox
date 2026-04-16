#ifndef __TB_STATE_MQH__
#define __TB_STATE_MQH__

enum TBCycleRegime
  {
   TB_REGIME_RANGE=0,
   TB_REGIME_BULL=1,
   TB_REGIME_BEAR=2
  };

struct TBCycleState
  {
   bool     is_armed;
   bool     is_active;
   bool     be_armed;
   bool     trail_armed;
   int      leg_count;
   int      last_break_direction;
   double   frame_mid_price;
   double   frame_upper_price;
   double   frame_lower_price;
   double   frame_height_points;
   double   last_leg_lots;
   double   basket_be_price;
   double   cycle_trail_price;
  };

void TB_ResetCycleState(TBCycleState &state)
  {
   ZeroMemory(state);
   state.last_break_direction=0;
  }

#endif
