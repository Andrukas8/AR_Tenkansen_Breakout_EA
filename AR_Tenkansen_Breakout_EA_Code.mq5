//+------------------------------------------------------------------+
//|                                        AR_Tenkansen_Breakout.mq5 |
//|                                                               AR |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "AR Ichimoku"
#property link      ""
#property version   "1.00"

#include <Trade/Trade.mqh>

input group "Ichimoku inputs";
input int IchimokuMultiplier = 1;

input group "Trade settings";
input double PercentRisk = 2;
input double MinSLPoints = 10;
input double RiskToReward = 1;

input group "Position Management";
input bool Close_Pos_Kijunsen = false; // CLOSE WHEN PRICE TOUCHES KIJUNSEN
input bool Close_Pos_Tenkansen = false; // CLOSE WHEN PRICE TOUCHES TENKANESEN
input bool ClosePosTenkansen = false; // CLOSE IF PRICE CLOSES OVER TENKANSEN

bool BuySignal_1 = false;
bool BuySignal_2 = false;
bool BuySignal_3 = false;
bool BuySignal_4 = false;
bool BuySignal_GO = false;

bool SellSignal_1 = false;
bool SellSignal_2 = false;
bool SellSignal_3 = false;
bool SellSignal_4 = false;
bool SellSignal_GO = false;

int Tenkansen;
int Kijunsen;
int SenkouspanB;

int barsTotal;

int handleIchimoku;
string textComment;

CTrade trade;


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   Tenkansen = 9 * IchimokuMultiplier;
   Kijunsen = 26 * IchimokuMultiplier;
   SenkouspanB = 52 * IchimokuMultiplier;

   handleIchimoku = iIchimoku(_Symbol,PERIOD_CURRENT,Tenkansen,Kijunsen,SenkouspanB);
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---


  }

//+------------------------------------------------------------------+
//| Closing All Positions which are now open                         |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void closeAllPositions()
  {
   for(int i=PositionsTotal()-1; i>=0; i--)
     {
      ulong positionticket = PositionGetTicket(i);
      trade.PositionClose(positionticket,-1);
      Print("eliminando posición ",positionticket);
     }
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
//---


   long spreadPos = SymbolInfoInteger(Symbol(),SYMBOL_SPREAD);
   int bars = iBars(_Symbol, PERIOD_CURRENT);
   int totalPos = PositionsTotal();


   if(barsTotal != bars) // New bar appeared on the chart
     {
      barsTotal = bars;

      BuySignal_1 = false;
      BuySignal_2 = false;
      BuySignal_3 = false;
      BuySignal_4 = false;
      BuySignal_GO = false;

      SellSignal_1 = false;
      SellSignal_2 = false;
      SellSignal_3 = false;
      SellSignal_4 = false;
      SellSignal_GO = false;

      static datetime timeStamp;

      double ClosePrice_1 = iClose(_Symbol,PERIOD_CURRENT,1);
      double ClosePrice_2 = iClose(_Symbol,PERIOD_CURRENT,2);
      double ClosePrice_3 = iClose(_Symbol,PERIOD_CURRENT,3);

      datetime time = iTime(_Symbol,PERIOD_CURRENT,0);

      double TenkansenArr[];
      double KijunsenArr[];
      double SenkouspanAArr[];
      double SenkouspanBArr[];

      double ShiftedSenkouspanAArr[];
      double ShiftedSenkouspanBArr[];

      double ChikouspanArr[];

      double Bar26High = iHigh(_Symbol,PERIOD_CURRENT,26);
      double Bar26Low = iLow(_Symbol,PERIOD_CURRENT,26);
      double CurrentHigh = iHigh(_Symbol,PERIOD_CURRENT,0);
      double CurrentLow = iLow(_Symbol,PERIOD_CURRENT,0);

      CopyBuffer(handleIchimoku,0,0,3,TenkansenArr);
      CopyBuffer(handleIchimoku,1,0,3,KijunsenArr);
      CopyBuffer(handleIchimoku,2,0,3,SenkouspanAArr);
      CopyBuffer(handleIchimoku,3,0,3,SenkouspanBArr);

      CopyBuffer(handleIchimoku,2,-26,3,ShiftedSenkouspanAArr);
      CopyBuffer(handleIchimoku,3,-26,3,ShiftedSenkouspanBArr);

      CopyBuffer(handleIchimoku,4,26,1,ChikouspanArr);

      if(timeStamp != time)
        {
         timeStamp = time;




         //--------------------------------------------------------------
         //----CALCULATE STOP LOSS TAKE PROFIT AND LOT SIZE------------
         //------------------------------------------------------------------

         double ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
         double bid = SymbolInfoDouble(_Symbol,SYMBOL_BID);
         double last = SymbolInfoDouble(_Symbol,SYMBOL_LAST);

         double slBuy = iLow(_Symbol,PERIOD_CURRENT,2);
         double slSell = iHigh(_Symbol,PERIOD_CURRENT,2);

         double ask_tp = ask + RiskToReward * (ask - slBuy);
         double bid_tp = bid - RiskToReward * (slSell - bid);

         double bufferSLPoints = 0;

         if(MinSLPoints > spreadPos)
            bufferSLPoints = MinSLPoints;
         else
            bufferSLPoints = spreadPos;

         int SlPointsBuy = (int)MathCeil((MathAbs(last - slBuy)) / _Point) - (bufferSLPoints);
         int SlPointsSell = (int)MathCeil((MathAbs(last - slSell)) / _Point) + (bufferSLPoints);


         // % Risk Position Size
         double AccountBalance = NormalizeDouble(AccountInfoDouble(ACCOUNT_BALANCE),2);
         double AmountToRisk = NormalizeDouble(AccountBalance*PercentRisk/100,2);
         double ValuePp  = SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE);

         double LotsBuy  = 0;
         double LotsSell = 0;

         LotsBuy = (SlPointsBuy > 0) ? NormalizeDouble(AmountToRisk/(SlPointsBuy)/ValuePp,2) : 0;
         LotsSell = (SlPointsSell > 0) ? NormalizeDouble(AmountToRisk/(SlPointsSell)/ValuePp,2) : 0;

         //------------------------------------------------------------------
         //-------END OF CALCULATE STOP LOSS TAKE PROFIT AND LOT SIZE-------
         //----------------------------------------------------------------






         BuySignal_4 = false;
         SellSignal_4 = false;

         // Buy Signal

         if(TenkansenArr[2] > KijunsenArr[2])
           {
            BuySignal_1 = true; // TK Cross
            SellSignal_1 = false; // cancelling sell signal
           }

         if(ChikouspanArr[0] > Bar26High) // Chikou span above prices
           {
            BuySignal_2 = true;
            SellSignal_2 = false;
           }
         else
            BuySignal_2 = false;

         if((ShiftedSenkouspanAArr[0] > ShiftedSenkouspanBArr[0])) // Kumo green
           {
            BuySignal_3 = true;
            SellSignal_3 = false;
           }

         if(ClosePrice_2 < TenkansenArr[0] && ClosePrice_1 > TenkansenArr[1]) // <<<<<<<<<<<<<<<<<<<<<<<< Buy Signal
           {
            BuySignal_4 = true;
            SellSignal_4 = false;
           }

         if(BuySignal_1 && BuySignal_2 && BuySignal_3 && BuySignal_4)
           {
            BuySignal_GO = true;
            SellSignal_GO = false;
           }

         if(BuySignal_GO)
           {
            Print(__FUNCTION__," > Buy signal ",BuySignal_GO);
            trade.Buy(LotsBuy,_Symbol,ask,slBuy,ask_tp,"This is a BUY trade");

            BuySignal_GO = false;
            BuySignal_1 = false;
            BuySignal_2 = false;
            BuySignal_3 = false;
            BuySignal_4 = false;
           }

         // SELL trades

         if(TenkansenArr[2] < KijunsenArr[2])
           {
            SellSignal_1 = true; // KT Cross
            BuySignal_1 = false; // cancelling buy signal
           }

         if(ChikouspanArr[0] < Bar26Low) // Chikous span
           {
            SellSignal_2 = true;
            BuySignal_2 = false;
           }
         else
           {
            SellSignal_2 = false;
           }

         if((ShiftedSenkouspanAArr[0] < ShiftedSenkouspanBArr[0]))
           {
            SellSignal_3 = true; // Kumo red
            BuySignal_3 = false;
           }

         if(ClosePrice_2 > TenkansenArr[0] && ClosePrice_1 < TenkansenArr[1]) // <<<<<<<<<<<<<<<<<<<<<<<< Sell Signal
           {
            BuySignal_4 = false;
            SellSignal_4 = true;
           }

         if(SellSignal_1 && SellSignal_2 && SellSignal_3 && SellSignal_4)
           {
            SellSignal_GO = true;
            BuySignal_GO = false;
           }

         if(SellSignal_GO)
           {
            Print(__FUNCTION__," > Sell signal ",SellSignal_GO);
            trade.Sell(LotsSell,_Symbol,bid,slSell,bid_tp,"This is a SELL trade");

            SellSignal_GO = false;
            SellSignal_1 = false;
            SellSignal_2 = false;
            SellSignal_3 = false;
            SellSignal_4 = false;
           }

         Print("\nNew Bar:\nTK Break Buy_: ",BuySignal_1," ",BuySignal_2," ",BuySignal_3," ",BuySignal_4," ",BuySignal_GO,"\nTK Break Sell: ",SellSignal_1," ",SellSignal_2," ",SellSignal_3," ",SellSignal_4," ",SellSignal_GO);

         textComment += "\n\nShiftedSenkouspanAArr[0] = " + DoubleToString(ShiftedSenkouspanAArr[0],_Digits) + "\nShiftedSenkouspanBArr[0] = " + DoubleToString(ShiftedSenkouspanBArr[0],_Digits) + "\n";
         textComment += "Buy Signels  = " + IntegerToString(BuySignal_1) + " " + IntegerToString(BuySignal_2) + " " + IntegerToString(BuySignal_3) + " " + IntegerToString(BuySignal_4) + "\n";
         textComment += "Sell Signals = " + IntegerToString(SellSignal_1) + " " + IntegerToString(SellSignal_2) + " " + IntegerToString(SellSignal_3) + " " + IntegerToString(SellSignal_4) + "\n";




         // Close Position on Tenkansen Cross
         if(
            (
               (Close_Pos_Tenkansen) &&
               (last > TenkansenArr[0]) &&
               (SellSignal_1 == true)
            ) ||
            (
               (Close_Pos_Tenkansen) &&
               (last < TenkansenArr[0]) &&
               (BuySignal_1 == true))
         )

           {
            Print("Closing Position on Kijunsen = ",Close_Pos_Kijunsen);
            closeAllPositions();
           }
         // End Close Position on Tenkansen Cross




         // Close Position on Kijunsen Cross
         if(
            (
               (Close_Pos_Kijunsen) &&
               (last > KijunsenArr[0]) &&
               (SellSignal_1 == true)
            ) ||
            (
               (Close_Pos_Kijunsen) &&
               (last < KijunsenArr[0]) &&
               (BuySignal_1 == true))
         )

           {
            Print("Closing Position on Kijunsen = ",Close_Pos_Kijunsen);
            closeAllPositions();
           }
         // End Close Position on Kijunsen Cross




        } // timeStamp != time

     } // barsTotal != bars



// Close Position If Price Closes Over Tenkansen
   if(ClosePosTenkansen)
     {
      // CTrade trade;
      double TenkansenArr[];
      CopyBuffer(handleIchimoku,0,0,2,TenkansenArr);

      double ClosePrevBar = NormalizeDouble(iClose(_Symbol,PERIOD_CURRENT,1),_Digits); // previous close price
      double TenkansenPrevBar = NormalizeDouble(TenkansenArr[0],_Digits); // previous kijunsen value

      textComment += "Close Pri Prev bar = " + DoubleToString(ClosePrevBar,_Digits) + "\n";
      textComment += "Tenkansen Prev Bar = " + DoubleToString(TenkansenPrevBar,_Digits) + "\n";

      if(ArraySize(TenkansenArr) > 0)
        {
         // --------------------
         // --- BUY POSITION ---
         // --------------------
         if(ClosePrevBar < TenkansenPrevBar)
            for(int i = 0; i < totalPos; i++)
              {
               ulong posTicket = PositionGetTicket(i);
               if(PositionSelectByTicket(posTicket))
                  if(PositionGetString(POSITION_SYMBOL) == _Symbol && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
                    {
                     int OpenBar = iBarShift(_Symbol,0,PositionGetInteger(POSITION_TIME));
                     if(OpenBar > 1)
                        if(trade.PositionClose(posTicket))
                           Print(__FUNCTION__," > Position #",posTicket," was closed because price closed below Tenkansen. ",ClosePrevBar," < ",TenkansenPrevBar);
                    }

              }

         // --------------------
         // --- SELL POSITION --
         // --------------------
         if(ClosePrevBar > TenkansenPrevBar)
            for(int i = 0; i < totalPos; i++)
              {
               ulong posTicket = PositionGetTicket(i);
               if(PositionSelectByTicket(posTicket))
                  if(PositionGetString(POSITION_SYMBOL) == _Symbol && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
                    {
                     int OpenBar = iBarShift(_Symbol,0,PositionGetInteger(POSITION_TIME));
                     if(OpenBar > 1)
                        if(trade.PositionClose(posTicket))
                           Print(__FUNCTION__," > Position #",posTicket," was closed because price closed above Tenkansen. ",ClosePrevBar," > ",TenkansenPrevBar);
                    }
              }


        } // ArraySize(TenkansenArr) > 0
     } // ClosePosTenkansen

  } // OnTick

//+------------------------------------------------------------------+
