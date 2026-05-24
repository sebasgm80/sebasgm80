//+------------------------------------------------------------------+
//|                                                    HullSuite.mq5 |
//|                                    Copyright 2026, InSilico / AI |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright   "Copyright 2026, InSilico / AI"
#property link        "https://www.mql5.com"
#property version     "1.00"
#property description "Hull Suite - MQL5 Conversion of InSilico's Pine Indicator"
#property tester_everytick_calculate

//--- Indicator Properties
#property indicator_chart_window
#property indicator_buffers 11
#property indicator_plots   4

//--- Plot 1: MHULL (Main Line)
#property indicator_label1  "MHULL"
#property indicator_type1   DRAW_COLOR_LINE
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
#property indicator_color1  C'0,220,0', C'255,40,40', C'255,152,0' // Green, Red, Orange

//--- Plot 2: SHULL (Delayed Signal Line)
#property indicator_label2  "SHULL"
#property indicator_type2   DRAW_COLOR_LINE
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1
#property indicator_color2  C'0,220,0', C'255,40,40', C'255,152,0' // Green, Red, Orange

//--- Plot 3: Band Filler
#property indicator_label3  "Band Filler"
#property indicator_type3   DRAW_FILLING
#property indicator_color3  C'40,160,40', C'160,40,40' // Soft Green, Soft Red filling

//--- Plot 4: Colored Candles
#property indicator_label4  "Colored Candles"
#property indicator_type4   DRAW_COLOR_CANDLES
#property indicator_color4  C'0,220,0', C'255,40,40', C'255,152,0' // Green, Red, Orange

//--- Custom Enums
enum ENUM_HULL_MODE
{
   HULL_MODE_HMA  = 0,  // Hma (Hull Moving Average)
   HULL_MODE_EHMA = 1,  // Ehma (Exponential Hull Moving Average)
   HULL_MODE_THMA = 2   // Thma (Triple Hull Moving Average)
};

//--- Input Parameters
input group "=== CORE SETTINGS ==="
input ENUM_APPLIED_PRICE InpSource         = PRICE_CLOSE;        // Price Source
input ENUM_HULL_MODE     InpModeSwitch     = HULL_MODE_HMA;      // Hull Variation
input int                InpLength         = 55;                 // Length (180-200 floating S/R, 55 swing)
input double             InpLengthMult     = 1.0;                // Length Multiplier

input group "=== MULTI-TIMEFRAME (MTF) ==="
input bool               InpUseHtf         = false;              // Show Hull from Higher Timeframe?
input ENUM_TIMEFRAMES    InpHtf            = PERIOD_H4;          // Higher Timeframe

input group "=== VISUAL SETTINGS ==="
input bool               InpSwitchColor    = true;               // Color according to trend?
input bool               InpCandleCol      = false;              // Color candles based on Hull trend?
input bool               InpVisualSwitch   = true;               // Show as a Band?
input int                InpLineThickness  = 1;                  // Line Thickness

input group "=== ALERTS ==="
input bool               InpAlertSound        = true;            // Sound & Pop-up Alerts
input bool               InpAlertNotification = false;           // Mobile Push Notifications
input bool               InpAlertEmail        = false;           // Email Alerts
input bool               InpAlertOnlyOnClose  = true;            // Alert only on Bar Close

//--- Indicator Buffers
double MHullBuf[];       // Buffer 0 (Main Value - EA Signal)
double MHullColorBuf[];  // Buffer 1 (Main Trend color: 0=Up, 1=Down, 2=Neutral)

double SHullBuf[];       // Buffer 2 (Signal Value - EA Signal)
double SHullColorBuf[];  // Buffer 3 (Signal Trend color: 0=Up, 1=Down, 2=Neutral)

double FillUpperBuf[];   // Buffer 4
double FillLowerBuf[];   // Buffer 5

double CandleOpenBuf[];  // Buffer 6
double CandleHighBuf[];  // Buffer 7
double CandleLowBuf[];   // Buffer 8
double CandleCloseBuf[]; // Buffer 9
double CandleColorBuf[]; // Buffer 10 (Candle color: 0=Up, 1=Down, 2=Neutral)

//--- Global Variables
int g_warmup_period = 0;

//+------------------------------------------------------------------+
//| Custom Indicator Initialization Function                         |
//+------------------------------------------------------------------+
int OnInit()
{
   //--- Bind Indicator Buffers
   SetIndexBuffer(0, MHullBuf, INDICATOR_DATA);
   SetIndexBuffer(1, MHullColorBuf, INDICATOR_COLOR_INDEX);
   
   SetIndexBuffer(2, SHullBuf, INDICATOR_DATA);
   SetIndexBuffer(3, SHullColorBuf, INDICATOR_COLOR_INDEX);
   
   SetIndexBuffer(4, FillUpperBuf, INDICATOR_DATA);
   SetIndexBuffer(5, FillLowerBuf, INDICATOR_DATA);
   
   SetIndexBuffer(6, CandleOpenBuf, INDICATOR_DATA);
   SetIndexBuffer(7, CandleHighBuf, INDICATOR_DATA);
   SetIndexBuffer(8, CandleLowBuf, INDICATOR_DATA);
   SetIndexBuffer(9, CandleCloseBuf, INDICATOR_DATA);
   SetIndexBuffer(10, CandleColorBuf, INDICATOR_COLOR_INDEX);
   
   //--- Calculate Warmup Period
   int len = (int)MathRound(InpLength * InpLengthMult);
   if(len < 1) len = 1;
   
   if(InpModeSwitch == HULL_MODE_HMA)
   {
      g_warmup_period = len + (int)MathRound(MathSqrt(len)) - 2;
   }
   else if(InpModeSwitch == HULL_MODE_EHMA)
   {
      g_warmup_period = len + (int)MathRound(MathSqrt(len)) - 2;
   }
   else if(InpModeSwitch == HULL_MODE_THMA)
   {
      int actual_len = len / 2;
      if(actual_len < 1) actual_len = 1;
      g_warmup_period = actual_len * 2 - 2; // Approximated warmup for nested WMA
   }
   
   if(g_warmup_period < 0) g_warmup_period = 0;
   
   //--- Configure Plot Begin Positions
   PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, g_warmup_period);
   PlotIndexSetInteger(1, PLOT_DRAW_BEGIN, g_warmup_period + 2); // shifted 2 bars
   PlotIndexSetInteger(2, PLOT_DRAW_BEGIN, g_warmup_period + 2);
   PlotIndexSetInteger(3, PLOT_DRAW_BEGIN, g_warmup_period);
   
   //--- Set Line Thicknesses
   PlotIndexSetInteger(0, PLOT_LINE_WIDTH, InpLineThickness);
   PlotIndexSetInteger(1, PLOT_LINE_WIDTH, InpLineThickness);
   
   //--- Dynamic Visual Customization
   if(!InpVisualSwitch)
   {
      // Hide the filling band and the delayed signal line from display
      PlotIndexSetInteger(1, PLOT_DRAW_TYPE, DRAW_NONE);
      PlotIndexSetInteger(2, PLOT_DRAW_TYPE, DRAW_NONE);
   }
   
   if(!InpSwitchColor)
   {
      // If trend color is disabled, set all plots to the flat neutral color (Orange)
      PlotIndexSetInteger(2, PLOT_LINE_COLOR, 0, C'255,152,0');
      PlotIndexSetInteger(2, PLOT_LINE_COLOR, 1, C'255,152,0');
   }
   
   //--- Dynamic Name Settings
   string shortName = "HullSuite(" + IntegerToString(InpLength) + ")";
   if(InpUseHtf) shortName = shortName + " [HTF: " + EnumToString(InpHtf) + "]";
   IndicatorSetString(INDICATOR_SHORTNAME, shortName);
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| High-performance WMA (Weighted Moving Average) Calculation       |
//+------------------------------------------------------------------+
double CalculateWMA(const double &src[], int i, int length)
{
   if(i < length - 1) return EMPTY_VALUE;
   
   double sum = 0.0;
   double weight_sum = 0.0;
   for(int k = 0; k < length; k++)
   {
      double val = src[i - k];
      if(val == EMPTY_VALUE) return EMPTY_VALUE;
      double w = (double)(length - k);
      sum += val * w;
      weight_sum += w;
   }
   
   return (weight_sum > 0.0) ? (sum / weight_sum) : EMPTY_VALUE;
}

//+------------------------------------------------------------------+
//| High-performance EMA (Exponential Moving Average) Calculation    |
//+------------------------------------------------------------------+
bool CalculateEMA(const double &src[], double &dst[], int rates_total, int length)
{
   if(rates_total < length) return false;
   ArrayResize(dst, rates_total);
   
   // Initialize early elements
   for(int i = 0; i < length - 1; i++) dst[i] = EMPTY_VALUE;
   
   // First EMA value is SMA
   double sum = 0.0;
   int count = 0;
   for(int i = 0; i < length; i++)
   {
      if(src[i] != EMPTY_VALUE)
      {
         sum += src[i];
         count++;
      }
   }
   if(count < length) return false;
   dst[length - 1] = sum / length;
   
   double alpha = 2.0 / (double)(length + 1);
   for(int i = length; i < rates_total; i++)
   {
      if(src[i] == EMPTY_VALUE || dst[i - 1] == EMPTY_VALUE)
      {
         dst[i] = EMPTY_VALUE;
      }
      else
      {
         dst[i] = src[i] * alpha + dst[i - 1] * (1.0 - alpha);
      }
   }
   return true;
}

//+------------------------------------------------------------------+
//| Core Hull Suite Calculations (HMA, EHMA, THMA) on custom array    |
//+------------------------------------------------------------------+
bool CalculateHullSuite(const double &src[], double &hull[], int rates_total, ENUM_HULL_MODE mode, int length, double length_mult)
{
   int len = (int)MathRound(length * length_mult);
   if(len < 1) len = 1;
   
   ArrayResize(hull, rates_total);
   ArrayInitialize(hull, EMPTY_VALUE);
   
   if(rates_total < len) return false;
   
   //--- HMA Calculation
   if(mode == HULL_MODE_HMA)
   {
      int len_half = len / 2;
      if(len_half < 1) len_half = 1;
      
      double wma_half[], wma_full[];
      ArrayResize(wma_half, rates_total);
      ArrayResize(wma_full, rates_total);
      
      for(int i = 0; i < rates_total; i++)
      {
         wma_half[i] = CalculateWMA(src, i, len_half);
         wma_full[i] = CalculateWMA(src, i, len);
      }
      
      double diff[];
      ArrayResize(diff, rates_total);
      for(int i = 0; i < rates_total; i++)
      {
         if(wma_half[i] == EMPTY_VALUE || wma_full[i] == EMPTY_VALUE)
            diff[i] = EMPTY_VALUE;
         else
            diff[i] = 2.0 * wma_half[i] - wma_full[i];
      }
      
      int len_sqrt = (int)MathRound(MathSqrt(len));
      if(len_sqrt < 1) len_sqrt = 1;
      
      for(int i = 0; i < rates_total; i++)
      {
         hull[i] = CalculateWMA(diff, i, len_sqrt);
      }
   }
   
   //--- EHMA Calculation
   else if(mode == HULL_MODE_EHMA)
   {
      int len_half = len / 2;
      if(len_half < 1) len_half = 1;
      
      double ema_half[], ema_full[];
      if(!CalculateEMA(src, ema_half, rates_total, len_half) ||
         !CalculateEMA(src, ema_full, rates_total, len))
      {
         return false;
      }
      
      double diff[];
      ArrayResize(diff, rates_total);
      for(int i = 0; i < rates_total; i++)
      {
         if(ema_half[i] == EMPTY_VALUE || ema_full[i] == EMPTY_VALUE)
            diff[i] = EMPTY_VALUE;
         else
            diff[i] = 2.0 * ema_half[i] - ema_full[i];
      }
      
      int len_sqrt = (int)MathRound(MathSqrt(len));
      if(len_sqrt < 1) len_sqrt = 1;
      
      double ema_final[];
      if(CalculateEMA(diff, ema_final, rates_total, len_sqrt))
      {
         ArrayCopy(hull, ema_final);
      }
   }
   
   //--- THMA Calculation
   else if(mode == HULL_MODE_THMA)
   {
      int actual_len = len / 2;
      if(actual_len < 1) actual_len = 1;
      
      int len_third = actual_len / 3;
      int len_half = actual_len / 2;
      if(len_third < 1) len_third = 1;
      if(len_half < 1) len_half = 1;
      
      double wma_third[], wma_half[], wma_full[];
      ArrayResize(wma_third, rates_total);
      ArrayResize(wma_half, rates_total);
      ArrayResize(wma_full, rates_total);
      
      for(int i = 0; i < rates_total; i++)
      {
         wma_third[i] = CalculateWMA(src, i, len_third);
         wma_half[i] = CalculateWMA(src, i, len_half);
         wma_full[i] = CalculateWMA(src, i, actual_len);
      }
      
      double diff[];
      ArrayResize(diff, rates_total);
      for(int i = 0; i < rates_total; i++)
      {
         if(wma_third[i] == EMPTY_VALUE || wma_half[i] == EMPTY_VALUE || wma_full[i] == EMPTY_VALUE)
            diff[i] = EMPTY_VALUE;
         else
            diff[i] = 3.0 * wma_third[i] - wma_half[i] - wma_full[i];
      }
      
      for(int i = 0; i < rates_total; i++)
      {
         hull[i] = CalculateWMA(diff, i, actual_len);
      }
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Standard Alert Triggering Helper                                 |
//+------------------------------------------------------------------+
void TriggerAlert(string message)
{
   if(InpAlertSound)
   {
      Alert(message);
   }
   if(InpAlertNotification)
   {
      SendNotification(message);
   }
   if(InpAlertEmail)
   {
      SendMail("Hull Suite Alert", message);
   }
}

//+------------------------------------------------------------------+
//| Custom Indicator Iteration Function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   //--- Validate Warmup limits
    if(rates_total <= g_warmup_period + 2)
       return prev_calculated;
      
   //--- Array setups (Ensure forward indexing)
   ArraySetAsSeries(time, false);
   ArraySetAsSeries(open, false);
   ArraySetAsSeries(high, false);
   ArraySetAsSeries(low, false);
   ArraySetAsSeries(close, false);
   
   ArraySetAsSeries(MHullBuf, false);
   ArraySetAsSeries(MHullColorBuf, false);
   ArraySetAsSeries(SHullBuf, false);
   ArraySetAsSeries(SHullColorBuf, false);
   ArraySetAsSeries(FillUpperBuf, false);
   ArraySetAsSeries(FillLowerBuf, false);
   
   ArraySetAsSeries(CandleOpenBuf, false);
   ArraySetAsSeries(CandleHighBuf, false);
   ArraySetAsSeries(CandleLowBuf, false);
   ArraySetAsSeries(CandleCloseBuf, false);
   ArraySetAsSeries(CandleColorBuf, false);

    //--- Extract prices for current timeframe
    double src_prices[];
    ArrayResize(src_prices, rates_total);
    for(int i = 0; i < rates_total; i++)
    {
       double val = 0;
       switch(InpSource)
       {
          case PRICE_CLOSE:     val = close[i]; break;
          case PRICE_OPEN:      val = open[i]; break;
          case PRICE_HIGH:      val = high[i]; break;
          case PRICE_LOW:       val = low[i]; break;
          case PRICE_MEDIAN:    val = (high[i] + low[i]) / 2.0; break;
          case PRICE_TYPICAL:   val = (high[i] + low[i] + close[i]) / 3.0; break;
          case PRICE_WEIGHTED:  val = (high[i] + low[i] + 2.0 * close[i]) / 4.0; break;
          default:              val = close[i]; break;
       }
       src_prices[i] = val;
    }

   //--- Compute Hull Suite Values
   double hull_values[];
   
   //--- High Timeframe (HTF) branch
   if(InpUseHtf)
   {
      MqlRates htf_rates[];
      int htf_rates_total = CopyRates(_Symbol, InpHtf, 0, rates_total, htf_rates);
      if(htf_rates_total <= 0)
      {
         return prev_calculated; // Wait for HTF download
      }
      
      ArraySetAsSeries(htf_rates, false);
      
      double htf_src[];
      ArrayResize(htf_src, htf_rates_total);
      for(int j = 0; j < htf_rates_total; j++)
      {
         double val = 0;
         switch(InpSource)
         {
            case PRICE_CLOSE:     val = htf_rates[j].close; break;
            case PRICE_OPEN:      val = htf_rates[j].open; break;
            case PRICE_HIGH:      val = htf_rates[j].high; break;
            case PRICE_LOW:       val = htf_rates[j].low; break;
            case PRICE_MEDIAN:    val = (htf_rates[j].high + htf_rates[j].low) / 2.0; break;
            case PRICE_TYPICAL:   val = (htf_rates[j].high + htf_rates[j].low + htf_rates[j].close) / 3.0; break;
            case PRICE_WEIGHTED:  val = (htf_rates[j].high + htf_rates[j].low + 2.0 * htf_rates[j].close) / 4.0; break;
            default:              val = htf_rates[j].close; break;
         }
         htf_src[j] = val;
      }
      
      double htf_hull[];
      if(!CalculateHullSuite(htf_src, htf_hull, htf_rates_total, InpModeSwitch, InpLength, InpLengthMult))
      {
         return prev_calculated;
      }
      
      // Map HTF values using the fast O(N) Chronological Linear Scan
      int htf_idx = 0;
      ArrayResize(hull_values, rates_total);
      ArrayInitialize(hull_values, EMPTY_VALUE);
      
      for(int i = 0; i < rates_total; i++)
      {
         datetime t = time[i];
         while(htf_idx < htf_rates_total - 1 && htf_rates[htf_idx + 1].time <= t)
         {
            htf_idx++;
         }
         hull_values[i] = htf_hull[htf_idx];
      }
   }
   //--- Current Timeframe branch
   else
   {
      if(!CalculateHullSuite(src_prices, hull_values, rates_total, InpModeSwitch, InpLength, InpLengthMult))
      {
         return prev_calculated;
      }
   }

   //--- Determine loop starting position
   int start = (prev_calculated == 0) ? 0 : prev_calculated - 1;
   if(start < g_warmup_period) start = g_warmup_period;
   
   //--- Clear out early bars on fresh drawing
   if(prev_calculated == 0)
   {
      for(int i = 0; i < start; i++)
      {
         MHullBuf[i] = EMPTY_VALUE;
         MHullColorBuf[i] = 2; // Neutral
         
         SHullBuf[i] = EMPTY_VALUE;
         SHullColorBuf[i] = 2; // Neutral
         
         FillUpperBuf[i] = EMPTY_VALUE;
         FillLowerBuf[i] = EMPTY_VALUE;
         
         CandleOpenBuf[i]  = EMPTY_VALUE;
         CandleHighBuf[i]  = EMPTY_VALUE;
         CandleLowBuf[i]   = EMPTY_VALUE;
         CandleCloseBuf[i] = EMPTY_VALUE;
         CandleColorBuf[i] = 2;
      }
   }

   //--- Core rendering loop
   for(int i = start; i < rates_total && !IsStopped(); i++)
   {
      // 1. Assign MHULL
      MHullBuf[i] = hull_values[i];
      
      // 2. Assign SHULL (MHULL shifted by 2 bars)
      if(i >= 2)
      {
         SHullBuf[i] = hull_values[i - 2];
      }
      else
      {
         SHullBuf[i] = EMPTY_VALUE;
      }
      
      // 3. Assign Band Filling
      if(InpVisualSwitch && MHullBuf[i] != EMPTY_VALUE && SHullBuf[i] != EMPTY_VALUE)
      {
         FillUpperBuf[i] = MHullBuf[i];
         FillLowerBuf[i] = SHullBuf[i];
      }
      else
      {
         FillUpperBuf[i] = EMPTY_VALUE;
         FillLowerBuf[i] = EMPTY_VALUE;
      }
      
      // 4. Color logic for lines & candles
      if(MHullBuf[i] != EMPTY_VALUE && SHullBuf[i] != EMPTY_VALUE)
      {
         int color_idx = 2; // Neutral
         if(InpSwitchColor)
         {
            color_idx = (MHullBuf[i] > SHullBuf[i]) ? 0 : 1; // 0=Green, 1=Red
         }
         
         MHullColorBuf[i] = color_idx;
         SHullColorBuf[i] = color_idx;
         
         // Candle rendering
         if(InpCandleCol)
         {
            CandleOpenBuf[i]  = open[i];
            CandleHighBuf[i]  = high[i];
            CandleLowBuf[i]   = low[i];
            CandleCloseBuf[i] = close[i];
            CandleColorBuf[i] = color_idx;
         }
         else
         {
            CandleOpenBuf[i]  = EMPTY_VALUE;
            CandleHighBuf[i]  = EMPTY_VALUE;
            CandleLowBuf[i]   = EMPTY_VALUE;
            CandleCloseBuf[i] = EMPTY_VALUE;
         }
      }
      else
      {
         MHullColorBuf[i] = 2;
         SHullColorBuf[i] = 2;
         
         CandleOpenBuf[i]  = EMPTY_VALUE;
         CandleHighBuf[i]  = EMPTY_VALUE;
         CandleLowBuf[i]   = EMPTY_VALUE;
         CandleCloseBuf[i] = EMPTY_VALUE;
      }
   }

   //--- Crossover / Crossunder Alert Module
   static datetime last_alert_time = 0;
   
   if(rates_total > 3)
   {
      int check_idx = rates_total - 2; // Closed bar
      int prev_idx = rates_total - 3;
      
      if(!InpAlertOnlyOnClose)
      {
         check_idx = rates_total - 1; // Live tick bar
         prev_idx = rates_total - 2;
      }
      
      datetime current_bar_time = time[check_idx];
      
      if(current_bar_time > last_alert_time)
      {
         double m_curr = MHullBuf[check_idx];
         double s_curr = SHullBuf[check_idx];
         double m_prev = MHullBuf[prev_idx];
         double s_prev = SHullBuf[prev_idx];
         
         if(m_curr != EMPTY_VALUE && s_curr != EMPTY_VALUE && m_prev != EMPTY_VALUE && s_prev != EMPTY_VALUE)
         {
            bool is_bullish_cross = (m_prev <= s_prev && m_curr > s_curr);
            bool is_bearish_cross = (m_prev >= s_prev && m_curr < s_curr);
            
            if(is_bullish_cross)
            {
               string msg = "Hull Suite (" + _Symbol + ", " + EnumToString(_Period) + "): Hull trending up.";
               TriggerAlert(msg);
               last_alert_time = current_bar_time;
            }
            else if(is_bearish_cross)
            {
               string msg = "Hull Suite (" + _Symbol + ", " + EnumToString(_Period) + "): Hull trending down.";
               TriggerAlert(msg);
               last_alert_time = current_bar_time;
            }
         }
      }
   }

   return(rates_total);
}
//+------------------------------------------------------------------+
