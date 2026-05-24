//+------------------------------------------------------------------+
//|                                          HullPullbackAlpha.mq5   |
//|                                    Copyright 2026, InSilico / AI |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright   "Copyright 2026, InSilico / AI"
#property link        "https://www.mql5.com"
#property version     "1.00"
#property description "Hull Pullback Alpha - Multi-Timeframe Trend Pullback EA for Index CFDs"

//--- Includes
#include <Trade\Trade.mqh>

//--- Custom Enums (matching HullSuite)
enum ENUM_HULL_MODE
{
   HULL_MODE_HMA  = 0,  // Hma
   HULL_MODE_EHMA = 1,  // Ehma
   HULL_MODE_THMA = 2   // Thma
};

//--- Input Parameters
input group "=== EXPLAINER ==="
input string             InpNote             = "Trades ONLY buy setups on indices. Safe for 5:1 leverage."; // Strategy Note

input group "=== EA RISK MANAGEMENT ==="
input bool               InpUseDynamicLot    = true;             // Use dynamic risk-based lot sizing?
input double             InpRiskPercent      = 1.0;              // Risk % of Equity per trade
input double             InpMaxMarginPercent = 15.0;             // Max margin usage % of Equity
input double             InpFixedLot         = 0.01;             // Fixed lot size if dynamic is false
input ulong              InpMagicNumber      = 80085;            // EA Magic Number

input group "=== HULL SUITE FILTER (D1) ==="
input ENUM_APPLIED_PRICE InpSource           = PRICE_CLOSE;      // Price Source for Hull
input int                InpSlowLength       = 55;               // D1 Slow Hull Length (Trend Filter)
input string             InpIndicatorName    = "HullSuite";      // Indicator Name in MQL5/Indicators

input group "=== HULL SUITE TRIGGER ==="
input ENUM_TIMEFRAMES    InpExecutionTimeframe = PERIOD_H4;      // Execution Timeframe (H4 recommended)
input int                InpFastLength       = 21;               // Trigger Timeframe Fast Hull Length

input group "=== STOP LOSS & TAKE PROFIT ==="
input double             InpStopLossAtrMult  = 1.5;              // Stop Loss ATR Multiplier
input double             InpRewardRatio      = 2.0;              // Take Profit R:R Ratio (e.g. 2.0x SL)

//--- Global Handles
int hSlowHull = INVALID_HANDLE;
int hFastHull = INVALID_HANDLE;
int hAtr      = INVALID_HANDLE;

//--- Global Variables
CTrade trade;

//+------------------------------------------------------------------+
//| Expert Initialization Function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   //--- Validate Risk Parameters
   if(InpRiskPercent <= 0 || InpRiskPercent > 10.0)
   {
      Alert("Hull EA: Risk percent must be between 0.1% and 10%!");
      return INIT_PARAMETERS_INCORRECT;
   }
   
   if(InpMaxMarginPercent <= 0 || InpMaxMarginPercent > 50.0)
   {
      Alert("Hull EA: Max margin usage percent must be between 1% and 50%!");
      return INIT_PARAMETERS_INCORRECT;
   }
   
   //--- Initialize CTrade Magic Number
   trade.SetExpertMagicNumber(InpMagicNumber);
   trade.SetDeviationInPoints(10);
   
   //--- Create Custom Indicator Handles
   // 1. Slow Hull on Daily (D1) timeframe
   hSlowHull = iCustom(_Symbol, PERIOD_D1, InpIndicatorName, 
                       InpSource,         // Price Source
                       HULL_MODE_HMA,     // Mode Hma
                       InpSlowLength,     // Slow Length (55)
                       1.0,               // Length Mult
                       false,             // Use HTF (false because we load D1 directly)
                       PERIOD_H4,         // HTF Timeframe (dummy)
                       true,              // Switch Color
                       false,             // Candle Color
                       true,              // Show Band
                       1                  // Thickness
                       );
                       
   // 2. Fast Hull on Execution Timeframe (e.g., H4)
   hFastHull = iCustom(_Symbol, InpExecutionTimeframe, InpIndicatorName, 
                       InpSource,         // Price Source
                       HULL_MODE_HMA,     // Mode Hma
                       InpFastLength,     // Fast Length (21)
                       1.0,               // Length Mult
                       false,             // Use HTF (false)
                       PERIOD_H4,         // HTF Timeframe (dummy)
                       true,              // Switch Color
                       false,             // Candle Color
                       true,              // Show Band
                       1                  // Thickness
                       );
                       
   // 3. ATR on Execution Timeframe
   hAtr = iATR(_Symbol, InpExecutionTimeframe, 14);
   
   //--- Validate Handles
   if(hSlowHull == INVALID_HANDLE || hFastHull == INVALID_HANDLE || hAtr == INVALID_HANDLE)
   {
      Print("Hull EA: Error initializing indicator handles.");
      return INIT_FAILED;
   }
   
   Print("Hull EA: Expert Advisor initialized successfully. Slow HMA (D1) = ", InpSlowLength, ", Fast HMA (", EnumToString(InpExecutionTimeframe), ") = ", InpFastLength);
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert Deinitialization Function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   //--- Release Handles
   if(hSlowHull != INVALID_HANDLE) IndicatorRelease(hSlowHull);
   if(hFastHull != INVALID_HANDLE) IndicatorRelease(hFastHull);
   if(hAtr != INVALID_HANDLE)      IndicatorRelease(hAtr);
}

//+------------------------------------------------------------------+
//| Helper to detect a New Candle on the Execution Timeframe        |
//+------------------------------------------------------------------+
bool IsNewBar()
{
   static datetime last_bar_time = 0;
   datetime current_bar_time = 0;
   
   // Fetch opening time of current bar 0
   datetime times[1];
   if(CopyTime(_Symbol, InpExecutionTimeframe, 0, 1, times) < 1)
      return false;
      
   current_bar_time = times[0];
   
   if(current_bar_time != last_bar_time)
   {
      last_bar_time = current_bar_time;
      return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| Helper to check if a position is already open                    |
//+------------------------------------------------------------------+
bool HasOpenPosition()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      string symbol = PositionGetSymbol(i);
      if(symbol == _Symbol)
      {
         long magic = PositionGetInteger(POSITION_MAGIC);
         if(magic == InpMagicNumber)
            return true;
      }
   }
   return false;
}

//+------------------------------------------------------------------+
//| Calculate dynamic lot size tailored for 5:1 leverage             |
//+------------------------------------------------------------------+
double CalculateLotSize(double sl_distance_points)
{
   double lot = InpFixedLot;
   
   if(InpUseDynamicLot && sl_distance_points > 0)
   {
      double equity = AccountInfoDouble(ACCOUNT_EQUITY);
      double risk_value = equity * (InpRiskPercent / 100.0);
      double tick_size = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
      double tick_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
      
      if(tick_size > 0 && tick_value > 0)
      {
         double point_value = tick_value / (tick_size / _Point);
         lot = risk_value / (sl_distance_points * point_value);
      }
   }
   
   //--- Enforce maximum margin usage safety check (leverage safety)
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double required_margin = 0;
   
   if(OrderCalcMargin(ORDER_TYPE_BUY, _Symbol, lot, ask, required_margin) && required_margin > 0)
   {
      double max_margin_allowed = AccountInfoDouble(ACCOUNT_EQUITY) * (InpMaxMarginPercent / 100.0);
      if(required_margin > max_margin_allowed)
      {
         double original_lot = lot;
         lot = lot * (max_margin_allowed / required_margin);
         Print("Hull EA: Margin safety limit triggered. Lot reduced from ", DoubleToString(original_lot, 2), " to ", DoubleToString(lot, 2), " to fit within max margin usage (", DoubleToString(max_margin_allowed, 2), " USD).");
      }
   }
   
   //--- Enforce broker specifications
   double min_volume = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double max_volume = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double volume_step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   
   lot = MathFloor(lot / volume_step) * volume_step;
   
   if(lot < min_volume) lot = min_volume;
   if(lot > max_volume) lot = max_volume;
   
   return lot;
}

//+------------------------------------------------------------------+
//| Manage trailing exit based on H4 Hull turning Red                |
//+------------------------------------------------------------------+
void ManageOpenTrades(double current_h4_m, double current_h4_s)
{
   // Select current symbol position
   if(PositionSelect(_Symbol))
   {
      long magic = PositionGetInteger(POSITION_MAGIC);
      long type  = PositionGetInteger(POSITION_TYPE);
      
      if(magic == InpMagicNumber && type == POSITION_TYPE_BUY)
      {
         // Exiting buy trade immediately if fast HMA signals a trend top/pullback (MHULL <= SHULL)
         if(current_h4_m != EMPTY_VALUE && current_h4_s != EMPTY_VALUE && current_h4_m <= current_h4_s)
         {
            trade.PositionClose(_Symbol);
            Print("Hull EA: Fast H4 HMA turned Bearish (Red). Dynamic trailing exit executed to lock profits.");
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Expert Tick Function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   //--- 1. Fetch Fast H4 Hull values for trailing exits (checked on every tick for maximum speed)
   double fast_m_tick[], fast_s_tick[];
   ArrayResize(fast_m_tick, 1);
   ArrayResize(fast_s_tick, 1);
   ArraySetAsSeries(fast_m_tick, true);
   ArraySetAsSeries(fast_s_tick, true);
   
   if(CopyBuffer(hFastHull, 0, 0, 1, fast_m_tick) == 1 && CopyBuffer(hFastHull, 2, 0, 1, fast_s_tick) == 1)
   {
      ManageOpenTrades(fast_m_tick[0], fast_s_tick[0]);
   }

   //--- 2. Execute new bar trigger analysis
   if(!IsNewBar())
      return;
      
   //--- 3. Fetch indicators data
   // Copy D1 Slow Hull (trend filter) - we copy last closed bar (index 1) and bar before it
   double slow_m[], slow_s[];
   ArrayResize(slow_m, 2);
   ArrayResize(slow_s, 2);
   ArraySetAsSeries(slow_m, true);
   ArraySetAsSeries(slow_s, true);
   
   if(CopyBuffer(hSlowHull, 0, 0, 2, slow_m) < 2 || CopyBuffer(hSlowHull, 2, 0, 2, slow_s) < 2)
   {
      Print("Hull EA: Failed to copy D1 slow indicator data.");
      return;
   }
   
   // Copy Fast Hull on Execution Timeframe - we copy last 3 bars (index 0, 1, 2)
   double fast_m[], fast_s[];
   ArrayResize(fast_m, 3);
   ArrayResize(fast_s, 3);
   ArraySetAsSeries(fast_m, true);
   ArraySetAsSeries(fast_s, true);
   
   if(CopyBuffer(hFastHull, 0, 0, 3, fast_m) < 3 || CopyBuffer(hFastHull, 2, 0, 3, fast_s) < 3)
   {
      Print("Hull EA: Failed to copy fast trigger indicator data.");
      return;
   }
   
// Copy ATR on Execution Timeframe - we need the ATR of the last closed bar
    double atr[];
    ArrayResize(atr, 1);
    ArraySetAsSeries(atr, true);
   if(CopyBuffer(hAtr, 0, 1, 1, atr) < 1)
   {
      Print("Hull EA: Failed to copy ATR data.");
      return;
   }

   //--- 4. Verify Trend Condition on D1 (Last closed bar 1)
   // Slow Hull is bullish when MHULL > SHULL
   if(slow_m[1] == EMPTY_VALUE || slow_s[1] == EMPTY_VALUE || 
      fast_m[1] == EMPTY_VALUE || fast_s[1] == EMPTY_VALUE || 
      fast_m[2] == EMPTY_VALUE || fast_s[2] == EMPTY_VALUE)
   {
      PrintFormat("Hull EA Error: EMPTY_VALUE detected! D1(%.2f, %.2f) H4_old(%.2f, %.2f) H4_new(%.2f, %.2f)", 
                  slow_m[1], slow_s[1], fast_m[2], fast_s[2], fast_m[1], fast_s[1]);
      return;
   }
   
   bool d1_trend_bullish = (slow_m[1] > slow_s[1]);
   
   //--- 5. Detect H4 Pullback Trigger (Buy-the-Dip)
   bool h4_was_bearish = (fast_m[2] <= fast_s[2]);
   bool h4_is_bullish  = (fast_m[1] > fast_s[1]);
   
   // DEBUG PRINT ON EVERY NEW BAR TO SEE WHAT IS GOING ON
   PrintFormat("Hull EA NewBar: D1(%.2f, %.2f) H4_old(%.2f, %.2f) H4_new(%.2f, %.2f)", 
               slow_m[1], slow_s[1], fast_m[2], fast_s[2], fast_m[1], fast_s[1]);
               
   if(h4_was_bearish && h4_is_bullish)
   {
      PrintFormat("Hull EA Debug: H4 Pullback Crossover! D1 Bullish: %s", d1_trend_bullish ? "true" : "false");
   }
   
   bool buy_trigger    = d1_trend_bullish && h4_was_bearish && h4_is_bullish;
   
   //--- 6. Process Buy Signals
   if(buy_trigger)
   {
      // Check if we already have an open position to avoid piling
      if(!HasOpenPosition())
      {
         double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         
         // SL distance using ATR multiplier
         double sl_distance = atr[0] * InpStopLossAtrMult;
         if(sl_distance <= 0) return;
         
         double sl_price = ask - sl_distance;
         double tp_price = ask + (sl_distance * InpRewardRatio);
         
         // Round levels to symbol specifications
         int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
         sl_price = NormalizeDouble(sl_price, digits);
         tp_price = NormalizeDouble(tp_price, digits);
         
         // Calculate lot size
         double sl_dist_points = sl_distance / _Point;
         double lot = CalculateLotSize(sl_dist_points);
         
         // Send order
         if(trade.Buy(lot, _Symbol, ask, sl_price, tp_price, "Hull Suite Pullback BUY"))
         {
            Print("Hull EA: Buy order successfully opened. Lot: ", DoubleToString(lot, 2), ", Price: ", ask, ", SL: ", sl_price, ", TP: ", tp_price);
         }
         else
         {
            PrintFormat("Hull EA Error: Failed to open Buy order! RetCode: %d, Description: %s", 
                        trade.ResultRetcode(), trade.ResultComment());
         }
      }
   }
}
//+------------------------------------------------------------------+
