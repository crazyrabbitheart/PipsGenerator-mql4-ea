//+------------------------------------------------------------------+
//|                                      wolfgang_pips_generator.mq4 |
//|                               Copyright 2024, Stefan Stevanovic. |
//|            https://www.peopleperhour.com/stream/view?id=27818520 |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Stefan Stevanovic."
#property link      "https://www.peopleperhour.com/stream/view?id=27818520"
#property version   "1.07"
#property strict

enum trade_direction{
   BOTH = 0,
   LONG = 1,
   SHORT = 2,
};
//
//enum sl_to_use{
//   PIP = 0,
//   APOLLO = 1,
//};

// input variable
input int               magicNumber       = 12345; // Set Magic Number
input trade_direction   TRADE_DIRECTION   = 0;     // Trade Direction
//input sl_to_use         SL_TO_USE         = 0;     // Use Pip Or Stars
input double            lotSize           = 1.0;     // Set Lot Size
input int               sl                = 100;   // Stoploss Value
input int               tp1               = 25;    // TakeProfit Value 1
input int               tp2               = 50;   // TakeProfit Value 2(TP2>TP1)
input double            tpPro             = 0.5;   // Multiple partial targets(1>value>0)
input bool              breakEnabled      = true;  // Set BREAKEVEN
input int               breakTriggerValue = 100;   // Break Trigger Value
input bool              trailEnabled      = true;  // Set Trail
input int               trailTriggerValue = 100;   // Trail Trigger Value
input int               trailPipValue     = 50;    // Trail Pips Value

// initail variable
datetime now = 0;
string currentSymbol = "";

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   currentSymbol = ChartSymbol(0);
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   ObjectsDeleteAll(0, "HLine", -1, -1);
   ObjectsDeleteAll(0, "Text", -1, -1);
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
  
//--- get time new bar opened
   if( now == Time[0]) return;
   now = Time[0];
   
//--- get value from indicator      
   double handle1 = NormalizeDouble(iCustom(ChartID(), 0, "Market\\Pips Generator", 0, 1), Digits);      //Market\\Pips Generator value
   double handle2 = NormalizeDouble(iCustom(ChartID(), 0, "Market\\Pips Generator", 1, 1), Digits);      //value2
   double handle3 = NormalizeDouble(iCustom(ChartID(), 0, "Market\\Pips Generator", 2, 1), Digits);      //value3
   double handle4 = NormalizeDouble(iCustom(ChartID(), 0, "Market\\Pips Generator", 3, 1), Digits);      //value4-blue arrow
   double handle5 = NormalizeDouble(iCustom(ChartID(), 0, "Market\\Pips Generator", 4, 1), Digits);      //value5-red arrow
   double handle6 = NormalizeDouble(iCustom(ChartID(), 0, "Market\\Pips Generator", 5, 1), Digits);      //buy value-blue star
   double handle7 = NormalizeDouble(iCustom(ChartID(), 0, "Market\\Pips Generator", 6, 1), Digits);      //sell value-pink star
   double handle8 = NormalizeDouble(iCustom(ChartID(), 0, "Market\\Pips Generator", 7, 1), Digits);      //lower value
   double handle9 = NormalizeDouble(iCustom(ChartID(), 0, "Market\\Pips Generator", 8, 1), Digits);      //upper value
   double handle10 = NormalizeDouble(iCustom(ChartID(), 0, "Market\\Pips Generator", 9, 1), Digits);     //middle value
   
   if (Symbol() == currentSymbol && handle4 != 2147483647.0){
      if (TRADE_DIRECTION == LONG || TRADE_DIRECTION == BOTH){
         double stoploss=NormalizeDouble(Bid-sl*Point,Digits); 
         double takeprofit1=NormalizeDouble(Bid+tp1*Point,Digits); 
         double takeprofit2=NormalizeDouble(Bid+tp2*Point,Digits);          
         int ticket=OrderSend(Symbol(),OP_BUY,lotSize,Ask,3,stoploss,takeprofit2,"long",magicNumber,0,clrAliceBlue);
         if (ticket > 0){
         //   OrderModify(ticket, OrderOpenPrice(), stoploss, takeprofit1, 0, clrAliceBlue);
         //   OrderModify(ticket, OrderOpenPrice(), stoploss, takeprofit2, 0, clrAliceBlue);
            drawTakeprofitAndStoplossLines(ticket, takeprofit1, takeprofit2, stoploss);
         }
      }
      CloseSelectedOrders(OP_SELL);      
   }
   
   if (Symbol() == currentSymbol && handle5 != 2147483647.0){
      if (TRADE_DIRECTION == SHORT || TRADE_DIRECTION == BOTH){
         double stoploss=NormalizeDouble(Ask+sl*Point,Digits); 
         double takeprofit1=NormalizeDouble(Ask-tp1*Point,Digits); 
         double takeprofit2=NormalizeDouble(Ask-tp2*Point,Digits); 
         int ticket=OrderSend(Symbol(),OP_SELL,lotSize,Bid,3,stoploss,takeprofit2,"short",magicNumber,0,clrAliceBlue);
         if (ticket > 0){
         //   OrderModify(ticket, OrderOpenPrice(), stoploss, takeprofit1, 0, clrAliceBlue);
         //   OrderModify(ticket, OrderOpenPrice(), stoploss, takeprofit2, 0, clrAliceBlue);
            drawTakeprofitAndStoplossLines(ticket, takeprofit1, takeprofit2, stoploss);
         }
      }
      CloseSelectedOrders(OP_BUY);
   }
  
  for (int i = OrdersTotal() - 1; i >= 0; i--) {
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES) && OrderSymbol() == Symbol()){
         
         int orderType = OrderType();
         double entryPrice = OrderOpenPrice();
         
         if(breakEnabled){
            double breakevenLevel = 0.0;
            if (orderType == OP_BUY) {
               breakevenLevel = NormalizeDouble(entryPrice + breakTriggerValue * Point, Digits);
            } else if (orderType == OP_SELL) {
               breakevenLevel = NormalizeDouble(entryPrice - breakTriggerValue * Point, Digits);
            }            
            
            // Retrieve the current symbol price
            double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
            
            // Check if the current price has reached the breakeven level
            if ((orderType == OP_BUY && currentPrice >= breakevenLevel) ||
               (orderType == OP_SELL && currentPrice <= breakevenLevel)) {
               // Modify the stop loss to breakeven level
               double newStopLoss = breakevenLevel;
               
               // Modify the stop loss
               if (newStopLoss != OrderStopLoss())
                  if (OrderModify(OrderTicket(), entryPrice, newStopLoss, OrderTakeProfit(), 0, clrYellow) == true) {
                      Print("Stop loss moved to breakeven for order ", OrderTicket());
                  } else {
                      Print("Failed to move stop loss to breakeven for order ", OrderTicket());
                  }
            }   
         }
         
         if (trailEnabled){
            if (orderType == OP_BUY) {               
               if (NormalizeDouble(Bid - entryPrice - trailTriggerValue * Point, Digits) > 0)
                  if(OrderStopLoss()==0||OrderStopLoss()<NormalizeDouble(Bid-trailPipValue*Point, Digits))
                     if (OrderModify(OrderTicket(),OrderOpenPrice(),NormalizeDouble(Bid-trailPipValue*Point, Digits),OrderTakeProfit(),0,clrNONE) == true) {
                        Print("Trail moved to breakeven for order ", OrderTicket());
                     } else {
                        Print("Failed to move trail to breakeven for order ", OrderTicket());
                     }
            } else if (orderType == OP_SELL) {
               if (NormalizeDouble(entryPrice - Ask - trailTriggerValue * Point, Digits) > 0)
                  if(OrderStopLoss()==0||OrderStopLoss()>NormalizeDouble(Ask+trailPipValue*Point, Digits))
                     if (OrderModify(OrderTicket(),OrderOpenPrice(),NormalizeDouble(Ask+trailPipValue*Point, Digits),OrderTakeProfit(),0,clrNONE) == true) {
                        Print("Trail moved to breakeven for order ", OrderTicket());
                     } else {
                        Print("Failed to move trail to breakeven for order ", OrderTicket());
                     }
            }
         }
         
         if (OrderProfit() >= tp1){
            int ticket = OrderClose(OrderTicket(), lotSize * tpPro, OrderClosePrice(), 3, clrGray);            
         }  
       }
   }
   
   for (int i = OrdersHistoryTotal() - 1; i >= 0; i--) {      
      if (OrderSelect(i, SELECT_BY_POS, MODE_HISTORY) && OrderSymbol() == currentSymbol){
         int ticket = OrderTicket();
         ObjectsDeleteAll(0, "HLine"  + IntegerToString(ticket, 0, ' '), -1, -1);
         ObjectsDeleteAll(0, "Text"  + IntegerToString(ticket, 0, ' '), -1, -1);
      }   
   }
  }
//+------------------------------------------------------------------+

void CloseSelectedOrders(int cmd) {
   for (int i = OrdersTotal() - 1; i >= 0; i--) {
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES) && OrderType() == cmd  && OrderSymbol() == Symbol()) {         
         bool result = OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), 3, clrBlue);
         if (result)
            Print("All Orders that you selected are closed");
         else
            Print("All Orders that you selected are not closed by error", GetLastError());
      }
   }
}

void drawTakeprofitAndStoplossLines (int ticket, double takeprofit1, double takeprofit2, double stoploss){
   string ObjName = "HLine" + IntegerToString(ticket, 0, ' ') + "TP1";
   ObjectCreate(0, ObjName, OBJ_HLINE, 0, 0, takeprofit1);
   ObjectSetInteger(0,ObjName,OBJPROP_COLOR,clrYellow);
   ObjectSetInteger(0,ObjName,OBJPROP_STYLE,STYLE_SOLID);
   ObjectSetInteger(0,ObjName,OBJPROP_WIDTH,1);
   ObjName = "HLine"  + IntegerToString(ticket, 0, ' ') + "TP2";
   ObjectCreate(0, ObjName, OBJ_HLINE, 0, 0, takeprofit2);
   ObjectSetInteger(0,ObjName,OBJPROP_COLOR,clrYellow);
   ObjectSetInteger(0,ObjName,OBJPROP_STYLE,STYLE_SOLID);
   ObjectSetInteger(0,ObjName,OBJPROP_WIDTH,1);
   ObjName = "HLine"  + IntegerToString(ticket, 0, ' ') + "SL";
   ObjectCreate(0, ObjName, OBJ_HLINE, 0, 0, stoploss);
   ObjectSetInteger(0,ObjName,OBJPROP_COLOR,clrGreen);
   ObjectSetInteger(0,ObjName,OBJPROP_STYLE,STYLE_SOLID);
   ObjectSetInteger(0,ObjName,OBJPROP_WIDTH,1);
   ObjName = "Text" + IntegerToString(ticket, 0, ' ') + "TP1";
   ObjectCreate(0,ObjName,OBJ_TEXT,0,TimeCurrent(),takeprofit1);
   ObjectSetString(0,ObjName,OBJPROP_TEXT,"TP1");
   ObjectSetInteger(0,ObjName,OBJPROP_FONTSIZE,10);
   ObjectSetDouble(0,ObjName,OBJPROP_ANGLE,0);
   ObjectSetInteger(0,ObjName,OBJPROP_ANCHOR,ANCHOR_BOTTOM); 
   ObjectSetInteger(0,ObjName,OBJPROP_COLOR,clrRed);
   ObjName = "Text" + IntegerToString(ticket, 0, ' ') + "TP2";
   ObjectCreate(0,ObjName,OBJ_TEXT,0,TimeCurrent(),takeprofit2);
   ObjectSetString(0,ObjName,OBJPROP_TEXT,"TP2");
   ObjectSetInteger(0,ObjName,OBJPROP_FONTSIZE,10);
   ObjectSetDouble(0,ObjName,OBJPROP_ANGLE,0);
   ObjectSetInteger(0,ObjName,OBJPROP_ANCHOR,ANCHOR_BOTTOM); 
   ObjectSetInteger(0,ObjName,OBJPROP_COLOR,clrRed); 
   ObjName = "Text" + IntegerToString(ticket, 0, ' ') + "SL";
   ObjectCreate(0,ObjName,OBJ_TEXT,0,TimeCurrent(),stoploss);
   ObjectSetString(0,ObjName,OBJPROP_TEXT,"SL");
   ObjectSetInteger(0,ObjName,OBJPROP_FONTSIZE,10);
   ObjectSetDouble(0,ObjName,OBJPROP_ANGLE,0);
   ObjectSetInteger(0,ObjName,OBJPROP_ANCHOR,ANCHOR_BOTTOM); 
   ObjectSetInteger(0,ObjName,OBJPROP_COLOR,clrRed);  
}