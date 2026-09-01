#property copyright "Fxpart.com"
#property link      "https://www.fxpart.com"
#property version   "4.1"
#property strict
#property description "TGR - Fxpart.com"

#include <Trade/Trade.mqh>

#define OP_BUY       0
#define OP_SELL      1
#define OP_BUYLIMIT  2
#define OP_SELLLIMIT 3
#define OP_BUYSTOP   4
#define OP_SELLSTOP  5

#define SELECT_BY_POS    0
#define SELECT_BY_TICKET 1
#define MODE_TRADES      0
#define MODE_HISTORY     1

#define MODE_BID          9
#define MODE_ASK          10
#define MODE_POINT        11
#define MODE_DIGITS       12
#define MODE_SPREAD       13
#define MODE_STOPLEVEL    14
#define MODE_LOTSIZE      15
#define MODE_TICKVALUE    16
#define MODE_TICKSIZE     17
#define MODE_SWAPLONG     18
#define MODE_SWAPSHORT    19
#define MODE_STARTING     20
#define MODE_EXPIRATION   21
#define MODE_TRADEALLOWED 22
#define MODE_MINLOT       23
#define MODE_LOTSTEP      24
#define MODE_MAXLOT       25
#define MODE_FREEZELEVEL  33

#define Blue  clrBlue
#define Red   clrRed
#define Green clrGreen

struct MQL4SelectedOrder
{
   bool     valid;
   bool     is_position;
   ulong    ticket;
   string   symbol;
   long     magic;
   int      type;
   double   lots;
   double   open_price;
   double   close_price;
   double   sl;
   double   tp;
   datetime open_time;
   datetime close_time;
   datetime expiration;
   string   comment;
   double   profit;
   double   swap;
   double   commission;
};

MQL4SelectedOrder __mql4_sel;

int __Mql4TypeFromOrderType(ENUM_ORDER_TYPE t)
{
   if(t==ORDER_TYPE_BUY_LIMIT)  return OP_BUYLIMIT;
   if(t==ORDER_TYPE_SELL_LIMIT) return OP_SELLLIMIT;
   if(t==ORDER_TYPE_BUY_STOP)   return OP_BUYSTOP;
   if(t==ORDER_TYPE_SELL_STOP)  return OP_SELLSTOP;
   if(t==ORDER_TYPE_BUY_STOP_LIMIT)  return OP_BUYSTOP;
   if(t==ORDER_TYPE_SELL_STOP_LIMIT) return OP_SELLSTOP;
   return -1;
}

ENUM_ORDER_TYPE __Mql5OrderTypeFromMql4(int cmd)
{
   if(cmd==OP_BUY)       return ORDER_TYPE_BUY;
   if(cmd==OP_SELL)      return ORDER_TYPE_SELL;
   if(cmd==OP_BUYLIMIT)  return ORDER_TYPE_BUY_LIMIT;
   if(cmd==OP_SELLLIMIT) return ORDER_TYPE_SELL_LIMIT;
   if(cmd==OP_BUYSTOP)   return ORDER_TYPE_BUY_STOP;
   if(cmd==OP_SELLSTOP)  return ORDER_TYPE_SELL_STOP;
   return ORDER_TYPE_BUY;
}

bool RefreshRates(){ return true; }
double MQL4_Bid(){ MqlTick t; SymbolInfoTick(_Symbol,t); return t.bid; }
double MQL4_Ask(){ MqlTick t; SymbolInfoTick(_Symbol,t); return t.ask; }

#define Bid MQL4_Bid()
#define Ask MQL4_Ask()
#define Point _Point
#define Digits _Digits

double AccountBalance(){ return AccountInfoDouble(ACCOUNT_BALANCE); }
double AccountEquity(){ return AccountInfoDouble(ACCOUNT_EQUITY); }
double AccountFreeMargin(){ return AccountInfoDouble(ACCOUNT_MARGIN_FREE); }
string AccountCurrency(){ return AccountInfoString(ACCOUNT_CURRENCY); }

double AccountFreeMarginCheck(string symbol,int cmd,double volume)
{
   ENUM_ORDER_TYPE type=(cmd==OP_SELL ? ORDER_TYPE_SELL : ORDER_TYPE_BUY);
   double price=(cmd==OP_SELL ? SymbolInfoDouble(symbol,SYMBOL_BID) : SymbolInfoDouble(symbol,SYMBOL_ASK));
   double margin=0.0;
   if(!OrderCalcMargin(type,symbol,volume,price,margin)) return -1.0;
   return AccountInfoDouble(ACCOUNT_MARGIN_FREE)-margin;
}

bool IsTesting(){ return (bool)MQLInfoInteger(MQL_TESTER); }
bool IsDemo(){ return (AccountInfoInteger(ACCOUNT_TRADE_MODE)==ACCOUNT_TRADE_MODE_DEMO); }

ENUM_TIMEFRAMES __Mql4Timeframe(int timeframe)
{
   switch(timeframe)
   {
      case 0:     return PERIOD_CURRENT;
      case 1:     return PERIOD_M1;
      case 2:     return PERIOD_M2;
      case 3:     return PERIOD_M3;
      case 4:     return PERIOD_M4;
      case 5:     return PERIOD_M5;
      case 6:     return PERIOD_M6;
      case 10:    return PERIOD_M10;
      case 12:    return PERIOD_M12;
      case 15:    return PERIOD_M15;
      case 20:    return PERIOD_M20;
      case 30:    return PERIOD_M30;
      case 60:    return PERIOD_H1;
      case 120:   return PERIOD_H2;
      case 180:   return PERIOD_H3;
      case 240:   return PERIOD_H4;
      case 360:   return PERIOD_H6;
      case 480:   return PERIOD_H8;
      case 720:   return PERIOD_H12;
      case 1440:  return PERIOD_D1;
      case 10080: return PERIOD_W1;
      case 43200: return PERIOD_MN1;
   }
   if(timeframe>=PERIOD_H1) return (ENUM_TIMEFRAMES)timeframe;
   return PERIOD_CURRENT;
}

int __Mql4Bars()
{
   return iBars(_Symbol,PERIOD_CURRENT);
}
#define Bars __Mql4Bars()

string MQL4_StringConcatenate(int first,string second)
{
   return IntegerToString(first)+second;
}
#define StringConcatenate MQL4_StringConcatenate

int __DatePart(datetime value,int part)
{
   MqlDateTime dt;
   TimeToStruct(value,dt);
   if(part==0) return dt.year;
   if(part==1) return dt.mon;
   if(part==2) return dt.day;
   if(part==3) return dt.day_of_week;
   if(part==4) return dt.hour;
   if(part==5) return dt.min;
   if(part==6) return dt.sec;
   if(part==7) return dt.day_of_year;
   return 0;
}

int Year(){ return __DatePart(TimeCurrent(),0); }
int Month(){ return __DatePart(TimeCurrent(),1); }
int Day(){ return __DatePart(TimeCurrent(),2); }
int DayOfWeek(){ return __DatePart(TimeCurrent(),3); }
int Hour(){ return __DatePart(TimeCurrent(),4); }
int Minute(){ return __DatePart(TimeCurrent(),5); }
int Seconds(){ return __DatePart(TimeCurrent(),6); }
int TimeYear(datetime value){ return __DatePart(value,0); }
int TimeMonth(datetime value){ return __DatePart(value,1); }
int TimeDay(datetime value){ return __DatePart(value,2); }
int TimeDayOfWeek(datetime value){ return __DatePart(value,3); }
int TimeHour(datetime value){ return __DatePart(value,4); }
int TimeMinute(datetime value){ return __DatePart(value,5); }
int TimeSeconds(datetime value){ return __DatePart(value,6); }
int TimeDayOfYear(datetime value){ return __DatePart(value,7); }

int OrdersTotalMQL4Compat(){ return (int)(PositionsTotal()+OrdersTotal()); }
#define OrdersTotal OrdersTotalMQL4Compat

double MarketInfo(string symbol,int mode)
{
   MqlTick tick;
   SymbolInfoTick(symbol,tick);
   switch(mode)
   {
      case MODE_BID: return tick.bid;
      case MODE_ASK: return tick.ask;
      case MODE_POINT: return SymbolInfoDouble(symbol,SYMBOL_POINT);
      case MODE_DIGITS: return (double)SymbolInfoInteger(symbol,SYMBOL_DIGITS);
      case MODE_SPREAD: return (double)SymbolInfoInteger(symbol,SYMBOL_SPREAD);
      case MODE_STOPLEVEL: return (double)SymbolInfoInteger(symbol,SYMBOL_TRADE_STOPS_LEVEL);
      case MODE_FREEZELEVEL: return (double)SymbolInfoInteger(symbol,SYMBOL_TRADE_FREEZE_LEVEL);
      case MODE_TICKVALUE: return SymbolInfoDouble(symbol,SYMBOL_TRADE_TICK_VALUE);
      case MODE_TICKSIZE: return SymbolInfoDouble(symbol,SYMBOL_TRADE_TICK_SIZE);
      case MODE_MINLOT: return SymbolInfoDouble(symbol,SYMBOL_VOLUME_MIN);
      case MODE_LOTSTEP: return SymbolInfoDouble(symbol,SYMBOL_VOLUME_STEP);
      case MODE_MAXLOT: return SymbolInfoDouble(symbol,SYMBOL_VOLUME_MAX);
      case MODE_TRADEALLOWED: return (double)(SymbolInfoInteger(symbol,SYMBOL_TRADE_MODE)!=SYMBOL_TRADE_MODE_DISABLED);
   }
   return 0.0;
}

bool __SelectPositionByIndex(int index)
{
   if(index<0 || index>=PositionsTotal()) return false;
   ulong ticket=PositionGetTicket(index);
   if(ticket==0 || !PositionSelectByTicket(ticket)) return false;
   __mql4_sel.valid=true; __mql4_sel.is_position=true; __mql4_sel.ticket=ticket;
   __mql4_sel.symbol=PositionGetString(POSITION_SYMBOL);
   __mql4_sel.magic=PositionGetInteger(POSITION_MAGIC);
   long ptype=PositionGetInteger(POSITION_TYPE);
   __mql4_sel.type=(ptype==POSITION_TYPE_BUY ? OP_BUY : OP_SELL);
   __mql4_sel.lots=PositionGetDouble(POSITION_VOLUME);
   __mql4_sel.open_price=PositionGetDouble(POSITION_PRICE_OPEN);
   __mql4_sel.close_price=PositionGetDouble(POSITION_PRICE_CURRENT);
   __mql4_sel.sl=PositionGetDouble(POSITION_SL);
   __mql4_sel.tp=PositionGetDouble(POSITION_TP);
   __mql4_sel.open_time=(datetime)PositionGetInteger(POSITION_TIME);
   __mql4_sel.close_time=0;
   __mql4_sel.expiration=0;
   __mql4_sel.comment=PositionGetString(POSITION_COMMENT);
   __mql4_sel.profit=PositionGetDouble(POSITION_PROFIT);
   __mql4_sel.swap=PositionGetDouble(POSITION_SWAP);
   __mql4_sel.commission=0.0;
   return true;
}

bool __SelectOrderByIndex(int index)
{
   if(index<0 || index>=OrdersTotal()) return false;
   ulong ticket=OrderGetTicket(index);
   if(ticket==0 || !OrderSelect(ticket)) return false;
   __mql4_sel.valid=true; __mql4_sel.is_position=false; __mql4_sel.ticket=ticket;
   __mql4_sel.symbol=OrderGetString(ORDER_SYMBOL);
   __mql4_sel.magic=OrderGetInteger(ORDER_MAGIC);
   __mql4_sel.type=__Mql4TypeFromOrderType((ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE));
   __mql4_sel.lots=OrderGetDouble(ORDER_VOLUME_CURRENT);
   __mql4_sel.open_price=OrderGetDouble(ORDER_PRICE_OPEN);
   __mql4_sel.close_price=0.0;
   __mql4_sel.sl=OrderGetDouble(ORDER_SL);
   __mql4_sel.tp=OrderGetDouble(ORDER_TP);
   __mql4_sel.open_time=(datetime)OrderGetInteger(ORDER_TIME_SETUP);
   __mql4_sel.close_time=0;
   __mql4_sel.expiration=(datetime)OrderGetInteger(ORDER_TIME_EXPIRATION);
   __mql4_sel.comment=OrderGetString(ORDER_COMMENT);
   __mql4_sel.profit=0.0; __mql4_sel.swap=0.0; __mql4_sel.commission=0.0;
   return true;
}

bool __SelectHistoryDealByTicket(ulong ticket)
{
   if(ticket==0 || !HistoryDealSelect(ticket)) return false;
   long dtype=HistoryDealGetInteger(ticket,DEAL_TYPE);
   if(dtype!=DEAL_TYPE_BUY && dtype!=DEAL_TYPE_SELL) return false;
   __mql4_sel.valid=true; __mql4_sel.is_position=false; __mql4_sel.ticket=ticket;
   __mql4_sel.symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
   __mql4_sel.magic=HistoryDealGetInteger(ticket,DEAL_MAGIC);
   __mql4_sel.type=(dtype==DEAL_TYPE_BUY ? OP_BUY : OP_SELL);
   __mql4_sel.lots=HistoryDealGetDouble(ticket,DEAL_VOLUME);
   __mql4_sel.open_price=HistoryDealGetDouble(ticket,DEAL_PRICE);
   __mql4_sel.close_price=HistoryDealGetDouble(ticket,DEAL_PRICE);
   __mql4_sel.sl=0.0;
   __mql4_sel.tp=0.0;
   __mql4_sel.open_time=(datetime)HistoryDealGetInteger(ticket,DEAL_TIME);
   __mql4_sel.close_time=(datetime)HistoryDealGetInteger(ticket,DEAL_TIME);
   __mql4_sel.expiration=0;
   __mql4_sel.comment=HistoryDealGetString(ticket,DEAL_COMMENT);
   __mql4_sel.profit=HistoryDealGetDouble(ticket,DEAL_PROFIT);
   __mql4_sel.swap=HistoryDealGetDouble(ticket,DEAL_SWAP);
   __mql4_sel.commission=HistoryDealGetDouble(ticket,DEAL_COMMISSION);
   return true;
}

int HistoryTotal()
{
   HistorySelect(0,TimeCurrent()+86400);
   return (int)HistoryDealsTotal();
}

bool __SelectHistoryDealByIndex(int index)
{
   HistorySelect(0,TimeCurrent()+86400);
   int total=(int)HistoryDealsTotal();
   if(index<0 || index>=total) return false;
   ulong ticket=HistoryDealGetTicket(index);
   return __SelectHistoryDealByTicket(ticket);
}

bool MQL4_OrderSelect(long index_or_ticket,int select,int pool=MODE_TRADES)
{
   __mql4_sel.valid=false;
   if(select==SELECT_BY_POS)
   {
      if(pool==MODE_TRADES)
      {
         int pc=PositionsTotal();
         if(index_or_ticket<pc) return __SelectPositionByIndex((int)index_or_ticket);
         return __SelectOrderByIndex((int)(index_or_ticket-pc));
      }
      if(pool==MODE_HISTORY) return __SelectHistoryDealByIndex((int)index_or_ticket);
      return false;
   }
   ulong ticket=(ulong)index_or_ticket;
   for(int i=0;i<PositionsTotal();i++)
      if(PositionGetTicket(i)==ticket) return __SelectPositionByIndex(i);
   if(OrderSelect(ticket))
   {
      __mql4_sel.valid=true; __mql4_sel.is_position=false; __mql4_sel.ticket=ticket;
      __mql4_sel.symbol=OrderGetString(ORDER_SYMBOL);
      __mql4_sel.magic=OrderGetInteger(ORDER_MAGIC);
      __mql4_sel.type=__Mql4TypeFromOrderType((ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE));
      __mql4_sel.lots=OrderGetDouble(ORDER_VOLUME_CURRENT);
      __mql4_sel.open_price=OrderGetDouble(ORDER_PRICE_OPEN);
      __mql4_sel.close_price=0.0;
      __mql4_sel.sl=OrderGetDouble(ORDER_SL); __mql4_sel.tp=OrderGetDouble(ORDER_TP);
      __mql4_sel.open_time=(datetime)OrderGetInteger(ORDER_TIME_SETUP);
      __mql4_sel.close_time=0;
      __mql4_sel.expiration=(datetime)OrderGetInteger(ORDER_TIME_EXPIRATION);
      __mql4_sel.comment=OrderGetString(ORDER_COMMENT);
      __mql4_sel.profit=0.0; __mql4_sel.swap=0.0; __mql4_sel.commission=0.0;
      return true;
   }
   if(__SelectHistoryDealByTicket(ticket)) return true;
   return false;
}
#define OrderSelect MQL4_OrderSelect

int OrderType(){ return __mql4_sel.type; }
long OrderTicket(){ return (long)__mql4_sel.ticket; }
double OrderLots(){ return __mql4_sel.lots; }
double OrderOpenPrice(){ return __mql4_sel.open_price; }
double OrderClosePrice(){ return __mql4_sel.close_price; }
double OrderStopLoss(){ return __mql4_sel.sl; }
double OrderTakeProfit(){ return __mql4_sel.tp; }
int OrderMagicNumber(){ return (int)__mql4_sel.magic; }
string OrderSymbol(){ return __mql4_sel.symbol; }
string OrderComment(){ return __mql4_sel.comment; }
datetime OrderOpenTime(){ return __mql4_sel.open_time; }
datetime OrderCloseTime(){ return __mql4_sel.close_time; }
datetime OrderExpiration(){ return __mql4_sel.expiration; }
double OrderProfit(){ return __mql4_sel.profit; }
double OrderSwap(){ return __mql4_sel.swap; }
double OrderCommission(){ return __mql4_sel.commission; }

bool __Mql5OrderSendRaw(MqlTradeRequest &req,MqlTradeResult &res)
{
   return OrderSend(req,res);
}

ENUM_ORDER_TYPE_FILLING __TGRBestFillingMode(string symbol)
{
   long filling=(long)SymbolInfoInteger(symbol,SYMBOL_FILLING_MODE);
   if((filling & SYMBOL_FILLING_IOC)==SYMBOL_FILLING_IOC) return ORDER_FILLING_IOC;
   if((filling & SYMBOL_FILLING_FOK)==SYMBOL_FILLING_FOK) return ORDER_FILLING_FOK;
   return ORDER_FILLING_RETURN;
}

string __TGRTradeRetcodeText(uint code)
{
   switch(code)
   {
      case TRADE_RETCODE_REQUOTE: return "requote";
      case TRADE_RETCODE_REJECT: return "request rejected";
      case TRADE_RETCODE_CANCEL: return "request canceled";
      case TRADE_RETCODE_PLACED: return "order placed";
      case TRADE_RETCODE_DONE: return "done";
      case TRADE_RETCODE_DONE_PARTIAL: return "partially done";
      case TRADE_RETCODE_ERROR: return "common trade error";
      case TRADE_RETCODE_TIMEOUT: return "trade timeout";
      case TRADE_RETCODE_INVALID: return "invalid request";
      case TRADE_RETCODE_INVALID_VOLUME: return "invalid volume";
      case TRADE_RETCODE_INVALID_PRICE: return "invalid price";
      case TRADE_RETCODE_INVALID_STOPS: return "invalid stops";
      case TRADE_RETCODE_TRADE_DISABLED: return "trade disabled for symbol/account";
      case TRADE_RETCODE_MARKET_CLOSED: return "market closed";
      case TRADE_RETCODE_NO_MONEY: return "not enough money";
      case TRADE_RETCODE_PRICE_CHANGED: return "price changed";
      case TRADE_RETCODE_PRICE_OFF: return "no price";
      case TRADE_RETCODE_INVALID_EXPIRATION: return "invalid expiration";
      case TRADE_RETCODE_TOO_MANY_REQUESTS: return "too many requests";
      case TRADE_RETCODE_NO_CHANGES: return "no changes";
      case TRADE_RETCODE_SERVER_DISABLES_AT: return "autotrading disabled by server";
      case TRADE_RETCODE_CLIENT_DISABLES_AT: return "autotrading disabled in terminal";
      case TRADE_RETCODE_LOCKED: return "trade context locked";
      case TRADE_RETCODE_FROZEN: return "order/position frozen";
      case TRADE_RETCODE_INVALID_FILL: return "invalid filling mode";
      case TRADE_RETCODE_CONNECTION: return "no trade connection";
      case TRADE_RETCODE_LIMIT_ORDERS: return "too many pending orders";
      case TRADE_RETCODE_LIMIT_VOLUME: return "volume limit reached";
      case TRADE_RETCODE_INVALID_ORDER: return "invalid order type";
   }
   return "unknown trade retcode";
}

void __TGRPrintTradeReject(string context,const MqlTradeRequest &req,const MqlTradeResult &res,int last_error)
{
   Print("TGR trade ",context,
         " | retcode=",res.retcode," (",__TGRTradeRetcodeText(res.retcode),")",
         " | last_error=",last_error,
         " | symbol=",req.symbol,
         " | action=",req.action,
         " | type=",req.type,
         " | filling=",req.type_filling,
         " | volume=",DoubleToString(req.volume,2),
         " | price=",DoubleToString(req.price,(int)SymbolInfoInteger(req.symbol,SYMBOL_DIGITS)),
         " | sl=",DoubleToString(req.sl,(int)SymbolInfoInteger(req.symbol,SYMBOL_DIGITS)),
         " | tp=",DoubleToString(req.tp,(int)SymbolInfoInteger(req.symbol,SYMBOL_DIGITS)));
}

void __TGRCheckTradePermissions(string stage)
{
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
      Print("TGR ",stage,": automated trading is disabled in the MT5 terminal. Enable the Algo Trading button.");
   if(!MQLInfoInteger(MQL_TRADE_ALLOWED))
      Print("TGR ",stage,": trading is not allowed for this EA. Check the Common tab and enable Allow Algo Trading.");
   if(!AccountInfoInteger(ACCOUNT_TRADE_ALLOWED))
      Print("TGR ",stage,": trading is not allowed for this account.");
   if(!AccountInfoInteger(ACCOUNT_TRADE_EXPERT))
      Print("TGR ",stage,": expert advisor trading is disabled for this account/server.");
}

ulong __FindNewestPositionTicket(string symbol,int magic,int cmd,string comment)
{
   ulong best_ticket=0;
   datetime best_time=0;
   long wanted_type=(cmd==OP_BUY ? POSITION_TYPE_BUY : POSITION_TYPE_SELL);
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      ulong ticket=PositionGetTicket(i);
      if(ticket==0 || !PositionSelectByTicket(ticket)) continue;
      if(PositionGetString(POSITION_SYMBOL)!=symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC)!=magic) continue;
      if(PositionGetInteger(POSITION_TYPE)!=wanted_type) continue;
      datetime opened=(datetime)PositionGetInteger(POSITION_TIME);
      if(opened>=best_time)
      {
         best_time=opened;
         best_ticket=ticket;
      }
   }
   return best_ticket;
}

long MQL4_OrderSend(string symbol,int cmd,double volume,double price,int slippage,double sl,double tp,string comment=NULL,int magic=0,datetime expiration=0,color arrow_color=clrNONE)
{
   MqlTradeRequest req; MqlTradeResult res; ZeroMemory(req); ZeroMemory(res);
   req.symbol=symbol; req.volume=volume; req.magic=magic; req.comment=comment; req.sl=sl; req.tp=tp; req.deviation=(uint)slippage;
   ENUM_ORDER_TYPE type=__Mql5OrderTypeFromMql4(cmd);
   req.type=type;
   if(cmd==OP_BUY || cmd==OP_SELL)
   {
      req.action=TRADE_ACTION_DEAL;
      req.price=(cmd==OP_BUY ? SymbolInfoDouble(symbol,SYMBOL_ASK) : SymbolInfoDouble(symbol,SYMBOL_BID));
      req.type_filling=__TGRBestFillingMode(symbol);
   }
   else
   {
      req.action=TRADE_ACTION_PENDING;
      req.price=price;
      if(expiration>0){ req.type_time=ORDER_TIME_SPECIFIED; req.expiration=expiration; }
      else req.type_time=ORDER_TIME_GTC;
      req.type_filling=ORDER_FILLING_RETURN;
   }
   if(!__Mql5OrderSendRaw(req,res)) { __TGRPrintTradeReject("send failed",req,res,GetLastError()); return -1; }
   if(res.retcode!=TRADE_RETCODE_DONE && res.retcode!=TRADE_RETCODE_PLACED && res.retcode!=TRADE_RETCODE_DONE_PARTIAL)
   { __TGRPrintTradeReject("send rejected",req,res,GetLastError()); return -1; }
   if(cmd==OP_BUY || cmd==OP_SELL)
   {
      ulong position_ticket=__FindNewestPositionTicket(symbol,magic,cmd,comment);
      if(position_ticket>0) return (long)position_ticket;
   }
   if(res.order>0) return (long)res.order;
   if(res.deal>0)  return (long)res.deal;
   return 0;
}
#define OrderSend MQL4_OrderSend

bool MQL4_OrderDelete(long ticket,color arrow_color=clrNONE)
{
   MqlTradeRequest req; MqlTradeResult res; ZeroMemory(req); ZeroMemory(res);
   req.action=TRADE_ACTION_REMOVE; req.order=(ulong)ticket;
   if(!__Mql5OrderSendRaw(req,res)) { Print("OrderDelete failed: ",GetLastError()," retcode=",res.retcode); return false; }
   return (res.retcode==TRADE_RETCODE_DONE || res.retcode==TRADE_RETCODE_PLACED);
}
#define OrderDelete MQL4_OrderDelete

bool MQL4_OrderClose(long ticket,double lots,double price,int slippage,color arrow_color=clrNONE)
{
   if(!PositionSelectByTicket((ulong)ticket)) return MQL4_OrderDelete(ticket,arrow_color);
   string symbol=PositionGetString(POSITION_SYMBOL);
   long ptype=PositionGetInteger(POSITION_TYPE);
   MqlTradeRequest req; MqlTradeResult res; ZeroMemory(req); ZeroMemory(res);
   req.action=TRADE_ACTION_DEAL; req.position=(ulong)ticket; req.symbol=symbol; req.volume=lots; req.deviation=(uint)slippage;
   req.type=(ptype==POSITION_TYPE_BUY ? ORDER_TYPE_SELL : ORDER_TYPE_BUY);
   req.price=(ptype==POSITION_TYPE_BUY ? SymbolInfoDouble(symbol,SYMBOL_BID) : SymbolInfoDouble(symbol,SYMBOL_ASK));
   req.type_filling=__TGRBestFillingMode(symbol);
   if(!__Mql5OrderSendRaw(req,res)) { __TGRPrintTradeReject("close failed",req,res,GetLastError()); return false; }
   if(res.retcode!=TRADE_RETCODE_DONE && res.retcode!=TRADE_RETCODE_DONE_PARTIAL)
   { __TGRPrintTradeReject("close rejected",req,res,GetLastError()); return false; }
   return (res.retcode==TRADE_RETCODE_DONE || res.retcode==TRADE_RETCODE_DONE_PARTIAL);
}
#define OrderClose MQL4_OrderClose

bool MQL4_OrderModify(long ticket,double price,double sl,double tp,datetime expiration,color arrow_color=clrNONE)
{
   MqlTradeRequest req; MqlTradeResult res; ZeroMemory(req); ZeroMemory(res);
   if(PositionSelectByTicket((ulong)ticket))
   {
      req.action=TRADE_ACTION_SLTP; req.position=(ulong)ticket; req.symbol=PositionGetString(POSITION_SYMBOL); req.sl=sl; req.tp=tp;
   }
   else
   {
      req.action=TRADE_ACTION_MODIFY; req.order=(ulong)ticket; req.price=price; req.sl=sl; req.tp=tp;
      if(expiration>0){ req.type_time=ORDER_TIME_SPECIFIED; req.expiration=expiration; }
   }
   if(!__Mql5OrderSendRaw(req,res)) { Print("OrderModify failed: ",GetLastError()," retcode=",res.retcode); return false; }
   return (res.retcode==TRADE_RETCODE_DONE || res.retcode==TRADE_RETCODE_PLACED || res.retcode==TRADE_RETCODE_NO_CHANGES);
}
#define OrderModify MQL4_OrderModify

datetime MQL4_iTime(string symbol,int timeframe,int shift)
{
   return iTime(symbol,__Mql4Timeframe(timeframe),shift);
}
#define iTime MQL4_iTime

int MQL4_iBars(string symbol,int timeframe)
{
   return iBars(symbol,__Mql4Timeframe(timeframe));
}
#define iBars MQL4_iBars

double MQL4_iOpen(string symbol,int timeframe,int shift)
{
   return iOpen(symbol,__Mql4Timeframe(timeframe),shift);
}
#define iOpen MQL4_iOpen

double MQL4_iHigh(string symbol,int timeframe,int shift)
{
   return iHigh(symbol,__Mql4Timeframe(timeframe),shift);
}
#define iHigh MQL4_iHigh

double MQL4_iLow(string symbol,int timeframe,int shift)
{
   return iLow(symbol,__Mql4Timeframe(timeframe),shift);
}
#define iLow MQL4_iLow

double MQL4_iClose(string symbol,int timeframe,int shift)
{
   return iClose(symbol,__Mql4Timeframe(timeframe),shift);
}
#define iClose MQL4_iClose

double MQL4_iFractals(string symbol,int timeframe,int mode,int shift)
{
   int buffer=(mode==1 ? 0 : 1);
   int handle=iFractals(symbol,__Mql4Timeframe(timeframe));
   if(handle==INVALID_HANDLE) return 0.0;
   double values[];
   ArraySetAsSeries(values,true);
   if(CopyBuffer(handle,buffer,shift,1,values)<=0)
   {
      IndicatorRelease(handle);
      return 0.0;
   }
   IndicatorRelease(handle);
   return values[0];
}
#define iFractals MQL4_iFractals

double MQL4_iMA(string symbol,int timeframe,int period,int ma_shift,int ma_method,int applied_price,int shift)
{
   ENUM_TIMEFRAMES tf=__Mql4Timeframe(timeframe);
   int handle=iMA(symbol,tf,period,ma_shift,(ENUM_MA_METHOD)ma_method,(ENUM_APPLIED_PRICE)applied_price);
   if(handle==INVALID_HANDLE) return 0.0;
   double buf[]; ArraySetAsSeries(buf,true);
   if(CopyBuffer(handle,0,shift,1,buf)<=0){ IndicatorRelease(handle); return 0.0; }
   IndicatorRelease(handle);
   return buf[0];
}
#define iMA MQL4_iMA


  enum enum_TradeFrequency      {Extreme_cons_Frequency = 0,//extreme conservative
                   Conservative_Frequency = 1,//conservative
                   Moderate_Frequency = 2,//moderate
                   Intens_Frequency = 3,//Intense
                   Extreme_Frequency = 4,//Extreme (high risk!)
                   Auto_Frequency = 5,//Auto (based on balance and risk)
                   Manual_Strategy_Selection = 6//Manual strategy selection
                     };
  enum e_SlippageControlMode      {SCT_1 = 1,SCT_2 = 2  };
  enum FakeoutFilters      {Filter_Off = 0,//OFF
                   Filter_Low = 1,//Low
                   Filter_Medium = 2,//Medium
                   Filter_High = 3//High
                     };
  enum e_VirtualStopMode      {VSL_OFF = 1,VSL_BASIC = 2,VSL_ADV = 3  };
  enum Select_Entry_Strategy      {Strategy_ONE = 1,Strategy_TWO = 2  };
  enum e_TimeFrame_St_ONE      {ST1_M1 = 1,ST1_M5 = 5,ST1_M15 = 15,ST1_M30 = 30,ST1_H1 = 60,ST1_H4 = 240,ST1_Daily = 1440,ST1_Chart = 0  };
  enum e_TimeFrame_Entry_Timing      {Entry_T_Tick = 0,Entry_T_M1 = 1,Entry_T_M5 = 5,Entry_T_M15 = 15,Entry_T_M30 = 30,Entry_T_H1 = 60,Entry_T_H4 = 240  };
  enum e_UseOfCompound      {no_compound = 0,one_trade = 1,Multi_trades = 2  };
  enum e_MonitorTradesFilter      {MT_all = 0,MT_PairOfChart = 1  };
  enum e_TimeFrame_Exit_Timing      {ET_Tick = 0,ET_M1 = 1,ET_M5 = 5,ET_M15 = 15,ET_M30 = 30,ET_H1 = 60  };
  enum e_Exit_HL_trailingSL_timeframe      {HLT_Chart = 0,HLT_M1 = 1,HLT_M5 = 5,HLT_M15 = 15,HLT_M30 = 30,HLT_H1 = 60,HLT_H4 = 240,HLT_D1 = 1440  };
  enum ST1_e_MagicTrail_Mode      {ST1_MT_M_O = 0,ST1_MT_M_F = 1,ST1_MT_M_B = 2  };
  enum e_Risk      {Manual_Lotsize = 0,//use StartLots
                   MaxHistoricalDD = 1234,//Max Allowed Total Drawdown
                   MaxRiskStrat = 3//Max Risk Per Strategy
                     };
  enum Performance_options      {NormalizedProfit = 2,RealProfit = 1  };
  enum RankingOptions      {ranking_profit = 1,ranking_pertrade = 2  };
  enum Reduction_choices      {Red_10 = 10,Red_20 = 20,Red_30 = 30,Red_40 = 40,Red_50 = 50,Red_60 = 60,Red_70 = 70,Red_80 = 80,Red_90 = 90  };
  enum e_factortype      {factor_type_1 = 1,factor_type_2 = 2,factor_type_3 = 3  };
  enum e_TimeSource      {TZ_GMT = 0,TZ_PC = 1,TZ_Broker = 2  };


//------------------
bool USE_CUSTOM_DASHBOARD=false;
bool STYLE_NATIVE_CANDLES=false;
bool SHOW_STYLED_CANDLES=false;
int  STYLED_CANDLES_COUNT=90;
int  VISUAL_REFRESH_SECONDS=1;
input group "01 - GENERAL";
input bool UseVariableValues=true  ;   
input bool AdjustLotsizeToVariableValues=true  ;   
input bool ShowInfoPanel=true  ;   
input double InfoPanelSizeAdjust=1  ;    //Adjustment for Infopanel size
input bool UpdateInfoTesting=false ;    //update infopanel during testing
input group "02 - TRADE SETUP";
input string spreadfilter="------------------------------ Settings ------------------------------"  ;   //- - -
input bool AllowBuyTrades=true  ;    //Allow Buy Trades
input bool AllowSellTrades=true  ;    //Allow Sell Trades
input  enum_TradeFrequency  TradeFrequency=4  ;   
input double MaxSpread=500  ;    //Maximum allowed spread
input bool PRINT_ENTRY_DEBUG=false  ;    //Print why pending orders are not placed
input bool UseHL_TrailingSL=true  ;   
input int   FridayStopHour=25  ;    //Friday stop hour (brokertime; close all trades)
input bool setSL_TP_After_Entry=false ;   
input bool Virtual_expiration=true  ;    //Use Virtual Expiration
input double Randomization=0  ;    //Randomization (entries and exit) in pips
input  FakeoutFilters  FakeOutFilter=2  ;    //Fake Breakout Filter
input int   ST1_MagicNumber=8000  ;    //BaseMagicnumber
input string ST1_Comment="TGR"  ;   //Comment for trades
input bool RemoveCommentSuffix=false ;   
input group "03 - NEWS AND TIME";
input string NFP_FILTER="----------------------- NFP Filter -----------------------"  ;  
input bool UseNewsFilter=false  ;    //Master switch for news/NFP filter
input bool EnableNFP_Filter=true  ;    //Legacy set compatibility
input bool AutoGMT=true  ;   
input bool UseExternalGMTSync=false  ;    //Allow WebRequest GMT sync
input int   Broker_GMT_OFFSET_Winter=2  ;    //GMT_OFFSET_Winter (AutoGMT=false or backtesting)
input int   Broker_GMT_OFFSET_Summer=3  ;    //MT_OFFSET_Summer (AutoGMT=false or backtesting)
input bool NFP_CloseOpenTrades=true  ;   
input bool NFP_ClosePendingOrders=true  ;   
input int   NFP_MinutesBefore=100  ;   
input int   NFP_MinutesAfter=60  ;   
input group "04 - PROP AND ENTRY ADJUSTMENTS";
input string propfirmsettings="----------------------- Propfirm unique trades settings -----------------------"  ;   //- - -
input double AdjustEntry=0  ;   
input double AdjustSL=0  ;   
input double AdjustTP=0  ;   
input double AdjustTrailSL=0  ;   
input double AdjustTrailTP=0  ;   
input double AdjustBreakEven=0  ;   
input group "05 - MONEY MANAGEMENT";
input string LotSizeSettings="----------------------- LotSize Settings -----------------------"  ;   //- - -
input double ForceBalanceToUse=0  ;    //manually set balance to use (if > 0)
input  e_Risk  Risk=1234  ;    //Lotsize Calculation method
input double StartLots=0.01  ;   
double StartLotsRuntime=0.01;
input double MaxAllowedDD=30  ;    //Max Allowed TOTAL Drawdown
input bool UseWeightedLots=true  ;    //Weighted Lotsize
input double MaxRiskPerStrategy_=1  ;    //Max Risk Per Strat
input double PropFirmMaxDailyDD=0  ;    //Set Max DAILY Drawdown (Prop Firms)
input bool UseEquity=false ;    //Use Equity Instead of Balance
input bool OnlyUp=true  ;   
input bool CheckMargin=true  ;    //check for free margin before setting trades
input group "06 - STRATEGIES";
input string ManualStratSelect="------------------------- Manual Strategy Selection -------------------------"  ;   //- - -
input string ManStratWarn="!! DO NOT RUN MANUAL STRATEGIES WHILE USING 'MAX ALLOWED TOTAL DD' OPTION !! "  ;   //- - -
input bool RunStrat1=true  ;    //Run Strategy 1 (low risk)
input bool RunStrat2=true  ;    //Run Strategy 2 (low risk)
input bool RunStrat3=true  ;    //Run Strategy 3 (low risk)
input bool RunStrat4=true  ;    //Run Strategy 4 (med risk)
input bool RunStrat5=true  ;    //Run Strategy 5 (med risk)
input bool RunStrat6=true  ;    //Run Strategy 6 (med risk)
input bool RunStrat7=true  ;    //Run Strategy 7 (med risk)
input bool RunStrat8=true  ;    //Run Strategy 8 (high risk)
input bool RunStrat9=true  ;    //Run Strategy 9 (high risk)
  double    g_var_1 = 0.0;
  double    g_var_2 = 0.0;
  int       g_var_3 = 30;
  int       g_var_4 = 1440;
  int       g_var_5 = 0;
  double    g_var_6[];
  double    g_var_7 = 0.0;
  double    g_var_8 = 0.0;
  double    g_var_9 = 0.0;
  bool      g_var_10 = false;
  int       g_var_11 = 3;
  int       g_var_12 = 2;
  bool      g_var_13 = false;
  bool      g_var_14 = false;
  int       g_var_15 = 0;
  string    g_var_16 = "------------------------------ trading filters ------------------------------";
  bool      g_var_17 = false;
  string    g_var_18 = "EURUSD;GBPUSD;USDJPY;AUDJPY;AUDUSD;EURAUD;EURCAD;EURGBP;EURJPY;GBPJPY;USDCAD;USDCHF;";
  int       g_var_19 = 5;
  bool      g_var_20 = true;
  bool      g_var_21 = false;
  bool      g_var_22 = false;
  bool      g_var_23 = true;
  bool      g_var_24 = false;
  bool      g_var_25 = false;
  bool      g_var_26 = true;
  bool      g_var_27 = false;
  bool      g_var_28 = false;
  bool      g_var_29 = false;
  bool      g_var_30 = false;
  bool      g_var_31 = false;
  bool      g_var_32 = false;
  bool      g_var_33 = false;
  bool      g_var_34 = false;
  bool      g_var_35 = true;
  int       g_var_36 = 2;
  double    g_var_37 = 0.0;
  double    g_var_38 = 5000.0;
  int       g_var_39 = 1;
  double    g_var_40 = 400.0;
  double    g_var_41 = 100.0;
  double    g_var_42 = 300.0;
  bool      g_var_43 = true;
  string    g_var_44 = "------------------------------ time filters ------------------------------";
  bool      g_var_45 = false;
  bool      g_var_46 = false;
  bool      g_var_47 = false;
  int       g_var_48 = 14;
  int       g_var_49 = 17;
  string    g_var_50 = "------------------------------ other filters ------------------------------";
  int       g_var_51 = 1;
  int       g_var_52 = 1;
  bool      g_var_53 = false;
  int       g_var_54 = 5;
  bool      g_var_55 = false;
  int       g_var_56 = 15;
  bool      g_var_57 = false;
  int       g_var_58 = 30;
  bool      g_var_59 = false;
  int       g_var_60 = 60;
  bool      g_var_61 = false;
  bool      g_var_62 = false;
  int       g_var_63 = 1;
  double    g_var_64 = 0.0;
  int       g_var_65 = 99;
  int       g_var_66 = 5;
  bool      g_var_67 = false;
  int       g_var_68 = 5;
  int       g_var_69 = 1;
  string    g_var_70 = "------------------------------ Trade Entry management ------------------------------";
  int       g_var_71 = 0;
  int       g_var_72 = 60;
  int       g_var_73 = 10;
  int       g_var_74 = 3;
  bool      g_var_75 = false;
  bool      g_var_76 = false;
  int       g_var_77 = 120;
  int       g_var_78 = 0;
  int       g_var_79 = 0;
  double    g_var_80 = 30.0;
  double    g_var_81 = 0.0;
  double    g_var_82 = 25.0;
  double    g_var_83 = 0.5;
  double    g_var_84 = 0.0;
  double    g_var_85 = 0.0;
  int       g_var_86 = 1;
  int       g_var_87 = 99;
  double    g_var_88 = 1.0;
  int       g_var_89 = 24;
  double    g_var_90 = 3.0;
  int       g_var_91 = 0;
  int       g_var_92 = 100;
  int       g_var_93 = 0;
  string    g_var_94 = "------------------------------ Strategy 2 - Manual Trade settings ------------------------------";
  int       g_var_95 = 1;
  int       g_var_96 = 1991199118;
  string    g_var_97 = "";
  string    g_var_98 = "------------------------------ Trade Exit management ------------------------------";
  int       g_var_99 = 0;
  double    g_var_100 = 20.0;
  double    g_var_101 = 100.0;
  string    g_var_102 = "------------------------------ Trailing SL settings ------------------------------";
  double    g_var_103 = 10.0;
  double    g_var_104 = 10.0;
  double    g_var_105 = 100.0;
  double    g_var_106 = 0.1;
  double    g_var_107 = 0.0;
  double    g_var_108 = 0.0;
  double    g_var_109 = 0.0;
  double    g_var_110 = 0.0;
  double    g_var_111 = 0.0;
  string    g_var_112 = "------------------------------ Break-even SL management ------------------------------";
  double    g_var_113 = 0.0;
  double    g_var_114 = 0.0;
  string    g_var_115 = "------------------------------ HIGH/LOW Trailing SL settings ------------------------------";
  bool      g_var_116 = false;
  int       g_var_117 = 0;
  int       g_var_118 = 0;
  int       g_var_119 = 0;
  int       g_var_120 = 0;
  int       g_var_121 = 0;
  int       g_var_122 = 0;
  double    g_var_123 = 2.0;
  string    g_var_124 = "------------------------------ recovery Trailing SL based on time ------------------------------";
  double    g_var_125 = 0.0;
  double    g_var_126 = 0.0;
  string    g_var_127 = "------------------------------ MagicTrail SL settings ------------------------------";
  int       g_var_128 = 0;
  double    g_var_129 = 0.1;
  int       g_var_130 = 1;
  double    g_var_131 = 0.1;
  double    g_var_132 = 1.0;
  int       g_var_133 = 0;
  double    g_var_134 = 0.0;
  bool      g_var_135 = false;
  bool      g_var_136 = false;
  int       g_var_137 = 2024;
  datetime  g_var_138[13];
  bool      g_var_139 = false;
  double    g_var_140 = 5.0;
  double    g_var_141 = 99.0;
  int       g_var_142 = 999;
  int       g_var_143 = 9999;
  int       g_var_144 = 99999;
  int       g_var_145 = 600;
  double    g_var_146 = 1.0;
  double    g_var_147 = 10.0;
  double    g_var_148 = 2.0;
  string    g_var_149 = "==== Performance numbers overview ====";
  bool      g_var_150 = true;
  int       g_var_151 = 1;
  int       g_var_152 = 1;
  int       g_var_153 = 90;
  int       g_var_154 = 30;
  int       g_var_155 = 10;
  int       g_var_156 = 50;
  bool      g_var_157 = true;
  string    g_var_158 = "------------------------------ zone_recovery_settings ------------------------------";
  bool      g_var_159 = false;
  double    g_var_160 = 50.0;
  double    g_var_161 = 10.0;
  double    g_var_162 = 5.0;
  double    g_var_163 = 0.0;
  int       g_var_164 = 1;
  double    g_var_165 = 2.0;
  int       g_var_166 = 999;
  double    g_var_167 = 100.0;
  int       g_var_168 = 900010;
  int       g_var_169 = 900011;
  string    g_var_170 = "------------------------- Trading hours ST1 -------------------------";
  bool      g_var_171 = false;
  int       g_var_172 = 2;
  bool      g_var_173 = false;
  int       g_var_174 = 0;
  int       g_var_175 = 24;
  int       g_var_176 = 0;
  int       g_var_177 = 24;
  int       g_var_178 = 0;
  int       g_var_179 = 24;
  int       g_var_180 = 0;
  int       g_var_181 = 24;
  int       g_var_182 = 0;
  int       g_var_183 = 24;
  int       g_var_184 = 0;
  int       g_var_185 = 24;
  string    g_var_186 = "------------------------- use for backtesting only! -------------------------";
  int       g_var_187 = 0;
  double    g_var_188 = 0.0;
  double    g_var_189 = 0.0;
  int       g_var_190 = 0;
  double    g_var_191 = 0.0;
  int       g_var_192 = 0;
  int       g_var_193 = 0;
  bool      g_var_194 = false;
  bool      g_var_195 = false;
  double    g_var_196[20][2];
  double    g_var_197[100][3];
  double    g_var_198[100][2];
  int       g_var_199 = 20;
  int       g_var_200 = 100;
  double    g_var_201 = 0.0;
  double    g_var_202 = 0.0;
  double    g_var_203 = 0.0;
  double    g_var_204 = 0.0;
  double    g_var_205 = 0.0;
  double    g_var_206 = 0.0;
  bool      g_var_207 = false;
  int       g_var_208 = 10;
  double    g_var_209 = 0.0;
  double    g_var_210 = 0.0;
  double    g_var_211 = 0.0;
  double    g_var_212 = 0.0;
  bool      g_var_213 = false;
  int       g_var_214 = 1;
  datetime  g_var_215[99];
  long      g_var_216 = 0;
  int       g_var_217 = 370;
  bool      g_var_218 = true;
  bool      g_var_219 = false;
  int       g_var_220 = 0;
  double    g_var_221 = 4.0;
  double    g_var_222 = 0.0;
  double    g_var_223[99];
  double    g_var_224 = 0.0;
  int       g_var_225 = 0;
  int       g_var_226 = 0;
  double    g_var_227 = 0.0;
  double    g_var_228 = 0.0;
  double    g_var_229 = 0.0;
  int       g_var_230 = 0;
  bool      g_var_231 = false;
  double    g_var_232 = 0.0;
  double    g_var_233 = 0.0;
  int       g_var_234 = 0;
  double    g_var_235 = 0.0;
  double    g_var_236 = 0.0;
  double    g_var_237 = 0.0;
  bool      g_var_238 = false;
  bool      g_var_239 = false;
  bool      g_var_240 = false;
  double    g_var_241[99];
  double    g_var_242[99];
  double    g_var_243 = 0.0;
  double    g_var_244 = 0.0;
  double    g_var_245 = 0.0;
  double    g_var_246 = 0.0;
  double    g_var_247 = 0.0;
  double    g_var_248 = 0.0;
  double    g_var_249 = 0.0;
  int       g_var_250 = 0;
  double    g_var_251 = 0.0;
  string    g_var_252;
  string    g_var_253;
  string    g_var_254;
  string    g_var_255;
  bool      g_var_256 = false;
  bool      g_var_257 = false;
  int       g_var_258 = 0;
  int       g_var_259 = 0;
  double    g_var_260 = 0.0;
  double    g_var_261 = 0.0;
  double    g_var_262 = 0.0;
  double    g_var_263 = 0.0;
  double    g_var_264 = 0.0;
  int       g_var_265 = 0;
  int       g_var_266 = 0;
  int       g_var_267 = 0;
  double    g_var_268 = 0.0;
  double    g_var_269 = 0.0;
  double    g_var_270 = 0.0;
  double    g_var_271 = 0.0;
  double    g_var_272 = 0.0;
  double    g_var_273 = 0.0;
  int       g_var_274 = 0;
  double    g_var_275 = 0.0;
  double    g_var_276 = 0.0;
  double    g_var_277 = 0.0;
  bool      g_var_278 = false;
  bool      g_var_279 = false;
  bool      g_var_280 = false;
  bool      g_var_281 = false;
  bool      g_var_282 = false;
  bool      g_var_283 = false;
  double    g_var_284 = 0.0;
  double    g_var_285 = 0.0;
  bool      g_var_286 = false;
  double    g_var_287 = 0.0;
  double    g_var_288 = 0.0;
  int       g_var_289 = 0;
  int       g_var_290 = 0;
  double    g_var_291[10];
  double    g_var_292[10];
  double    g_var_293[10];
  double    g_var_294[10];
  int       g_var_295 = 0;
  int       g_var_296 = 0;
  int       g_var_297 = 0;
  int       g_var_298 = 0;
  string    g_var_299;
  double    g_var_300 = 0.0;
  double    g_var_301 = 0.0;
  datetime  g_var_302 = 0;
  bool      g_var_303 = false;
  int       g_var_304 = 0;
  bool      g_var_305 = false;
  int       g_var_306 = 0;
  double    g_var_307 = 0.0;
  double    g_var_308 = 0.0;
  double    g_var_309 = 0.0;
  double    g_var_310 = 0.0;
  double    g_var_311 = 0.0;
  bool      g_var_312 = false;
  datetime  g_var_313 = 0;
  datetime  g_var_314 = 0;
  datetime  g_var_315 = 0;
  bool      g_var_316 = false;
  bool      g_var_317 = false;
  double    g_var_318 = 0.0;
  datetime  g_var_319 = 0;
  bool      g_var_320 = false;
  int       g_var_321[99];
  int       g_var_322[99];
  double    g_var_323[30];
  double    g_var_324[30];
  double    g_var_325[30];
  double    g_var_326[30];
  int       g_var_327 = 1;
  int       g_var_328 = 0;
  uint      g_var_329 = DarkBlue;
  bool      g_var_330 = false;
  long      g_var_331 = 0;
  int       g_var_332 = 5;
  bool      g_var_333 = false;
  string    g_var_334;
  bool      g_var_335 = false;
  string    g_var_336;
  double    g_var_337 = 0.0;
  double    g_var_338 = 0.0;
  int       g_var_339[99];
  int       g_var_340 = 0;
  double    g_var_341[99];
  bool      g_var_342[99];
  int       g_var_343[99];
  int       g_var_344[99];
  double    g_var_345[99];
  double    g_var_346[99];
  string    g_var_347[99]={};
  bool      g_var_348[99];
  double    g_var_349[99];
  double    g_var_350[99];
  double    g_var_351[99];
  double    g_var_352[99];
  double    g_var_353[99];
  double    g_var_354[99];
  bool      g_var_355[99];
  int       g_var_356[99];
  bool      g_var_357 = false;
  double    g_var_358 = 5.0;
  double    g_var_359 = 10.0;
  int       g_var_360 = 0;
  double    g_var_361 = 0.0;
  double    g_var_362 = 0.0;
  int       g_var_363 = 0;
  uint      g_var_364 = LightSteelBlue;
  bool      g_var_365 = true;
  double    g_var_366 = 12.0;
  int       g_var_367 = 230;
  int       g_var_368 = 320;
  int       g_var_369 = 500;
  int       g_var_370 = 350;
  int       g_var_371 = 2;
  int       g_var_372 = 7;
  int       g_var_373 = 10;
  int       g_var_374 = 30;
  string    g_var_375[4]={};
  double    g_var_376 = 0.45;
  double    g_var_377 = 0.6;
  int       g_var_378 = 0;
  datetime  g_var_379 = 0;
  bool      g_var_380 = false;
  int       g_var_381 = 0;
  bool      g_var_382 = false;
  int       g_var_383 = 0;
  double    g_var_384 = 0.0;
  int       g_var_385 = 200;
  int       g_var_386 = 330;
  int       g_var_387 = 560;
  int       g_var_388 = 810;
  int       g_var_389 = 1150;
  datetime  g_var_390 = 0;
  datetime  g_var_391[300];
  bool      g_var_392 = false;
  bool      g_var_393 = false;
  bool      g_var_394 = false;
  int       g_var_395 = 0;
  int       g_var_396 = 0;
  double    g_var_397 = 0.0;
  double    g_var_398 = 0.0;
  datetime  g_var_399 = 0;
  double    g_var_400[99];
  double    g_var_401 = 0.0;
  double    g_var_402 = 0.0;
  int init()
{
  double    l_var_2;
  double    l_var_3;
  int       l_var_4;
  int       l_var_5;
  int       l_var_6;
  int       l_var_7;
  int       l_var_8;
  int       l_var_9;
//----- -----
  bool      tmp_var_1;

  g_var_401 = AccountInfoDouble(ACCOUNT_BALANCE) ;
  if ( UseEquity )
  {
    g_var_401 = AccountInfoDouble(ACCOUNT_EQUITY) ;
  }
  if ( ForceBalanceToUse>0.0 )
  {
    g_var_401 = ForceBalanceToUse ;
  }
  g_var_402 = g_var_401 ;
  g_var_392 = false ;
  g_var_393 = false ;
  g_var_391[0] = D'2026.12.04 12:30';
  g_var_391[1] = D'2026.11.06 12:30';
  g_var_391[2] = D'2026.10.02 12:30';
  g_var_391[3] = D'2026.09.04 12:30';
  g_var_391[4] = D'2026.08.07 12:30';
  g_var_391[5] = D'2026.07.02 12:30';
  g_var_391[6] = D'2026.06.05 12:30';
  g_var_391[7] = D'2026.05.08 12:30';
  g_var_391[8] = D'2026.04.03 12:30';
  g_var_391[9] = D'2026.03.06 12:30';
  g_var_391[10] = D'2026.02.11 12:30';
  g_var_391[11] = D'2026.01.09 12:30';
  g_var_391[12] = D'2025.12.16 12:30';
  g_var_391[13] = D'2025.11.07 12:30';
  g_var_391[14] = D'2025.10.03 12:30';
  g_var_391[15] = D'2025.09.05 12:30';
  g_var_391[16] = D'2025.08.01 12:30';
  g_var_391[17] = D'2025.07.03 12:30';
  g_var_391[18] = D'2025.06.06 12:30';
  g_var_391[19] = D'2025.05.02 12:30';
  g_var_391[20] = D'2025.04.04 12:30';
  g_var_391[21] = D'2025.03.07 12:30';
  g_var_391[22] = D'2025.02.07 12:30';
  g_var_391[23] = D'2025.01.10 12:30';
  g_var_391[24] = D'2024.12.06 12:30';
  g_var_391[25] = D'2024.11.01 12:30';
  g_var_391[26] = D'2024.10.04 12:30';
  g_var_391[27] = D'2024.09.06 12:30';
  g_var_391[28] = D'2024.08.02 12:30';
  g_var_391[29] = D'2024.07.05 12:30';
  g_var_391[30] = D'2024.06.07 12:30';
  g_var_391[31] = D'2024.05.03 12:30';
  g_var_391[32] = D'2024.04.05 12:30';
  g_var_391[33] = D'2024.03.08 12:30';
  g_var_391[34] = D'2024.02.02 12:30';
  g_var_391[35] = D'2024.01.05 12:30';
  g_var_391[36] = D'2023.12.08 12:30';
  g_var_391[37] = D'2023.11.03 12:30';
  g_var_391[38] = D'2023.10.06 12:30';
  g_var_391[39] = D'2023.09.01 12:30';
  g_var_391[40] = D'2023.08.04 12:30';
  g_var_391[41] = D'2023.07.07 12:30';
  g_var_391[42] = D'2023.06.02 12:30';
  g_var_391[43] = D'2023.05.05 12:30';
  g_var_391[44] = D'2023.04.07 12:30';
  g_var_391[45] = D'2023.03.10 12:30';
  g_var_391[46] = D'2023.02.03 12:30';
  g_var_391[47] = D'2023.01.06 12:30';
  g_var_391[48] = D'2022.12.02 12:30';
  g_var_391[49] = D'2022.11.04 12:30';
  g_var_391[50] = D'2022.10.07 12:30';
  g_var_391[51] = D'2022.09.02 12:30';
  g_var_391[52] = D'2022.08.05 12:30';
  g_var_391[53] = D'2022.07.08 12:30';
  g_var_391[54] = D'2022.06.03 12:30';
  g_var_391[55] = D'2022.05.06 12:30';
  g_var_391[56] = D'2022.04.01 12:30';
  g_var_391[57] = D'2022.03.04 12:30';
  g_var_391[58] = D'2022.02.04 12:30';
  g_var_391[59] = D'2022.01.07 12:30';
  g_var_391[60] = D'2021.12.03 12:30';
  g_var_391[61] = D'2021.11.05 12:30';
  g_var_391[62] = D'2021.10.08 12:30';
  g_var_391[63] = D'2021.09.03 12:30';
  g_var_391[64] = D'2021.08.06 12:30';
  g_var_391[65] = D'2021.07.02 12:30';
  g_var_391[66] = D'2021.06.04 12:30';
  g_var_391[67] = D'2021.05.07 12:30';
  g_var_391[68] = D'2021.04.02 12:30';
  g_var_391[69] = D'2021.03.05 12:30';
  g_var_391[70] = D'2021.02.05 12:30';
  g_var_391[71] = D'2021.01.08 12:30';
  g_var_391[72] = D'2020.12.04 12:30';
  g_var_391[73] = D'2020.11.06 12:30';
  g_var_391[74] = D'2020.10.02 12:30';
  g_var_391[75] = D'2020.09.04 12:30';
  g_var_391[76] = D'2020.08.07 12:30';
  g_var_391[77] = D'2020.07.02 12:30';
  g_var_391[78] = D'2020.06.05 12:30';
  g_var_391[79] = D'2020.05.08 12:30';
  g_var_391[80] = D'2020.04.03 12:30';
  g_var_391[81] = D'2020.03.06 12:30';
  g_var_391[82] = D'2020.02.07 12:30';
  g_var_391[83] = D'2020.01.10 12:30';
  g_var_391[84] = D'2019.12.06 12:30';
  g_var_391[85] = D'2019.11.01 12:30';
  g_var_391[86] = D'2019.10.04 12:30';
  g_var_391[87] = D'2019.09.06 12:30';
  g_var_391[88] = D'2019.08.02 12:30';
  g_var_391[89] = D'2019.07.05 12:30';
  g_var_391[90] = D'2019.06.07 12:30';
  g_var_391[91] = D'2019.05.03 12:30';
  g_var_391[92] = D'2019.04.05 12:30';
  g_var_391[93] = D'2019.03.08 12:30';
  g_var_391[94] = D'2019.02.01 12:30';
  g_var_391[95] = D'2019.01.04 12:30';
  g_var_391[96] = D'2018.12.07 12:30';
  g_var_391[97] = D'2018.11.02 12:30';
  g_var_391[98] = D'2018.10.05 12:30';
  g_var_391[99] = D'2018.09.07 12:30';
  g_var_391[100] = D'2018.08.03 12:30';
  g_var_391[101] = D'2018.07.06 12:30';
  g_var_391[102] = D'2018.06.01 12:30';
  g_var_391[103] = D'2018.05.04 12:30';
  g_var_391[104] = D'2018.04.06 12:30';
  g_var_391[105] = D'2018.03.09 12:30';
  g_var_391[106] = D'2018.02.02 12:30';
  g_var_391[107] = D'2018.01.05 12:30';
  g_var_391[108] = D'2017.12.08 12:30';
  g_var_391[109] = D'2017.11.03 12:30';
  g_var_391[110] = D'2017.10.06 12:30';
  g_var_391[111] = D'2017.09.01 12:30';
  g_var_391[112] = D'2017.08.04 12:30';
  g_var_391[113] = D'2017.07.07 12:30';
  g_var_391[114] = D'2017.06.02 12:30';
  g_var_391[115] = D'2017.05.05 12:30';
  g_var_391[116] = D'2017.04.07 12:30';
  g_var_391[117] = D'2017.03.10 12:30';
  g_var_391[118] = D'2017.02.03 12:30';
  g_var_391[119] = D'2017.01.06 12:30';
  g_var_391[120] = D'2016.12.02 12:30';
  g_var_391[121] = D'2016.11.04 12:30';
  g_var_391[122] = D'2016.10.07 12:30';
  g_var_391[123] = D'2016.09.02 12:30';
  g_var_391[124] = D'2016.08.05 12:30';
  g_var_391[125] = D'2016.07.08 12:30';
  g_var_391[126] = D'2016.06.03 12:30';
  g_var_391[127] = D'2016.05.06 12:30';
  g_var_391[128] = D'2016.04.01 12:30';
  g_var_391[129] = D'2016.03.04 12:30';
  g_var_391[130] = D'2016.02.05 12:30';
  g_var_391[131] = D'2016.01.08 12:30';
  g_var_391[132] = D'2015.12.04 12:30';
  g_var_391[133] = D'2015.11.06 12:30';
  g_var_391[134] = D'2015.10.02 12:30';
  g_var_391[135] = D'2015.09.04 12:30';
  g_var_391[136] = D'2015.08.07 12:30';
  g_var_391[137] = D'2015.07.02 12:30';
  g_var_391[138] = D'2015.06.05 12:30';
  g_var_391[139] = D'2015.05.08 12:30';
  g_var_391[140] = D'2015.04.03 12:30';
  g_var_391[141] = D'2015.03.06 12:30';
  g_var_391[142] = D'2015.02.06 12:30';
  g_var_391[143] = D'2015.01.09 12:30';
  g_var_391[144] = D'2014.12.05 12:30';
  g_var_391[145] = D'2014.11.07 12:30';
  g_var_391[146] = D'2014.10.03 12:30';
  g_var_391[147] = D'2014.09.05 12:30';
  g_var_391[148] = D'2014.08.01 12:30';
  g_var_391[149] = D'2014.07.03 12:30';
  g_var_391[150] = D'2014.06.06 12:30';
  g_var_391[151] = D'2014.05.02 12:30';
  g_var_391[152] = D'2014.04.04 12:30';
  g_var_391[153] = D'2014.03.07 12:30';
  g_var_391[154] = D'2014.02.07 12:30';
  g_var_391[155] = D'2014.01.10 12:30';
  g_var_391[156] = D'2013.12.06 12:30';
  g_var_391[157] = D'2013.11.08 12:30';
  g_var_391[158] = D'2013.10.22 12:30';
  g_var_391[159] = D'2013.09.06 12:30';
  g_var_391[160] = D'2013.08.02 12:30';
  g_var_391[161] = D'2013.07.05 12:30';
  g_var_391[162] = D'2013.06.07 12:30';
  g_var_391[163] = D'2013.05.03 12:30';
  g_var_391[164] = D'2013.04.05 12:30';
  g_var_391[165] = D'2013.03.08 12:30';
  g_var_391[166] = D'2013.02.01 12:30';
  g_var_391[167] = D'2013.01.04 12:30';
  g_var_391[168] = D'2012.12.07 12:30';
  g_var_391[169] = D'2012.11.02 12:30';
  g_var_391[170] = D'2012.10.05 12:30';
  g_var_391[171] = D'2012.09.07 12:30';
  g_var_391[172] = D'2012.08.03 12:30';
  g_var_391[173] = D'2012.07.06 12:30';
  g_var_391[174] = D'2012.06.01 12:30';
  g_var_391[175] = D'2012.05.04 12:30';
  g_var_391[176] = D'2012.04.06 12:30';
  g_var_391[177] = D'2012.03.09 12:30';
  g_var_391[178] = D'2012.02.03 12:30';
  g_var_391[179] = D'2012.01.06 12:30';
  g_var_391[180] = D'2011.12.02 12:30';
  g_var_391[181] = D'2011.11.04 12:30';
  g_var_391[182] = D'2011.10.07 12:30';
  g_var_391[183] = D'2011.09.02 12:30';
  g_var_391[184] = D'2011.08.05 12:30';
  g_var_391[185] = D'2011.07.08 12:30';
  g_var_391[186] = D'2011.06.03 12:30';
  g_var_391[187] = D'2011.05.06 12:30';
  g_var_391[188] = D'2011.04.01 12:30';
  g_var_391[189] = D'2011.03.04 12:30';
  g_var_391[190] = D'2011.02.04 12:30';
  g_var_391[191] = D'2011.01.07 12:30';
  g_var_391[192] = D'2010.12.03 12:30';
  g_var_391[193] = D'2010.11.05 12:30';
  g_var_391[194] = D'2010.10.08 12:30';
  g_var_391[195] = D'2010.09.03 12:30';
  g_var_391[196] = D'2010.08.06 12:30';
  g_var_391[197] = D'2010.07.02 12:30';
  g_var_391[198] = D'2010.06.04 12:30';
  g_var_391[199] = D'2010.05.07 12:30';
  g_var_391[200] = D'2010.04.02 12:30';
  g_var_391[201] = D'2010.03.05 12:30';
  g_var_391[202] = D'2010.02.05 12:30';
  g_var_391[203] = D'2010.01.08 12:30';
  g_var_391[204] = D'2009.12.04 12:30';
  g_var_391[205] = D'2009.11.06 12:30';
  g_var_391[206] = D'2009.10.02 12:30';
  g_var_391[207] = D'2009.09.04 12:30';
  g_var_391[208] = D'2009.08.07 12:30';
  g_var_391[209] = D'2009.07.02 12:30';
  g_var_391[210] = D'2009.06.05 12:30';
  g_var_391[211] = D'2009.05.08 12:30';
  g_var_391[212] = D'2009.04.03 12:30';
  g_var_391[213] = D'2009.03.06 12:30';
  g_var_391[214] = D'2009.02.06 12:30';
  g_var_391[215] = D'2009.01.09 12:30';
  g_var_391[216] = D'2008.12.05 12:30';
  g_var_391[217] = D'2008.11.07 12:30';
  g_var_391[218] = D'2008.10.03 12:30';
  g_var_391[219] = D'2008.09.05 12:30';
  g_var_391[220] = D'2008.08.01 12:30';
  g_var_391[221] = D'2008.07.03 12:30';
  g_var_391[222] = D'2008.06.06 12:30';
  g_var_391[223] = D'2008.05.02 12:30';
  g_var_391[224] = D'2008.04.04 12:30';
  g_var_391[225] = D'2008.03.07 12:30';
  g_var_391[226] = D'2008.02.01 12:30';
  g_var_391[227] = D'2008.01.04 12:30';
  g_var_391[228] = D'2007.12.07 12:30';
  g_var_391[229] = D'2007.11.02 12:30';
  g_var_391[230] = D'2007.10.05 12:30';
  g_var_391[231] = D'2007.09.07 12:30';
  g_var_391[232] = D'2007.08.03 12:30';
  g_var_391[233] = D'2007.07.06 12:30';
  g_var_391[234] = D'2007.06.01 12:30';
  g_var_391[235] = D'2007.05.04 12:30';
  g_var_391[236] = D'2007.04.06 12:30';
  g_var_391[237] = D'2007.03.09 12:30';
  g_var_391[238] = D'2007.02.02 12:30';
  g_var_391[239] = D'2007.01.05 12:30';

  if ( Risk == 1234 )
  {
    StartLotsRuntime = MarketInfo(g_var_336,MODE_MINLOT) ;
  }
  if ( TradeFrequency == 5 && Risk == 1234 )
  {
    l_var_2 = TGR_36(AccountInfoDouble(ACCOUNT_BALANCE)) ;
    l_var_3 = MaxAllowedDD / 100.0 * l_var_2 ;
    if ( l_var_3>g_var_388 )
    {
      g_var_19 = 3 ;
    }
    else
    {
      if ( l_var_3>g_var_387 )
      {
        g_var_19 = 2 ;
      }
      else
      {
        if ( l_var_3>g_var_386 )
        {
          g_var_19 = 1 ;
        }
        else
        {
          g_var_19 = 0 ;
        }
      }
    }
  }
  else
  {
    g_var_19 = TradeFrequency ;
  }
  if ( g_var_19 == 0 )
  {
    g_var_27 = false ;
    g_var_31 = false ;
    g_var_28 = false ;
    g_var_33 = false ;
    g_var_34 = false ;
    g_var_32 = false ;
    g_var_398 = 2.4 ;
    if ( UseVariableValues )
    {
      g_var_398 = 3.0 ;
    }
  }
  else
  {
    if ( g_var_19 == 1 )
    {
      g_var_27 = true ;
      g_var_31 = true ;
      g_var_28 = false ;
      g_var_33 = false ;
      g_var_34 = false ;
      g_var_32 = false ;
      g_var_398 = 3.4 ;
      if ( UseVariableValues )
      {
        g_var_398 = 4.0 ;
      }
    }
    else
    {
      if ( g_var_19 == 2 )
      {
        g_var_27 = true ;
        g_var_31 = true ;
        g_var_28 = true ;
        g_var_33 = true ;
        g_var_34 = false ;
        g_var_32 = false ;
        g_var_398 = 4.1 ;
        if ( UseVariableValues )
        {
          g_var_398 = 5.0 ;
        }
      }
      else
      {
        if ( g_var_19 == 3 )
        {
          g_var_27 = true ;
          g_var_31 = true ;
          g_var_28 = true ;
          g_var_33 = true ;
          g_var_34 = true ;
          g_var_32 = false ;
          g_var_398 = 4.8 ;
          if ( UseVariableValues )
          {
            g_var_398 = 5.6 ;
          }
        }
        else
        {
          if ( g_var_19 == 4 )
          {
            g_var_27 = true ;
            g_var_31 = true ;
            g_var_28 = true ;
            g_var_33 = true ;
            g_var_34 = true ;
            g_var_32 = true ;
            g_var_398 = 5.1 ;
            if ( UseVariableValues )
            {
              g_var_398 = 6.0 ;
            }
          }
          else
          {
            if ( g_var_19 == 6 )
            {
              g_var_20 = RunStrat1 ;
              g_var_23 = RunStrat2 ;
              g_var_26 = RunStrat3 ;
              g_var_27 = RunStrat4 ;
              g_var_31 = RunStrat5 ;
              g_var_28 = RunStrat6 ;
              g_var_33 = RunStrat7 ;
              g_var_34 = RunStrat8 ;
              g_var_32 = RunStrat9 ;
            }
          }
        }
      }
    }
  }
  g_var_334 = ST1_Comment ;
  g_var_384 = 0.0 ;
  g_var_382 = false ;
  g_var_379 = 0 ;
  g_var_380 = true ;
  g_var_358 = 5.0 ;
  g_var_359 = 10.0 ;
  g_var_93 = ST1_MagicNumber ;
  g_var_360 = 300 ;
  g_var_361 = g_var_372 * 25 * g_var_376 * InfoPanelSizeAdjust ;
  g_var_362 = g_var_372 * 3.5 * g_var_377 * InfoPanelSizeAdjust ;
  g_var_363 = 7 ;
  g_var_328 = 0 ;
  g_var_336 = Symbol() ;
  g_var_337 = SymbolInfoDouble(g_var_336,16) ;
  g_var_229 = g_var_337 ;
  if ( ( MarketInfo(g_var_336,MODE_DIGITS)==3.0 || MarketInfo(g_var_336,MODE_DIGITS)==5.0 ) )
  {
    g_var_229 = g_var_337 * 10.0 ;
  }
  if ( SymbolInfoInteger(g_var_336,17) == 0x1 )
  {
    g_var_229 = g_var_337 / 10.0 ;
  }
  g_var_190 = MarketInfo(g_var_336,MODE_DIGITS) ;
  if ( FridayStopHour <  0 )
  {
    g_var_45 = false ;
  }
  else
  {
    g_var_45 = true ;
  }
  g_var_251 = TimeCurrent() ;
  g_var_1 = MarketInfo(g_var_336,MODE_ASK) - MarketInfo(g_var_336,MODE_BID) ;
  g_var_223[g_var_328] = NormalizeDouble(MathFloor(StartLotsRuntime * 100.0) / 100.0,2);
  if ( MarketInfo(g_var_336,MODE_LOTSTEP)==0.1 )
  {
     g_var_223[g_var_328] = NormalizeDouble((MathFloor(StartLotsRuntime * 10.0)) / 10.0,1);
    if ( g_var_223[g_var_328]<0.1 )
    {
      g_var_223[g_var_328] = 0.1;
    }
  }
  if ( g_var_223[g_var_328]<MarketInfo(g_var_336,MODE_MINLOT) )
  {
    g_var_223[g_var_328] = MarketInfo(g_var_336,MODE_MINLOT);
  }
  if ( g_var_223[g_var_328]>MarketInfo(g_var_336,MODE_MAXLOT) )
  {
    g_var_223[g_var_328] = MarketInfo(g_var_336,MODE_MAXLOT);
  }
  g_var_306 = Bars ;
  if ( g_var_131 * g_var_229<g_var_337 )
  {
    g_var_131 = g_var_337 / g_var_229 ;
  }
  g_var_307 = AccountBalance() ;
  g_var_221 = MarketInfo(g_var_336,MODE_STOPLEVEL) * g_var_337 ;
  g_var_309 = MarketInfo(g_var_336,MODE_FREEZELEVEL) * g_var_337 ;
  g_var_299 = StringSubstr(Symbol(),6,10) ;
  if ( g_var_299 != "" )
  {
    Print("Suffix detected: " + g_var_299); 
  }
  if ( ( StringFind(Symbol(),"XAUUSD",0) >= 0 || StringFind(Symbol(),"xauusd",0) >= 0 || StringFind(Symbol(),"GOLD",0) >= 0 || StringFind(Symbol(),"gold",0) >= 0 || StringFind(Symbol(),"Gold",0) >= 0 || StringFind(Symbol(),"GLD",0) >= 0 ) )
  {
    g_var_336 = Symbol() ;
    g_var_347[g_var_378] = Symbol();
    TGR_37(); 
    TGR_6(0); 
    g_var_378 ++;
  }
  else
  {
    g_var_336 = Symbol() ;
    TGR_6(0); 
  }
  if ( !(g_var_380) )
  {
    Print("Initialisation of pairs failed!"); 
  }
  if ( g_var_100<=0.0 )
  {
    g_var_100 = 1.0 ;
  }
  if ( g_var_101<=0.0 )
  {
    g_var_101 = 1.0 ;
  }
  if ( g_var_114>g_var_113 )
  {
    g_var_114 = g_var_113 + 0.1 ;
  }
  if ( g_var_36<g_var_309 / g_var_229 )
  {
    g_var_36 = g_var_309 / g_var_229 ;
  }
  if ( g_var_103!=0.0 && g_var_103<g_var_309 / g_var_229 )
  {
    g_var_103 = g_var_309 / g_var_229 ;
  }
  if ( g_var_103!=0.0 && g_var_103<g_var_221 / g_var_229 )
  {
    g_var_103 = g_var_221 / g_var_229 ;
  }
  if ( g_var_125>0.0 && g_var_126<g_var_309 / g_var_229 )
  {
    g_var_126 = g_var_309 / g_var_229 ;
  }
  if ( g_var_125>0.0 && g_var_126<g_var_221 / g_var_229 )
  {
    g_var_126 = g_var_221 / g_var_229 ;
  }
  if ( g_var_100<g_var_221 * 2.0 / g_var_229 )
  {
    g_var_100 = g_var_221 * 2.0 / g_var_229 ;
  }
  if ( g_var_101<g_var_221 * 2.0 / g_var_229 )
  {
    g_var_101 = g_var_221 * 2.0 / g_var_229 ;
  }
  if ( g_var_80<g_var_221 * 2.0 / g_var_229 )
  {
    g_var_80 = g_var_221 * 2.0 / g_var_229 ;
  }
  if ( g_var_73 <  1 )
  {
    g_var_73 = 1 ;
  }
  if ( g_var_74 <  1 )
  {
    g_var_74 = 1 ;
  }
  if ( g_var_80<0.1 )
  {
    g_var_80 = 0.1 ;
  }
  g_var_234=g_var_89 * 60 * 60;
  if ( g_var_89 >  0 )
  {
    g_var_302=TimeCurrent() + g_var_234;
  }
  else
  {
    g_var_302 = 0 ;
  }
  if ( Virtual_expiration )
  {
    g_var_302 = 0 ;
  }
  g_var_320 = false ;
  g_var_260 = Seconds() ;
  g_var_319 = TimeCurrent() ;
  g_var_194 = false ;
  g_var_195 = false ;
  g_var_258 = Month() ;
  g_var_313 = iTime(g_var_336,PERIOD_W1,1) ;
  g_var_314 = iTime(g_var_336,PERIOD_M1,1) ;
  g_var_315 = iTime(g_var_336,PERIOD_M1,1) ;
  if ( g_var_37>MaxSpread )
  {
    g_var_37 = MaxSpread ;
  }
  g_var_257 = false ;
  TGR_11(g_var_71); 
  TGR_12(g_var_71); 
  g_var_188 = NormalizeDouble(g_var_262,g_var_190) ;
  g_var_189 = NormalizeDouble(g_var_261,g_var_190) ;
  g_var_250 = 0 ;
  g_var_256 = false ;
  g_var_304 = g_var_125 * 60.0 ;
  g_var_139 = false ;
  g_var_303 = true ;
  g_var_309 = MarketInfo(g_var_336,MODE_FREEZELEVEL) * g_var_337 ;
  if ( !(g_var_171) )
  {
    g_var_303 = false ;
  }
  g_var_191 = 0.0 ;
  g_var_201 = 0.0 ;
  g_var_202 = 0.0 ;
  g_var_240 = false ;
  g_var_299 = StringSubstr(g_var_336,6,0) ;
  if ( Risk >  0 )
  {
    g_var_139 = true ;
  }
   if ( StartLotsRuntime<0.0 )
  {
     StartLotsRuntime = 0.01 ;
  }
  if ( g_var_141>MarketInfo(g_var_336,MODE_MAXLOT) )
  {
    g_var_141 = MarketInfo(g_var_336,MODE_MAXLOT) ;
  }
  for (l_var_4 = 0 ; l_var_4 < g_var_199 ; l_var_4 ++)
  {
    for (l_var_5 = 0 ; l_var_5 < 2 ; l_var_5 ++)
    {
      g_var_196[l_var_4][l_var_5] = 0.0;
    }
  }
  for (l_var_6 = 0 ; l_var_6 < g_var_200 ; l_var_6 ++)
  {
    for (l_var_7 = 0 ; l_var_7 < 3 ; l_var_7 ++)
    {
      g_var_197[l_var_6][l_var_7] = 0.0;
    }
  }
  for (l_var_8 = 0 ; l_var_8 < 100 ; l_var_8 ++)
  {
    g_var_197[l_var_8][0] = 0.0;
    g_var_197[l_var_8][1] = 0.0;
  }
  g_var_305 = false ;
  g_var_272 = iFractals(g_var_336,0,1,1) ;
  g_var_273 = iFractals(g_var_336,0,2,1) ;
  g_var_270 = g_var_272 ;
  g_var_271 = g_var_273 ;
  g_var_275 = 0.0 ;
  g_var_231 = false ;
  g_var_290 = Hour() ;
  g_var_289 = 0 ;
  g_var_252=ST1_Comment + "B1";
  g_var_253=ST1_Comment + "B2";
  g_var_254=ST1_Comment + "S1";
  g_var_255=ST1_Comment + "S2";
  g_var_297 = 0 ;
  g_var_298 = 0 ;
  g_var_267 = Hour() ;
  if ( g_var_67 )
  {
    g_var_86 = 1 ;
    g_var_278 = true ;
    g_var_279 = true ;
  }
  g_var_209 = 999.0 ;
  g_var_210 = 0.0 ;
  g_var_300 = 0.0 ;
  g_var_301 = 0.0 ;
  for (l_var_9 = 0 ; l_var_9 < 99 ; l_var_9 ++)
  {
    g_var_322[l_var_9] = 0;
    g_var_321[l_var_9] = 0;
    g_var_215[l_var_9] = iTime(g_var_336,g_var_71,1);
     if ( !(g_var_223[l_var_9]<StartLotsRuntime) )   continue;
     g_var_223[l_var_9] = StartLotsRuntime;
    
  }
  g_var_216 = 0 ;
  g_var_238 = false ;
  g_var_239 = false ;
  if ( g_var_63 == 1 )
  {
    g_var_64 = 0.0 ;
  }
  g_var_190 = MarketInfo(g_var_336,MODE_DIGITS) ;
  g_var_312 = false ;
  IsDemo(); 

  if ( tmp_var_1 == true )
  {
    g_var_312 = true ;
  }
  if ( ShowInfoPanel )
  {
    if ( g_var_152 == 1 )
    {
      TGR_33(); 
    }
    else
    {
      if ( g_var_152 == 2 )
      {
        TGR_34(); 
      }
    }
    TGR_24(); 
    TGR_27(); 
    TGR_29(); 
  }
  return(0); 
}
//init <<==--------   --------

void OnTick()
{
  UpdateTGRVisuals();
  bool      l_var_1;
  double    l_var_2;
  double    l_var_3;
  bool      l_var_4;
  MqlDateTime l_var_5;
  MqlDateTime l_var_6;
//----- -----
  bool       tmp_var_1;
  double     tmp_var_2;
  double     tmp_var_3;
  int        tmp_var_4;
  double     tmp_var_5;
  double     tmp_var_6;
  int        tmp_var_7;
  double     tmp_var_8;
  double     tmp_var_9;
  int        tmp_var_10;
  double     tmp_var_11;
  double     tmp_var_12;
  int        tmp_var_13;
  double     tmp_var_14;
  double     tmp_var_15;
  int        tmp_var_16;
  double     tmp_var_17;
  double     tmp_var_18;
  int        tmp_var_19;
  double     tmp_var_20;
  double     tmp_var_21;
  int        tmp_var_22;
  double     tmp_var_23;
  double     tmp_var_24;
  int        tmp_var_25;
  double     tmp_var_26;
  double     tmp_var_27;
  int        tmp_var_28;

  g_var_401 = AccountInfoDouble(ACCOUNT_BALANCE) ;
  if ( UseEquity )
  {
    g_var_401 = AccountInfoDouble(ACCOUNT_EQUITY) ;
  }
  if ( ForceBalanceToUse>0.0 )
  {
    g_var_401 = ForceBalanceToUse ;
  }
  if ( OnlyUp && g_var_402>g_var_401 )
  {
    g_var_401 = g_var_402 ;
  }
  if ( g_var_401>g_var_402 )
  {
    g_var_402 = g_var_401 ;
  }
  if ( FakeOutFilter == 0 )
  {
    g_var_53 = false ;
    g_var_57 = false ;
    g_var_61 = false ;
  }
  else
  {
    if ( FakeOutFilter == 1 )
    {
      g_var_53 = true ;
      g_var_57 = false ;
      g_var_61 = false ;
    }
    else
    {
      if ( FakeOutFilter == 2 )
      {
        g_var_53 = true ;
        g_var_57 = true ;
        g_var_61 = false ;
      }
      else
      {
        if ( FakeOutFilter == 3 )
        {
          g_var_53 = true ;
          g_var_57 = true ;
          g_var_61 = true ;
        }
      }
    }
  }
  l_var_1 = false ;
  if ( TGR_48() )
  {
    g_var_395 = Broker_GMT_OFFSET_Summer ;
     if ( ( !(g_var_392) || !(g_var_394) ) && UseExternalGMTSync && AutoGMT && !(l_var_1) )
    {
      g_var_392 = true ;
      g_var_393 = true ;
      g_var_396 = TGR_47() ;
      if ( g_var_396 == 999 )
      {
        Print("GMT_Offset wrongly detected.  Trying againg!"); 
        Sleep(2000); 
        g_var_396 = TGR_47() ;
      }
      if ( g_var_396 == 999 )
      {
        Print("GMT_Offset still wrong.  Using VPS time for GMT detection!"); 
      }
      g_var_394 = true ;
      l_var_1 = true ;
      Print("DST_US on"); 
    }
  }
  else
  {
    g_var_395 = Broker_GMT_OFFSET_Winter ;
     if ( ( g_var_392 || !(g_var_394) ) && UseExternalGMTSync && AutoGMT && !(l_var_1) )
    {
      g_var_392 = false ;
      g_var_393 = false ;
      g_var_396 = TGR_47() ;
      if ( g_var_396 == 999 )
      {
        Print("GMT_Offset wrongly detected.  Trying againg!"); 
        Sleep(2000); 
        g_var_396 = TGR_47() ;
      }
      if ( g_var_396 == 999 )
      {
        Print("GMT_Offset still wrong.  Using VPS time for GMT detection!"); 
      }
      g_var_394 = true ;
      l_var_1 = true ;
      Print("DST_US off"); 
    }
  }
  TimeToStruct(StringToTime(string(TimeYear(TimeCurrent())) + ".03.31 01:00"),l_var_5); 
  TimeToStruct(StringToTime(string(TimeYear(TimeCurrent())) + ".10.31 02:00"),l_var_6); 
  if ( TimeDayOfYear(TimeCurrent()) >  TimeDayOfYear(StringToTime(string(TimeYear(TimeCurrent())) + ".03.31 01:00") - l_var_5.day_of_week * 86400) && TimeDayOfYear(TimeCurrent()) <  TimeDayOfYear(StringToTime(string(TimeYear(TimeCurrent())) + ".10.31 02:00") - l_var_6.day_of_week * 86400) )
  {
    tmp_var_1 = true;
  }
  else
  {
    tmp_var_1 = false;
  }
  if ( tmp_var_1 )
  {
     if ( ( !(g_var_393) || !(g_var_394) ) && UseExternalGMTSync && AutoGMT && !(l_var_1) )
    {
      g_var_393 = true ;
      g_var_396 = TGR_47() ;
      if ( g_var_396 == 999 )
      {
        Print("GMT_Offset wrongly detected.  Trying againg!"); 
        Sleep(2000); 
        g_var_396 = TGR_47() ;
      }
      if ( g_var_396 == 999 )
      {
        Print("GMT_Offset still wrong.  Using VPS time for GMT detection!"); 
      }
      g_var_394 = true ;
      l_var_1 = true ;
      Print("DST_EU on"); 
    }
  }
  else
  {
     if ( ( g_var_393 || !(g_var_394) ) && UseExternalGMTSync && AutoGMT && !(l_var_1) )
    {
      g_var_393 = false ;
      g_var_396 = TGR_47() ;
      if ( g_var_396 == 999 )
      {
        Print("GMT_Offset wrongly detected.  Trying againg!"); 
        Sleep(2000); 
        g_var_396 = TGR_47() ;
      }
      if ( g_var_396 == 999 )
      {
        Print("GMT_Offset still wrong.  Using VPS time for GMT detection!"); 
      }
      g_var_394 = true ;
      l_var_1 = true ;
      Print("DST_EU off"); 
    }
  }
   if ( UseExternalGMTSync && AutoGMT && MQLInfoInteger(MQL_TESTER) != 1 )
  {
    if ( g_var_396 != 999 )
    {
      g_var_390=TimeCurrent() - g_var_396 * 3600;
    }
    else
    {
      g_var_390 = TimeGMT() ;
    }
  }
  else
  {
    g_var_390=TimeCurrent() - g_var_395 * 3600;
  }
  if ( TradeFrequency == 5 && Risk == 1234 )
  {
    l_var_2 = TGR_36(AccountInfoDouble(ACCOUNT_BALANCE)) ;
    l_var_3 = MaxAllowedDD / 100.0 * l_var_2 ;
    if ( l_var_3>g_var_388 )
    {
      g_var_19 = 3 ;
    }
    else
    {
      if ( l_var_3>g_var_387 )
      {
        g_var_19 = 2 ;
      }
      else
      {
        if ( l_var_3>g_var_386 )
        {
          g_var_19 = 1 ;
        }
        else
        {
          g_var_19 = 0 ;
        }
      }
    }
  }
  else
  {
    g_var_19 = TradeFrequency ;
  }
  if ( g_var_19 == 0 )
  {
    g_var_27 = false ;
    g_var_31 = false ;
    g_var_28 = false ;
    g_var_33 = false ;
    g_var_34 = false ;
    g_var_32 = false ;
    g_var_398 = 2.4 ;
    if ( UseVariableValues )
    {
      g_var_398 = 3.0 ;
    }
  }
  else
  {
    if ( g_var_19 == 1 )
    {
      g_var_27 = true ;
      g_var_31 = true ;
      g_var_28 = false ;
      g_var_33 = false ;
      g_var_34 = false ;
      g_var_32 = false ;
      g_var_398 = 3.4 ;
      if ( UseVariableValues )
      {
        g_var_398 = 4.0 ;
      }
    }
    else
    {
      if ( g_var_19 == 2 )
      {
        g_var_27 = true ;
        g_var_31 = true ;
        g_var_28 = true ;
        g_var_33 = true ;
        g_var_34 = false ;
        g_var_32 = false ;
        g_var_398 = 4.1 ;
        if ( UseVariableValues )
        {
          g_var_398 = 5.0 ;
        }
      }
      else
      {
        if ( g_var_19 == 3 )
        {
          g_var_27 = true ;
          g_var_31 = true ;
          g_var_28 = true ;
          g_var_33 = true ;
          g_var_34 = true ;
          g_var_32 = false ;
          g_var_398 = 4.8 ;
          if ( UseVariableValues )
          {
            g_var_398 = 5.6 ;
          }
        }
        else
        {
          if ( g_var_19 == 4 )
          {
            g_var_27 = true ;
            g_var_31 = true ;
            g_var_28 = true ;
            g_var_33 = true ;
            g_var_34 = true ;
            g_var_32 = true ;
            g_var_398 = 5.1 ;
            if ( UseVariableValues )
            {
              g_var_398 = 6.0 ;
            }
          }
          else
          {
            if ( g_var_19 == 6 )
            {
              g_var_20 = RunStrat1 ;
              g_var_23 = RunStrat2 ;
              g_var_26 = RunStrat3 ;
              g_var_27 = RunStrat4 ;
              g_var_31 = RunStrat5 ;
              g_var_28 = RunStrat6 ;
              g_var_33 = RunStrat7 ;
              g_var_34 = RunStrat8 ;
              g_var_32 = RunStrat9 ;
            }
          }
        }
      }
    }
  }
  if ( iBars(g_var_336,PERIOD_D1) != g_var_383 )
  {
    g_var_383 = iBars(g_var_336,PERIOD_D1) ;
    g_var_382 = false ;
    g_var_384 = 0.0 ;
  }
  if ( PropFirmMaxDailyDD>0.0 )
  {
    TGR_46(); 
  }
  if ( g_var_382 || !(g_var_380) )   return;
  l_var_4 = false ;
  if ( g_var_399 != iTime(g_var_336,PERIOD_H1,1) )
  {
    l_var_4 = true ;
    g_var_399 = iTime(g_var_336,PERIOD_H1,1) ;
  }
  if ( ( StringFind(Symbol(),"XAUUSD",0) >= 0 || StringFind(Symbol(),"xauusd",0) >= 0 || StringFind(Symbol(),"GOLD",0) >= 0 || StringFind(Symbol(),"GLD",0) >= 0 || StringFind(Symbol(),"gold",0) >= 0 || StringFind(Symbol(),"Gold",0) >= 0 ) )
  {
    g_var_336 = Symbol() ;
    if ( g_var_20 )
    {
      TGR_37(); 
      TGR_6(0); 
      TGR_7(0); 
      if ( l_var_4 )
      {
        if ( MQLInfoInteger(MQL_TESTER) == 1 && !(UpdateInfoTesting) )
        {
          tmp_var_2 = 0.0;
        }
        else
        {
          tmp_var_3 = 0.0;
          g_var_343[g_var_328] = 0;
          for (tmp_var_4 = HistoryTotal() ; tmp_var_4 >= 0 ; tmp_var_4=tmp_var_4 - 1)
          {
            if ( OrderSelect(tmp_var_4,0,1) != true || OrderSymbol() != g_var_336 || OrderMagicNumber() != g_var_93 )   continue;
            
            if ( ( OrderType() != 0 && OrderType() != 1 ) )   continue;
            g_var_343[g_var_328] ++;
            tmp_var_3 = tmp_var_3 + OrderProfit() + OrderSwap() + OrderCommission();
            
          }
          tmp_var_2 = tmp_var_3;
        }
        g_var_400[0] = tmp_var_2;
        if ( g_var_400[0]!=0.0 && g_var_343[0] >  0 )
        {
          g_var_345[0] = g_var_400[0] / g_var_343[0];
        }
      }
    }
    if ( g_var_27 )
    {
      TGR_38(); 
      TGR_6(3); 
      TGR_7(3); 
      if ( l_var_4 )
      {
        if ( MQLInfoInteger(MQL_TESTER) == 1 && !(UpdateInfoTesting) )
        {
          tmp_var_5 = 0.0;
        }
        else
        {
          tmp_var_6 = 0.0;
          g_var_343[g_var_328] = 0;
          for (tmp_var_7 = HistoryTotal() ; tmp_var_7 >= 0 ; tmp_var_7=tmp_var_7 - 1)
          {
            if ( OrderSelect(tmp_var_7,0,1) != true || OrderSymbol() != g_var_336 || OrderMagicNumber() != g_var_93 )   continue;
            
            if ( ( OrderType() != 0 && OrderType() != 1 ) )   continue;
            g_var_343[g_var_328] ++;
            tmp_var_6 = tmp_var_6 + OrderProfit() + OrderSwap() + OrderCommission();
            
          }
          tmp_var_5 = tmp_var_6;
        }
        g_var_400[3] = tmp_var_5;
        if ( g_var_400[3]!=0.0 && g_var_343[3] >  0 )
        {
          g_var_345[3] = g_var_400[3] / g_var_343[3];
        }
      }
    }
    if ( g_var_23 )
    {
      TGR_39(); 
      TGR_6(1); 
      TGR_7(1); 
      if ( l_var_4 )
      {
        if ( MQLInfoInteger(MQL_TESTER) == 1 && !(UpdateInfoTesting) )
        {
          tmp_var_8 = 0.0;
        }
        else
        {
          tmp_var_9 = 0.0;
          g_var_343[g_var_328] = 0;
          for (tmp_var_10 = HistoryTotal() ; tmp_var_10 >= 0 ; tmp_var_10=tmp_var_10 - 1)
          {
            if ( OrderSelect(tmp_var_10,0,1) != true || OrderSymbol() != g_var_336 || OrderMagicNumber() != g_var_93 )   continue;
            
            if ( ( OrderType() != 0 && OrderType() != 1 ) )   continue;
            g_var_343[g_var_328] ++;
            tmp_var_9 = tmp_var_9 + OrderProfit() + OrderSwap() + OrderCommission();
            
          }
          tmp_var_8 = tmp_var_9;
        }
        g_var_400[1] = tmp_var_8;
        if ( g_var_400[1]!=0.0 && g_var_343[1] >  0 )
        {
          g_var_345[1] = g_var_400[1] / g_var_343[1];
        }
      }
    }
    if ( g_var_26 )
    {
      TGR_40(); 
      TGR_6(2); 
      TGR_7(2); 
      if ( l_var_4 )
      {
        if ( MQLInfoInteger(MQL_TESTER) == 1 && !(UpdateInfoTesting) )
        {
          tmp_var_11 = 0.0;
        }
        else
        {
          tmp_var_12 = 0.0;
          g_var_343[g_var_328] = 0;
          for (tmp_var_13 = HistoryTotal() ; tmp_var_13 >= 0 ; tmp_var_13=tmp_var_13 - 1)
          {
            if ( OrderSelect(tmp_var_13,0,1) != true || OrderSymbol() != g_var_336 || OrderMagicNumber() != g_var_93 )   continue;
            
            if ( ( OrderType() != 0 && OrderType() != 1 ) )   continue;
            g_var_343[g_var_328] ++;
            tmp_var_12 = tmp_var_12 + OrderProfit() + OrderSwap() + OrderCommission();
            
          }
          tmp_var_11 = tmp_var_12;
        }
        g_var_400[2] = tmp_var_11;
        if ( g_var_400[2]!=0.0 && g_var_343[2] >  0 )
        {
          g_var_345[2] = g_var_400[2] / g_var_343[2];
        }
      }
    }
    if ( g_var_28 )
    {
      TGR_41(); 
      TGR_6(5); 
      TGR_7(5); 
      if ( l_var_4 )
      {
        if ( MQLInfoInteger(MQL_TESTER) == 1 && !(UpdateInfoTesting) )
        {
          tmp_var_14 = 0.0;
        }
        else
        {
          tmp_var_15 = 0.0;
          g_var_343[g_var_328] = 0;
          for (tmp_var_16 = HistoryTotal() ; tmp_var_16 >= 0 ; tmp_var_16=tmp_var_16 - 1)
          {
            if ( OrderSelect(tmp_var_16,0,1) != true || OrderSymbol() != g_var_336 || OrderMagicNumber() != g_var_93 )   continue;
            
            if ( ( OrderType() != 0 && OrderType() != 1 ) )   continue;
            g_var_343[g_var_328] ++;
            tmp_var_15 = tmp_var_15 + OrderProfit() + OrderSwap() + OrderCommission();
            
          }
          tmp_var_14 = tmp_var_15;
        }
        g_var_400[5] = tmp_var_14;
        if ( g_var_400[5]!=0.0 && g_var_343[5] >  0 )
        {
          g_var_345[5] = g_var_400[5] / g_var_343[5];
        }
      }
    }
    if ( g_var_31 )
    {
      TGR_42(); 
      TGR_6(4); 
      TGR_7(4); 
      if ( l_var_4 )
      {
        if ( MQLInfoInteger(MQL_TESTER) == 1 && !(UpdateInfoTesting) )
        {
          tmp_var_17 = 0.0;
        }
        else
        {
          tmp_var_18 = 0.0;
          g_var_343[g_var_328] = 0;
          for (tmp_var_19 = HistoryTotal() ; tmp_var_19 >= 0 ; tmp_var_19=tmp_var_19 - 1)
          {
            if ( OrderSelect(tmp_var_19,0,1) != true || OrderSymbol() != g_var_336 || OrderMagicNumber() != g_var_93 )   continue;
            
            if ( ( OrderType() != 0 && OrderType() != 1 ) )   continue;
            g_var_343[g_var_328] ++;
            tmp_var_18 = tmp_var_18 + OrderProfit() + OrderSwap() + OrderCommission();
            
          }
          tmp_var_17 = tmp_var_18;
        }
        g_var_400[4] = tmp_var_17;
        if ( g_var_400[4]!=0.0 && g_var_343[4] >  0 )
        {
          g_var_345[4] = g_var_400[4] / g_var_343[4];
        }
      }
    }
    if ( g_var_32 )
    {
      TGR_43(); 
      TGR_6(8); 
      TGR_7(8); 
      if ( l_var_4 )
      {
        if ( MQLInfoInteger(MQL_TESTER) == 1 && !(UpdateInfoTesting) )
        {
          tmp_var_20 = 0.0;
        }
        else
        {
          tmp_var_21 = 0.0;
          g_var_343[g_var_328] = 0;
          for (tmp_var_22 = HistoryTotal() ; tmp_var_22 >= 0 ; tmp_var_22=tmp_var_22 - 1)
          {
            if ( OrderSelect(tmp_var_22,0,1) != true || OrderSymbol() != g_var_336 || OrderMagicNumber() != g_var_93 )   continue;
            
            if ( ( OrderType() != 0 && OrderType() != 1 ) )   continue;
            g_var_343[g_var_328] ++;
            tmp_var_21 = tmp_var_21 + OrderProfit() + OrderSwap() + OrderCommission();
            
          }
          tmp_var_20 = tmp_var_21;
        }
        g_var_400[8] = tmp_var_20;
        if ( g_var_400[8]!=0.0 && g_var_343[8] >  0 )
        {
          g_var_345[8] = g_var_400[8] / g_var_343[8];
        }
      }
    }
    if ( g_var_33 )
    {
      TGR_44(); 
      TGR_6(6); 
      TGR_7(6); 
      if ( l_var_4 )
      {
        if ( MQLInfoInteger(MQL_TESTER) == 1 && !(UpdateInfoTesting) )
        {
          tmp_var_23 = 0.0;
        }
        else
        {
          tmp_var_24 = 0.0;
          g_var_343[g_var_328] = 0;
          for (tmp_var_25 = HistoryTotal() ; tmp_var_25 >= 0 ; tmp_var_25=tmp_var_25 - 1)
          {
            if ( OrderSelect(tmp_var_25,0,1) != true || OrderSymbol() != g_var_336 || OrderMagicNumber() != g_var_93 )   continue;
            
            if ( ( OrderType() != 0 && OrderType() != 1 ) )   continue;
            g_var_343[g_var_328] ++;
            tmp_var_24 = tmp_var_24 + OrderProfit() + OrderSwap() + OrderCommission();
            
          }
          tmp_var_23 = tmp_var_24;
        }
        g_var_400[6] = tmp_var_23;
        if ( g_var_400[6]!=0.0 && g_var_343[6] >  0 )
        {
          g_var_345[6] = g_var_400[6] / g_var_343[6];
        }
      }
    }
    if ( g_var_34 )
    {
      TGR_45(); 
      TGR_6(7); 
      TGR_7(7); 
      if ( l_var_4 )
      {
        if ( MQLInfoInteger(MQL_TESTER) == 1 && !(UpdateInfoTesting) )
        {
          tmp_var_26 = 0.0;
        }
        else
        {
          tmp_var_27 = 0.0;
          g_var_343[g_var_328] = 0;
          for (tmp_var_28 = HistoryTotal() ; tmp_var_28 >= 0 ; tmp_var_28=tmp_var_28 - 1)
          {
            if ( OrderSelect(tmp_var_28,0,1) != true || OrderSymbol() != g_var_336 || OrderMagicNumber() != g_var_93 )   continue;
            
            if ( ( OrderType() != 0 && OrderType() != 1 ) )   continue;
            g_var_343[g_var_328] ++;
            tmp_var_27 = tmp_var_27 + OrderProfit() + OrderSwap() + OrderCommission();
            
          }
          tmp_var_26 = tmp_var_27;
        }
        g_var_400[7] = tmp_var_26;
        if ( g_var_400[7]!=0.0 && g_var_343[7] >  0 )
        {
          g_var_345[7] = g_var_400[7] / g_var_343[7];
        }
      }
    }
  }
  else
  {
    g_var_336 = Symbol() ;
    TGR_7(0); 
  }
  TGR_27(); 
  if ( iTime(Symbol(),PERIOD_M5,1) != g_var_379 )
  {
    g_var_379 = iTime(Symbol(),PERIOD_M5,1) ;
    TGR_28(); 
    TGR_29(); 
  }
  g_var_381 ++;
  if ( g_var_381 < 2 )   return;
  g_var_318 = AccountBalance() ;
  g_var_381 = 0 ;
}
//OnTick <<==--------   --------

int deinit()
{
  TGR_26(); 
  return(0); 
}
//deinit <<==--------   --------
void TGR_6( int arg_0)
{
  g_var_328 = arg_0 ;
  g_var_337 = SymbolInfoDouble(g_var_336,16) ;
  g_var_229 = g_var_337 ;
  if ( ( MarketInfo(g_var_336,MODE_DIGITS)==3.0 || MarketInfo(g_var_336,MODE_DIGITS)==5.0 ) )
  {
    g_var_229 = g_var_337 * 10.0 ;
  }
  if ( SymbolInfoInteger(g_var_336,17) == 0x1 )
  {
    g_var_229 = g_var_337 / 10.0 ;
  }
  g_var_190 = MarketInfo(g_var_336,MODE_DIGITS) ;
  g_var_1 = MarketInfo(g_var_336,MODE_ASK) - MarketInfo(g_var_336,MODE_BID) ;
  g_var_221 = MarketInfo(g_var_336,MODE_STOPLEVEL) * g_var_337 ;
  g_var_309 = MarketInfo(g_var_336,MODE_FREEZELEVEL) * g_var_337 ;
  g_var_234 = g_var_89 * 60 * 60;
  if ( g_var_89 >  0 )
  {
    g_var_302 = TimeCurrent() + g_var_234;
  }
  else
  {
    g_var_302 = 0 ;
  }
  if ( Virtual_expiration )
  {
    g_var_302 = 0 ;
  }
  g_var_9 = 1.0 ;
  if ( !(UseVariableValues) )   return;
  
  if ( g_var_7>0.0 )
  {
    g_var_8 = iOpen(g_var_336,PERIOD_D1,1) / g_var_7 ;
  }
  else
  {
    g_var_8 = 1.0 ;
  }
  if ( AdjustLotsizeToVariableValues )
  {
    g_var_9 = 1.0 / g_var_8 ;
  }
  else
  {
    g_var_9 = 1.0 ;
  }
  g_var_80 = g_var_80 * g_var_8 ;
  g_var_83 = NormalizeDouble(g_var_83 * g_var_8,0) ;
  g_var_84 = NormalizeDouble(g_var_84 * g_var_8,0) ;
  g_var_100 = g_var_100 * g_var_8 ;
  g_var_101 = g_var_101 * g_var_8 ;
  g_var_103 = g_var_103 * g_var_8 ;
  g_var_104 = g_var_104 * g_var_8 ;
  g_var_105 = g_var_105 * g_var_8 ;
  g_var_108 = g_var_108 * g_var_8 ;
  g_var_109 = g_var_109 * g_var_8 ;
  g_var_113 = g_var_113 * g_var_8 ;
  g_var_114 = g_var_114 * g_var_8 ;
}
//TGR_6 <<==--------   --------

int TGR_7( int arg_0)
{
  bool      l_var_2;
  datetime  l_var_3;
  int       l_var_4;
  int       l_var_5;
  string    l_var_6;
  datetime  l_var_7;
  int       l_var_8;
  int       l_var_9;
//----- -----
  int        tmp_var_1;
  int        tmp_var_2;
  int        tmp_var_3;
  int        tmp_var_4;
  int        tmp_var_5;
  int        tmp_var_6;
  int        tmp_var_7;
  int        tmp_var_8;
  int        tmp_var_9;
  int        tmp_var_10;
  int        tmp_var_11;
  int        tmp_var_12;
  int        tmp_var_13;
  int        tmp_var_14;
  int        tmp_var_15;
  int        tmp_var_16;
  int        tmp_var_17;
  int        tmp_var_18;
  int        tmp_var_19;
  int        tmp_var_20;
  int        tmp_var_21;
  int        tmp_var_22;
  int        tmp_var_23;
  int        tmp_var_24;
  int        tmp_var_25;
  int        tmp_var_26;
  int        tmp_var_27;
  int        tmp_var_28;
  int        tmp_var_29;
  int        tmp_var_30;
  int        tmp_var_31;
  int        tmp_var_32;
  int        tmp_var_33;
  int        tmp_var_34;
  int        tmp_var_35;
  int        tmp_var_36;
  int        tmp_var_37;
  int        tmp_var_38;
  int        tmp_var_39;
  int        tmp_var_40;
  int        tmp_var_41;
  int        tmp_var_42;
  int        tmp_var_43;
  int        tmp_var_44;
  int        tmp_var_45;
  int        tmp_var_46;
  int        tmp_var_47;
  int        tmp_var_48;
  int        tmp_var_49;
  int        tmp_var_50;
  int        tmp_var_51;
  int        tmp_var_52;
  int        tmp_var_53;
  int        tmp_var_54;
  int        tmp_var_55;
  int        tmp_var_56;
  int        tmp_var_57;
  int        tmp_var_58;
  int        tmp_var_59;
  int        tmp_var_60;
  int        tmp_var_61;
  int        tmp_var_62;
  int        tmp_var_63;
  int        tmp_var_64;
  int        tmp_var_65;
  int        tmp_var_66;
  int        tmp_var_67;
  int        tmp_var_68;
  int        tmp_var_69;
  int        tmp_var_70;
  int        tmp_var_71;
  int        tmp_var_72;
  int        tmp_var_73;
  int        tmp_var_74;
  int        tmp_var_75;
  int        tmp_var_76;
  int        tmp_var_77;
  int        tmp_var_78;
  int        tmp_var_79;
  int        tmp_var_80;
  int        tmp_var_81;
  int        tmp_var_82;
  int        tmp_var_83;
  int        tmp_var_84;
  int        tmp_var_85;
  int        tmp_var_86;
  int        tmp_var_87;
  int        tmp_var_88;
  int        tmp_var_89;
  double     tmp_var_90;
  long       tmp_var_91;
  int        tmp_var_92;
  long       tmp_var_93;
  int        tmp_var_94;
  int        tmp_var_95;
  int        tmp_var_96;
  double     tmp_var_97;
  long       tmp_var_98;
  int        tmp_var_99;
  long       tmp_var_100;
  int        tmp_var_101;
  int        tmp_var_102;
  int        tmp_var_103;
  int        tmp_var_104;
  int        tmp_var_105;
  bool       tmp_var_106;
  int        tmp_var_107;
  int        tmp_var_108;
  bool       tmp_var_109;
  int        tmp_var_110;
  long       tmp_var_111;
  int        tmp_var_112;
  long       tmp_var_113;
  string     tmp_var_114;
  int        tmp_var_115;
  int        tmp_var_116;
  int        tmp_var_117;
  int        tmp_var_118;

  g_var_328 = arg_0 ;
  l_var_2 = false ;
  
  if ( g_var_81>0.0 )
  {
    g_var_80 = g_var_81 / 100.0 * MarketInfo(g_var_336,MODE_ASK) * 10.0 ;
  }
  if ( g_var_99 == 0 )
  {
    if ( TGR_18() )
    {
      l_var_2 = true ;
    }
    if ( TGR_19() )
    {
      l_var_2 = true ;
    }
    if ( l_var_2 )
    {
      return(0); 
    }
  }
  else
  {
    if ( g_var_321[g_var_328] != iBars(g_var_336,g_var_99) )
    {
      g_var_321[g_var_328] = iBars(g_var_336,g_var_99);
      if ( TGR_18() )
      {
        l_var_2 = true ;
      }
      if ( TGR_19() )
      {
        l_var_2 = true ;
      }
      if ( l_var_2 )
      {
        return(0); 
      }
    }
  }
  TGR_22(false); 
  if ( !(IsTesting()) && MarketInfo(g_var_336,MODE_TRADEALLOWED)==0.0 )
  {
    if ( !(g_var_256) )
    {
      Print("Market closed... waiting to continue"); 
    }
    g_var_256 = true ;
    return(0); 
  }
  if ( g_var_68 >  0 && ( ( Hour() == 0 && Minute() < g_var_68 ) || (Hour() == 23 && g_var_68 >  60 - g_var_68) ) )
  {
    if ( !(g_var_256) )
    {
      Print("DAYSWITCH -> Market might be closed... waiting " + string(g_var_68) + " minutes before setting order.."); 
    }
    g_var_256 = true ;
    return(0); 
  }
  g_var_256 = false ;
  if ( g_var_171 )
  {
    if ( TGR_20() && g_var_303 )
    {
      if ( g_var_173 )
      {
        TGR_8(); 
      }
      g_var_303 = false ;
    }
    if ( !(TGR_20()) && !(g_var_303) )
    {
      Print("ENTERING NON-TRADING HOURS! Closing orders..."); 
      if ( g_var_173 )
      {
        for (tmp_var_1 = 0 ; tmp_var_1 < g_var_200 ; tmp_var_1 = tmp_var_1 + 1)
        {
          for (tmp_var_2 = 0 ; tmp_var_2 < 2 ; tmp_var_2 = tmp_var_2 + 1)
          {
            g_var_197[tmp_var_1][tmp_var_2] = 0.0;
          }
        }
        tmp_var_3 = 0;
        for (tmp_var_4 = OrdersTotal() ; tmp_var_4 >= 0 ; tmp_var_4 = tmp_var_4 - 1)
        {
          if ( OrderSelect(tmp_var_4,0,0) != true || OrderMagicNumber() != g_var_93 || OrderSymbol() != g_var_336 )   continue;
          
          if ( ( OrderType() != 4 && OrderType() != 5 ) )   continue;
          Print("Storing pending order nr " + string(OrderTicket())); 
          g_var_197[tmp_var_3][1] = OrderType();
          g_var_197[tmp_var_3][0] = OrderOpenPrice();
          g_var_197[tmp_var_3][2] = OrderLots();
          tmp_var_3 = tmp_var_3 + 1;
          
        }
      }
      tmp_var_5 = 1;
      for (tmp_var_6 = OrdersTotal() ; tmp_var_6 >= 0 ; tmp_var_6 = tmp_var_6 - 1)
      {
        if ( OrderSelect(tmp_var_6,0,0) != true || OrderMagicNumber() != g_var_93 || OrderSymbol() != g_var_336 || OrderType() != 4 )   continue;
        OrderDelete(OrderTicket(),0xFFFFFFFF); 
        
      }
      if ( tmp_var_5 == 2 )
      {
        for (tmp_var_7 = OrdersTotal() ; tmp_var_7 >= 0 ; tmp_var_7 = tmp_var_7 - 1)
        {
          if ( OrderSelect(tmp_var_7,0,0) != true || OrderMagicNumber() != g_var_96 || OrderSymbol() != g_var_336 || OrderType() != 4 )   continue;
          OrderDelete(OrderTicket(),0xFFFFFFFF); 
          
        }
      }
      tmp_var_8 = 1;
      for (tmp_var_9 = OrdersTotal() ; tmp_var_9 >= 0 ; tmp_var_9 = tmp_var_9 - 1)
      {
        if ( OrderSelect(tmp_var_9,0,0) != true || OrderMagicNumber() != g_var_93 || OrderSymbol() != g_var_336 || OrderType() != 5 )   continue;
        OrderDelete(OrderTicket(),0xFFFFFFFF); 
        
      }
      if ( tmp_var_8 == 2 )
      {
        for (tmp_var_10 = OrdersTotal() ; tmp_var_10 >= 0 ; tmp_var_10 = tmp_var_10 - 1)
        {
          if ( OrderSelect(tmp_var_10,0,0) != true || OrderMagicNumber() != g_var_96 || OrderSymbol() != g_var_336 || OrderType() != 5 )   continue;
          OrderDelete(OrderTicket(),0xFFFFFFFF); 
          
        }
      }
      tmp_var_11 = 2;
      if(1==0) 
      {
        do
        {
          if ( OrderSelect(1,0,0) != true || OrderMagicNumber() != g_var_93 || OrderSymbol() != g_var_336 || OrderType() != 4 )   continue;
          OrderDelete(OrderTicket(),0xFFFFFFFF); 
          
        }
        while( - 1 >= 0);
        
      }
      if ( tmp_var_11 == 2 )
      {
        for (tmp_var_12 = OrdersTotal() ; tmp_var_12 >= 0 ; tmp_var_12 = tmp_var_12 - 1)
        {
          if ( OrderSelect(tmp_var_12,0,0) != true || OrderMagicNumber() != g_var_96 || OrderSymbol() != g_var_336 || OrderType() != 4 )   continue;
          OrderDelete(OrderTicket(),0xFFFFFFFF); 
          
        }
      }
      tmp_var_13 = 2;
      if(1==0) 
      {
        do
        {
          if ( OrderSelect(1,0,0) != true || OrderMagicNumber() != g_var_93 || OrderSymbol() != g_var_336 || OrderType() != 5 )   continue;
          OrderDelete(OrderTicket(),0xFFFFFFFF); 
          
        }
        while( - 1 >= 0);
        
      }
      if ( tmp_var_13 == 2 )
      {
        for (tmp_var_14 = OrdersTotal() ; tmp_var_14 >= 0 ; tmp_var_14 = tmp_var_14 - 1)
        {
          if ( OrderSelect(tmp_var_14,0,0) != true || OrderMagicNumber() != g_var_96 || OrderSymbol() != g_var_336 || OrderType() != 5 )   continue;
          OrderDelete(OrderTicket(),0xFFFFFFFF); 
          
        }
      }
      g_var_303 = true ;
      return(0); 
    }
  }
  if ( UseNewsFilter && EnableNFP_Filter )
  {
    if ( Year() <= 2026 )
    {
      l_var_3 = 0 ;
      for (l_var_4 = 0 ; l_var_4 < 300 ; l_var_4 ++)
      {
        tmp_var_15 = TimeYear(g_var_391[l_var_4]);
        if ( tmp_var_15 != Year() )   continue;
        tmp_var_16 = TimeMonth(g_var_391[l_var_4]);
        if ( tmp_var_16 != Month() )   continue;
        l_var_3 = g_var_391[l_var_4] ;
        break;
        
      }
      l_var_5 = 60 ;
      if ( TGR_48() )
      {
        l_var_5 = 0 ;
      }
      if ( g_var_390 >= l_var_3 - NFP_MinutesBefore * 60 + l_var_5 * 60 && g_var_390 <= l_var_3 + NFP_MinutesAfter * 60 + l_var_5 * 60 )
      {
        if ( NFP_ClosePendingOrders )
        {
          tmp_var_17 = 1;
          for (tmp_var_18 = OrdersTotal() ; tmp_var_18 >= 0 ; tmp_var_18 = tmp_var_18 - 1)
          {
            if ( OrderSelect(tmp_var_18,0,0) != true || OrderMagicNumber() != g_var_93 || OrderSymbol() != g_var_336 || OrderType() != 4 )   continue;
            OrderDelete(OrderTicket(),0xFFFFFFFF); 
            
          }
          if ( tmp_var_17 == 2 )
          {
            for (tmp_var_19 = OrdersTotal() ; tmp_var_19 >= 0 ; tmp_var_19 = tmp_var_19 - 1)
            {
              if ( OrderSelect(tmp_var_19,0,0) != true || OrderMagicNumber() != g_var_96 || OrderSymbol() != g_var_336 || OrderType() != 4 )   continue;
              OrderDelete(OrderTicket(),0xFFFFFFFF); 
              
            }
          }
          tmp_var_20 = 1;
          for (tmp_var_21 = OrdersTotal() ; tmp_var_21 >= 0 ; tmp_var_21 = tmp_var_21 - 1)
          {
            if ( OrderSelect(tmp_var_21,0,0) != true || OrderMagicNumber() != g_var_93 || OrderSymbol() != g_var_336 || OrderType() != 5 )   continue;
            OrderDelete(OrderTicket(),0xFFFFFFFF); 
            
          }
          if ( tmp_var_20 == 2 )
          {
            for (tmp_var_22 = OrdersTotal() ; tmp_var_22 >= 0 ; tmp_var_22 = tmp_var_22 - 1)
            {
              if ( OrderSelect(tmp_var_22,0,0) != true || OrderMagicNumber() != g_var_96 || OrderSymbol() != g_var_336 || OrderType() != 5 )   continue;
              OrderDelete(OrderTicket(),0xFFFFFFFF); 
              
            }
          }
          tmp_var_23 = 2;
          if(1==0) 
          {
            do
            {
              if ( OrderSelect(1,0,0) != true || OrderMagicNumber() != g_var_93 || OrderSymbol() != g_var_336 || OrderType() != 4 )   continue;
              OrderDelete(OrderTicket(),0xFFFFFFFF); 
              
            }
            while( - 1 >= 0);
            
          }
          if ( tmp_var_23 == 2 )
          {
            for (tmp_var_24 = OrdersTotal() ; tmp_var_24 >= 0 ; tmp_var_24 = tmp_var_24 - 1)
            {
              if ( OrderSelect(tmp_var_24,0,0) != true || OrderMagicNumber() != g_var_96 || OrderSymbol() != g_var_336 || OrderType() != 4 )   continue;
              OrderDelete(OrderTicket(),0xFFFFFFFF); 
              
            }
          }
          tmp_var_25 = 2;
          if(1==0) 
          {
            do
            {
              if ( OrderSelect(1,0,0) != true || OrderMagicNumber() != g_var_93 || OrderSymbol() != g_var_336 || OrderType() != 5 )   continue;
              OrderDelete(OrderTicket(),0xFFFFFFFF); 
              
            }
            while( - 1 >= 0);
            
          }
          if ( tmp_var_25 == 2 )
          {
            for (tmp_var_26 = OrdersTotal() ; tmp_var_26 >= 0 ; tmp_var_26 = tmp_var_26 - 1)
            {
              if ( OrderSelect(tmp_var_26,0,0) != true || OrderMagicNumber() != g_var_96 || OrderSymbol() != g_var_336 || OrderType() != 5 )   continue;
              OrderDelete(OrderTicket(),0xFFFFFFFF); 
              
            }
          }
        }
        if ( NFP_CloseOpenTrades )
        {
          for (tmp_var_27 = OrdersTotal() ; tmp_var_27 >= 0 ; tmp_var_27 = tmp_var_27 - 1)
          {
            if ( OrderSelect(tmp_var_27,0,0) != true || OrderSymbol() != g_var_336 )   continue;
            tmp_var_28 = OrderMagicNumber();
            tmp_var_29 = ST1_MagicNumber + 1;
            if ( tmp_var_28 != tmp_var_29 )
            {
              tmp_var_29 = OrderMagicNumber();
              tmp_var_30 = ST1_MagicNumber + 2;
              if ( tmp_var_29 != tmp_var_30 )
              {
                tmp_var_30 = OrderMagicNumber();
                tmp_var_31 = ST1_MagicNumber + 3;
                if ( tmp_var_30 != tmp_var_31 )
                {
                  tmp_var_31 = OrderMagicNumber();
                  tmp_var_32 = ST1_MagicNumber + 4;
                  if ( tmp_var_31 != tmp_var_32 )
                  {
                    tmp_var_32 = OrderMagicNumber();
                    tmp_var_33 = ST1_MagicNumber + 5;
                    if ( tmp_var_32 != tmp_var_33 )
                    {
                      tmp_var_33 = OrderMagicNumber();
                      tmp_var_34 = ST1_MagicNumber + 6;
                      if ( tmp_var_33 != tmp_var_34 )
                      {
                        tmp_var_34 = OrderMagicNumber();
                        tmp_var_35 = ST1_MagicNumber + 7;
                        if ( tmp_var_34 != tmp_var_35 )
                        {
                          tmp_var_35 = OrderMagicNumber();
                          tmp_var_36 = ST1_MagicNumber + 8;
                          if ( tmp_var_35 != tmp_var_36 )
                          {
                            tmp_var_36 = OrderMagicNumber();
                            tmp_var_37 = ST1_MagicNumber + 9;
                            if ( tmp_var_36 != tmp_var_37 )
                            {
                              tmp_var_37 = OrderMagicNumber();
                              tmp_var_38 = ST1_MagicNumber + 10;
                              if ( tmp_var_37 != tmp_var_38 )
                              {
                                tmp_var_38 = OrderMagicNumber();
                                tmp_var_39 = ST1_MagicNumber + 11;
                                if ( tmp_var_38 != tmp_var_39 )
                                {
                                  tmp_var_39 = OrderMagicNumber();
                                  tmp_var_40 = ST1_MagicNumber + 12;
                                  if ( tmp_var_39 != tmp_var_40 )
                                  {
                                    tmp_var_40 = OrderMagicNumber();
                                    tmp_var_41 = ST1_MagicNumber + 13;
                                    if ( tmp_var_40 != tmp_var_41 )
                                    {
                                      tmp_var_41 = OrderMagicNumber();
                                      tmp_var_42 = ST1_MagicNumber + 14;
                                      if ( tmp_var_41 != tmp_var_42 )
                                      {
                                        tmp_var_42 = OrderMagicNumber();
                                        tmp_var_43 = ST1_MagicNumber + 15;
                                      if ( tmp_var_42 != tmp_var_43 )   continue;
                                      }
                                    }
                                  }
                                }
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
            if ( OrderType() == 0 )
            {
              OrderClose(OrderTicket(),OrderLots(),MarketInfo(g_var_336,MODE_BID),99999,Red); 
            }
            if ( OrderType() != 1 )   continue;
            OrderClose(OrderTicket(),OrderLots(),MarketInfo(g_var_336,MODE_ASK),99999,Red); 
            
          }
        }
        if ( !(g_var_320) )
        {
          Print("NFP!! deleting trades!!"); 
        }
        g_var_320 = true ;
      }
      else
      {
        g_var_320 = false ;
      }
    }
    else
    {
      if ( Day() <= 7 && DayOfWeek() == 5 )
      {
        l_var_6 = IntegerToString(Year(),0,32) + IntegerToString(Month(),0,32) + IntegerToString(Day(),0,32) + " " + IntegerToString(0x4CE,0,32) ;
        l_var_7 = StringToTime(l_var_6) ;
        if ( g_var_390 >= l_var_7 - NFP_MinutesBefore * 60 && g_var_390 <= l_var_7 + NFP_MinutesAfter * 60 )
        {
          if ( NFP_ClosePendingOrders )
          {
            tmp_var_44 = 1;
            for (tmp_var_45 = OrdersTotal() ; tmp_var_45 >= 0 ; tmp_var_45 = tmp_var_45 - 1)
            {
              if ( OrderSelect(tmp_var_45,0,0) != true || OrderMagicNumber() != g_var_93 || OrderSymbol() != g_var_336 || OrderType() != 4 )   continue;
              OrderDelete(OrderTicket(),0xFFFFFFFF); 
              
            }
            if ( tmp_var_44 == 2 )
            {
              for (tmp_var_46 = OrdersTotal() ; tmp_var_46 >= 0 ; tmp_var_46 = tmp_var_46 - 1)
              {
                if ( OrderSelect(tmp_var_46,0,0) != true || OrderMagicNumber() != g_var_96 || OrderSymbol() != g_var_336 || OrderType() != 4 )   continue;
                OrderDelete(OrderTicket(),0xFFFFFFFF); 
                
              }
            }
            tmp_var_47 = 1;
            for (tmp_var_48 = OrdersTotal() ; tmp_var_48 >= 0 ; tmp_var_48 = tmp_var_48 - 1)
            {
              if ( OrderSelect(tmp_var_48,0,0) != true || OrderMagicNumber() != g_var_93 || OrderSymbol() != g_var_336 || OrderType() != 5 )   continue;
              OrderDelete(OrderTicket(),0xFFFFFFFF); 
              
            }
            if ( tmp_var_47 == 2 )
            {
              for (tmp_var_49 = OrdersTotal() ; tmp_var_49 >= 0 ; tmp_var_49 = tmp_var_49 - 1)
              {
                if ( OrderSelect(tmp_var_49,0,0) != true || OrderMagicNumber() != g_var_96 || OrderSymbol() != g_var_336 || OrderType() != 5 )   continue;
                OrderDelete(OrderTicket(),0xFFFFFFFF); 
                
              }
            }
            tmp_var_50 = 2;
            if(1==0) 
            {
              do
              {
                if ( OrderSelect(1,0,0) != true || OrderMagicNumber() != g_var_93 || OrderSymbol() != g_var_336 || OrderType() != 4 )   continue;
                OrderDelete(OrderTicket(),0xFFFFFFFF); 
                
              }
              while( - 1 >= 0);
              
            }
            if ( tmp_var_50 == 2 )
            {
              for (tmp_var_51 = OrdersTotal() ; tmp_var_51 >= 0 ; tmp_var_51 = tmp_var_51 - 1)
              {
                if ( OrderSelect(tmp_var_51,0,0) != true || OrderMagicNumber() != g_var_96 || OrderSymbol() != g_var_336 || OrderType() != 4 )   continue;
                OrderDelete(OrderTicket(),0xFFFFFFFF); 
                
              }
            }
            tmp_var_52 = 2;
            if(1==0) 
            {
              do
              {
                if ( OrderSelect(1,0,0) != true || OrderMagicNumber() != g_var_93 || OrderSymbol() != g_var_336 || OrderType() != 5 )   continue;
                OrderDelete(OrderTicket(),0xFFFFFFFF); 
                
              }
              while( - 1 >= 0);
              
            }
            if ( tmp_var_52 == 2 )
            {
              for (tmp_var_53 = OrdersTotal() ; tmp_var_53 >= 0 ; tmp_var_53 = tmp_var_53 - 1)
              {
                if ( OrderSelect(tmp_var_53,0,0) != true || OrderMagicNumber() != g_var_96 || OrderSymbol() != g_var_336 || OrderType() != 5 )   continue;
                OrderDelete(OrderTicket(),0xFFFFFFFF); 
                
              }
            }
          }
          if ( NFP_CloseOpenTrades )
          {
            for (tmp_var_54 = OrdersTotal() ; tmp_var_54 >= 0 ; tmp_var_54 = tmp_var_54 - 1)
            {
              if ( OrderSelect(tmp_var_54,0,0) != true || OrderSymbol() != g_var_336 )   continue;
              tmp_var_55 = OrderMagicNumber();
              tmp_var_56 = ST1_MagicNumber + 1;
              if ( tmp_var_55 != tmp_var_56 )
              {
                tmp_var_56 = OrderMagicNumber();
                tmp_var_57 = ST1_MagicNumber + 2;
                if ( tmp_var_56 != tmp_var_57 )
                {
                  tmp_var_57 = OrderMagicNumber();
                  tmp_var_58 = ST1_MagicNumber + 3;
                  if ( tmp_var_57 != tmp_var_58 )
                  {
                    tmp_var_58 = OrderMagicNumber();
                    tmp_var_59 = ST1_MagicNumber + 4;
                    if ( tmp_var_58 != tmp_var_59 )
                    {
                      tmp_var_59 = OrderMagicNumber();
                      tmp_var_60 = ST1_MagicNumber + 5;
                      if ( tmp_var_59 != tmp_var_60 )
                      {
                        tmp_var_60 = OrderMagicNumber();
                        tmp_var_61 = ST1_MagicNumber + 6;
                        if ( tmp_var_60 != tmp_var_61 )
                        {
                          tmp_var_61 = OrderMagicNumber();
                          tmp_var_62 = ST1_MagicNumber + 7;
                          if ( tmp_var_61 != tmp_var_62 )
                          {
                            tmp_var_62 = OrderMagicNumber();
                            tmp_var_63 = ST1_MagicNumber + 8;
                            if ( tmp_var_62 != tmp_var_63 )
                            {
                              tmp_var_63 = OrderMagicNumber();
                              tmp_var_64 = ST1_MagicNumber + 9;
                              if ( tmp_var_63 != tmp_var_64 )
                              {
                                tmp_var_64 = OrderMagicNumber();
                                tmp_var_65 = ST1_MagicNumber + 10;
                                if ( tmp_var_64 != tmp_var_65 )
                                {
                                  tmp_var_65 = OrderMagicNumber();
                                  tmp_var_66 = ST1_MagicNumber + 11;
                                  if ( tmp_var_65 != tmp_var_66 )
                                  {
                                    tmp_var_66 = OrderMagicNumber();
                                    tmp_var_67 = ST1_MagicNumber + 12;
                                    if ( tmp_var_66 != tmp_var_67 )
                                    {
                                      tmp_var_67 = OrderMagicNumber();
                                      tmp_var_68 = ST1_MagicNumber + 13;
                                      if ( tmp_var_67 != tmp_var_68 )
                                      {
                                        tmp_var_68 = OrderMagicNumber();
                                        tmp_var_69 = ST1_MagicNumber + 14;
                                        if ( tmp_var_68 != tmp_var_69 )
                                        {
                                          tmp_var_69 = OrderMagicNumber();
                                          tmp_var_70 = ST1_MagicNumber + 15;
                                        if ( tmp_var_69 != tmp_var_70 )   continue;
                                        }
                                      }
                                    }
                                  }
                                }
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
              if ( OrderType() == 0 )
              {
                OrderClose(OrderTicket(),OrderLots(),MarketInfo(g_var_336,MODE_BID),99999,Red); 
              }
              if ( OrderType() != 1 )   continue;
              OrderClose(OrderTicket(),OrderLots(),MarketInfo(g_var_336,MODE_ASK),99999,Red); 
              
            }
          }
          if ( !(g_var_320) )
          {
            Print("NFP!! deleting trades!!"); 
          }
          g_var_320 = true ;
        }
        else
        {
          g_var_320 = false ;
        }
      }
    }
  }
  if ( g_var_320 )
  {
    return(0); 
  }
  if ( g_var_45 )
  {
    if ( DayOfWeek() == 5 && Hour() >= FridayStopHour && !(g_var_305) )
    {
      for (tmp_var_71 = OrdersTotal() ; tmp_var_71 >= 0 ; tmp_var_71 = tmp_var_71 - 1)
      {
        if ( OrderSelect(tmp_var_71,0,0) != true || OrderSymbol() != g_var_336 )   continue;
        tmp_var_72 = OrderMagicNumber();
        tmp_var_73 = ST1_MagicNumber + 1;
        if ( tmp_var_72 != tmp_var_73 )
        {
          tmp_var_73 = OrderMagicNumber();
          tmp_var_74 = ST1_MagicNumber + 2;
          if ( tmp_var_73 != tmp_var_74 )
          {
            tmp_var_74 = OrderMagicNumber();
            tmp_var_75 = ST1_MagicNumber + 3;
            if ( tmp_var_74 != tmp_var_75 )
            {
              tmp_var_75 = OrderMagicNumber();
              tmp_var_76 = ST1_MagicNumber + 4;
              if ( tmp_var_75 != tmp_var_76 )
              {
                tmp_var_76 = OrderMagicNumber();
                tmp_var_77 = ST1_MagicNumber + 5;
                if ( tmp_var_76 != tmp_var_77 )
                {
                  tmp_var_77 = OrderMagicNumber();
                  tmp_var_78 = ST1_MagicNumber + 6;
                  if ( tmp_var_77 != tmp_var_78 )
                  {
                    tmp_var_78 = OrderMagicNumber();
                    tmp_var_79 = ST1_MagicNumber + 7;
                    if ( tmp_var_78 != tmp_var_79 )
                    {
                      tmp_var_79 = OrderMagicNumber();
                      tmp_var_80 = ST1_MagicNumber + 8;
                      if ( tmp_var_79 != tmp_var_80 )
                      {
                        tmp_var_80 = OrderMagicNumber();
                        tmp_var_81 = ST1_MagicNumber + 9;
                        if ( tmp_var_80 != tmp_var_81 )
                        {
                          tmp_var_81 = OrderMagicNumber();
                          tmp_var_82 = ST1_MagicNumber + 10;
                          if ( tmp_var_81 != tmp_var_82 )
                          {
                            tmp_var_82 = OrderMagicNumber();
                            tmp_var_83 = ST1_MagicNumber + 11;
                            if ( tmp_var_82 != tmp_var_83 )
                            {
                              tmp_var_83 = OrderMagicNumber();
                              tmp_var_84 = ST1_MagicNumber + 12;
                              if ( tmp_var_83 != tmp_var_84 )
                              {
                                tmp_var_84 = OrderMagicNumber();
                                tmp_var_85 = ST1_MagicNumber + 13;
                                if ( tmp_var_84 != tmp_var_85 )
                                {
                                  tmp_var_85 = OrderMagicNumber();
                                  tmp_var_86 = ST1_MagicNumber + 14;
                                  if ( tmp_var_85 != tmp_var_86 )
                                  {
                                    tmp_var_86 = OrderMagicNumber();
                                    tmp_var_87 = ST1_MagicNumber + 15;
                                  if ( tmp_var_86 != tmp_var_87 )   continue;
                                  }
                                }
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
        if ( OrderType() == 0 )
        {
          OrderClose(OrderTicket(),OrderLots(),MarketInfo(g_var_336,MODE_BID),g_var_38,Red); 
        }
        if ( OrderType() == 1 )
        {
          OrderClose(OrderTicket(),OrderLots(),MarketInfo(g_var_336,MODE_ASK),g_var_38,Red); 
        }
        if ( ( OrderType() != 4 && OrderType() != 5 ) )   continue;
        OrderDelete(OrderTicket(),Red); 
        
      }
      Print("Weekend starting! closing trades.."); 
      g_var_305 = true ;
      return(0); 
    }
    if ( DayOfWeek() != 5 && g_var_305 == true )
    {
      g_var_305 = false ;
      if ( g_var_46 )
      {
        TGR_8(); 
        return(0); 
      }
    }
  }
  g_var_1 = MarketInfo(g_var_336,MODE_ASK) - MarketInfo(g_var_336,MODE_BID) ;
  if ( g_var_35 )
  {
    if ( g_var_1>MaxSpread * g_var_229 )
    {
      TGR_9(); 
      return(0); 
    }
    if ( g_var_1<=g_var_37 * g_var_229 && ( !(g_var_45) || DayOfWeek() != 5 || Hour() <  FridayStopHour ) && ( !(g_var_171) || TGR_20() ) )
    {
      TGR_8(); 
    }
  }
  if ( g_var_69 == 1 )
  {
    tmp_var_88 = 0;
    for (tmp_var_89 = OrdersTotal() ; tmp_var_89 >= 0 ; tmp_var_89 = tmp_var_89 - 1)
    {
      if ( OrderSelect(tmp_var_89,0,0) != true || OrderMagicNumber() != g_var_93 || OrderSymbol() != g_var_336 || OrderType() != 4 )   continue;
      tmp_var_88 = tmp_var_88 + 1;
      
    }
    if ( tmp_var_88 >  g_var_86 )
    {
      tmp_var_90 = 0.0;
      tmp_var_91 = 0;
      for (tmp_var_92 = OrdersTotal() ; tmp_var_92 >= 0 ; tmp_var_92 = tmp_var_92 - 1)
      {
        if ( OrderSelect(tmp_var_92,0,0) != true || OrderMagicNumber() != g_var_93 || OrderSymbol() != g_var_336 || OrderType() != 4 || !(OrderOpenPrice()>tmp_var_90) )   continue;
        tmp_var_91 = OrderTicket();
        tmp_var_90 = OrderOpenPrice();
        
      }
      if ( tmp_var_91 != 0 )
      {
        OrderDelete(tmp_var_91,Green); 
        tmp_var_93 = tmp_var_91;
        for (tmp_var_94 = 0 ; tmp_var_94 < 100 ; tmp_var_94 = tmp_var_94 + 1)
        {
          if ( !(g_var_198[tmp_var_94][0]==tmp_var_93) )   continue;
          g_var_198[tmp_var_94][0] = 0.0;
          g_var_198[tmp_var_94][1] = 0.0;
          break;
          
        }
        Print("Max number of pending buy orders reached... deleting highest buystop order!"); 
      }
    }
    tmp_var_95 = 0;
    for (tmp_var_96 = OrdersTotal() ; tmp_var_96 >= 0 ; tmp_var_96 = tmp_var_96 - 1)
    {
      if ( OrderSelect(tmp_var_96,0,0) != true || OrderMagicNumber() != g_var_93 || OrderSymbol() != g_var_336 || OrderType() != 5 )   continue;
      tmp_var_95 = tmp_var_95 + 1;
      
    }
    if ( tmp_var_95 >  g_var_86 )
    {
      tmp_var_97 = 9999.0;
      tmp_var_98 = 0;
      for (tmp_var_99 = OrdersTotal() ; tmp_var_99 >= 0 ; tmp_var_99 = tmp_var_99 - 1)
      {
        if ( OrderSelect(tmp_var_99,0,0) != true || OrderMagicNumber() != g_var_93 || OrderSymbol() != g_var_336 || OrderType() != 5 || !(OrderOpenPrice()<tmp_var_97) )   continue;
        tmp_var_98 = OrderTicket();
        tmp_var_97 = OrderOpenPrice();
        
      }
      if ( tmp_var_98 != 0 )
      {
        OrderDelete(tmp_var_98,Green); 
        tmp_var_100 = tmp_var_98;
        for (tmp_var_101 = 0 ; tmp_var_101 < 100 ; tmp_var_101 = tmp_var_101 + 1)
        {
          if ( !(g_var_198[tmp_var_101][0]==tmp_var_100) )   continue;
          g_var_198[tmp_var_101][0] = 0.0;
          g_var_198[tmp_var_101][1] = 0.0;
          break;
          
        }
        Print("Max number of pending sell orders reached... deleting lowest sellstop order!"); 
      }
    }
  }
  if ( !(g_var_305) && g_var_69 == 1 && !(g_var_303) )
  {
    if ( ( g_var_322[g_var_328] != iBars(g_var_336,g_var_72) || g_var_72 == 0 ) )
    {
      g_var_322[g_var_328] = iBars(g_var_336,g_var_72);
      if ( g_var_119 >  0 && g_var_120 >= 0 )
      {
        g_var_241[g_var_328] = g_var_123 * g_var_229 + (TGR_13(g_var_117,g_var_119,g_var_120) + g_var_1);
        g_var_242[g_var_328] = TGR_14(g_var_117,g_var_119,g_var_120) - g_var_123 * g_var_229;
      }
      if ( g_var_187 >  0 )
      {
        l_var_8 = MathRand() * g_var_187 / 32768 + 1;
        g_var_15 = l_var_8 ;
        Print("Slippage: " + (string(l_var_8))); 
      }
      if ( g_var_63 != 1 )
      {
        tmp_var_102 = 0;
        for (tmp_var_103 = OrdersTotal() ; tmp_var_103 >= 0 ; tmp_var_103 = tmp_var_103 - 1)
        {
          if ( OrderSelect(tmp_var_103,0,0) != true || OrderMagicNumber() != g_var_93 || OrderSymbol() != g_var_336 || OrderType() != 0 )   continue;
          tmp_var_102 = tmp_var_102 + 1;
          
        }
        if ( tmp_var_102 == 0 )
        {
          tmp_var_104 = 0;
          for (tmp_var_105 = OrdersTotal() ; tmp_var_105 >= 0 ; tmp_var_105 = tmp_var_105 - 1)
          {
            if ( OrderSelect(tmp_var_105,0,0) != true || OrderMagicNumber() != g_var_93 || OrderSymbol() != g_var_336 || OrderType() != 1 )   continue;
            tmp_var_104 = tmp_var_104 + 1;
            
          }
          if ( tmp_var_104 == 0 )
          {
            tmp_var_106 = false;
            for (tmp_var_107 = 0 ; tmp_var_107 < g_var_199 ; tmp_var_107 = tmp_var_107 + 1)
            {
              if ( !(g_var_196[tmp_var_107][0]>0.0) )   continue;
              tmp_var_106 = false;
              for (tmp_var_108 = OrdersTotal() ; tmp_var_108 >= 0 ; tmp_var_108 = tmp_var_108 - 1)
              {
                if ( OrderSelect(tmp_var_108,0,0) != true )   continue;
                
                if ( ( OrderType() != 0 && OrderType() != 1 ) || !(OrderTicket()==g_var_196[tmp_var_107][0]) )   continue;
                tmp_var_106 = true;
                
              }
              if ( tmp_var_106 )   continue;
              g_var_196[tmp_var_107][0] = 0.0;
              g_var_196[tmp_var_107][1] = 0.0;
              
            }
          }
        }
      }
      for (l_var_9 = 0 ; l_var_9 < g_var_86 ; l_var_9 ++)
      {
        TGR_15(); 
      }
    }
    TGR_29(); 
    if ( g_var_267 != Hour() )
    {
      g_var_267 = Hour() ;
      tmp_var_109 = false;
      for (tmp_var_110 = 0 ; tmp_var_110 < 100 ; tmp_var_110 = tmp_var_110 + 1)
      {
        tmp_var_111 = g_var_198[tmp_var_110][0];
        tmp_var_109 = false;
        for (tmp_var_112 = OrdersTotal() ; tmp_var_112 >= 0 ; tmp_var_112 = tmp_var_112 - 1)
        {
          if ( !(OrderSelect(tmp_var_112,0,0)) )   continue;
          tmp_var_113 = OrderTicket();
          if ( tmp_var_111 != tmp_var_113 )   continue;
          tmp_var_109 = true;
          
        }
        if ( tmp_var_109 )   continue;
        g_var_198[tmp_var_110][0] = 0.0;
        g_var_198[tmp_var_110][1] = 0.0;
        
      }
    }
  }
  if ( g_var_62 )
  {
    tmp_var_114="Current spread: " + string(NormalizeDouble(g_var_1 / g_var_229,1)) + "\nPending Buy Order: ";
    tmp_var_115 = 0;
    for (tmp_var_116 = OrdersTotal() ; tmp_var_116 >= 0 ; tmp_var_116 = tmp_var_116 - 1)
    {
      if ( OrderSelect(tmp_var_116,0,0) != true || OrderMagicNumber() != g_var_93 || OrderSymbol() != g_var_336 || OrderType() != 4 )   continue;
      tmp_var_115 = tmp_var_115 + 1;
      
    }
    tmp_var_114 = tmp_var_114 + string(tmp_var_115);
    tmp_var_114 = tmp_var_114 + "\nPending Sell Orders: ";
    tmp_var_117 = 0;
    for (tmp_var_118 = OrdersTotal() ; tmp_var_118 >= 0 ; tmp_var_118 = tmp_var_118 - 1)
    {
      if ( OrderSelect(tmp_var_118,0,0) != true || OrderMagicNumber() != g_var_93 || OrderSymbol() != g_var_336 || OrderType() != 5 )   continue;
      tmp_var_117 = tmp_var_117 + 1;
      
    }
    tmp_var_114 = tmp_var_114 + string(tmp_var_117);
    Comment(tmp_var_114); 
  }
  return(0); 
}
//TGR_7 <<==--------   --------

void TGR_8()
{
  int       l_var_1;
//----- -----
  double     tmp_var_1;
  long       tmp_var_2;
  int        tmp_var_3;
  double     tmp_var_4;
  long       tmp_var_5;
  int        tmp_var_6;
  double     tmp_var_7;
  long       tmp_var_8;
  int        tmp_var_9;
  double     tmp_var_10;
  long       tmp_var_11;
  int        tmp_var_12;
  int        tmp_var_13;

  for (l_var_1 = 0 ; l_var_1 < g_var_200 ; l_var_1 ++)
  {
    if ( !(g_var_197[l_var_1][0]>0.0) )   continue;
    
    if ( g_var_197[l_var_1][1]==4.0 && MarketInfo(g_var_336,MODE_ASK)<g_var_197[l_var_1][0] - g_var_221 )
    {
      Print("Restoring pending buy-order"); 
      g_var_230 = OrderSend(g_var_336,4,g_var_197[l_var_1][2],g_var_197[l_var_1][0],int(g_var_38 * g_var_229),g_var_197[l_var_1][0] - (g_var_100 + g_var_64) * g_var_229,g_var_101 * g_var_229 + g_var_197[l_var_1][0],g_var_334,g_var_93,g_var_302 + 0x2A300,Green) ;
      g_var_280 = false ;
      tmp_var_1 = g_var_197[l_var_1][0];
      tmp_var_2 = g_var_230;
      for (tmp_var_3 = 0 ; tmp_var_3 < 100 ; tmp_var_3 = tmp_var_3 + 1)
      {
        if ( !(g_var_198[tmp_var_3][0]==0.0) )   continue;
        g_var_198[tmp_var_3][0] = tmp_var_2;
        g_var_198[tmp_var_3][1] = tmp_var_1;
        break;
        
      }
      if ( g_var_230 <= 0 )
      {
        if ( GetLastError() == 132 )
        {
          ResetLastError();
          if(1==0) 
          {
            do
            {
              Sleep(2500); 
              g_var_230 = OrderSend(g_var_336,4,g_var_197[l_var_1][2],g_var_197[l_var_1][0],int(g_var_38 * g_var_229),g_var_197[l_var_1][0] - (g_var_100 + g_var_64) * g_var_229,g_var_101 * g_var_229 + g_var_197[l_var_1][0],g_var_334,g_var_93,g_var_302 + 0x2A300,Green) ;
              g_var_280 = false ;
              tmp_var_4 = g_var_197[l_var_1][0];
              tmp_var_5 = g_var_230;
              for (tmp_var_6 = 0 ; tmp_var_6 < 100 ; tmp_var_6 = tmp_var_6 + 1)
              {
                if ( !(g_var_198[tmp_var_6][0]==0.0) )   continue;
                g_var_198[tmp_var_6][0] = tmp_var_5;
                g_var_198[tmp_var_6][1] = tmp_var_4;
                break;
                
              }
            }
            while(GetLastError() == 132);
            
          }
        }
        Print("error: \'" + TGR_21(GetLastError()) + "\' when setting entry order"); 
      }
    }
    if ( !(g_var_197[l_var_1][1]==5.0) || !(MarketInfo(g_var_336,MODE_BID)>g_var_197[l_var_1][0] + g_var_221) )   continue;
    Print("Restoring pending sell-order"); 
    g_var_230 = OrderSend(g_var_336,5,g_var_197[l_var_1][2],g_var_197[l_var_1][0],int(g_var_38 * g_var_229),(g_var_100 + g_var_64) * g_var_229 + g_var_197[l_var_1][0],g_var_197[l_var_1][0] - g_var_101 * g_var_229,g_var_334,g_var_93,g_var_302 + 0x2A300,Green) ;
    g_var_281 = false ;
    tmp_var_7 = g_var_197[l_var_1][0];
    tmp_var_8 = g_var_230;
    for (tmp_var_9 = 0 ; tmp_var_9 < 100 ; tmp_var_9 = tmp_var_9 + 1)
    {
      if ( !(g_var_198[tmp_var_9][0]==0.0) )   continue;
      g_var_198[tmp_var_9][0] = tmp_var_8;
      g_var_198[tmp_var_9][1] = tmp_var_7;
      break;
      
    }
    if ( g_var_230 > 0 )   continue;
    
    if ( GetLastError() == 132 )
    {
      ResetLastError();
      if(1==0) 
      {
        do
        {
          Sleep(2500); 
          g_var_230 = OrderSend(g_var_336,5,g_var_197[l_var_1][2],g_var_197[l_var_1][0],int(g_var_38 * g_var_229),(g_var_100 + g_var_64) * g_var_229 + g_var_197[l_var_1][0],g_var_197[l_var_1][0] - g_var_101 * g_var_229,g_var_334,g_var_93,g_var_302 + 0x2A300,Green) ;
          g_var_281 = false ;
          tmp_var_10 = g_var_197[l_var_1][0];
          tmp_var_11 = g_var_230;
          for (tmp_var_12 = 0 ; tmp_var_12 < 100 ; tmp_var_12 = tmp_var_12 + 1)
          {
            if ( !(g_var_198[tmp_var_12][0]==0.0) )   continue;
            g_var_198[tmp_var_12][0] = tmp_var_11;
            g_var_198[tmp_var_12][1] = tmp_var_10;
            break;
            
          }
        }
        while(GetLastError() == 132);
        
      }
    }
    Print("error: \'" + TGR_21(GetLastError()) + "\' when setting entry order"); 
    
  }
  for (tmp_var_13 = 0 ; tmp_var_13 < g_var_200 ; tmp_var_13 = tmp_var_13 + 1)
  {
    g_var_197[tmp_var_13][0] = 0.0;
    g_var_197[tmp_var_13][1] = 0.0;
    g_var_197[tmp_var_13][2] = 0.0;
  }
}
//TGR_8 <<==--------   --------

bool TGR_9()
{
  int       l_var_2;
  int       l_var_3;
  int       l_var_4;
//----- -----
  long       tmp_var_1;
  int        tmp_var_2;
  long       tmp_var_3;
  int        tmp_var_4;
  double     tmp_var_5;
  double     tmp_var_6;
  long       tmp_var_7;
  int        tmp_var_8;
  long       tmp_var_9;
  int        tmp_var_10;

  for (l_var_2 = OrdersTotal() ; l_var_2 >= 0 ; l_var_2 --)
  {
    if ( OrderSelect(l_var_2,0,0) != true )   continue;
    
    if ( ( OrderMagicNumber() != g_var_93 && OrderMagicNumber() != g_var_96 ) || OrderSymbol() != g_var_336 )   continue;
    
    if ( OrderType() == 4 && OrderOpenPrice()<g_var_36 * g_var_229 + MarketInfo(g_var_336,MODE_ASK) && MarketInfo(g_var_336,MODE_ASK)<OrderOpenPrice() - g_var_309 )
    {
      if ( g_var_37>0.0 )
      {
        Print("Spread too high..(" + string(g_var_1) + ") storing and deleting order " + string(OrderTicket())); 
        for (l_var_3 = 0 ; l_var_3 < g_var_200 ; l_var_3 ++)
        {
          if ( g_var_197[l_var_3][0]==0.0 )
          {
            Print("Storing pending order nr " + string(OrderTicket())); 
            g_var_197[l_var_3][1] = OrderType();
            g_var_197[l_var_3][0] = OrderOpenPrice();
            g_var_197[l_var_3][2] = OrderLots();
            break;
          }
        }
        tmp_var_1 = OrderTicket();
        for (tmp_var_2 = 0 ; tmp_var_2 < 100 ; tmp_var_2 = tmp_var_2 + 1)
        {
          if ( !(g_var_198[tmp_var_2][0]==tmp_var_1) )   continue;
          g_var_198[tmp_var_2][0] = 0.0;
          g_var_198[tmp_var_2][1] = 0.0;
          break;
          
        }
        OrderDelete(OrderTicket(),Green); 
      }
      else
      {
        Print("Spread too high..(" + string(g_var_1) + ") deleting order " + string(OrderTicket())); 
        tmp_var_3 = OrderTicket();
        for (tmp_var_4 = 0 ; tmp_var_4 < 100 ; tmp_var_4 = tmp_var_4 + 1)
        {
          if ( !(g_var_198[tmp_var_4][0]==tmp_var_3) )   continue;
          g_var_198[tmp_var_4][0] = 0.0;
          g_var_198[tmp_var_4][1] = 0.0;
          break;
          
        }
        OrderDelete(OrderTicket(),Green); 
      }
    }
    if ( OrderType() != 5 )   continue;
    tmp_var_5 = OrderOpenPrice();
    if ( !(tmp_var_5>MarketInfo(g_var_336,MODE_BID) - g_var_36 * g_var_229) )   continue;
    tmp_var_6 = MarketInfo(g_var_336,MODE_BID);
    if ( !(tmp_var_6>OrderOpenPrice() + g_var_309) )   continue;
    
    if ( g_var_37>0.0 )
    {
      Print("Spread too high..(" + string(g_var_1) + ") storing and deleting order " + string(OrderTicket())); 
      for (l_var_4 = 0 ; l_var_4 < g_var_200 ; l_var_4 ++)
      {
        if ( g_var_197[l_var_4][0]==0.0 )
        {
          Print("Storing pending order nr " + string(OrderTicket())); 
          g_var_197[l_var_4][1] = OrderType();
          g_var_197[l_var_4][0] = OrderOpenPrice();
          g_var_197[l_var_4][2] = OrderLots();
          break;
        }
      }
      tmp_var_7 = OrderTicket();
      for (tmp_var_8 = 0 ; tmp_var_8 < 100 ; tmp_var_8 = tmp_var_8 + 1)
      {
        if ( !(g_var_198[tmp_var_8][0]==tmp_var_7) )   continue;
        g_var_198[tmp_var_8][0] = 0.0;
        g_var_198[tmp_var_8][1] = 0.0;
        break;
        
      }
      OrderDelete(OrderTicket(),Green); 
       continue;
    }
    Print("Spread too high..(" + string(g_var_1) + ") deleting order " + string(OrderTicket())); 
    tmp_var_9 = OrderTicket();
    for (tmp_var_10 = 0 ; tmp_var_10 < 100 ; tmp_var_10 = tmp_var_10 + 1)
    {
      if ( !(g_var_198[tmp_var_10][0]==tmp_var_9) )   continue;
      g_var_198[tmp_var_10][0] = 0.0;
      g_var_198[tmp_var_10][1] = 0.0;
      break;
      
    }
    OrderDelete(OrderTicket(),Green); 
    
  }
  return(false); 
}
//TGR_9 <<==--------   --------

void TGR_10( double arg_0,int arg_1)
{
  double    l_var_1;
  double    l_var_2;
  double    l_var_3;
  double    l_var_4;
  double    l_var_5;
  double    l_var_6;
  double    l_var_7;
//----- -----

  l_var_1 = g_var_223[g_var_328] ;
  l_var_2 = g_var_223[g_var_328] ;
  g_var_401 = AccountInfoDouble(ACCOUNT_BALANCE) ;
  if ( UseEquity )
  {
    g_var_401 = AccountInfoDouble(ACCOUNT_EQUITY) ;
  }
  if ( ForceBalanceToUse>0.0 )
  {
    g_var_401 = ForceBalanceToUse ;
  }
  if ( OnlyUp && g_var_402>g_var_401 )
  {
    g_var_401 = g_var_402 ;
  }
  if ( g_var_401>g_var_402 )
  {
    g_var_402 = g_var_401 ;
  }
  l_var_3 = arg_0 ;
  if ( ( g_var_190 == 2 || g_var_190 == 4 ) )
  {
    l_var_3 = arg_0 / 10.0 ;
  }
  if ( Risk <  999 && Risk >  0 )
  {
    l_var_4 = Risk ;
    l_var_5 = l_var_4 / 1000.0 * g_var_401 ;
    if ( MarketInfo(g_var_336,MODE_LOTSTEP)==0.1 )
    {
      l_var_2 = NormalizeDouble(arg_1 * 0.01 * (l_var_5 / (MarketInfo(g_var_336,MODE_TICKVALUE) * l_var_3) * 0.1),1) ;
    }
    if ( MarketInfo(g_var_336,MODE_LOTSTEP)==0.01 )
    {
      l_var_2 = NormalizeDouble(arg_1 * 0.01 * (l_var_5 / (MarketInfo(g_var_336,MODE_TICKVALUE) * l_var_3) * 0.1),2) ;
    }
  }
  if ( Risk == 999 )
  {
    l_var_6 = g_var_148 / 100.0 * g_var_401 ;
    if ( MarketInfo(g_var_336,MODE_LOTSTEP)==0.1 )
    {
      l_var_2 = NormalizeDouble(arg_1 * 0.01 * (l_var_6 / (MarketInfo(g_var_336,MODE_TICKVALUE) * l_var_3) * 0.1),1) ;
    }
    if ( MarketInfo(g_var_336,MODE_LOTSTEP)==0.01 )
    {
      l_var_2 = NormalizeDouble(arg_1 * 0.01 * (l_var_6 / (MarketInfo(g_var_336,MODE_TICKVALUE) * l_var_3) * 0.1),2) ;
    }
  }
  if ( Risk == 0 )
  {
    if ( MarketInfo(g_var_336,MODE_LOTSTEP)==0.1 )
    {
       l_var_2 = NormalizeDouble(arg_1 * 0.01 * StartLotsRuntime,1) ;
    }
    if ( MarketInfo(g_var_336,MODE_LOTSTEP)==0.01 )
    {
       l_var_2 = NormalizeDouble(arg_1 * 0.01 * StartLotsRuntime,2) ;
    }
  }
  if ( Risk == 9999 )
  {
    if ( MarketInfo(g_var_336,MODE_LOTSTEP)==0.1 )
    {
      l_var_2 = NormalizeDouble(arg_1 * 0.01 * (g_var_401 / g_var_145 * 0.01),1) ;
    }
    if ( MarketInfo(g_var_336,MODE_LOTSTEP)==0.01 )
    {
      l_var_2 = NormalizeDouble(arg_1 * 0.01 * (g_var_401 / g_var_145 * 0.01),2) ;
    }
  }
  if ( Risk == 1234 )
  {
    if ( UseWeightedLots )
    {
      if ( g_var_397==0.0 )
      {
        g_var_397 = 100000.0 ;
      }
      g_var_146 = MaxAllowedDD / g_var_398 ;
      if ( SymbolInfoDouble(g_var_336,36)==0.1 )
      {
        l_var_2 = NormalizeDouble(g_var_146 / g_var_397 * g_var_401 / 100.0 * 0.01,1) ;
      }
      if ( SymbolInfoDouble(g_var_336,36)==0.01 )
      {
        l_var_2 = NormalizeDouble(g_var_146 / g_var_397 * g_var_401 / 100.0 * 0.01,2) ;
      }
    }
    else
    {
      if ( g_var_397==0.0 )
      {
        g_var_397 = 100000.0 ;
      }
      l_var_7 = TGR_36(g_var_401) ;
      if ( g_var_19 == 0 )
      {
        g_var_145 = g_var_385 / (MaxAllowedDD / 100.0) ;
      }
      if ( g_var_19 == 1 )
      {
        g_var_145 = g_var_386 / (MaxAllowedDD / 100.0) ;
      }
      if ( g_var_19 == 2 )
      {
        g_var_145 = g_var_387 / (MaxAllowedDD / 100.0) ;
      }
      if ( g_var_19 == 3 )
      {
        g_var_145 = g_var_388 / (MaxAllowedDD / 100.0) ;
      }
      if ( g_var_19 == 4 )
      {
        g_var_145 = g_var_389 / (MaxAllowedDD / 100.0) ;
      }
      if ( SymbolInfoDouble(g_var_336,36)==0.1 )
      {
        l_var_2 = NormalizeDouble(arg_1 * 0.01 * (l_var_7 / g_var_145 * 0.01),1) ;
      }
      if ( SymbolInfoDouble(g_var_336,36)==0.01 )
      {
        l_var_2 = NormalizeDouble(arg_1 * 0.01 * (l_var_7 / g_var_145 * 0.01),2) ;
      }
    }
  }
  if ( Risk == 3 )
  {
    if ( SymbolInfoDouble(g_var_336,36)==0.1 )
    {
      l_var_2 = NormalizeDouble(MaxRiskPerStrategy_ / g_var_397 * g_var_401 / 100.0 * 0.01,1) ;
    }
    if ( SymbolInfoDouble(g_var_336,36)==0.01 )
    {
      l_var_2 = NormalizeDouble(MaxRiskPerStrategy_ / g_var_397 * g_var_401 / 100.0 * 0.01,2) ;
    }
  }
  l_var_2 = l_var_2 * g_var_9 ;
  if ( l_var_2<MarketInfo(g_var_336,MODE_LOTSTEP) )
  {
    l_var_2 = MarketInfo(g_var_336,MODE_LOTSTEP) ;
  }
  if ( l_var_2>g_var_141 )
  {
    l_var_2 = g_var_141 ;
  }
  if ( l_var_2<MarketInfo(g_var_336,MODE_MINLOT) )
  {
    l_var_2 = MarketInfo(g_var_336,MODE_MINLOT) ;
  }
  if ( l_var_2>MarketInfo(g_var_336,MODE_MAXLOT) && MarketInfo(g_var_336,MODE_MAXLOT)!=0.0 )
  {
    l_var_2 = MarketInfo(g_var_336,MODE_MAXLOT) ;
  }
  if ( MarketInfo(g_var_336,MODE_LOTSTEP)==0.1 )
  {
    g_var_223[g_var_328] = NormalizeDouble((MathFloor(l_var_2 * 10.0)) / 10.0,1);
    return;
  }
  g_var_223[g_var_328] = NormalizeDouble(MathFloor(l_var_2 * 100.0) / 100.0,2);
}
//TGR_10 <<==--------   --------

double TGR_11( int arg_0)
{
  bool      l_var_2 = false;
  bool      l_var_3 = false;
  bool      l_var_4;
  int       l_var_5;
  int       l_var_6;
  int       l_var_7;
//----- -----
  double     tmp_var_1;
  int        tmp_var_2;
  double     tmp_var_3;
  int        tmp_var_4;
  double     tmp_var_5;
  int        tmp_var_6;
  bool       tmp_var_7;

  l_var_4 = false ;
  l_var_5=g_var_74 + 1;
  do
  {
    l_var_3 = true ;
    l_var_4 = true ;
    for (l_var_6 = l_var_5 ; l_var_6 >= l_var_5 - g_var_74 ; l_var_6 --)
    {
      if ( iHigh(g_var_336,arg_0,l_var_6)>iHigh(g_var_336,arg_0,l_var_5) )
      {
        l_var_4 = false ;
      }
    }
    for (l_var_7 = l_var_5 ; l_var_7 <= l_var_5 + g_var_73 ; l_var_7 ++)
    {
      if ( iHigh(g_var_336,arg_0,l_var_7)>iHigh(g_var_336,arg_0,l_var_5) )
      {
        l_var_3 = false ;
      }
    }
    if ( l_var_4 && l_var_3 && iHigh(g_var_336,arg_0,l_var_5)>g_var_80 * g_var_229 + MarketInfo(g_var_336,MODE_ASK) )
    {
      tmp_var_1 = iHigh(g_var_336,arg_0,l_var_5);
      tmp_var_2 = l_var_5;
      tmp_var_3 = iHigh(g_var_336,g_var_71,0);
      for (tmp_var_4 = 1 ; tmp_var_4 <= tmp_var_2 ; tmp_var_4 = tmp_var_4 + 1)
      {
        if ( iHigh(g_var_336,g_var_71,tmp_var_4)>tmp_var_3 )
        {
          tmp_var_3 = iHigh(g_var_336,g_var_71,tmp_var_4);
        }
      }
      if ( tmp_var_1>=tmp_var_3 )
      {
        tmp_var_5 = NormalizeDouble(iHigh(g_var_336,arg_0,l_var_5),g_var_190);
        tmp_var_7=false; 
        for (tmp_var_6 = OrdersTotal() ; tmp_var_6 >= 0 ; tmp_var_6 = tmp_var_6 - 1)
        {
          if ( OrderSelect(tmp_var_6,0,0) != true || OrderMagicNumber() != g_var_93 || OrderSymbol() != g_var_336 || OrderType() != 4 || !(MathAbs(OrderOpenPrice() - (g_var_83 * g_var_229 + tmp_var_5))<g_var_88 * g_var_229) )   continue;
          tmp_var_7 = true;
           break;
          
        }
        if ( !(tmp_var_7) && ( !(g_var_75) || !(iClose(g_var_336,arg_0,l_var_5 - 1)>iHigh(g_var_336,arg_0,l_var_5) - g_var_80 * g_var_229) ) )
        {
          l_var_2 = true ;
          g_var_262 = NormalizeDouble(iHigh(g_var_336,arg_0,l_var_5),g_var_190) ;
          g_var_265 = l_var_5 ;
          break;
        }
      }
    }
    l_var_5 ++;
    if ( l_var_5 <= g_var_77 )   continue;
    g_var_262 = 0.0 ;
    break;
    
  }
  while(!(l_var_2));
  
  return(g_var_262); 
}
//TGR_11 <<==--------   --------

double TGR_12( int arg_0)
{
  bool      l_var_2 = false;
  bool      l_var_3 = false;
  bool      l_var_4;
  int       l_var_5;
  int       l_var_6;
  int       l_var_7;
//----- -----
  double     tmp_var_1;
  int        tmp_var_2;
  double     tmp_var_3;
  int        tmp_var_4;
  double     tmp_var_5;
  int        tmp_var_6;
  bool       tmp_var_7;

  l_var_4 = false ;
  l_var_5=g_var_74 + 1;
  do
  {
    l_var_3 = true ;
    l_var_4 = true ;
    for (l_var_6 = l_var_5 ; l_var_6 >= l_var_5 - g_var_74 ; l_var_6 --)
    {
      if ( iLow(g_var_336,arg_0,l_var_6)<iLow(g_var_336,arg_0,l_var_5) )
      {
        l_var_4 = false ;
      }
    }
    for (l_var_7 = l_var_5 ; l_var_7 <= l_var_5 + g_var_73 ; l_var_7 ++)
    {
      if ( iLow(g_var_336,arg_0,l_var_7)<iLow(g_var_336,arg_0,l_var_5) )
      {
        l_var_3 = false ;
      }
    }
    if ( l_var_4 && l_var_3 && iLow(g_var_336,arg_0,l_var_5)<MarketInfo(g_var_336,MODE_BID) - g_var_80 * g_var_229 )
    {
      tmp_var_1 = iLow(g_var_336,arg_0,l_var_5);
      tmp_var_2 = l_var_5;
      tmp_var_3 = iLow(g_var_336,g_var_71,0);
      for (tmp_var_4 = 1 ; tmp_var_4 <= tmp_var_2 ; tmp_var_4 = tmp_var_4 + 1)
      {
        if ( iLow(g_var_336,g_var_71,tmp_var_4)<tmp_var_3 )
        {
          tmp_var_3 = iLow(g_var_336,g_var_71,tmp_var_4);
        }
      }
      if ( tmp_var_1<=tmp_var_3 )
      {
        tmp_var_5 = NormalizeDouble(iLow(g_var_336,arg_0,l_var_5),g_var_190);
        tmp_var_7=false; 
        for (tmp_var_6 = OrdersTotal() ; tmp_var_6 >= 0 ; tmp_var_6 = tmp_var_6 - 1)
        {
          if ( OrderSelect(tmp_var_6,0,0) != true || OrderMagicNumber() != g_var_93 || OrderSymbol() != g_var_336 || OrderType() != 5 || !(MathAbs(OrderOpenPrice() - (tmp_var_5 - g_var_84 * g_var_229))<g_var_88 * g_var_229) )   continue;
          tmp_var_7 = true;
           break;
          
        }
        if ( !(tmp_var_7) && ( !(g_var_75) || !(iClose(g_var_336,arg_0,l_var_5 - 1)<g_var_80 * g_var_229 + iLow(g_var_336,arg_0,l_var_5)) ) )
        {
          l_var_2 = true ;
          g_var_261 = NormalizeDouble(iLow(g_var_336,arg_0,l_var_5),g_var_190) ;
          g_var_266 = l_var_5 ;
          break;
        }
      }
    }
    l_var_5 ++;
    if ( l_var_5 <= g_var_77 )   continue;
    g_var_261 = 0.0 ;
    break;
    
  }
  while(!(l_var_2));
  
  return(g_var_261); 
}
//TGR_12 <<==--------   --------

double TGR_13( int arg_0,int arg_1,int arg_2)
{
  bool      l_var_2 = false;
  double    l_var_3 = 0.0;
  bool      l_var_4 = false;
  bool      l_var_5;
  int       l_var_6;
  int       l_var_7;
  int       l_var_8;
//----- -----

  l_var_5 = false ;
  l_var_6=arg_2 + 1;
  do
  {
    l_var_4 = true ;
    l_var_5 = true ;
    for (l_var_7 = l_var_6 ; l_var_7 >= l_var_6 - arg_2 ; l_var_7 --)
    {
      if ( iHigh(g_var_336,arg_0,l_var_7)>iHigh(g_var_336,arg_0,l_var_6) )
      {
        l_var_5 = false ;
      }
    }
    for (l_var_8 = l_var_6 ; l_var_8 <= l_var_6 + arg_1 ; l_var_8 ++)
    {
      if ( iHigh(g_var_336,arg_0,l_var_8)>iHigh(g_var_336,arg_0,l_var_6) )
      {
        l_var_4 = false ;
      }
    }
    if ( l_var_5 && l_var_4 && iHigh(g_var_336,arg_0,l_var_6)>g_var_221 * g_var_229 + MarketInfo(g_var_336,MODE_ASK) )
    {
      l_var_2 = true ;
      l_var_3 = NormalizeDouble(iHigh(g_var_336,arg_0,l_var_6),g_var_190) ;
      break;
    }
    l_var_6 ++;
    if ( l_var_6 <= g_var_118 )   continue;
    l_var_3 = 9999.0 ;
    break;
    
  }
  while(!(l_var_2));
  
  return(l_var_3); 
}
//TGR_13 <<==--------   --------

double TGR_14( int arg_0,int arg_1,int arg_2)
{
  bool      l_var_2 = false;
  double    l_var_3 = 0.0;
  bool      l_var_4 = false;
  bool      l_var_5;
  int       l_var_6;
  int       l_var_7;
  int       l_var_8;
//----- -----

  l_var_5 = false ;
  l_var_6=arg_2 + 1;
  do
  {
    l_var_4 = true ;
    l_var_5 = true ;
    for (l_var_7 = l_var_6 ; l_var_7 >= l_var_6 - arg_2 ; l_var_7 --)
    {
      if ( iLow(g_var_336,arg_0,l_var_7)<iLow(g_var_336,arg_0,l_var_6) )
      {
        l_var_5 = false ;
      }
    }
    for (l_var_8 = l_var_6 ; l_var_8 <= l_var_6 + arg_1 ; l_var_8 ++)
    {
      if ( iLow(g_var_336,arg_0,l_var_8)<iLow(g_var_336,arg_0,l_var_6) )
      {
        l_var_4 = false ;
      }
    }
    if ( l_var_5 && l_var_4 && iLow(g_var_336,arg_0,l_var_6)<MarketInfo(g_var_336,MODE_BID) - g_var_221 * g_var_229 )
    {
      l_var_2 = true ;
      l_var_3 = NormalizeDouble(iLow(g_var_336,arg_0,l_var_6),g_var_190) ;
      break;
    }
    l_var_6 ++;
    if ( l_var_6 <= g_var_118 )   continue;
    l_var_3 = 0.0 ;
    break;
    
  }
  while(!(l_var_2));
  
  return(l_var_3); 
}
//TGR_14 <<==--------   --------

void TGR_15()
{
  int       l_var_1;
//----- -----
  long       tmp_var_1;
  long       tmp_var_2;
  int        tmp_var_3;
  int        tmp_var_4;
  int        tmp_var_5;
  int        tmp_var_6;
  int        tmp_var_7;
  int        tmp_var_8;
  int        tmp_var_9;
  int        tmp_var_10;
  int        tmp_var_11;
  int        tmp_var_12;

  if ( g_var_213 )
  {
    g_var_268 = iMA(g_var_336,0,g_var_214,0,1,0,1) ;
    g_var_269 = iMA(g_var_336,0,g_var_217,0,1,0,1) ;
  }
  TGR_10(g_var_100,g_var_92); 
  if ( g_var_223[g_var_328]>g_var_141 )
  {
    g_var_223[g_var_328] = g_var_141;
  }
  if ( g_var_89 >  0 )
  {
    g_var_302=TimeCurrent() + g_var_234;
  }
  if ( Virtual_expiration )
  {
    g_var_302 = 0 ;
    for (l_var_1 = OrdersTotal() ; l_var_1 >= 0 ; l_var_1 --)
    {
      if ( OrderSelect(l_var_1,0,0) != true || OrderMagicNumber() != g_var_93 || OrderSymbol() != g_var_336 )   continue;
      
      if ( ( OrderType() != 4 && OrderType() != 5 ) )   continue;
      tmp_var_1 = TimeCurrent();
      tmp_var_2 = OrderOpenTime() + g_var_234;
      if ( tmp_var_1 < tmp_var_2 )   continue;
      OrderDelete(OrderTicket(),Red); 
      
    }
  }
  tmp_var_3 = 0;
  for (tmp_var_4 = OrdersTotal() ; tmp_var_4 >= 0 ; tmp_var_4 = tmp_var_4 - 1)
  {
    if ( OrderSelect(tmp_var_4,0,0) != true || OrderMagicNumber() != g_var_93 || OrderSymbol() != g_var_336 || OrderType() != 0 )   continue;
    tmp_var_3 = tmp_var_3 + 1;
    
  }
  if ( tmp_var_3 <  g_var_87 )
  {
    if(!TGR_16(1)) __TGREntryDebug("buy pending skipped");
  }
  else
  {
    tmp_var_5 = 1;
    for (tmp_var_6 = OrdersTotal() ; tmp_var_6 >= 0 ; tmp_var_6 = tmp_var_6 - 1)
    {
      if ( OrderSelect(tmp_var_6,0,0) != true || OrderMagicNumber() != g_var_93 || OrderSymbol() != g_var_336 || OrderType() != 4 )   continue;
      OrderDelete(OrderTicket(),0xFFFFFFFF); 
      
    }
    if ( tmp_var_5 == 2 )
    {
      for (tmp_var_7 = OrdersTotal() ; tmp_var_7 >= 0 ; tmp_var_7 = tmp_var_7 - 1)
      {
        if ( OrderSelect(tmp_var_7,0,0) != true || OrderMagicNumber() != g_var_96 || OrderSymbol() != g_var_336 || OrderType() != 4 )   continue;
        OrderDelete(OrderTicket(),0xFFFFFFFF); 
        
      }
    }
  }
  tmp_var_8 = 0;
  for (tmp_var_9 = OrdersTotal() ; tmp_var_9 >= 0 ; tmp_var_9 = tmp_var_9 - 1)
  {
    if ( OrderSelect(tmp_var_9,0,0) != true || OrderMagicNumber() != g_var_93 || OrderSymbol() != g_var_336 || OrderType() != 1 )   continue;
    tmp_var_8 = tmp_var_8 + 1;
    
  }
  if ( tmp_var_8 <  g_var_87 )
  {
    if(!TGR_17(1)) __TGREntryDebug("sell pending skipped");
    return;
  }
  tmp_var_10 = 1;
  for (tmp_var_11 = OrdersTotal() ; tmp_var_11 >= 0 ; tmp_var_11 = tmp_var_11 - 1)
  {
    if ( OrderSelect(tmp_var_11,0,0) != true || OrderMagicNumber() != g_var_93 || OrderSymbol() != g_var_336 || OrderType() != 5 )   continue;
    OrderDelete(OrderTicket(),0xFFFFFFFF); 
    
  }
  if ( tmp_var_10 != 2 )   return;
  for (tmp_var_12 = OrdersTotal() ; tmp_var_12 >= 0 ; tmp_var_12 = tmp_var_12 - 1)
  {
    if ( OrderSelect(tmp_var_12,0,0) != true || OrderMagicNumber() != g_var_96 || OrderSymbol() != g_var_336 || OrderType() != 5 )   continue;
    OrderDelete(OrderTicket(),0xFFFFFFFF); 
    
  }
}
//TGR_15 <<==--------   --------

bool TGR_16( int arg_0)
{
  bool      l_var_2;
  double    l_var_3;
  double    l_var_4;
  double    l_var_5;
  double    l_var_6;
//----- -----
  bool       tmp_var_1;
  int        tmp_var_2;
  double     tmp_var_3;
  int        tmp_var_4;
  bool       tmp_var_5;
  int        tmp_var_6;
  int        tmp_var_7;
  double     tmp_var_8;
  int        tmp_var_9;
  double     tmp_var_10;
  int        tmp_var_11;
  bool       tmp_var_12;
  bool       tmp_var_13;
  int        tmp_var_14;
  bool       tmp_var_15;
  int        tmp_var_16;
  double     tmp_var_17;
  long       tmp_var_18;
  int        tmp_var_19;

  if ( !(AllowBuyTrades) )
  {
    return(false); 
  }
  if ( g_var_218 )
  {
    tmp_var_1 = false;
  }
  else
  {
    tmp_var_1 = false; 
    for (tmp_var_2 = 0 ; tmp_var_2 < OrdersTotal() ; tmp_var_2 = tmp_var_2 + 1)
    {
      if ( OrderSelect(tmp_var_2,0,0) != true || OrderType() != 0 || OrderMagicNumber() != g_var_93 || OrderSymbol() != g_var_336 )   continue;
      tmp_var_1 = true;
       break;
      
    }
  }
  if ( tmp_var_1 == true )
  {
    return(false); 
  }
  if ( g_var_213 && g_var_268<g_var_269 )
  {
    return(false); 
  }
  if ( arg_0 == 1 )
  {
    TGR_11(g_var_71); 
    l_var_2 = false ;
    tmp_var_3 = g_var_262;
    tmp_var_5 = false; 
    for (tmp_var_4 = OrdersTotal() ; tmp_var_4 >= 0 ; tmp_var_4 = tmp_var_4 - 1)
    {
      if ( OrderSelect(tmp_var_4,0,0) != true || OrderMagicNumber() != g_var_93 || OrderSymbol() != g_var_336 || OrderType() != 4 || !(MathAbs(OrderOpenPrice() - (g_var_83 * g_var_229 + tmp_var_3))<g_var_88 * g_var_229) )   continue;
      tmp_var_5 = true;
       break;
      
    }
    if ( !(tmp_var_5) )
    {
      tmp_var_6 = 0;
      for (tmp_var_7 = OrdersTotal() ; tmp_var_7 >= 0 ; tmp_var_7 = tmp_var_7 - 1)
      {
        if ( OrderSelect(tmp_var_7,0,0) != true || OrderMagicNumber() != g_var_93 || OrderSymbol() != g_var_336 || OrderType() != 4 )   continue;
        tmp_var_6 = tmp_var_6 + 1;
        
      }
      if ( tmp_var_6 == g_var_86 )
      {
        tmp_var_8 = 9999.0;
        for (tmp_var_9 = OrdersTotal() ; tmp_var_9 >= 0 ; tmp_var_9 = tmp_var_9 - 1)
        {
          if ( OrderSelect(tmp_var_9,0,0) != true || OrderMagicNumber() != g_var_93 || OrderSymbol() != g_var_336 || OrderType() != 4 || !(OrderOpenPrice()<tmp_var_8) )   continue;
          tmp_var_8 = OrderOpenPrice();
          
        }
        if ( g_var_262>tmp_var_8 )
        {
          return(false); 
        }
      }
      g_var_264 = g_var_262 ;
      l_var_2 = true ;
      g_var_188 = NormalizeDouble(g_var_262,g_var_190) ;
    }
    if ( g_var_188==0.0 )
    {
      return(false); 
    }
    if ( l_var_2 )
    {
      g_var_247 = g_var_129 ;
      l_var_3 = NormalizeDouble(g_var_83 * g_var_229 + g_var_188,g_var_190) ;
      tmp_var_10 = l_var_3;
      tmp_var_12 = false; 
      for (tmp_var_11 = OrdersTotal() ; tmp_var_11 >= 0 ; tmp_var_11 = tmp_var_11 - 1)
      {
        if ( OrderSelect(tmp_var_11,0,0) != true || OrderMagicNumber() != g_var_93 || OrderSymbol() != g_var_336 || OrderType() != 4 || !(OrderOpenPrice()<=tmp_var_10) )   continue;
        tmp_var_12 = true;
         break;
        
      }
      if ( tmp_var_12 )
      {
        return(false); 
      }
      g_var_310 = l_var_3 ;
      if ( !(g_var_67) )
      {
        if ( CheckMargin && AccountFreeMarginCheck(g_var_336,0,g_var_223[g_var_328])<=0.0 )
        {
          Print("Free margin not sufficient for setting order with lotsize " + string(g_var_223[g_var_328]) + "..."); 
          return(false); 
        }
        l_var_4 = NormalizeDouble(g_var_15 * g_var_229 + l_var_3,g_var_190) ;
        l_var_5 = NormalizeDouble(l_var_3 - (g_var_100 + g_var_64) * g_var_229,g_var_190) ;
        l_var_6 = NormalizeDouble(g_var_101 * g_var_229 + l_var_3,g_var_190) ;
        if ( g_var_223[g_var_328]<SymbolInfoDouble(g_var_336,34) )
        {
          Print("Volume is less than the minimal allowed SYMBOL_VOLUME_MIN=" + string(SymbolInfoDouble(g_var_336,34))); 
          tmp_var_13 = false;
        }
        else
        {
          if ( g_var_223[g_var_328]>SymbolInfoDouble(g_var_336,35) )
          {
            Print("Volume is greater than the maximal allowed SYMBOL_VOLUME_MAX=" + string(SymbolInfoDouble(g_var_336,35))); 
            tmp_var_13 = false;
          }
          else
          {
            if ( MathAbs(NormalizeDouble(g_var_223[g_var_328] / SymbolInfoDouble(g_var_336,36),0) * SymbolInfoDouble(g_var_336,36) - g_var_223[g_var_328])>0.0000001 )
            {
              Print("Volume " + string(g_var_223[g_var_328]) + " is not a multiple of the minimal step SYMBOL_VOLUME_STEP=" + string(SymbolInfoDouble(g_var_336,36))); 
              tmp_var_13 = false;
            }
            else
            {
              tmp_var_13 = true;
            }
          }
        }

        tmp_var_14 = AccountInfoInteger(ACCOUNT_LIMIT_ORDERS);
        if ( tmp_var_14 == 0 )
        {
          tmp_var_15 = true;
        }
        else
        {
          tmp_var_15 = OrdersTotal()<tmp_var_14;
        }
        if ( ( !(tmp_var_13) || !(tmp_var_15) ) )
        {
          return(false); 
        }
        if ( MarketInfo(g_var_336,MODE_ASK)<l_var_4 - g_var_309 * g_var_229 && MarketInfo(g_var_336,MODE_ASK)<l_var_4 - g_var_221 * g_var_229 )
        {
          if ( !(setSL_TP_After_Entry) )
          {
            g_var_230 = OrderSend(g_var_336,4,g_var_223[g_var_328],l_var_4,int(g_var_38 * g_var_229),l_var_5,l_var_6,g_var_334,g_var_93,g_var_302,Green) ;
          }
          else
          {
            g_var_230 = OrderSend(g_var_336,4,g_var_223[g_var_328],l_var_4,int(g_var_38 * g_var_229),0.0,0.0,g_var_334,g_var_93,g_var_302,Green) ;
          }
          g_var_280 = false ;
          if ( g_var_230 <= 0 )
          {
            tmp_var_16 = GetLastError();
            if ( tmp_var_16 == 132 )
            {
              ResetLastError();
              if(1==0) 
              {
                do
                {
                  Sleep(2500); 
                  if ( !(setSL_TP_After_Entry) )
                  {
                    tmp_var_16 = g_var_38 * g_var_229;
                    g_var_230 = OrderSend(g_var_336,4,g_var_223[g_var_328],l_var_4,tmp_var_16,l_var_5,l_var_6,g_var_334,g_var_93,g_var_302,Green) ;
                  }
                  else
                  {
                    g_var_230 = OrderSend(g_var_336,4,g_var_223[g_var_328],l_var_4,int(g_var_38 * g_var_229),0.0,0.0,g_var_334,g_var_93,g_var_302,Green) ;
                  }
                  g_var_280 = false ;
                }
                while(GetLastError() == 132);
                
              }
            }
            Print("error: \'" + TGR_21(GetLastError()) + "\' when setting entry order"); 
          }
          else
          {
            tmp_var_17 = l_var_3;
            tmp_var_18 = g_var_230;
            for (tmp_var_19 = 0 ; tmp_var_19 < 100 ; tmp_var_19 = tmp_var_19 + 1)
            {
              if ( !(g_var_198[tmp_var_19][0]==0.0) )   continue;
              g_var_198[tmp_var_19][0] = tmp_var_18;
              g_var_198[tmp_var_19][1] = tmp_var_17;
              break;
              
            }
          }
        }
      }
      return(true); 
    }
  }
  return(false); 
}
//TGR_16 <<==--------   --------

bool TGR_17( int arg_0)
{
  bool      l_var_2;
  double    l_var_3;
  double    l_var_4;
  double    l_var_5;
  double    l_var_6;
//----- -----
  bool       tmp_var_1;
  int        tmp_var_2;
  double     tmp_var_3;
  int        tmp_var_4;
  bool       tmp_var_5;
  int        tmp_var_6;
  int        tmp_var_7;
  double     tmp_var_8;
  int        tmp_var_9;
  double     tmp_var_10;
  int        tmp_var_11;
  bool       tmp_var_12;
  bool       tmp_var_13;
  int        tmp_var_14;
  bool       tmp_var_15;
  int        tmp_var_16;
  double     tmp_var_17;
  long       tmp_var_18;
  int        tmp_var_19;

  if ( !(AllowSellTrades) )
  {
    return(false); 
  }
  if ( g_var_218 )
  {
    tmp_var_1 = false;
  }
  else
  {
    tmp_var_1 = false; 
    for (tmp_var_2 = 0 ; tmp_var_2 < OrdersTotal() ; tmp_var_2 = tmp_var_2 + 1)
    {
      if ( OrderSelect(tmp_var_2,0,0) != true || OrderType() != 1 || OrderMagicNumber() != g_var_93 || OrderSymbol() != g_var_336 )   continue;
      tmp_var_1 = true;
       break;
      
    }
  }
  if ( tmp_var_1 == true )
  {
    return(false); 
  }
  if ( g_var_213 && g_var_268>g_var_269 )
  {
    return(false); 
  }
  if ( arg_0 == 1 )
  {
    TGR_12(g_var_71); 
    l_var_2 = false ;
    tmp_var_3 = g_var_261;
    tmp_var_5 = false; 
    for (tmp_var_4 = OrdersTotal() ; tmp_var_4 >= 0 ; tmp_var_4 = tmp_var_4 - 1)
    {
      if ( OrderSelect(tmp_var_4,0,0) != true || OrderMagicNumber() != g_var_93 || OrderSymbol() != g_var_336 || OrderType() != 5 || !(MathAbs(OrderOpenPrice() - (tmp_var_3 - g_var_84 * g_var_229))<g_var_88 * g_var_229) )   continue;
      tmp_var_5 = true;
       break;
      
    }
    if ( !(tmp_var_5) )
    {
      tmp_var_6 = 0;
      for (tmp_var_7 = OrdersTotal() ; tmp_var_7 >= 0 ; tmp_var_7 = tmp_var_7 - 1)
      {
        if ( OrderSelect(tmp_var_7,0,0) != true || OrderMagicNumber() != g_var_93 || OrderSymbol() != g_var_336 || OrderType() != 5 )   continue;
        tmp_var_6 = tmp_var_6 + 1;
        
      }
      if ( tmp_var_6 == g_var_86 )
      {
        tmp_var_8 = 0.0;
        for (tmp_var_9 = OrdersTotal() ; tmp_var_9 >= 0 ; tmp_var_9 = tmp_var_9 - 1)
        {
          if ( OrderSelect(tmp_var_9,0,0) != true || OrderMagicNumber() != g_var_93 || OrderSymbol() != g_var_336 || OrderType() != 5 || !(OrderOpenPrice()>tmp_var_8) )   continue;
          tmp_var_8 = OrderOpenPrice();
          
        }
        if ( g_var_261<tmp_var_8 )
        {
          return(false); 
        }
      }
      g_var_263 = g_var_261 ;
      l_var_2 = true ;
      g_var_189 = NormalizeDouble(g_var_261,g_var_190) ;
    }
    if ( g_var_189==0.0 )
    {
      return(false); 
    }
    if ( l_var_2 )
    {
      g_var_247 = g_var_129 ;
      l_var_3 = NormalizeDouble(g_var_189 - g_var_84 * g_var_229,g_var_190) ;
      tmp_var_10 = l_var_3;
      tmp_var_12 = false; 
      for (tmp_var_11 = OrdersTotal() ; tmp_var_11 >= 0 ; tmp_var_11 = tmp_var_11 - 1)
      {
        if ( OrderSelect(tmp_var_11,0,0) != true || OrderMagicNumber() != g_var_93 || OrderSymbol() != g_var_336 || OrderType() != 5 || !(OrderOpenPrice()>=tmp_var_10) )   continue;
        tmp_var_12 = true;
         break;
        
      }
      if ( tmp_var_12 )
      {
        return(false); 
      }
      g_var_311 = l_var_3 ;
      if ( !(g_var_67) )
      {
        if ( CheckMargin && AccountFreeMarginCheck(g_var_336,1,g_var_223[g_var_328])<=0.0 )
        {
          Print("Free margin not sufficient for setting order with lotsize " + string(g_var_223[g_var_328]) + "..."); 
          return(false); 
        }
        l_var_4 = NormalizeDouble(l_var_3 - g_var_15 * g_var_229,g_var_190) ;
        l_var_5 = NormalizeDouble((g_var_100 + g_var_64) * g_var_229 + l_var_3,g_var_190) ;
        l_var_6 = NormalizeDouble(l_var_3 - g_var_101 * g_var_229,g_var_190) ;
        if ( g_var_223[g_var_328]<SymbolInfoDouble(g_var_336,34) )
        {
          Print("Volume is less than the minimal allowed SYMBOL_VOLUME_MIN=" + string(SymbolInfoDouble(g_var_336,34))); 
          tmp_var_13 = false;
        }
        else
        {
          if ( g_var_223[g_var_328]>SymbolInfoDouble(g_var_336,35) )
          {
            Print("Volume is greater than the maximal allowed SYMBOL_VOLUME_MAX=" + string(SymbolInfoDouble(g_var_336,35))); 
            tmp_var_13 = false;
          }
          else
          {
            if ( MathAbs(NormalizeDouble(g_var_223[g_var_328] / SymbolInfoDouble(g_var_336,36),0) * SymbolInfoDouble(g_var_336,36) - g_var_223[g_var_328])>0.0000001 )
            {
              Print("Volume " + string(g_var_223[g_var_328]) + " is not a multiple of the minimal step SYMBOL_VOLUME_STEP=" + string(SymbolInfoDouble(g_var_336,36))); 
              tmp_var_13 = false;
            }
            else
            {
              tmp_var_13 = true;
            }
          }
        }

        tmp_var_14 = AccountInfoInteger(ACCOUNT_LIMIT_ORDERS);
        if ( tmp_var_14 == 0 )
        {
          tmp_var_15 = true;
        }
        else
        {
          tmp_var_15 = OrdersTotal()<tmp_var_14;
        }
        if ( ( !(tmp_var_13) || !(tmp_var_15) ) )
        {
          return(false); 
        }
        if ( MarketInfo(g_var_336,MODE_BID)>g_var_309 * g_var_229 + l_var_4 && MarketInfo(g_var_336,MODE_BID)>g_var_221 * g_var_229 + l_var_4 )
        {
          if ( !(setSL_TP_After_Entry) )
          {
            g_var_230 = OrderSend(g_var_336,5,g_var_223[g_var_328],l_var_4,int(g_var_38 * g_var_229),l_var_5,l_var_6,g_var_334,g_var_93,g_var_302,Red) ;
          }
          else
          {
            g_var_230 = OrderSend(g_var_336,5,g_var_223[g_var_328],l_var_4,int(g_var_38 * g_var_229),0.0,0.0,g_var_334,g_var_93,g_var_302,Red) ;
          }
          g_var_281 = false ;
          if ( g_var_230 <= 0 )
          {
            tmp_var_16 = GetLastError();
            if ( tmp_var_16 == 132 )
            {
              ResetLastError();
              if(1==0) 
              {
                do
                {
                  Sleep(2500); 
                  if ( !(setSL_TP_After_Entry) )
                  {
                    tmp_var_16 = g_var_38 * g_var_229;
                    g_var_230 = OrderSend(g_var_336,5,g_var_223[g_var_328],l_var_4,tmp_var_16,l_var_5,l_var_6,g_var_334,g_var_93,g_var_302,Red) ;
                  }
                  else
                  {
                    g_var_230 = OrderSend(g_var_336,5,g_var_223[g_var_328],l_var_4,int(g_var_38 * g_var_229),0.0,0.0,g_var_334,g_var_93,g_var_302,Red) ;
                  }
                  g_var_281 = false ;
                }
                while(GetLastError() == 132);
                
              }
            }
            Print("error: \'" + TGR_21(GetLastError()) + "\' when setting entry order"); 
          }
          else
          {
            tmp_var_17 = l_var_3;
            tmp_var_18 = g_var_230;
            for (tmp_var_19 = 0 ; tmp_var_19 < 100 ; tmp_var_19 = tmp_var_19 + 1)
            {
              if ( !(g_var_198[tmp_var_19][0]==0.0) )   continue;
              g_var_198[tmp_var_19][0] = tmp_var_18;
              g_var_198[tmp_var_19][1] = tmp_var_17;
              break;
              
            }
          }
        }
      }
    }
  }
  return(false); 
}
//TGR_17 <<==--------   --------

bool TGR_18()
{
  bool      l_var_2 = false;
  bool      l_var_3 = false;
  double    l_var_4;
  double    l_var_5;
  int       l_var_6;
  double    l_var_7;
  double    l_var_8;
  long      l_var_9;
  double    l_var_10;
  string    l_var_11;
  double    l_var_12;
  datetime  l_var_13;
  int       l_var_14;
  int       l_var_15;
  string    l_var_16;
  double    l_var_17;
  double    l_var_18;
  bool      l_var_19;
  bool      l_var_20;
  double    l_var_21;
  bool      l_var_22;
  double    l_var_23;
  double    l_var_24;
  double    l_var_25;
  double    l_var_26;
  double    l_var_27;
  int       l_var_28;
  double    l_var_29;
//----- -----
  int        tmp_var_1;
  long       tmp_var_2;
  int        tmp_var_3;
  double     tmp_var_4;
  double     tmp_var_5;
  long       tmp_var_6;
  int        tmp_var_7;
  long       tmp_var_8;
  int        tmp_var_9;
  int        tmp_var_10;
  string     tmp_var_11;
  double     tmp_var_12;
  int        tmp_var_13;
  long       tmp_var_14;
  double     tmp_var_15;
  int        tmp_var_16;
  long       tmp_var_17;
  long       tmp_var_18;
  int        tmp_var_19;
  int        tmp_var_20;
  int        tmp_var_21;
  string     tmp_var_22;
  long       tmp_var_23;
  double     tmp_var_24;
  double     tmp_var_25;
  int        tmp_var_26;
  double     tmp_var_27;
  bool       tmp_var_28;
  int        tmp_var_29;
  int        tmp_var_30;
  double     tmp_var_31;
  long       tmp_var_32;
  int        tmp_var_33;
  long       tmp_var_34;
  double     tmp_var_35;
  double     tmp_var_36;
  int        tmp_var_37;
  double     tmp_var_38;
  bool       tmp_var_39;
  int        tmp_var_40;
  int        tmp_var_41;
  double     tmp_var_42;
  long       tmp_var_43;
  int        tmp_var_44;

  l_var_4 = 0.0 ;
  l_var_5 = 0.0 ;
  for (l_var_6 = 0 ; l_var_6 < OrdersTotal() ; l_var_6 ++)
  {
    if ( OrderSelect(l_var_6,0,0) == true )
    {
      l_var_2 = false ;
      l_var_7 = NormalizeDouble(OrderStopLoss(),g_var_190) ;
      l_var_8 = NormalizeDouble(OrderTakeProfit(),g_var_190) ;
      l_var_9 = OrderTicket() ;
      l_var_10 = NormalizeDouble(OrderOpenPrice(),g_var_190) ;
      l_var_11 = OrderComment() ;
      l_var_12 = OrderLots() ;
      l_var_13 = OrderOpenTime() ;
      l_var_14 = OrderType() ;
      l_var_15 = OrderMagicNumber() ;
      l_var_16 = OrderSymbol() ;
      if ( ( l_var_14 == 4 || l_var_14 == 2 ) && g_var_69 == 2 && ( g_var_95 == 0 || (g_var_95 == 1 && l_var_16 == g_var_336) ) && ( l_var_15 == g_var_96 || g_var_96 == 0 ) && ( l_var_11 == g_var_97 || g_var_97 == "" ) )
      {
        if ( ( l_var_7==0.0 || l_var_7==0.0 ) )
        {
          l_var_7 = NormalizeDouble(l_var_10 - g_var_100 * g_var_229,g_var_190) ;
          OrderModify(l_var_9,l_var_10,l_var_7,l_var_8,0,Green); 
        }
        if ( ( l_var_8==0.0 || l_var_8==0.0 ) )
        {
          l_var_8 = NormalizeDouble(g_var_101 * g_var_229 + l_var_10,g_var_190) ;
          OrderModify(l_var_9,l_var_10,l_var_7,l_var_8,0,Green); 
        }
      }
      if ( l_var_14 == 0 && ( ( l_var_15 == g_var_93 && g_var_69 == 1 && l_var_16 == g_var_336 ) || (g_var_69 == 2 && ( g_var_95 == 0 || (g_var_95 == 1 && l_var_16 == g_var_336) ) && ( l_var_15 == g_var_96 || g_var_96 == 0 ) && (l_var_11 == g_var_97 || g_var_97 == "")) ) )
      {
        if ( ( l_var_7==0.0 || l_var_7==0.0 ) )
        {
          l_var_7 = NormalizeDouble(l_var_10 - g_var_100 * g_var_229,g_var_190) ;
          OrderModify(l_var_9,l_var_10,l_var_7,l_var_8,0,Green); 
        }
        if ( ( l_var_8==0.0 || l_var_8==0.0 ) )
        {
          l_var_8 = NormalizeDouble(g_var_101 * g_var_229 + l_var_10,g_var_190) ;
          OrderModify(l_var_9,l_var_10,l_var_7,l_var_8,0,Green); 
        }
        if ( g_var_53 && iTime(g_var_336,g_var_52,g_var_51) <= l_var_13 && iTime(g_var_336,g_var_52,0) >  l_var_13 && iClose(g_var_336,g_var_52,1)<iOpen(g_var_336,g_var_52,1) && iClose(g_var_336,g_var_52,1)<l_var_10 )
        {
          OrderClose(l_var_9,l_var_12,MarketInfo(g_var_336,MODE_BID),0,Red); 
          Print("closing candle confirmation"); 
        }
        if ( g_var_55 && iTime(g_var_336,g_var_54,g_var_51) <= l_var_13 && iTime(g_var_336,g_var_54,0) >  l_var_13 && iClose(g_var_336,g_var_54,1)<iOpen(g_var_336,g_var_54,1) && iClose(g_var_336,g_var_54,1)<l_var_10 )
        {
          OrderClose(l_var_9,l_var_12,MarketInfo(g_var_336,MODE_BID),0,Red); 
          Print("closing candle confirmation"); 
        }
        if ( g_var_57 && iTime(g_var_336,g_var_56,g_var_51) <= l_var_13 && iTime(g_var_336,g_var_56,0) >  l_var_13 && iClose(g_var_336,g_var_56,1)<iOpen(g_var_336,g_var_56,1) && iClose(g_var_336,g_var_56,1)<l_var_10 )
        {
          OrderClose(l_var_9,l_var_12,MarketInfo(g_var_336,MODE_BID),0,Red); 
          Print("closing candle confirmation"); 
        }
        if ( g_var_59 && iTime(g_var_336,g_var_58,g_var_51) <= l_var_13 && iTime(g_var_336,g_var_58,0) >  l_var_13 && iClose(g_var_336,g_var_58,1)<iOpen(g_var_336,g_var_58,1) && iClose(g_var_336,g_var_58,1)<l_var_10 )
        {
          OrderClose(l_var_9,l_var_12,MarketInfo(g_var_336,MODE_BID),0,Red); 
          Print("closing candle confirmation"); 
        }
        if ( g_var_61 && iTime(g_var_336,g_var_60,g_var_51) <= l_var_13 && iTime(g_var_336,g_var_60,0) >  l_var_13 && iClose(g_var_336,g_var_60,1)<iOpen(g_var_336,g_var_60,1) && iClose(g_var_336,g_var_60,1)<l_var_10 )
        {
          OrderClose(l_var_9,l_var_12,MarketInfo(g_var_336,MODE_BID),0,Red); 
          Print("closing candle confirmation"); 
        }
        g_var_247 = g_var_129 ;
        if ( g_var_133 >  0 && TimeCurrent() >  l_var_13 + g_var_133 * 60 )
        {
          g_var_247 = g_var_134 ;
        }
        tmp_var_1 = g_var_190;
        tmp_var_2 = l_var_9;
        for (tmp_var_3 = 0 ; tmp_var_3 < 100 ; tmp_var_3 = tmp_var_3 + 1)
        {
          if ( !(g_var_198[tmp_var_3][0]==tmp_var_2) )   continue;
          tmp_var_4 = g_var_198[tmp_var_3][1];
          break;
          
        }
        tmp_var_4 = 0.0;
        l_var_17 = NormalizeDouble(tmp_var_4,tmp_var_1) ;
        if ( l_var_17==0.0 )
        {
          tmp_var_5 = l_var_10;
          tmp_var_6 = l_var_9;
          for (tmp_var_7 = 0 ; tmp_var_7 < 100 ; tmp_var_7 = tmp_var_7 + 1)
          {
            if ( !(g_var_198[tmp_var_7][0]==0.0) )   continue;
            g_var_198[tmp_var_7][0] = tmp_var_6;
            g_var_198[tmp_var_7][1] = tmp_var_5;
            break;
            
          }
          l_var_17 = l_var_10 ;
        }
        else
        {
          l_var_17 = l_var_17 - g_var_85 * g_var_229 ;
        }
        l_var_18 = l_var_10 - l_var_17 ;
        l_var_19 = false ;
        if ( l_var_17>0.0 - g_var_85 * g_var_229 && l_var_18>g_var_38 * g_var_229 )
        {
          l_var_19 = true ;
          if ( g_var_39 == 2 )
          {
            g_var_247 = -1000.0 ;
            Print("SlippageMode 2 active"); 
          }
        }
        if ( g_var_43 )
        {
          l_var_5 = l_var_17 ;
        }
        else
        {
          l_var_5 = l_var_10 ;
        }
        if ( l_var_7<NormalizeDouble(l_var_10 - (g_var_100 + g_var_64) * g_var_229 - g_var_1,g_var_190) )
        {
          l_var_7 = NormalizeDouble(l_var_10 - (g_var_100 + g_var_64) * g_var_229 - g_var_1,g_var_190) ;
          OrderModify(l_var_9,l_var_10,l_var_7,l_var_8,0,0xFFFFFFFF); 
        }
        if ( MarketInfo(g_var_336,MODE_BID)<l_var_10 - (g_var_100 + g_var_64) * g_var_229 - g_var_1 )
        {
          RefreshRates(); 
          OrderClose(OrderTicket(),OrderLots(),MarketInfo(g_var_336,MODE_BID),g_var_1,Red); 
          return(true); 
        }
        l_var_20 = false ;
        if ( g_var_159 )
        {
          tmp_var_8 = l_var_9;
          tmp_var_9 = 0;
          for (tmp_var_10 = OrdersTotal() ; tmp_var_10 >= 0 ; tmp_var_10 = tmp_var_10 - 1)
          {
            if ( OrderSelect(tmp_var_10,0,0) != true || OrderMagicNumber() != g_var_168 || OrderSymbol() != g_var_336 )   continue;
            tmp_var_11 = OrderComment();
            if ( tmp_var_11 != IntegerToString(tmp_var_8,0,32) )   continue;
            tmp_var_9 = tmp_var_9 + 1;
            
          }
          l_var_21 = tmp_var_9 ;
          l_var_22 = false ;
          if ( !(g_var_194) )
          {
            g_var_194 = true ;
            g_var_192 = 0 ;
          }
          if ( l_var_21==0.0 )
          {
            g_var_192 = 0 ;
          }
          if ( MathFloor(l_var_21 / 2.0)==l_var_21 / 2.0 )
          {
            g_var_192 = 0 ;
          }
          else
          {
            g_var_192 = 1 ;
          }
          if ( g_var_194 )
          {
            if ( l_var_21>0.0 )
            {
              tmp_var_12 = AccountEquity();
              if ( tmp_var_12>AccountBalance() + g_var_163 )
              {
                for (tmp_var_13 = OrdersTotal() ; tmp_var_13 >= 0 ; tmp_var_13 = tmp_var_13 - 1)
                {
                  if ( OrderSelect(tmp_var_13,0,0) != true )   continue;
                  
                  if ( ( OrderMagicNumber() != g_var_93 && OrderMagicNumber() != g_var_169 && OrderMagicNumber() != g_var_168 ) )   continue;
                  
                  if ( OrderType() == 0 )
                  {
                    OrderClose(OrderTicket(),OrderLots(),MarketInfo(g_var_336,MODE_BID),g_var_38,Red); 
                  }
                  if ( OrderType() != 1 )   continue;
                  OrderClose(OrderTicket(),OrderLots(),MarketInfo(g_var_336,MODE_ASK),g_var_38,Red); 
                  
                }
              }
            }
            if ( l_var_21>0.0 )
            {
              tmp_var_14 = l_var_9;
              tmp_var_15 = 0.0;
              for (tmp_var_16 = OrdersTotal() ; tmp_var_16 >= 0 ; tmp_var_16 = tmp_var_16 - 1)
              {
                if ( OrderSelect(tmp_var_16,0,0) != true )   continue;
                tmp_var_17 = OrderTicket();
                if ( tmp_var_17 != tmp_var_14 )
                {
                  tmp_var_11 = OrderComment();
                if ( tmp_var_11 != IntegerToString(tmp_var_14,0,32) )   continue;
                }
                tmp_var_15 = tmp_var_15 + OrderProfit();
                
              }
              if ( tmp_var_15>g_var_163 )
              {
                Print("Closing zone"); 
                tmp_var_18 = l_var_9;
                for (tmp_var_19 = OrdersTotal() ; tmp_var_19 >= 0 ; tmp_var_19 = tmp_var_19 - 1)
                {
                  if ( OrderSelect(tmp_var_19,0,0) != true )   continue;
                  
                  if ( OrderMagicNumber() == g_var_93 && OrderTicket() == tmp_var_18 )
                  {
                    OrderClose(OrderTicket(),OrderLots(),MarketInfo(g_var_336,MODE_BID),3,Red); 
                  }
                  if ( OrderMagicNumber() != g_var_168 )   continue;
                  tmp_var_11 = OrderComment();
                  if ( tmp_var_11 != IntegerToString(tmp_var_18,0,32) )   continue;
                  
                  if ( OrderType() == 0 )
                  {
                    OrderClose(OrderTicket(),OrderLots(),MarketInfo(g_var_336,MODE_BID),g_var_38,Red); 
                  }
                  if ( OrderType() != 1 )   continue;
                  OrderClose(OrderTicket(),OrderLots(),MarketInfo(g_var_336,MODE_ASK),g_var_38,Red); 
                  
                }
                g_var_194 = false ;
                l_var_20 = true ;
              }
            }
            else
            {
              l_var_23 = l_var_12 * g_var_165 ;
              if ( g_var_164 == 2 )
              {
                l_var_23 = (l_var_21 + 1.0) * l_var_12 + l_var_12 ;
              }
              if ( g_var_164 == 3 )
              {
                l_var_23 = l_var_12 * (MathPow(g_var_165,l_var_21 + 1.0)) ;
              }
              if ( g_var_192 == 0 )
              {
                l_var_24 = l_var_21 * g_var_161 * g_var_229 + (l_var_17 - g_var_160 * g_var_229) ;
                if ( l_var_24>l_var_17 - g_var_162 * g_var_229 )
                {
                  l_var_24 = l_var_17 - g_var_162 * g_var_229 ;
                }
                if ( MarketInfo(g_var_336,MODE_BID)<l_var_24 )
                {
                  if ( l_var_21>=g_var_166 )
                  {
                    for (tmp_var_20 = OrdersTotal() ; tmp_var_20 >= 0 ; tmp_var_20 = tmp_var_20 - 1)
                    {
                      if ( OrderSelect(tmp_var_20,0,0) != true )   continue;
                      
                      if ( OrderMagicNumber() == g_var_93 && OrderTicket() == l_var_9 )
                      {
                        OrderClose(OrderTicket(),OrderLots(),MarketInfo(g_var_336,MODE_BID),3,Red); 
                      }
                      if ( OrderMagicNumber() != g_var_168 )   continue;
                      tmp_var_11 = OrderComment();
                      if ( tmp_var_11 != IntegerToString(l_var_9,0,32) )   continue;
                      
                      if ( OrderType() == 0 )
                      {
                        OrderClose(OrderTicket(),OrderLots(),MarketInfo(g_var_336,MODE_BID),g_var_38,Red); 
                      }
                      if ( OrderType() != 1 )   continue;
                      OrderClose(OrderTicket(),OrderLots(),MarketInfo(g_var_336,MODE_ASK),g_var_38,Red); 
                      
                    }
                  }
                  else
                  {
                    OrderSend(g_var_336,1,l_var_23,MarketInfo(g_var_336,MODE_BID),g_var_38,0.0,0.0,IntegerToString(l_var_9,0,32),g_var_168,0,Green); 
                    g_var_192 = 1 ;
                    l_var_22 = true ;
                  }
                }
              }
              else
              {
                l_var_25 = l_var_17 ;
                if ( MarketInfo(g_var_336,MODE_ASK)>l_var_17 )
                {
                  if ( l_var_21>=g_var_166 )
                  {
                    for (tmp_var_21 = OrdersTotal() ; tmp_var_21 >= 0 ; tmp_var_21 = tmp_var_21 - 1)
                    {
                      if ( OrderSelect(tmp_var_21,0,0) != true )   continue;
                      
                      if ( OrderMagicNumber() == g_var_93 && OrderTicket() == l_var_9 )
                      {
                        OrderClose(OrderTicket(),OrderLots(),MarketInfo(g_var_336,MODE_BID),3,Red); 
                      }
                      if ( OrderMagicNumber() != g_var_168 )   continue;
                      tmp_var_22 = OrderComment();
                      if ( tmp_var_22 != IntegerToString(l_var_9,0,32) )   continue;
                      
                      if ( OrderType() == 0 )
                      {
                        OrderClose(OrderTicket(),OrderLots(),MarketInfo(g_var_336,MODE_BID),g_var_38,Red); 
                      }
                      if ( OrderType() != 1 )   continue;
                      OrderClose(OrderTicket(),OrderLots(),MarketInfo(g_var_336,MODE_ASK),g_var_38,Red); 
                      
                    }
                  }
                  else
                  {
                    OrderSend(g_var_336,0,l_var_23,MarketInfo(g_var_336,MODE_ASK),g_var_38,0.0,0.0,IntegerToString(l_var_9,0,32),g_var_168,0,Green); 
                    g_var_192 = 0 ;
                    l_var_22 = true ;
                  }
                }
              }
            }
          }
          if ( ( l_var_21>0.0 || l_var_22 ) )
          {
            l_var_20 = true ;
          }
        }
        if ( !(l_var_20) )
        {
          if ( ( g_var_63 == 1 || (g_var_63 != 3 && g_var_63 != 2) ) )
          {
            tmp_var_23 = l_var_9;
            tmp_var_24 = g_var_100;
            tmp_var_25 = l_var_10;
            tmp_var_26 = 1;
            tmp_var_27 = 0.0;
            tmp_var_28 = false;
            for (tmp_var_29 = 0 ; tmp_var_29 < g_var_199 ; tmp_var_29 = tmp_var_29 + 1)
            {
              if ( g_var_196[tmp_var_29][0]==tmp_var_23 )
              {
                tmp_var_27 = g_var_196[tmp_var_29][1];
                tmp_var_28 = true;
                break;
              }
            }
            if ( !(tmp_var_28) )
            {
              if ( tmp_var_26 == 1 )
              {
                tmp_var_27 = NormalizeDouble(tmp_var_25 - tmp_var_24 * g_var_229,g_var_190);
              }
              if ( tmp_var_26 == 2 )
              {
                tmp_var_27 = NormalizeDouble(tmp_var_24 * g_var_229 + tmp_var_25,g_var_190);
              }
              for (tmp_var_30 = 0 ; tmp_var_30 < g_var_199 ; tmp_var_30 = tmp_var_30 + 1)
              {
                if ( g_var_196[tmp_var_30][0]==0.0 )
                {
                  g_var_196[tmp_var_30][0] = tmp_var_23;
                  g_var_196[tmp_var_30][1] = tmp_var_27;
                  break;
                }
              }
            }
            g_var_191 = tmp_var_27 ;
            l_var_4 = g_var_191 ;
            if ( MarketInfo(g_var_336,MODE_BID)<l_var_4 )
            {
              Print("Closing with virtual SL"); 
              RefreshRates(); 
              OrderClose(l_var_9,l_var_12,MarketInfo(g_var_336,MODE_BID),g_var_1,0xFFFFFFFF); 
              return(true); 
            }
            if ( g_var_125>0.0 && TimeCurrent() >= l_var_13 + g_var_304 && MarketInfo(g_var_336,MODE_BID)>NormalizeDouble(g_var_126 * g_var_229 + (l_var_7 + g_var_337),g_var_190) && MarketInfo(g_var_336,MODE_BID)<l_var_8 - g_var_309 )
            {
              l_var_7 = NormalizeDouble(MarketInfo(g_var_336,MODE_BID) - g_var_126 * g_var_229,g_var_190) ;
              if ( l_var_7<MarketInfo(g_var_336,MODE_BID) - g_var_221 )
              {
                g_var_230 = OrderModify(l_var_9,l_var_10,l_var_7,l_var_8,0,0xFFFFFFFF) ;
                if ( g_var_230 <= 0 )
                {
                  Print("TrailStop error: \'" + TGR_21(GetLastError()) + "\' when setting trailing Exit_TrailSL_after_X_Minutes_size loss.  Trying again!"); 
                }
                l_var_2 = true ;
              }
            }
            if ( g_var_103>0.0 && MarketInfo(g_var_336,MODE_BID)>NormalizeDouble((g_var_103 + g_var_106) * g_var_229 + (l_var_7 + g_var_337),g_var_190) && MarketInfo(g_var_336,MODE_BID)>NormalizeDouble(g_var_104 * g_var_229 + l_var_5,g_var_190) && MarketInfo(g_var_336,MODE_BID)<l_var_8 - g_var_309 && l_var_7<NormalizeDouble(g_var_105 * g_var_229 + l_var_10,g_var_190) )
            {
              l_var_7 = NormalizeDouble(MarketInfo(g_var_336,MODE_BID) - g_var_103 * g_var_229,g_var_190) ;
              if ( l_var_7<MarketInfo(g_var_336,MODE_BID) - g_var_221 )
              {
                g_var_230 = OrderModify(l_var_9,l_var_10,l_var_7,l_var_8,0,0xFFFFFFFF) ;
                if ( g_var_230 <= 0 )
                {
                  Print("TrailStop error: \'" + TGR_21(GetLastError()) + "\' when setting trailing Exit_stop loss.  Trying again!"); 
                }
                else
                {
                  l_var_26 = NormalizeDouble(g_var_107 / 100.0 * g_var_223[g_var_328],2) ;
                  if ( l_var_26<l_var_12 && l_var_26>=MarketInfo(g_var_336,MODE_LOTSTEP) )
                  {
                    OrderClose(l_var_9,l_var_26,MarketInfo(g_var_336,MODE_BID),g_var_38,Red); 
                    return(true); 
                  }
                }
                l_var_2 = true ;
              }
            }
            if ( g_var_108>0.0 && MarketInfo(g_var_336,MODE_ASK)<NormalizeDouble(l_var_8 - g_var_337 - g_var_108 * g_var_229,g_var_190) && MarketInfo(g_var_336,MODE_ASK)<NormalizeDouble(l_var_5 - g_var_109 * g_var_229,g_var_190) && MarketInfo(g_var_336,MODE_BID)<l_var_8 - g_var_309 )
            {
              l_var_8 = NormalizeDouble(MarketInfo(g_var_336,MODE_BID) + g_var_108 * g_var_229,g_var_190) ;
              if ( l_var_8>MarketInfo(g_var_336,MODE_ASK) + g_var_221 )
              {
                g_var_230 = OrderModify(l_var_9,l_var_10,l_var_7,l_var_8,0,0xFFFFFFFF) ;
                if ( g_var_230 <= 0 )
                {
                  Print("TrailStop error: \'" + TGR_21(GetLastError()) + "\' when setting trailing Exit_TP.  Trying again!"); 
                }
                else
                {
                  l_var_27 = NormalizeDouble(g_var_107 / 100.0 * g_var_223[g_var_328],2) ;
                  if ( l_var_27<l_var_12 && l_var_27>=SymbolInfoDouble(g_var_336,34) )
                  {
                    OrderClose(l_var_9,l_var_27,MarketInfo(g_var_336,MODE_BID),g_var_38,Red); 
                    return(true); 
                  }
                }
                l_var_2 = true ;
              }
            }
            if ( l_var_19 && g_var_39 == 1 && g_var_41>0.0 && MarketInfo(g_var_336,MODE_BID)>NormalizeDouble(g_var_41 * g_var_229 + (l_var_7 + g_var_337),g_var_190) && MarketInfo(g_var_336,MODE_BID)>NormalizeDouble(g_var_40 * g_var_229 + l_var_17,g_var_190) && MarketInfo(g_var_336,MODE_BID)<l_var_8 - g_var_309 && l_var_7<NormalizeDouble(g_var_42 * g_var_229 + l_var_10,g_var_190) )
            {
              l_var_7 = NormalizeDouble(MarketInfo(g_var_336,MODE_BID) - g_var_41 * g_var_229,g_var_190) ;
              if ( l_var_7<MarketInfo(g_var_336,MODE_BID) - g_var_221 )
              {
                g_var_230 = OrderModify(l_var_9,l_var_10,l_var_7,l_var_8,0,0xFFFFFFFF) ;
                if ( g_var_230 <= 0 )
                {
                  Print("TrailStop error: \'" + TGR_21(GetLastError()) + "\' when setting Slip TL.  Trying again!"); 
                }
                else
                {
                  Print("Slippage control active"); 
                }
                l_var_2 = true ;
              }
            }
            if ( g_var_119 >  0 && g_var_120 >= 0 && UseHL_TrailingSL && g_var_242[g_var_328]>NormalizeDouble(l_var_7 + g_var_221 + g_var_337,g_var_190) && g_var_242[g_var_328]<MarketInfo(g_var_336,MODE_BID) - g_var_121 * g_var_229 && ( g_var_242[g_var_328]<l_var_10 || !(g_var_116) ) && g_var_242[g_var_328]<NormalizeDouble(MarketInfo(g_var_336,MODE_BID) - g_var_122 * g_var_229 - g_var_221 - g_var_337,g_var_190) && MarketInfo(g_var_336,MODE_BID)<l_var_8 - g_var_309 )
            {
              l_var_7 = NormalizeDouble(g_var_242[g_var_328],g_var_190) ;
              if ( l_var_7<MarketInfo(g_var_336,MODE_BID) - g_var_221 )
              {
                g_var_230 = OrderModify(l_var_9,l_var_10,l_var_7,l_var_8,0,0xFFFFFFFF) ;
                if ( g_var_230 <= 0 )
                {
                  Print("error: \'" + TGR_21(GetLastError()) + "\' when modifying stoploss"); 
                }
                l_var_2 = true ;
              }
            }
            if ( g_var_113>0.0 && MarketInfo(g_var_336,MODE_BID)>NormalizeDouble(g_var_113 * g_var_229 + l_var_10,g_var_190) && NormalizeDouble(g_var_114 * g_var_229 + l_var_10,g_var_190)>l_var_7 + g_var_337 && MarketInfo(g_var_336,MODE_BID)>NormalizeDouble(g_var_114 * g_var_229 + l_var_10 + g_var_221,g_var_190) && MarketInfo(g_var_336,MODE_BID)<l_var_8 - g_var_309 )
            {
              l_var_7 = NormalizeDouble(g_var_114 * g_var_229 + l_var_10,g_var_190) ;
              if ( l_var_7<MarketInfo(g_var_336,MODE_BID) - g_var_221 )
              {
                g_var_230 = OrderModify(l_var_9,l_var_10,l_var_7,l_var_8,0,0xFFFFFFFF) ;
                if ( g_var_230 <= 0 )
                {
                  Print("error when setting breakeven: \'" + TGR_21(GetLastError()) + "\' ..\'Exit_BE_start\' to close to \'Exit_BE_extra_pips\' ..trying again!"); 
                }
                l_var_2 = true ;
              }
            }
            if ( !(l_var_2) && ( g_var_128 == 1 || (g_var_128 == 2 && g_var_131 * g_var_229 + l_var_7<=g_var_132 * g_var_229 + (l_var_5 + g_var_1)) ) )
            {
              g_var_250 ++;
              if ( MarketInfo(g_var_336,MODE_BID)>g_var_131 * g_var_229 + l_var_7 + g_var_221 && MarketInfo(g_var_336,MODE_BID)<l_var_8 - g_var_309 && ( g_var_129==0.0 || MarketInfo(g_var_336,MODE_BID)>g_var_247 * g_var_229 + l_var_5 ) && g_var_250 >= g_var_130 && NormalizeDouble(g_var_131 * g_var_229 + l_var_7,g_var_190)>l_var_7 )
              {
                g_var_250 = 0 ;
                l_var_7 = NormalizeDouble(g_var_131 * g_var_229 + l_var_7,g_var_190) ;
                OrderModify(l_var_9,l_var_10,l_var_7,l_var_8,0,0xFFFFFFFF); 
                l_var_2 = true ;
              }
            }
            g_var_191 = l_var_7 ;
            if ( MarketInfo(g_var_336,MODE_BID)<l_var_7 )
            {
              Print("Closing with virtual SL"); 
              RefreshRates(); 
              OrderClose(l_var_9,l_var_12,MarketInfo(g_var_336,MODE_BID),g_var_1,0xFFFFFFFF); 
              return(true); 
            }
            if ( NormalizeDouble(l_var_4,g_var_190)!=NormalizeDouble(g_var_191,g_var_190) )
            {
              tmp_var_31 = NormalizeDouble(g_var_191,g_var_190);
              tmp_var_32 = l_var_9;
              for (tmp_var_33 = 0 ; tmp_var_33 < g_var_199 ; tmp_var_33 = tmp_var_33 + 1)
              {
                if ( g_var_196[tmp_var_33][0]==tmp_var_32 )
                {
                  g_var_196[tmp_var_33][1] = tmp_var_31;
                  break;
                }
              }
            }
            if ( l_var_2 && g_var_135 )
            {
              return(true); 
            }
          }
          if ( ( g_var_63 == 2 || g_var_63 == 3 ) )
          {
            tmp_var_34 = l_var_9;
            tmp_var_35 = g_var_100;
            tmp_var_36 = l_var_10;
            tmp_var_37 = 1;
            tmp_var_38 = 0.0;
            tmp_var_39 = false;
            for (tmp_var_40 = 0 ; tmp_var_40 < g_var_199 ; tmp_var_40 = tmp_var_40 + 1)
            {
              if ( g_var_196[tmp_var_40][0]==tmp_var_34 )
              {
                tmp_var_38 = g_var_196[tmp_var_40][1];
                tmp_var_39 = true;
                break;
              }
            }
            if ( !(tmp_var_39) )
            {
              if ( tmp_var_37 == 1 )
              {
                tmp_var_38 = NormalizeDouble(tmp_var_36 - tmp_var_35 * g_var_229,g_var_190);
              }
              if ( tmp_var_37 == 2 )
              {
                tmp_var_38 = NormalizeDouble(tmp_var_35 * g_var_229 + tmp_var_36,g_var_190);
              }
              for (tmp_var_41 = 0 ; tmp_var_41 < g_var_199 ; tmp_var_41 = tmp_var_41 + 1)
              {
                if ( g_var_196[tmp_var_41][0]==0.0 )
                {
                  g_var_196[tmp_var_41][0] = tmp_var_34;
                  g_var_196[tmp_var_41][1] = tmp_var_38;
                  break;
                }
              }
            }
            g_var_191 = tmp_var_38 ;
            l_var_4 = g_var_191 ;
            if ( MarketInfo(g_var_336,MODE_BID)<=l_var_4 )
            {
              RefreshRates(); 
              OrderClose(l_var_9,l_var_12,MarketInfo(g_var_336,MODE_BID),g_var_1,0xFFFFFFFF); 
              return(true); 
            }
            l_var_28 = TimeCurrent() - g_var_319 ;
            if ( l_var_28 >= g_var_65 )
            {
              if ( NormalizeDouble(g_var_191,g_var_190)>l_var_7 + g_var_337 )
              {
                OrderModify(l_var_9,l_var_10,NormalizeDouble(g_var_191,g_var_190),l_var_8,0,0xFFFFFFFF); 
              }
              g_var_319 = TimeCurrent() ;
            }
            if ( g_var_125>0.0 && TimeCurrent() >= l_var_13 + g_var_304 && MarketInfo(g_var_336,MODE_BID)>g_var_126 * g_var_229 + (g_var_191 + g_var_337) && MarketInfo(g_var_336,MODE_BID)<l_var_8 - g_var_309 )
            {
              l_var_2 = true ;
              g_var_191 = MarketInfo(g_var_336,MODE_BID) - g_var_126 * g_var_229 ;
            }
            if ( g_var_103>0.0 && MarketInfo(g_var_336,MODE_BID)>(g_var_103 + g_var_106) * g_var_229 + (g_var_191 + g_var_337) && MarketInfo(g_var_336,MODE_BID)>g_var_104 * g_var_229 + l_var_5 && g_var_191<g_var_105 * g_var_229 + l_var_10 )
            {
              l_var_2 = true ;
              g_var_191 = MarketInfo(g_var_336,MODE_BID) - g_var_103 * g_var_229 ;
              l_var_29 = NormalizeDouble(g_var_107 / 100.0 * g_var_223[g_var_328],2) ;
              if ( l_var_29<l_var_12 && l_var_29>=MarketInfo(g_var_336,MODE_LOTSTEP) )
              {
                OrderClose(l_var_9,l_var_29,MarketInfo(g_var_336,MODE_BID),g_var_38,Red); 
                return(true); 
              }
            }
            if ( l_var_19 && g_var_39 == 1 && g_var_41>0.0 && MarketInfo(g_var_336,MODE_BID)>g_var_41 * g_var_229 + (g_var_191 + g_var_337) && MarketInfo(g_var_336,MODE_BID)>g_var_40 * g_var_229 + l_var_17 && MarketInfo(g_var_336,MODE_BID)<l_var_8 - g_var_309 && g_var_191<g_var_42 * g_var_229 + l_var_10 )
            {
              Print("Slippage control active"); 
              l_var_2 = true ;
              g_var_191 = MarketInfo(g_var_336,MODE_BID) - g_var_41 * g_var_229 ;
            }
            if ( g_var_119 >  0 && g_var_120 >= 0 && g_var_242[g_var_328]>g_var_191 + g_var_221 + g_var_337 && ( g_var_242[g_var_328]<l_var_10 || !(g_var_116) ) && g_var_242[g_var_328]<MarketInfo(g_var_336,MODE_BID) - g_var_122 * g_var_229 - g_var_221 - g_var_337 && MarketInfo(g_var_336,MODE_BID)<l_var_8 - g_var_309 )
            {
              g_var_191 = g_var_242[g_var_328] ;
              l_var_2 = true ;
            }
            if ( g_var_113>0.0 && g_var_63 == 3 && MarketInfo(g_var_336,MODE_BID)>g_var_113 * g_var_229 + l_var_10 && g_var_114 * g_var_229 + l_var_10>l_var_7 + g_var_337 && MarketInfo(g_var_336,MODE_BID)>g_var_114 * g_var_229 + l_var_10 + g_var_221 && MarketInfo(g_var_336,MODE_BID)<l_var_8 - g_var_309 && NormalizeDouble(g_var_114 * g_var_229 + l_var_10,g_var_190)>OrderStopLoss() )
            {
              g_var_191 = NormalizeDouble(g_var_114 * g_var_229 + l_var_10,g_var_190) ;
              g_var_230 = OrderModify(l_var_9,l_var_10,g_var_191,l_var_8,0,0xFFFFFFFF) ;
              if ( g_var_230 <= 0 )
              {
                Print("error when setting breakeven: \'" + TGR_21(GetLastError()) + "\' ..\'Exit_BE_start\' to close to \'Exit_BE_extra_pips\' ..trying again!"); 
              }
              l_var_2 = true ;
            }
            if ( g_var_113>0.0 && g_var_63 == 2 && MarketInfo(g_var_336,MODE_BID)>g_var_113 * g_var_229 + l_var_10 && g_var_114 * g_var_229 + l_var_10>g_var_191 + g_var_337 && MarketInfo(g_var_336,MODE_BID)>g_var_114 * g_var_229 + l_var_10 + g_var_221 && MarketInfo(g_var_336,MODE_BID)<l_var_8 - g_var_309 )
            {
              g_var_191 = g_var_114 * g_var_229 + l_var_10 ;
              l_var_2 = true ;
            }
            if ( !(l_var_2) && ( g_var_128 == 1 || (g_var_128 == 2 && g_var_131 * g_var_229 + g_var_191<=g_var_132 * g_var_229 + (l_var_5 + g_var_1)) ) )
            {
              g_var_250 ++;
              if ( MarketInfo(g_var_336,MODE_BID)>g_var_131 * g_var_229 + g_var_191 + g_var_221 && MarketInfo(g_var_336,MODE_BID)<l_var_8 - g_var_309 && ( g_var_129==0.0 || MarketInfo(g_var_336,MODE_BID)>g_var_247 * g_var_229 + l_var_5 ) && g_var_250 >= g_var_130 )
              {
                g_var_250 = 0 ;
                g_var_191 = g_var_131 * g_var_229 + g_var_191 ;
                l_var_2 = true ;
              }
            }
            if ( MarketInfo(g_var_336,MODE_BID)<=g_var_191 )
            {
              RefreshRates(); 
              OrderClose(l_var_9,l_var_12,MarketInfo(g_var_336,MODE_BID),g_var_1,0xFFFFFFFF); 
              return(true); 
            }
            if ( NormalizeDouble(l_var_4,g_var_190)!=NormalizeDouble(g_var_191,g_var_190) )
            {
              tmp_var_42 = NormalizeDouble(g_var_191,g_var_190);
              tmp_var_43 = l_var_9;
              for (tmp_var_44 = 0 ; tmp_var_44 < g_var_199 ; tmp_var_44 = tmp_var_44 + 1)
              {
                if ( g_var_196[tmp_var_44][0]==tmp_var_43 )
                {
                  g_var_196[tmp_var_44][1] = tmp_var_42;
                  break;
                }
              }
            }
          }
        }
      }
      if ( l_var_2 )
      {
        l_var_3 = true ;
      }
    }
    if ( l_var_2 )
    {
      l_var_3 = true ;
    }
  }
  return(l_var_3); 
}
//TGR_18 <<==--------   --------

bool TGR_19()
{
  bool      l_var_2 = false;
  bool      l_var_3 = false;
  double    l_var_4;
  double    l_var_5;
  int       l_var_6;
  double    l_var_7;
  double    l_var_8;
  long      l_var_9;
  double    l_var_10;
  string    l_var_11;
  double    l_var_12;
  datetime  l_var_13;
  int       l_var_14;
  int       l_var_15;
  string    l_var_16;
  double    l_var_17;
  double    l_var_18;
  bool      l_var_19;
  bool      l_var_20;
  double    l_var_21;
  bool      l_var_22;
  double    l_var_23;
  double    l_var_24;
  double    l_var_25;
  double    l_var_26;
  double    l_var_27;
  int       l_var_28;
  double    l_var_29;
//----- -----
  int        tmp_var_1;
  long       tmp_var_2;
  int        tmp_var_3;
  double     tmp_var_4;
  double     tmp_var_5;
  long       tmp_var_6;
  int        tmp_var_7;
  long       tmp_var_8;
  int        tmp_var_9;
  int        tmp_var_10;
  string     tmp_var_11;
  double     tmp_var_12;
  int        tmp_var_13;
  long       tmp_var_14;
  double     tmp_var_15;
  int        tmp_var_16;
  long       tmp_var_17;
  long       tmp_var_18;
  int        tmp_var_19;
  int        tmp_var_20;
  int        tmp_var_21;
  string     tmp_var_22;
  long       tmp_var_23;
  double     tmp_var_24;
  double     tmp_var_25;
  int        tmp_var_26;
  double     tmp_var_27;
  bool       tmp_var_28;
  int        tmp_var_29;
  int        tmp_var_30;
  double     tmp_var_31;
  long       tmp_var_32;
  int        tmp_var_33;
  long       tmp_var_34;
  double     tmp_var_35;
  double     tmp_var_36;
  int        tmp_var_37;
  double     tmp_var_38;
  bool       tmp_var_39;
  int        tmp_var_40;
  int        tmp_var_41;
  double     tmp_var_42;
  long       tmp_var_43;
  int        tmp_var_44;

  l_var_4 = 0.0 ;
  l_var_5 = 0.0 ;
  for (l_var_6 = 0 ; l_var_6 < OrdersTotal() ; l_var_6 ++)
  {
    if ( OrderSelect(l_var_6,0,0) == true )
    {
      l_var_2 = false ;
      l_var_7 = NormalizeDouble(OrderStopLoss(),g_var_190) ;
      l_var_8 = NormalizeDouble(OrderTakeProfit(),g_var_190) ;
      l_var_9 = OrderTicket() ;
      l_var_10 = NormalizeDouble(OrderOpenPrice(),g_var_190) ;
      l_var_11 = OrderComment() ;
      l_var_12 = OrderLots() ;
      l_var_13 = OrderOpenTime() ;
      l_var_14 = OrderType() ;
      l_var_15 = OrderMagicNumber() ;
      l_var_16 = OrderSymbol() ;
      if ( ( l_var_14 == 5 || l_var_14 == 3 ) && g_var_69 == 2 && ( g_var_95 == 0 || (g_var_95 == 1 && l_var_16 == g_var_336) ) && ( l_var_15 == g_var_96 || g_var_96 == 0 ) && ( l_var_11 == g_var_97 || g_var_97 == "" ) )
      {
        if ( ( l_var_7==0.0 || l_var_7==0.0 ) )
        {
          l_var_7 = NormalizeDouble(g_var_100 * g_var_229 + l_var_10,g_var_190) ;
          OrderModify(l_var_9,l_var_10,l_var_7,l_var_8,0,Green); 
        }
        if ( ( l_var_8==0.0 || l_var_8==0.0 ) )
        {
          l_var_8 = NormalizeDouble(l_var_10 - g_var_101 * g_var_229,g_var_190) ;
          OrderModify(l_var_9,l_var_10,l_var_7,l_var_8,0,Green); 
        }
      }
      if ( l_var_14 == 1 && ( ( l_var_15 == g_var_93 && g_var_69 == 1 && l_var_16 == g_var_336 ) || (g_var_69 == 2 && ( g_var_95 == 0 || (g_var_95 == 1 && l_var_16 == g_var_336) ) && ( l_var_15 == g_var_96 || g_var_96 == 0 ) && (l_var_11 == g_var_97 || g_var_97 == "")) ) )
      {
        if ( ( l_var_7==0.0 || l_var_7==0.0 ) )
        {
          l_var_7 = NormalizeDouble(g_var_100 * g_var_229 + l_var_10,g_var_190) ;
          OrderModify(l_var_9,l_var_10,l_var_7,l_var_8,0,Green); 
        }
        if ( ( l_var_8==0.0 || l_var_8==0.0 ) )
        {
          l_var_8 = NormalizeDouble(l_var_10 - g_var_101 * g_var_229,g_var_190) ;
          OrderModify(l_var_9,l_var_10,l_var_7,l_var_8,0,Green); 
        }
        if ( g_var_53 && iTime(g_var_336,g_var_52,g_var_51) <= l_var_13 && iTime(g_var_336,g_var_52,0) >  l_var_13 && iClose(g_var_336,g_var_52,1)>iOpen(g_var_336,g_var_52,1) && iClose(g_var_336,g_var_52,1)>l_var_10 )
        {
          OrderClose(l_var_9,l_var_12,MarketInfo(g_var_336,MODE_ASK),0,Red); 
          Print("closing candle confirmation"); 
        }
        if ( g_var_55 && iTime(g_var_336,g_var_54,g_var_51) <= l_var_13 && iTime(g_var_336,g_var_54,0) >  l_var_13 && iClose(g_var_336,g_var_54,1)>iOpen(g_var_336,g_var_54,1) && iClose(g_var_336,g_var_54,1)>l_var_10 )
        {
          OrderClose(l_var_9,l_var_12,MarketInfo(g_var_336,MODE_ASK),0,Red); 
          Print("closing candle confirmation"); 
        }
        if ( g_var_57 && iTime(g_var_336,g_var_56,g_var_51) <= l_var_13 && iTime(g_var_336,g_var_56,0) >  l_var_13 && iClose(g_var_336,g_var_56,1)>iOpen(g_var_336,g_var_56,1) && iClose(g_var_336,g_var_56,1)>l_var_10 )
        {
          OrderClose(l_var_9,l_var_12,MarketInfo(g_var_336,MODE_ASK),0,Red); 
          Print("closing candle confirmation"); 
        }
        if ( g_var_59 && iTime(g_var_336,g_var_58,g_var_51) <= l_var_13 && iTime(g_var_336,g_var_58,0) >  l_var_13 && iClose(g_var_336,g_var_58,1)>iOpen(g_var_336,g_var_58,1) && iClose(g_var_336,g_var_58,1)>l_var_10 )
        {
          OrderClose(l_var_9,l_var_12,MarketInfo(g_var_336,MODE_ASK),0,Red); 
          Print("closing candle confirmation"); 
        }
        if ( g_var_61 && iTime(g_var_336,g_var_60,g_var_51) <= l_var_13 && iTime(g_var_336,g_var_60,0) >  l_var_13 && iClose(g_var_336,g_var_60,1)>iOpen(g_var_336,g_var_60,1) && iClose(g_var_336,g_var_60,1)>l_var_10 )
        {
          OrderClose(l_var_9,l_var_12,MarketInfo(g_var_336,MODE_ASK),0,Red); 
          Print("closing candle confirmation"); 
        }
        g_var_247 = g_var_129 ;
        if ( g_var_133 >  0 && TimeCurrent() >  l_var_13 + g_var_133 * 60 )
        {
          g_var_247 = g_var_134 ;
        }
        tmp_var_1 = g_var_190;
        tmp_var_2 = l_var_9;
        for (tmp_var_3 = 0 ; tmp_var_3 < 100 ; tmp_var_3 = tmp_var_3 + 1)
        {
          if ( !(g_var_198[tmp_var_3][0]==tmp_var_2) )   continue;
          tmp_var_4 = g_var_198[tmp_var_3][1];
          break;
          
        }
        tmp_var_4 = 0.0;
        l_var_17 = NormalizeDouble(tmp_var_4,tmp_var_1) ;
        if ( l_var_17==0.0 )
        {
          tmp_var_5 = l_var_10;
          tmp_var_6 = l_var_9;
          for (tmp_var_7 = 0 ; tmp_var_7 < 100 ; tmp_var_7 = tmp_var_7 + 1)
          {
            if ( !(g_var_198[tmp_var_7][0]==0.0) )   continue;
            g_var_198[tmp_var_7][0] = tmp_var_6;
            g_var_198[tmp_var_7][1] = tmp_var_5;
            break;
            
          }
          l_var_17 = l_var_10 ;
        }
        else
        {
          l_var_17 = l_var_17 - g_var_85 * g_var_229 ;
        }
        l_var_18 = l_var_17 - l_var_10 ;
        l_var_19 = false ;
        if ( l_var_17>g_var_85 * g_var_229 && l_var_18>g_var_38 * g_var_229 )
        {
          l_var_19 = true ;
          if ( g_var_39 == 2 )
          {
            g_var_247 = -1000.0 ;
            Print("Slippage Mode 2 active"); 
          }
        }
        if ( g_var_43 )
        {
          l_var_5 = l_var_17 ;
        }
        else
        {
          l_var_5 = l_var_10 ;
        }
        if ( l_var_7>NormalizeDouble((g_var_100 + g_var_64) * g_var_229 + l_var_10 + g_var_1,g_var_190) )
        {
          l_var_7 = NormalizeDouble((g_var_100 + g_var_64) * g_var_229 + l_var_10 + g_var_1,g_var_190) ;
          OrderModify(l_var_9,l_var_10,l_var_7,l_var_8,0,0xFFFFFFFF); 
        }
        if ( MarketInfo(g_var_336,MODE_ASK)>(g_var_100 + g_var_64) * g_var_229 + l_var_10 + g_var_1 )
        {
          RefreshRates(); 
          OrderClose(OrderTicket(),OrderLots(),MarketInfo(g_var_336,MODE_ASK),g_var_1,Red); 
          return(true); 
        }
        l_var_20 = false ;
        if ( g_var_159 )
        {
          tmp_var_8 = l_var_9;
          tmp_var_9 = 0;
          for (tmp_var_10 = OrdersTotal() ; tmp_var_10 >= 0 ; tmp_var_10 = tmp_var_10 - 1)
          {
            if ( OrderSelect(tmp_var_10,0,0) != true || OrderMagicNumber() != g_var_169 || OrderSymbol() != g_var_336 )   continue;
            tmp_var_11 = OrderComment();
            if ( tmp_var_11 != IntegerToString(tmp_var_8,0,32) )   continue;
            tmp_var_9 = tmp_var_9 + 1;
            
          }
          l_var_21 = tmp_var_9 ;
          l_var_22 = false ;
          if ( !(g_var_195) )
          {
            g_var_195 = true ;
            g_var_193 = 1 ;
          }
          if ( l_var_21==0.0 )
          {
            g_var_193 = 1 ;
          }
          if ( MathFloor(l_var_21 / 2.0)==l_var_21 / 2.0 )
          {
            g_var_193 = 1 ;
          }
          else
          {
            g_var_193 = 0 ;
          }
          if ( g_var_195 )
          {
            if ( l_var_21>0.0 )
            {
              tmp_var_12 = AccountEquity();
              if ( tmp_var_12>AccountBalance() + g_var_163 )
              {
                for (tmp_var_13 = OrdersTotal() ; tmp_var_13 >= 0 ; tmp_var_13 = tmp_var_13 - 1)
                {
                  if ( OrderSelect(tmp_var_13,0,0) != true )   continue;
                  
                  if ( ( OrderMagicNumber() != g_var_93 && OrderMagicNumber() != g_var_169 && OrderMagicNumber() != g_var_168 ) )   continue;
                  
                  if ( OrderType() == 0 )
                  {
                    OrderClose(OrderTicket(),OrderLots(),MarketInfo(g_var_336,MODE_BID),g_var_38,Red); 
                  }
                  if ( OrderType() != 1 )   continue;
                  OrderClose(OrderTicket(),OrderLots(),MarketInfo(g_var_336,MODE_ASK),g_var_38,Red); 
                  
                }
              }
            }
            if ( l_var_21>0.0 )
            {
              tmp_var_14 = l_var_9;
              tmp_var_15 = 0.0;
              for (tmp_var_16 = OrdersTotal() ; tmp_var_16 >= 0 ; tmp_var_16 = tmp_var_16 - 1)
              {
                if ( OrderSelect(tmp_var_16,0,0) != true )   continue;
                tmp_var_17 = OrderTicket();
                if ( tmp_var_17 != tmp_var_14 )
                {
                  tmp_var_11 = OrderComment();
                if ( tmp_var_11 != IntegerToString(tmp_var_14,0,32) )   continue;
                }
                tmp_var_15 = tmp_var_15 + OrderProfit();
                
              }
              if ( tmp_var_15>g_var_163 )
              {
                Print("Closing zone"); 
                tmp_var_18 = l_var_9;
                for (tmp_var_19 = OrdersTotal() ; tmp_var_19 >= 0 ; tmp_var_19 = tmp_var_19 - 1)
                {
                  if ( OrderSelect(tmp_var_19,0,0) != true )   continue;
                  
                  if ( OrderMagicNumber() == g_var_93 && OrderTicket() == tmp_var_18 )
                  {
                    OrderClose(OrderTicket(),OrderLots(),MarketInfo(g_var_336,MODE_ASK),3,Red); 
                  }
                  if ( OrderMagicNumber() != g_var_169 )   continue;
                  tmp_var_11 = OrderComment();
                  if ( tmp_var_11 != IntegerToString(tmp_var_18,0,32) )   continue;
                  
                  if ( OrderType() == 0 )
                  {
                    OrderClose(OrderTicket(),OrderLots(),MarketInfo(g_var_336,MODE_BID),g_var_38,Red); 
                  }
                  if ( OrderType() != 1 )   continue;
                  OrderClose(OrderTicket(),OrderLots(),MarketInfo(g_var_336,MODE_ASK),g_var_38,Red); 
                  
                }
                g_var_195 = false ;
                l_var_20 = true ;
              }
            }
            else
            {
              l_var_23 = l_var_12 * g_var_165 ;
              if ( g_var_164 == 2 )
              {
                l_var_23 = (l_var_21 + 1.0) * l_var_12 + l_var_12 ;
              }
              if ( g_var_164 == 3 )
              {
                l_var_23 = l_var_12 * (MathPow(g_var_165,l_var_21 + 1.0)) ;
              }
              if ( g_var_193 == 0 )
              {
                l_var_24 = l_var_17 ;
                if ( MarketInfo(g_var_336,MODE_BID)<l_var_17 )
                {
                  if ( l_var_21>=g_var_166 )
                  {
                    for (tmp_var_20 = OrdersTotal() ; tmp_var_20 >= 0 ; tmp_var_20 = tmp_var_20 - 1)
                    {
                      if ( OrderSelect(tmp_var_20,0,0) != true )   continue;
                      
                      if ( OrderMagicNumber() == g_var_93 && OrderTicket() == l_var_9 )
                      {
                        OrderClose(OrderTicket(),OrderLots(),MarketInfo(g_var_336,MODE_ASK),3,Red); 
                      }
                      if ( OrderMagicNumber() != g_var_169 )   continue;
                      tmp_var_11 = OrderComment();
                      if ( tmp_var_11 != IntegerToString(l_var_9,0,32) )   continue;
                      
                      if ( OrderType() == 0 )
                      {
                        OrderClose(OrderTicket(),OrderLots(),MarketInfo(g_var_336,MODE_BID),g_var_38,Red); 
                      }
                      if ( OrderType() != 1 )   continue;
                      OrderClose(OrderTicket(),OrderLots(),MarketInfo(g_var_336,MODE_ASK),g_var_38,Red); 
                      
                    }
                  }
                  else
                  {
                    OrderSend(g_var_336,1,l_var_23,MarketInfo(g_var_336,MODE_BID),g_var_38,0.0,0.0,IntegerToString(l_var_9,0,32),g_var_169,0,Green); 
                    g_var_193 = 1 ;
                    l_var_22 = true ;
                  }
                }
              }
              else
              {
                l_var_25 = g_var_160 * g_var_229 + l_var_17 - l_var_21 * g_var_161 * g_var_229 ;
                if ( l_var_25<g_var_162 * g_var_229 + l_var_17 )
                {
                  l_var_25 = g_var_162 * g_var_229 + l_var_17 ;
                }
                if ( MarketInfo(g_var_336,MODE_ASK)>l_var_25 )
                {
                  if ( l_var_21>=g_var_166 )
                  {
                    for (tmp_var_21 = OrdersTotal() ; tmp_var_21 >= 0 ; tmp_var_21 = tmp_var_21 - 1)
                    {
                      if ( OrderSelect(tmp_var_21,0,0) != true )   continue;
                      
                      if ( OrderMagicNumber() == g_var_93 && OrderTicket() == l_var_9 )
                      {
                        OrderClose(OrderTicket(),OrderLots(),MarketInfo(g_var_336,MODE_ASK),3,Red); 
                      }
                      if ( OrderMagicNumber() != g_var_169 )   continue;
                      tmp_var_22 = OrderComment();
                      if ( tmp_var_22 != IntegerToString(l_var_9,0,32) )   continue;
                      
                      if ( OrderType() == 0 )
                      {
                        OrderClose(OrderTicket(),OrderLots(),MarketInfo(g_var_336,MODE_BID),g_var_38,Red); 
                      }
                      if ( OrderType() != 1 )   continue;
                      OrderClose(OrderTicket(),OrderLots(),MarketInfo(g_var_336,MODE_ASK),g_var_38,Red); 
                      
                    }
                  }
                  else
                  {
                    OrderSend(g_var_336,0,l_var_23,MarketInfo(g_var_336,MODE_ASK),g_var_38,0.0,0.0,IntegerToString(l_var_9,0,32),g_var_169,0,Green); 
                    g_var_193 = 0 ;
                    l_var_22 = true ;
                  }
                }
              }
            }
          }
          if ( ( l_var_21>0.0 || l_var_22 ) )
          {
            l_var_20 = true ;
          }
        }
        if ( !(l_var_20) )
        {
          if ( ( g_var_63 == 1 || (g_var_63 != 2 && g_var_63 != 3) ) )
          {
            tmp_var_23 = l_var_9;
            tmp_var_24 = g_var_100;
            tmp_var_25 = l_var_10;
            tmp_var_26 = 2;
            tmp_var_27 = 0.0;
            tmp_var_28 = false;
            for (tmp_var_29 = 0 ; tmp_var_29 < g_var_199 ; tmp_var_29 = tmp_var_29 + 1)
            {
              if ( g_var_196[tmp_var_29][0]==tmp_var_23 )
              {
                tmp_var_27 = g_var_196[tmp_var_29][1];
                tmp_var_28 = true;
                break;
              }
            }
            if ( !(tmp_var_28) )
            {
              if ( tmp_var_26 == 1 )
              {
                tmp_var_27 = NormalizeDouble(tmp_var_25 - tmp_var_24 * g_var_229,g_var_190);
              }
              if ( tmp_var_26 == 2 )
              {
                tmp_var_27 = NormalizeDouble(tmp_var_24 * g_var_229 + tmp_var_25,g_var_190);
              }
              for (tmp_var_30 = 0 ; tmp_var_30 < g_var_199 ; tmp_var_30 = tmp_var_30 + 1)
              {
                if ( g_var_196[tmp_var_30][0]==0.0 )
                {
                  g_var_196[tmp_var_30][0] = tmp_var_23;
                  g_var_196[tmp_var_30][1] = tmp_var_27;
                  break;
                }
              }
            }
            g_var_191 = tmp_var_27 ;
            l_var_4 = g_var_191 ;
            if ( MarketInfo(g_var_336,MODE_ASK)>l_var_4 )
            {
              Print("Closing with virtual SL"); 
              RefreshRates(); 
              OrderClose(l_var_9,l_var_12,MarketInfo(g_var_336,MODE_ASK),g_var_1,0xFFFFFFFF); 
              return(true); 
            }
            if ( g_var_125>0.0 && TimeCurrent() >= l_var_13 + g_var_304 && MarketInfo(g_var_336,MODE_ASK)<l_var_7 - g_var_337 - g_var_126 * g_var_229 && MarketInfo(g_var_336,MODE_ASK)>l_var_8 + g_var_309 && NormalizeDouble(MarketInfo(g_var_336,MODE_ASK) + g_var_126 * g_var_229,g_var_190)<l_var_7 )
            {
              l_var_7 = NormalizeDouble(MarketInfo(g_var_336,MODE_ASK) + g_var_126 * g_var_229,g_var_190) ;
              if ( l_var_7>MarketInfo(g_var_336,MODE_ASK) + g_var_221 )
              {
                g_var_230 = OrderModify(l_var_9,l_var_10,l_var_7,l_var_8,0,0xFFFFFFFF) ;
                if ( g_var_230 <= 0 )
                {
                  Print("TrailStop error: \'" + TGR_21(GetLastError()) + "\' when setting trailing Exit_TrailSL_after_X_Minutes_size loss.  Trying again!"); 
                }
                l_var_2 = true ;
              }
            }
            if ( g_var_103>0.0 && MarketInfo(g_var_336,MODE_ASK)<l_var_7 - g_var_337 - (g_var_103 + g_var_106) * g_var_229 && MarketInfo(g_var_336,MODE_ASK)<l_var_5 - g_var_104 * g_var_229 && MarketInfo(g_var_336,MODE_ASK)>l_var_8 + g_var_309 && l_var_7>l_var_10 - g_var_105 * g_var_229 && NormalizeDouble(g_var_103 * g_var_229 + MarketInfo(g_var_336,MODE_ASK),g_var_190)<l_var_7 )
            {
              l_var_7 = NormalizeDouble(MarketInfo(g_var_336,MODE_ASK) + g_var_103 * g_var_229,g_var_190) ;
              if ( l_var_7>MarketInfo(g_var_336,MODE_ASK) + g_var_221 )
              {
                g_var_230 = OrderModify(l_var_9,l_var_10,l_var_7,l_var_8,0,0xFFFFFFFF) ;
                if ( g_var_230 <= 0 )
                {
                  Print("TrailStop error: \'" + TGR_21(GetLastError()) + "\' when setting trailing Exit_stop loss.  Trying again!"); 
                }
                else
                {
                  l_var_26 = NormalizeDouble(g_var_107 / 100.0 * g_var_223[g_var_328],2) ;
                  if ( l_var_26<l_var_12 && l_var_26>=MarketInfo(g_var_336,MODE_LOTSTEP) )
                  {
                    OrderClose(l_var_9,l_var_26,MarketInfo(g_var_336,MODE_ASK),g_var_38,Red); 
                    return(true); 
                  }
                }
                l_var_2 = true ;
              }
            }
            if ( g_var_108>0.0 && MarketInfo(g_var_336,MODE_BID)>NormalizeDouble(g_var_108 * g_var_229 + (l_var_8 + g_var_337),g_var_190) && Bid>NormalizeDouble(g_var_109 * g_var_229 + l_var_5,g_var_190) && MarketInfo(g_var_336,MODE_BID)>l_var_8 + g_var_309 )
            {
              l_var_8 = NormalizeDouble(MarketInfo(g_var_336,MODE_BID) - g_var_108 * g_var_229,g_var_190) ;
              if ( l_var_8<MarketInfo(g_var_336,MODE_BID) - g_var_221 )
              {
                g_var_230 = OrderModify(l_var_9,l_var_10,l_var_7,l_var_8,0,0xFFFFFFFF) ;
                if ( g_var_230 <= 0 )
                {
                  Print("TrailStop error: \'" + TGR_21(GetLastError()) + "\' when setting trailing Exit_TP.  Trying again!"); 
                }
                else
                {
                  l_var_27 = NormalizeDouble(g_var_107 / 100.0 * g_var_223[g_var_328],2) ;
                  if ( l_var_27<l_var_12 && l_var_27>=SymbolInfoDouble(g_var_336,34) )
                  {
                    OrderClose(l_var_9,l_var_27,MarketInfo(g_var_336,MODE_ASK),g_var_38,Red); 
                    return(true); 
                  }
                }
                l_var_2 = true ;
              }
            }
            if ( l_var_19 && g_var_39 == 1 && g_var_41>0.0 && MarketInfo(g_var_336,MODE_ASK)<l_var_7 - g_var_337 - g_var_41 * g_var_229 && MarketInfo(g_var_336,MODE_ASK)<l_var_17 - g_var_40 * g_var_229 && MarketInfo(g_var_336,MODE_ASK)>l_var_8 + g_var_309 && l_var_7>l_var_10 - g_var_42 * g_var_229 && NormalizeDouble(MarketInfo(g_var_336,MODE_ASK) + g_var_41 * g_var_229,g_var_190)<l_var_7 )
            {
              l_var_7 = NormalizeDouble(MarketInfo(g_var_336,MODE_ASK) + g_var_41 * g_var_229,g_var_190) ;
              if ( l_var_7>MarketInfo(g_var_336,MODE_ASK) + g_var_221 )
              {
                g_var_230 = OrderModify(l_var_9,l_var_10,l_var_7,l_var_8,0,0xFFFFFFFF) ;
                if ( g_var_230 <= 0 )
                {
                  Print("TrailStop error: \'" + TGR_21(GetLastError()) + "\' when setting Slip TL.  Trying again!"); 
                }
                else
                {
                  Print("Slippage controle active"); 
                }
                l_var_2 = true ;
              }
            }
            if ( g_var_119 >  0 && g_var_120 >= 0 && UseHL_TrailingSL && g_var_241[g_var_328]<l_var_7 - g_var_221 - g_var_337 && g_var_241[g_var_328]>g_var_121 * g_var_229 + MarketInfo(g_var_336,MODE_ASK) && ( g_var_241[g_var_328]>l_var_10 || !(g_var_116) ) && g_var_241[g_var_328]>g_var_122 * g_var_229 + MarketInfo(g_var_336,MODE_ASK) + g_var_221 + g_var_337 && MarketInfo(g_var_336,MODE_ASK)>l_var_8 + g_var_309 && NormalizeDouble(g_var_241[g_var_328],g_var_190)<l_var_7 )
            {
              l_var_7 = NormalizeDouble(g_var_241[g_var_328],g_var_190) ;
              if ( l_var_7>MarketInfo(g_var_336,MODE_ASK) + g_var_221 )
              {
                g_var_230 = OrderModify(l_var_9,l_var_10,l_var_7,l_var_8,0,0xFFFFFFFF) ;
                if ( g_var_230 <= 0 )
                {
                  Print("error: \'" + TGR_21(GetLastError()) + "\' when modifying stoploss"); 
                }
                l_var_2 = true ;
              }
            }
            if ( g_var_113>0.0 && MarketInfo(g_var_336,MODE_ASK)<l_var_10 - g_var_113 * g_var_229 && l_var_10 - g_var_114 * g_var_229<l_var_7 - g_var_337 && MarketInfo(g_var_336,MODE_ASK)<l_var_10 - g_var_114 * g_var_229 - g_var_221 && MarketInfo(g_var_336,MODE_ASK)>l_var_8 + g_var_309 && NormalizeDouble(l_var_10 - g_var_114 * g_var_229,g_var_190)<l_var_7 )
            {
              l_var_7 = NormalizeDouble(l_var_10 - g_var_114 * g_var_229,g_var_190) ;
              if ( l_var_7>MarketInfo(g_var_336,MODE_ASK) + g_var_221 )
              {
                g_var_230 = OrderModify(l_var_9,l_var_10,l_var_7,l_var_8,0,0xFFFFFFFF) ;
                if ( g_var_230 <= 0 )
                {
                  Print("error when setting breakeven: \'" + TGR_21(GetLastError()) + "\' ..\'Exit_BE_start\' to close to \'Exit_BE_extra_pips\' ..trying again!"); 
                }
                l_var_2 = true ;
              }
            }
            if ( !(l_var_2) && ( g_var_128 == 1 || (g_var_128 == 2 && l_var_7 - g_var_131 * g_var_229>=l_var_5 - g_var_1 - g_var_132 * g_var_229) ) )
            {
              g_var_250 ++;
              if ( MarketInfo(g_var_336,MODE_ASK)<l_var_7 - g_var_131 * g_var_229 - g_var_221 && MarketInfo(g_var_336,MODE_ASK)>l_var_8 + g_var_309 && ( g_var_129==0.0 || MarketInfo(g_var_336,MODE_ASK)<l_var_5 - g_var_247 * g_var_229 ) && g_var_250 >= g_var_130 && NormalizeDouble(l_var_7 - g_var_131 * g_var_229,g_var_190)<l_var_7 )
              {
                g_var_250 = 0 ;
                l_var_7 = NormalizeDouble(l_var_7 - g_var_131 * g_var_229,g_var_190) ;
                OrderModify(l_var_9,l_var_10,l_var_7,l_var_8,0,0xFFFFFFFF); 
                l_var_2 = true ;
              }
            }
            g_var_191 = l_var_7 ;
            if ( MarketInfo(g_var_336,MODE_ASK)>l_var_7 )
            {
              Print("Closing with virtual SL"); 
              RefreshRates(); 
              OrderClose(l_var_9,l_var_12,MarketInfo(g_var_336,MODE_ASK),g_var_1,0xFFFFFFFF); 
              return(true); 
            }
            if ( NormalizeDouble(l_var_4,g_var_190)!=NormalizeDouble(g_var_191,g_var_190) )
            {
              tmp_var_31 = NormalizeDouble(g_var_191,g_var_190);
              tmp_var_32 = l_var_9;
              for (tmp_var_33 = 0 ; tmp_var_33 < g_var_199 ; tmp_var_33 = tmp_var_33 + 1)
              {
                if ( g_var_196[tmp_var_33][0]==tmp_var_32 )
                {
                  g_var_196[tmp_var_33][1] = tmp_var_31;
                  break;
                }
              }
            }
            if ( l_var_2 && g_var_135 )
            {
              return(true); 
            }
          }
          if ( ( g_var_63 == 2 || g_var_63 == 3 ) )
          {
            tmp_var_34 = l_var_9;
            tmp_var_35 = g_var_100;
            tmp_var_36 = l_var_10;
            tmp_var_37 = 2;
            tmp_var_38 = 0.0;
            tmp_var_39 = false;
            for (tmp_var_40 = 0 ; tmp_var_40 < g_var_199 ; tmp_var_40 = tmp_var_40 + 1)
            {
              if ( g_var_196[tmp_var_40][0]==tmp_var_34 )
              {
                tmp_var_38 = g_var_196[tmp_var_40][1];
                tmp_var_39 = true;
                break;
              }
            }
            if ( !(tmp_var_39) )
            {
              if ( tmp_var_37 == 1 )
              {
                tmp_var_38 = NormalizeDouble(tmp_var_36 - tmp_var_35 * g_var_229,g_var_190);
              }
              if ( tmp_var_37 == 2 )
              {
                tmp_var_38 = NormalizeDouble(tmp_var_35 * g_var_229 + tmp_var_36,g_var_190);
              }
              for (tmp_var_41 = 0 ; tmp_var_41 < g_var_199 ; tmp_var_41 = tmp_var_41 + 1)
              {
                if ( g_var_196[tmp_var_41][0]==0.0 )
                {
                  g_var_196[tmp_var_41][0] = tmp_var_34;
                  g_var_196[tmp_var_41][1] = tmp_var_38;
                  break;
                }
              }
            }
            g_var_191 = tmp_var_38 ;
            l_var_4 = g_var_191 ;
            if ( MarketInfo(g_var_336,MODE_ASK)>=l_var_4 )
            {
              RefreshRates(); 
              OrderClose(l_var_9,l_var_12,MarketInfo(g_var_336,MODE_ASK),g_var_1,0xFFFFFFFF); 
              return(true); 
            }
            l_var_28 = TimeCurrent() - g_var_319 ;
            if ( l_var_28 >= g_var_65 )
            {
              if ( NormalizeDouble(g_var_191,g_var_190)<l_var_7 - g_var_337 )
              {
                OrderModify(l_var_9,l_var_10,NormalizeDouble(g_var_191,g_var_190),l_var_8,0,0xFFFFFFFF); 
              }
              g_var_319 = TimeCurrent() ;
            }
            if ( g_var_125>0.0 && TimeCurrent() >= l_var_13 + g_var_304 && MarketInfo(g_var_336,MODE_ASK)<g_var_191 - g_var_337 - g_var_126 * g_var_229 && MarketInfo(g_var_336,MODE_ASK)>l_var_8 + g_var_309 )
            {
              g_var_191 = MarketInfo(g_var_336,MODE_ASK) + g_var_126 * g_var_229 ;
              l_var_2 = true ;
            }
            if ( g_var_103>0.0 && MarketInfo(g_var_336,MODE_ASK)<g_var_191 - g_var_337 - (g_var_103 + g_var_106) * g_var_229 && MarketInfo(g_var_336,MODE_ASK)<l_var_5 - g_var_104 * g_var_229 && g_var_191>l_var_10 - g_var_105 * g_var_229 )
            {
              g_var_191 = g_var_103 * g_var_229 + MarketInfo(g_var_336,MODE_ASK) ;
              l_var_29 = NormalizeDouble(g_var_107 / 100.0 * g_var_223[g_var_328],2) ;
              if ( l_var_29<l_var_12 && l_var_29>=MarketInfo(g_var_336,MODE_LOTSTEP) )
              {
                OrderClose(l_var_9,l_var_29,MarketInfo(g_var_336,MODE_BID),g_var_38,Red); 
                return(true); 
              }
              l_var_2 = true ;
            }
            if ( l_var_19 && g_var_39 == 1 && g_var_41>0.0 && MarketInfo(g_var_336,MODE_ASK)<g_var_191 - g_var_337 - g_var_41 * g_var_229 && MarketInfo(g_var_336,MODE_ASK)<l_var_17 - g_var_40 * g_var_229 && MarketInfo(g_var_336,MODE_ASK)>l_var_8 + g_var_309 && g_var_191>l_var_10 - g_var_42 * g_var_229 )
            {
              Print("Slippage controle active"); 
              l_var_2 = true ;
              g_var_191 = MarketInfo(g_var_336,MODE_ASK) + g_var_41 * g_var_229 ;
            }
            if ( g_var_119 >  0 && g_var_120 >= 0 && g_var_241[g_var_328]<g_var_191 - g_var_221 - g_var_337 && ( g_var_241[g_var_328]>l_var_10 || !(g_var_116) ) && g_var_241[g_var_328]>g_var_122 * g_var_229 + MarketInfo(g_var_336,MODE_ASK) + g_var_221 + g_var_337 && MarketInfo(g_var_336,MODE_ASK)>l_var_8 + g_var_309 )
            {
              g_var_191 = g_var_241[g_var_328] ;
              l_var_2 = true ;
            }
            if ( g_var_113>0.0 && g_var_63 == 3 && MarketInfo(g_var_336,MODE_ASK)<l_var_10 - g_var_113 * g_var_229 && l_var_10 - g_var_114 * g_var_229<l_var_7 - g_var_337 && MarketInfo(g_var_336,MODE_ASK)<l_var_10 - g_var_114 * g_var_229 - g_var_221 && MarketInfo(g_var_336,MODE_ASK)>l_var_8 + g_var_309 && NormalizeDouble(l_var_10 - g_var_114 * g_var_229,g_var_190)<g_var_191 )
            {
              g_var_191 = NormalizeDouble(l_var_10 - g_var_114 * g_var_229,g_var_190) ;
              g_var_230 = OrderModify(l_var_9,l_var_10,g_var_191,l_var_8,0,0xFFFFFFFF) ;
              if ( g_var_230 <= 0 )
              {
                Print("error when setting breakeven: \'" + TGR_21(GetLastError()) + "\' ..\'Exit_BE_start\' to close to \'Exit_BE_extra_pips\' ..trying again!"); 
              }
              l_var_2 = true ;
            }
            if ( g_var_113>0.0 && g_var_63 == 2 && MarketInfo(g_var_336,MODE_ASK)<l_var_10 - g_var_113 * g_var_229 && l_var_10 - g_var_114 * g_var_229<g_var_191 - g_var_337 && MarketInfo(g_var_336,MODE_ASK)<l_var_10 - g_var_114 * g_var_229 - g_var_221 && MarketInfo(g_var_336,MODE_ASK)>l_var_8 + g_var_309 )
            {
              g_var_191 = l_var_10 - g_var_114 * g_var_229 ;
              l_var_2 = true ;
            }
            if ( !(l_var_2) && ( g_var_128 == 1 || (g_var_128 == 2 && g_var_191 - g_var_131 * g_var_229>=l_var_5 - g_var_1 - g_var_132 * g_var_229) ) )
            {
              g_var_250 ++;
              if ( MarketInfo(g_var_336,MODE_ASK)<g_var_191 - g_var_131 * g_var_229 - g_var_221 && MarketInfo(g_var_336,MODE_ASK)>l_var_8 + g_var_309 && ( g_var_129==0.0 || MarketInfo(g_var_336,MODE_ASK)<l_var_5 - g_var_247 * g_var_229 ) && g_var_250 >= g_var_130 )
              {
                g_var_250 = 0 ;
                g_var_191 = g_var_191 - g_var_131 * g_var_229 ;
                l_var_2 = true ;
              }
            }
            if ( MarketInfo(g_var_336,MODE_ASK)>=g_var_191 )
            {
              RefreshRates(); 
              OrderClose(l_var_9,l_var_12,MarketInfo(g_var_336,MODE_ASK),g_var_1,0xFFFFFFFF); 
              return(true); 
            }
            if ( NormalizeDouble(l_var_4,g_var_190)!=NormalizeDouble(g_var_191,g_var_190) )
            {
              tmp_var_42 = NormalizeDouble(g_var_191,g_var_190);
              tmp_var_43 = l_var_9;
              for (tmp_var_44 = 0 ; tmp_var_44 < g_var_199 ; tmp_var_44 = tmp_var_44 + 1)
              {
                if ( g_var_196[tmp_var_44][0]==tmp_var_43 )
                {
                  g_var_196[tmp_var_44][1] = tmp_var_42;
                  break;
                }
              }
            }
          }
        }
      }
      if ( l_var_2 )
      {
        l_var_3 = true ;
      }
    }
    if ( l_var_2 )
    {
      l_var_3 = true ;
    }
  }
  return(l_var_3); 
}
//TGR_19 <<==--------   --------
void TGR_6( int arg_0)
{
  g_var_328 = arg_0 ;
  g_var_337 = SymbolInfoDouble(g_var_336,16) ;
  g_var_229 = g_var_337 ;
  if ( ( MarketInfo(g_var_336,MODE_DIGITS)==3.0 || MarketInfo(g_var_336,MODE_DIGITS)==5.0 ) )
  {
    g_var_229 = g_var_337 * 10.0 ;
  }
  if ( SymbolInfoInteger(g_var_336,17) == 0x1 )
  {
    g_var_229 = g_var_337 / 10.0 ;
  }
  g_var_190 = MarketInfo(g_var_336,MODE_DIGITS) ;
  g_var_1 = MarketInfo(g_var_336,MODE_ASK) - MarketInfo(g_var_336,MODE_BID) ;
  g_var_221 = MarketInfo(g_var_336,MODE_STOPLEVEL) * g_var_337 ;
  g_var_309 = MarketInfo(g_var_336,MODE_FREEZELEVEL) * g_var_337 ;
  g_var_234 = g_var_89 * 60 * 60;
  if ( g_var_89 >  0 )
  {
    g_var_302 = TimeCurrent() + g_var_234;
  }
  else
  {
    g_var_302 = 0 ;
  }
  if ( Virtual_expiration )
  {
    g_var_302 = 0 ;
  }
  g_var_9 = 1.0 ;
  if ( !(UseVariableValues) )   return;
  
  if ( g_var_7>0.0 )
  {
    g_var_8 = iOpen(g_var_336,PERIOD_D1,1) / g_var_7 ;
  }
  else
  {
    g_var_8 = 1.0 ;
  }
  if ( AdjustLotsizeToVariableValues )
  {
    g_var_9 = 1.0 / g_var_8 ;
  }
  else
  {
    g_var_9 = 1.0 ;
  }
  g_var_80 = g_var_80 * g_var_8 ;
  g_var_83 = NormalizeDouble(g_var_83 * g_var_8,0) ;
  g_var_84 = NormalizeDouble(g_var_84 * g_var_8,0) ;
  g_var_100 = g_var_100 * g_var_8 ;
  g_var_101 = g_var_101 * g_var_8 ;
  g_var_103 = g_var_103 * g_var_8 ;
  g_var_104 = g_var_104 * g_var_8 ;
  g_var_105 = g_var_105 * g_var_8 ;
  g_var_108 = g_var_108 * g_var_8 ;
  g_var_109 = g_var_109 * g_var_8 ;
  g_var_113 = g_var_113 * g_var_8 ;
  g_var_114 = g_var_114 * g_var_8 ;
}
//TGR_6 <<==--------   --------

int TGR_7( int arg_0)
{
  bool      l_var_2;
  datetime  l_var_3;
  int       l_var_4;
  int       l_var_5;
  string    l_var_6;
  datetime  l_var_7;
  int       l_var_8;
  int       l_var_9;
//----- -----
  int        tmp_var_1;
  int        tmp_var_2;
  int        tmp_var_3;
  int        tmp_var_4;
  int        tmp_var_5;
  int        tmp_var_6;
  int        tmp_var_7;
  int        tmp_var_8;
  int        tmp_var_9;
  int        tmp_var_10;
  int        tmp_var_11;
  int        tmp_var_12;
  int        tmp_var_13;
  int        tmp_var_14;
  int        tmp_var_15;
  int        tmp_var_16;
  int        tmp_var_17;
  int        tmp_var_18;
  int        tmp_var_19;
  int        tmp_var_20;
  int        tmp_var_21;
  int        tmp_var_22;
  int        tmp_var_23;
  int        tmp_var_24;
  int        tmp_var_25;
  int        tmp_var_26;
  int        tmp_var_27;
  int        tmp_var_28;
  int        tmp_var_29;
  int        tmp_var_30;
  int        tmp_var_31;
  int        tmp_var_32;
  int        tmp_var_33;
  int        tmp_var_34;
  int        tmp_var_35;
  int        tmp_var_36;
  int        tmp_var_37;
  int        tmp_var_38;
  int        tmp_var_39;
  int        tmp_var_40;
  int        tmp_var_41;
  int        tmp_var_42;
  int        tmp_var_43;
  int        tmp_var_44;
  int        tmp_var_45;
  int        tmp_var_46;
  int        tmp_var_47;
  int        tmp_var_48;
  int        tmp_var_49;
  int        tmp_var_50;
  int        tmp_var_51;
  int        tmp_var_52;
  int        tmp_var_53;
  int        tmp_var_54;
  int        tmp_var_55;
  int        tmp_var_56;
  int        tmp_var_57;
  int        tmp_var_58;
  int        tmp_var_59;
  int        tmp_var_60;
  int        tmp_var_61;
  int        tmp_var_62;
  int        tmp_var_63;
  int        tmp_var_64;
  int        tmp_var_65;
  int        tmp_var_66;
  int        tmp_var_67;
  int        tmp_var_68;
  int        tmp_var_69;
  int        tmp_var_70;
  int        tmp_var_71;
  int        tmp_var_72;
  int        tmp_var_73;
  int        tmp_var_74;
  int        tmp_var_75;
  int        tmp_var_76;
  int        tmp_var_77;
  int        tmp_var_78;
  int        tmp_var_79;
  int        tmp_var_80;
  int        tmp_var_81;
  int        tmp_var_82;
  int        tmp_var_83;
  int        tmp_var_84;
  int        tmp_var_85;
  int        tmp_var_86;
  int        tmp_var_87;
  int        tmp_var_88;
  int        tmp_var_89;
  double     tmp_var_90;
  long       tmp_var_91;
  int        tmp_var_92;
  long       tmp_var_93;
  int        tmp_var_94;
  int        tmp_var_95;
  int        tmp_var_96;
  double     tmp_var_97;
  long       tmp_var_98;
  int        tmp_var_99;
  long       tmp_var_100;
  int        tmp_var_101;
  int        tmp_var_102;
  int        tmp_var_103;
  int        tmp_var_104;
  int        tmp_var_105;
  bool       tmp_var_106;
  int        tmp_var_107;
  int        tmp_var_108;
  bool       tmp_var_109;
  int        tmp_var_110;
  long       tmp_var_111;
  int        tmp_var_112;
  long       tmp_var_113;
  string     tmp_var_114;
  int        tmp_var_115;
  int        tmp_var_116;
  int        tmp_var_117;
  int        tmp_var_118;

  g_var_328 = arg_0 ;
  l_var_2 = false ;
  
  if ( g_var_81>0.0 )
  {
    g_var_80 = g_var_81 / 100.0 * MarketInfo(g_var_336,MODE_ASK) * 10.0 ;
  }
  if ( g_var_99 == 0 )
  {
    if ( TGR_18() )
    {
      l_var_2 = true ;
    }
    if ( TGR_19() )
    {
      l_var_2 = true ;
    }
    if ( l_var_2 )
    {
      return(0); 
    }
  }
  else
  {
    if ( g_var_321[g_var_328] != iBars(g_var_336,g_var_99) )
    {
      g_var_321[g_var_328] = iBars(g_var_336,g_var_99);
      if ( TGR_18() )
      {
        l_var_2 = true ;
      }
      if ( TGR_19() )
      {
        l_var_2 = true ;
      }
      if ( l_var_2 )
      {
        return(0); 
      }
    }
  }
  TGR_22(false); 
  if ( !(IsTesting()) && MarketInfo(g_var_336,MODE_TRADEALLOWED)==0.0 )
  {
    if ( !(g_var_256) )
    {
      Print("Market closed... waiting to continue"); 
    }
    g_var_256 = true ;
    return(0); 
  }
  if ( g_var_68 >  0 && ( ( Hour() == 0 && Minute() < g_var_68 ) || (Hour() == 23 && g_var_68 >  60 - g_var_68) ) )
  {
    if ( !(g_var_256) )
    {
      Print("DAYSWITCH -> Market might be closed... waiting " + string(g_var_68) + " minutes before setting order.."); 
    }
    g_var_256 = true ;
    return(0); 
  }
  g_var_256 = false ;
  if ( g_var_171 )
  {
    if ( TGR_20() && g_var_303 )
    {
      if ( g_var_173 )
      {
        TGR_8(); 
      }
      g_var_303 = false ;
    }
    if ( !(TGR_20()) && !(g_var_303) )
    {
      Print("ENTERING NON-TRADING HOURS! Closing orders..."); 
      if ( g_var_173 )
      {
        for (tmp_var_1 = 0 ; tmp_var_1 < g_var_200 ; tmp_var_1 = tmp_var_1 + 1)
        {
          for (tmp_var_2 = 0 ; tmp_var_2 < 2 ; tmp_var_2 = tmp_var_2 + 1)
          {
            g_var_197[tmp_var_1][tmp_var_2] = 0.0;
          }
        }
        tmp_var_3 = 0;
        for (tmp_var_4 = OrdersTotal() ; tmp_var_4 >= 0 ; tmp_var_4 = tmp_var_4 - 1)
        {
          if ( OrderSelect(tmp_var_4,0,0) != true || OrderMagicNumber() != g_var_93 || OrderSymbol() != g_var_336 )   continue;
          
          if ( ( OrderType() != 4 && OrderType() != 5 ) )   continue;
          Print("Storing pending order nr " + string(OrderTicket())); 
          g_var_197[tmp_var_3][1] = OrderType();
          g_var_197[tmp_var_3][0] = OrderOpenPrice();
          g_var_197[tmp_var_3][2] = OrderLots();
          tmp_var_3 = tmp_var_3 + 1;
          
        }
      }
      tmp_var_5 = 1;
      for (tmp_var_6 = OrdersTotal() ; tmp_var_6 >= 0 ; tmp_var_6 = tmp_var_6 - 1)
      {
        if ( OrderSelect(tmp_var_6,0,0) != true || OrderMagicNumber() != g_var_93 || OrderSymbol() != g_var_336 || OrderType() != 4 )   continue;
        OrderDelete(OrderTicket(),0xFFFFFFFF); 
        
      }
      if ( tmp_var_5 == 2 )
      {
        for (tmp_var_7 = OrdersTotal() ; tmp_var_7 >= 0 ; tmp_var_7 = tmp_var_7 - 1)
        {
          if ( OrderSelect(tmp_var_7,0,0) != true || OrderMagicNumber() != g_var_96 || OrderSymbol() != g_var_336 || OrderType() != 4 )   continue;
          OrderDelete(OrderTicket(),0xFFFFFFFF); 
          
        }
      }
      tmp_var_8 = 1;
      for (tmp_var_9 = OrdersTotal() ; tmp_var_9 >= 0 ; tmp_var_9 = tmp_var_9 - 1)
      {
        if ( OrderSelect(tmp_var_9,0,0) != true || OrderMagicNumber() != g_var_93 || OrderSymbol() != g_var_336 || OrderType() != 5 )   continue;
        OrderDelete(OrderTicket(),0xFFFFFFFF); 
        
      }
      if ( tmp_var_8 == 2 )
      {
        for (tmp_var_10 = OrdersTotal() ; tmp_var_10 >= 0 ; tmp_var_10 = tmp_var_10 - 1)
        {
          if ( OrderSelect(tmp_var_10,0,0) != true || OrderMagicNumber() != g_var_96 || OrderSymbol() != g_var_336 || OrderType() != 5 )   continue;
          OrderDelete(OrderTicket(),0xFFFFFFFF); 
          
        }
      }
      tmp_var_11 = 2;
      if(1==0) 
      {
        do
        {
          if ( OrderSelect(1,0,0) != true || OrderMagicNumber() != g_var_93 || OrderSymbol() != g_var_336 || OrderType() != 4 )   continue;
          OrderDelete(OrderTicket(),0xFFFFFFFF); 
          
        }
        while( - 1 >= 0);
        
      }
      if ( tmp_var_11 == 2 )
      {
        for (tmp_var_12 = OrdersTotal() ; tmp_var_12 >= 0 ; tmp_var_12 = tmp_var_12 - 1)
        {
          if ( OrderSelect(tmp_var_12,0,0) != true || OrderMagicNumber() != g_var_96 || OrderSymbol() != g_var_336 || OrderType() != 4 )   continue;
          OrderDelete(OrderTicket(),0xFFFFFFFF); 
          
        }
      }
      tmp_var_13 = 2;
      if(1==0) 
      {
        do
        {
          if ( OrderSelect(1,0,0) != true || OrderMagicNumber() != g_var_93 || OrderSymbol() != g_var_336 || OrderType() != 5 )   continue;
          OrderDelete(OrderTicket(),0xFFFFFFFF); 
          
        }
        while( - 1 >= 0);
        
      }
      if ( tmp_var_13 == 2 )
      {
        for (tmp_var_14 = OrdersTotal() ; tmp_var_14 >= 0 ; tmp_var_14 = tmp_var_14 - 1)
        {
          if ( OrderSelect(tmp_var_14,0,0) != true || OrderMagicNumber() != g_var_96 || OrderSymbol() != g_var_336 || OrderType() != 5 )   continue;
          OrderDelete(OrderTicket(),0xFFFFFFFF); 
          
        }
      }
      g_var_303 = true ;
      return(0); 
    }
  }
  if ( UseNewsFilter && EnableNFP_Filter )
  {
    if ( Year() <= 2026 )
    {
      l_var_3 = 0 ;
      for (l_var_4 = 0 ; l_var_4 < 300 ; l_var_4 ++)
      {
        tmp_var_15 = TimeYear(g_var_391[l_var_4]);
        if ( tmp_var_15 != Year() )   continue;
        tmp_var_16 = TimeMonth(g_var_391[l_var_4]);
        if ( tmp_var_16 != Month() )   continue;
        l_var_3 = g_var_391[l_var_4] ;
        break;
        
      }
      l_var_5 = 60 ;
      if ( TGR_48() )
      {
        l_var_5 = 0 ;
      }
      if ( g_var_390 >= l_var_3 - NFP_MinutesBefore * 60 + l_var_5 * 60 && g_var_390 <= l_var_3 + NFP_MinutesAfter * 60 + l_var_5 * 60 )
      {
        if ( NFP_ClosePendingOrders )
        {
          tmp_var_17 = 1;
          for (tmp_var_18 = OrdersTotal() ; tmp_var_18 >= 0 ; tmp_var_18 = tmp_var_18 - 1)
          {
            if ( OrderSelect(tmp_var_18,0,0) != true || OrderMagicNumber() != g_var_93 || OrderSymbol() != g_var_336 || OrderType() != 4 )   continue;
            OrderDelete(OrderTicket(),0xFFFFFFFF); 
            
          }
          if ( tmp_var_17 == 2 )
          {
            for (tmp_var_19 = OrdersTotal() ; tmp_var_19 >= 0 ; tmp_var_19 = tmp_var_19 - 1)
            {
              if ( OrderSelect(tmp_var_19,0,0) != true || OrderMagicNumber() != g_var_96 || OrderSymbol() != g_var_336 || OrderType() != 4 )   continue;
              OrderDelete(OrderTicket(),0xFFFFFFFF); 
              
            }
          }
          tmp_var_20 = 1;
          for (tmp_var_21 = OrdersTotal() ; tmp_var_21 >= 0 ; tmp_var_21 = tmp_var_21 - 1)
          {
            if ( OrderSelect(tmp_var_21,0,0) != true || OrderMagicNumber() != g_var_93 || OrderSymbol() != g_var_336 || OrderType() != 5 )   continue;
            OrderDelete(OrderTicket(),0xFFFFFFFF); 
            
          }
          if ( tmp_var_20 == 2 )
          {
            for (tmp_var_22 = OrdersTotal() ; tmp_var_22 >= 0 ; tmp_var_22 = tmp_var_22 - 1)
            {
              if ( OrderSelect(tmp_var_22,0,0) != true || OrderMagicNumber() != g_var_96 || OrderSymbol() != g_var_336 || OrderType() != 5 )   continue;
              OrderDelete(OrderTicket(),0xFFFFFFFF); 
              
            }
          }
          tmp_var_23 = 2;
          if(1==0) 
          {
            do
            {
              if ( OrderSelect(1,0,0) != true || OrderMagicNumber() != g_var_93 || OrderSymbol() != g_var_336 || OrderType() != 4 )   continue;
              OrderDelete(OrderTicket(),0xFFFFFFFF); 
              
            }
            while( - 1 >= 0);
            
          }
          if ( tmp_var_23 == 2 )
          {
            for (tmp_var_24 = OrdersTotal() ; tmp_var_24 >= 0 ; tmp_var_24 = tmp_var_24 - 1)
            {
              if ( OrderSelect(tmp_var_24,0,0) != true || OrderMagicNumber() != g_var_96 || OrderSymbol() != g_var_336 || OrderType() != 4 )   continue;
              OrderDelete(OrderTicket(),0xFFFFFFFF); 
              
            }
          }
          tmp_var_25 = 2;
          if(1==0) 
          {
            do
            {
              if ( OrderSelect(1,0,0) != true || OrderMagicNumber() != g_var_93 || OrderSymbol() != g_var_336 || OrderType() != 5 )   continue;
              OrderDelete(OrderTicket(),0xFFFFFFFF); 
              
            }
            while( - 1 >= 0);
            
          }
          if ( tmp_var_25 == 2 )
          {
            for (tmp_var_26 = OrdersTotal() ; tmp_var_26 >= 0 ; tmp_var_26 = tmp_var_26 - 1)
            {
              if ( OrderSelect(tmp_var_26,0,0) != true || OrderMagicNumber() != g_var_96 || OrderSymbol() != g_var_336 || OrderType() != 5 )   continue;
              OrderDelete(OrderTicket(),0xFFFFFFFF); 
              
            }
          }
        }
        if ( NFP_CloseOpenTrades )
        {
          for (tmp_var_27 = OrdersTotal() ; tmp_var_27 >= 0 ; tmp_var_27 = tmp_var_27 - 1)
          {
            if ( OrderSelect(tmp_var_27,0,0) != true || OrderSymbol() != g_var_336 )   continue;
            tmp_var_28 = OrderMagicNumber();
            tmp_var_29 = ST1_MagicNumber + 1;
            if ( tmp_var_28 != tmp_var_29 )
            {
              tmp_var_29 = OrderMagicNumber();
              tmp_var_30 = ST1_MagicNumber + 2;
              if ( tmp_var_29 != tmp_var_30 )
              {
                tmp_var_30 = OrderMagicNumber();
                tmp_var_31 = ST1_MagicNumber + 3;
                if ( tmp_var_30 != tmp_var_31 )
                {
                  tmp_var_31 = OrderMagicNumber();
                  tmp_var_32 = ST1_MagicNumber + 4;
                  if ( tmp_var_31 != tmp_var_32 )
                  {
                    tmp_var_32 = OrderMagicNumber();
                    tmp_var_33 = ST1_MagicNumber + 5;
                    if ( tmp_var_32 != tmp_var_33 )
                    {
                      tmp_var_33 = OrderMagicNumber();
                      tmp_var_34 = ST1_MagicNumber + 6;
                      if ( tmp_var_33 != tmp_var_34 )
                      {
                        tmp_var_34 = OrderMagicNumber();
                        tmp_var_35 = ST1_MagicNumber + 7;
                        if ( tmp_var_34 != tmp_var_35 )
                        {
                          tmp_var_35 = OrderMagicNumber();
                          tmp_var_36 = ST1_MagicNumber + 8;
                          if ( tmp_var_35 != tmp_var_36 )
                          {
                            tmp_var_36 = OrderMagicNumber();
                            tmp_var_37 = ST1_MagicNumber + 9;
                            if ( tmp_var_36 != tmp_var_37 )
                            {
                              tmp_var_37 = OrderMagicNumber();
                              tmp_var_38 = ST1_MagicNumber + 10;
                              if ( tmp_var_37 != tmp_var_38 )
                              {
                                tmp_var_38 = OrderMagicNumber();
                                tmp_var_39 = ST1_MagicNumber + 11;
                                if ( tmp_var_38 != tmp_var_39 )
                                {
                                  tmp_var_39 = OrderMagicNumber();
                                  tmp_var_40 = ST1_MagicNumber + 12;
                                  if ( tmp_var_39 != tmp_var_40 )
                                  {
                                    tmp_var_40 = OrderMagicNumber();
                                    tmp_var_41 = ST1_MagicNumber + 13;
                                    if ( tmp_var_40 != tmp_var_41 )
                                    {
                                      tmp_var_41 = OrderMagicNumber();
                                      tmp_var_42 = ST1_MagicNumber + 14;
                                      if ( tmp_var_41 != tmp_var_42 )
                                      {
                                        tmp_var_42 = OrderMagicNumber();
                                        tmp_var_43 = ST1_MagicNumber + 15;
                                      if ( tmp_var_42 != tmp_var_43 )   continue;
                                      }
                                    }
                                  }
                                }
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
            if ( OrderType() == 0 )
            {
              OrderClose(OrderTicket(),OrderLots(),MarketInfo(g_var_336,MODE_BID),99999,Red); 
            }
            if ( OrderType() != 1 )   continue;
            OrderClose(OrderTicket(),OrderLots(),MarketInfo(g_var_336,MODE_ASK),99999,Red); 
            
          }
        }
        if ( !(g_var_320) )
        {
          Print("NFP!! deleting trades!!"); 
        }
        g_var_320 = true ;
      }
      else
      {
        g_var_320 = false ;
      }
    }
    else
    {
      if ( Day() <= 7 && DayOfWeek() == 5 )
      {
        l_var_6 = IntegerToString(Year(),0,32) + IntegerToString(Month(),0,32) + IntegerToString(Day(),0,32) + " " + IntegerToString(0x4CE,0,32) ;
        l_var_7 = StringToTime(l_var_6) ;
        if ( g_var_390 >= l_var_7 - NFP_MinutesBefore * 60 && g_var_390 <= l_var_7 + NFP_MinutesAfter * 60 )
        {
          if ( NFP_ClosePendingOrders )
          {
            tmp_var_44 = 1;
            for (tmp_var_45 = OrdersTotal() ; tmp_var_45 >= 0 ; tmp_var_45 = tmp_var_45 - 1)
            {
              if ( OrderSelect(tmp_var_45,0,0) != true || OrderMagicNumber() != g_var_93 || OrderSymbol() != g_var_336 || OrderType() != 4 )   continue;
              OrderDelete(OrderTicket(),0xFFFFFFFF); 
              
            }
            if ( tmp_var_44 == 2 )
            {
              for (tmp_var_46 = OrdersTotal() ; tmp_var_46 >= 0 ; tmp_var_46 = tmp_var_46 - 1)
              {
                if ( OrderSelect(tmp_var_46,0,0) != true || OrderMagicNumber() != g_var_96 || OrderSymbol() != g_var_336 || OrderType() != 4 )   continue;
                OrderDelete(OrderTicket(),0xFFFFFFFF); 
                
              }
            }
            tmp_var_47 = 1;
            for (tmp_var_48 = OrdersTotal() ; tmp_var_48 >= 0 ; tmp_var_48 = tmp_var_48 - 1)
            {
              if ( OrderSelect(tmp_var_48,0,0) != true || OrderMagicNumber() != g_var_93 || OrderSymbol() != g_var_336 || OrderType() != 5 )   continue;
              OrderDelete(OrderTicket(),0xFFFFFFFF); 
              
            }
            if ( tmp_var_47 == 2 )
            {
              for (tmp_var_49 = OrdersTotal() ; tmp_var_49 >= 0 ; tmp_var_49 = tmp_var_49 - 1)
              {
                if ( OrderSelect(tmp_var_49,0,0) != true || OrderMagicNumber() != g_var_96 || OrderSymbol() != g_var_336 || OrderType() != 5 )   continue;
                OrderDelete(OrderTicket(),0xFFFFFFFF); 
                
              }
            }
            tmp_var_50 = 2;
            if(1==0) 
            {
              do
              {
                if ( OrderSelect(1,0,0) != true || OrderMagicNumber() != g_var_93 || OrderSymbol() != g_var_336 || OrderType() != 4 )   continue;
                OrderDelete(OrderTicket(),0xFFFFFFFF); 
                
              }
              while( - 1 >= 0);
              
            }
            if ( tmp_var_50 == 2 )
            {
              for (tmp_var_51 = OrdersTotal() ; tmp_var_51 >= 0 ; tmp_var_51 = tmp_var_51 - 1)
              {
                if ( OrderSelect(tmp_var_51,0,0) != true || OrderMagicNumber() != g_var_96 || OrderSymbol() != g_var_336 || OrderType() != 4 )   continue;
                OrderDelete(OrderTicket(),0xFFFFFFFF); 
                
              }
            }
            tmp_var_52 = 2;
            if(1==0) 
            {
              do
              {
                if ( OrderSelect(1,0,0) != true || OrderMagicNumber() != g_var_93 || OrderSymbol() != g_var_336 || OrderType() != 5 )   continue;
                OrderDelete(OrderTicket(),0xFFFFFFFF); 
                
              }
              while( - 1 >= 0);
              
            }
            if ( tmp_var_52 == 2 )
            {
              for (tmp_var_53 = OrdersTotal() ; tmp_var_53 >= 0 ; tmp_var_53 = tmp_var_53 - 1)
              {
                if ( OrderSelect(tmp_var_53,0,0) != true || OrderMagicNumber() != g_var_96 || OrderSymbol() != g_var_336 || OrderType() != 5 )   continue;
                OrderDelete(OrderTicket(),0xFFFFFFFF); 
                
              }
            }
          }
          if ( NFP_CloseOpenTrades )
          {
            for (tmp_var_54 = OrdersTotal() ; tmp_var_54 >= 0 ; tmp_var_54 = tmp_var_54 - 1)
            {
              if ( OrderSelect(tmp_var_54,0,0) != true || OrderSymbol() != g_var_336 )   continue;
              tmp_var_55 = OrderMagicNumber();
              tmp_var_56 = ST1_MagicNumber + 1;
              if ( tmp_var_55 != tmp_var_56 )
              {
                tmp_var_56 = OrderMagicNumber();
                tmp_var_57 = ST1_MagicNumber + 2;
                if ( tmp_var_56 != tmp_var_57 )
                {
                  tmp_var_57 = OrderMagicNumber();
                  tmp_var_58 = ST1_MagicNumber + 3;
                  if ( tmp_var_57 != tmp_var_58 )
                  {
                    tmp_var_58 = OrderMagicNumber();
                    tmp_var_59 = ST1_MagicNumber + 4;
                    if ( tmp_var_58 != tmp_var_59 )
                    {
                      tmp_var_59 = OrderMagicNumber();
                      tmp_var_60 = ST1_MagicNumber + 5;
                      if ( tmp_var_59 != tmp_var_60 )
                      {
                        tmp_var_60 = OrderMagicNumber();
                        tmp_var_61 = ST1_MagicNumber + 6;
                        if ( tmp_var_60 != tmp_var_61 )
                        {
                          tmp_var_61 = OrderMagicNumber();
                          tmp_var_62 = ST1_MagicNumber + 7;
                          if ( tmp_var_61 != tmp_var_62 )
                          {
                            tmp_var_62 = OrderMagicNumber();
                            tmp_var_63 = ST1_MagicNumber + 8;
                            if ( tmp_var_62 != tmp_var_63 )
                            {
                              tmp_var_63 = OrderMagicNumber();
                              tmp_var_64 = ST1_MagicNumber + 9;
                              if ( tmp_var_63 != tmp_var_64 )
                              {
                                tmp_var_64 = OrderMagicNumber();
                                tmp_var_65 = ST1_MagicNumber + 10;
                                if ( tmp_var_64 != tmp_var_65 )
                                {
                                  tmp_var_65 = OrderMagicNumber();
                                  tmp_var_66 = ST1_MagicNumber + 11;
                                  if ( tmp_var_65 != tmp_var_66 )
                                  {
                                    tmp_var_66 = OrderMagicNumber();
                                    tmp_var_67 = ST1_MagicNumber + 12;
                                    if ( tmp_var_66 != tmp_var_67 )
                                    {
                                      tmp_var_67 = OrderMagicNumber();
                                      tmp_var_68 = ST1_MagicNumber + 13;
                                      if ( tmp_var_67 != tmp_var_68 )
                                      {
                                        tmp_var_68 = OrderMagicNumber();
                                        tmp_var_69 = ST1_MagicNumber + 14;
                                        if ( tmp_var_68 != tmp_var_69 )
                                        {
                                          tmp_var_69 = OrderMagicNumber();
                                          tmp_var_70 = ST1_MagicNumber + 15;
                                        if ( tmp_var_69 != tmp_var_70 )   continue;
                                        }
                                      }
                                    }
                                  }
                                }
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
              if ( OrderType() == 0 )
              {
                OrderClose(OrderTicket(),OrderLots(),MarketInfo(g_var_336,MODE_BID),99999,Red); 
              }
              if ( OrderType() != 1 )   continue;
              OrderClose(OrderTicket(),OrderLots(),MarketInfo(g_var_336,MODE_ASK),99999,Red); 
              
            }
          }
          if ( !(g_var_320) )
          {
            Print("NFP!! deleting trades!!"); 
          }
          g_var_320 = true ;
        }
        else
        {
          g_var_320 = false ;
        }
      }
    }
  }
  if ( g_var_320 )
  {
    return(0); 
  }
  if ( g_var_45 )
  {
    if ( DayOfWeek() == 5 && Hour() >= FridayStopHour && !(g_var_305) )
    {
      for (tmp_var_71 = OrdersTotal() ; tmp_var_71 >= 0 ; tmp_var_71 = tmp_var_71 - 1)
      {
        if ( OrderSelect(tmp_var_71,0,0) != true || OrderSymbol() != g_var_336 )   continue;
        tmp_var_72 = OrderMagicNumber();
        tmp_var_73 = ST1_MagicNumber + 1;
        if ( tmp_var_72 != tmp_var_73 )
        {
          tmp_var_73 = OrderMagicNumber();
          tmp_var_74 = ST1_MagicNumber + 2;
          if ( tmp_var_73 != tmp_var_74 )
          {
            tmp_var_74 = OrderMagicNumber();
            tmp_var_75 = ST1_MagicNumber + 3;
            if ( tmp_var_74 != tmp_var_75 )
            {
              tmp_var_75 = OrderMagicNumber();
              tmp_var_76 = ST1_MagicNumber + 4;
              if ( tmp_var_75 != tmp_var_76 )
              {
                tmp_var_76 = OrderMagicNumber();
                tmp_var_77 = ST1_MagicNumber + 5;
                if ( tmp_var_76 != tmp_var_77 )
                {
                  tmp_var_77 = OrderMagicNumber();
                  tmp_var_78 = ST1_MagicNumber + 6;
                  if ( tmp_var_77 != tmp_var_78 )
                  {
                    tmp_var_78 = OrderMagicNumber();
                    tmp_var_79 = ST1_MagicNumber + 7;
                    if ( tmp_var_78 != tmp_var_79 )
                    {
                      tmp_var_79 = OrderMagicNumber();
                      tmp_var_80 = ST1_MagicNumber + 8;
                      if ( tmp_var_79 != tmp_var_80 )
                      {
                        tmp_var_80 = OrderMagicNumber();
                        tmp_var_81 = ST1_MagicNumber + 9;
                        if ( tmp_var_80 != tmp_var_81 )
                        {
                          tmp_var_81 = OrderMagicNumber();
                          tmp_var_82 = ST1_MagicNumber + 10;
                          if ( tmp_var_81 != tmp_var_82 )
                          {
                            tmp_var_82 = OrderMagicNumber();
                            tmp_var_83 = ST1_MagicNumber + 11;
                            if ( tmp_var_82 != tmp_var_83 )
                            {
                              tmp_var_83 = OrderMagicNumber();
                              tmp_var_84 = ST1_MagicNumber + 12;
                              if ( tmp_var_83 != tmp_var_84 )
                              {
                                tmp_var_84 = OrderMagicNumber();
                                tmp_var_85 = ST1_MagicNumber + 13;
                                if ( tmp_var_84 != tmp_var_85 )
                                {
                                  tmp_var_85 = OrderMagicNumber();
                                  tmp_var_86 = ST1_MagicNumber + 14;
                                  if ( tmp_var_85 != tmp_var_86 )
                                  {
                                    tmp_var_86 = OrderMagicNumber();
                                    tmp_var_87 = ST1_MagicNumber + 15;
                                  if ( tmp_var_86 != tmp_var_87 )   continue;
                                  }
                                }
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
        if ( OrderType() == 0 )
        {
          OrderClose(OrderTicket(),OrderLots(),MarketInfo(g_var_336,MODE_BID),g_var_38,Red); 
        }
        if ( OrderType() == 1 )
        {
          OrderClose(OrderTicket(),OrderLots(),MarketInfo(g_var_336,MODE_ASK),g_var_38,Red); 
        }
        if ( ( OrderType() != 4 && OrderType() != 5 ) )   continue;
        OrderDelete(OrderTicket(),Red); 
        
      }
      Print("Weekend starting! closing trades.."); 
      g_var_305 = true ;
      return(0); 
    }
    if ( DayOfWeek() != 5 && g_var_305 == true )
    {
      g_var_305 = false ;
      if ( g_var_46 )
      {
        TGR_8(); 
        return(0); 
      }
    }
  }
  g_var_1 = MarketInfo(g_var_336,MODE_ASK) - MarketInfo(g_var_336,MODE_BID) ;
  if ( g_var_35 )
  {
    if ( g_var_1>MaxSpread * g_var_229 )
    {
      TGR_9(); 
      return(0); 
    }
    if ( g_var_1<=g_var_37 * g_var_229 && ( !(g_var_45) || DayOfWeek() != 5 || Hour() <  FridayStopHour ) && ( !(g_var_171) || TGR_20() ) )
    {
      TGR_8(); 
    }
  }
  if ( g_var_69 == 1 )
  {
    tmp_var_88 = 0;
    for (tmp_var_89 = OrdersTotal() ; tmp_var_89 >= 0 ; tmp_var_89 = tmp_var_89 - 1)
    {
      if ( OrderSelect(tmp_var_89,0,0) != true || OrderMagicNumber() != g_var_93 || OrderSymbol() != g_var_336 || OrderType() != 4 )   continue;
      tmp_var_88 = tmp_var_88 + 1;
      
    }
    if ( tmp_var_88 >  g_var_86 )
    {
      tmp_var_90 = 0.0;
      tmp_var_91 = 0;
      for (tmp_var_92 = OrdersTotal() ; tmp_var_92 >= 0 ; tmp_var_92 = tmp_var_92 - 1)
      {
        if ( OrderSelect(tmp_var_92,0,0) != true || OrderMagicNumber() != g_var_93 || OrderSymbol() != g_var_336 || OrderType() != 4 || !(OrderOpenPrice()>tmp_var_90) )   continue;
        tmp_var_91 = OrderTicket();
        tmp_var_90 = OrderOpenPrice();
        
      }
      if ( tmp_var_91 != 0 )
      {
        OrderDelete(tmp_var_91,Green); 
        tmp_var_93 = tmp_var_91;
        for (tmp_var_94 = 0 ; tmp_var_94 < 100 ; tmp_var_94 = tmp_var_94 + 1)
        {
          if ( !(g_var_198[tmp_var_94][0]==tmp_var_93) )   continue;
          g_var_198[tmp_var_94][0] = 0.0;
          g_var_198[tmp_var_94][1] = 0.0;
          break;
          
        }
        Print("Max number of pending buy orders reached... deleting highest buystop order!"); 
      }
    }
    tmp_var_95 = 0;
    for (tmp_var_96 = OrdersTotal() ; tmp_var_96 >= 0 ; tmp_var_96 = tmp_var_96 - 1)
    {
      if ( OrderSelect(tmp_var_96,0,0) != true || OrderMagicNumber() != g_var_93 || OrderSymbol() != g_var_336 || OrderType() != 5 )   continue;
      tmp_var_95 = tmp_var_95 + 1;
      
    }
    if ( tmp_var_95 >  g_var_86 )
    {
      tmp_var_97 = 9999.0;
      tmp_var_98 = 0;
      for (tmp_var_99 = OrdersTotal() ; tmp_var_99 >= 0 ; tmp_var_99 = tmp_var_99 - 1)
      {
        if ( OrderSelect(tmp_var_99,0,0) != true || OrderMagicNumber() != g_var_93 || OrderSymbol() != g_var_336 || OrderType() != 5 || !(OrderOpenPrice()<tmp_var_97) )   continue;
        tmp_var_98 = OrderTicket();
        tmp_var_97 = OrderOpenPrice();
        
      }
      if ( tmp_var_98 != 0 )
      {
        OrderDelete(tmp_var_98,Green); 
        tmp_var_100 = tmp_var_98;
        for (tmp_var_101 = 0 ; tmp_var_101 < 100 ; tmp_var_101 = tmp_var_101 + 1)
        {
          if ( !(g_var_198[tmp_var_101][0]==tmp_var_100) )   continue;
          g_var_198[tmp_var_101][0] = 0.0;
          g_var_198[tmp_var_101][1] = 0.0;
          break;
          
        }
        Print("Max number of pending sell orders reached... deleting lowest sellstop order!"); 
      }
    }
  }
  if ( !(g_var_305) && g_var_69 == 1 && !(g_var_303) )
  {
    if ( ( g_var_322[g_var_328] != iBars(g_var_336,g_var_72) || g_var_72 == 0 ) )
    {
      g_var_322[g_var_328] = iBars(g_var_336,g_var_72);
      if ( g_var_119 >  0 && g_var_120 >= 0 )
      {
        g_var_241[g_var_328] = g_var_123 * g_var_229 + (TGR_13(g_var_117,g_var_119,g_var_120) + g_var_1);
        g_var_242[g_var_328] = TGR_14(g_var_117,g_var_119,g_var_120) - g_var_123 * g_var_229;
      }
      if ( g_var_187 >  0 )
      {
        l_var_8 = MathRand() * g_var_187 / 32768 + 1;
        g_var_15 = l_var_8 ;
        Print("Slippage: " + (string(l_var_8))); 
      }
      if ( g_var_63 != 1 )
      {
        tmp_var_102 = 0;
        for (tmp_var_103 = OrdersTotal() ; tmp_var_103 >= 0 ; tmp_var_103 = tmp_var_103 - 1)
        {
          if ( OrderSelect(tmp_var_103,0,0) != true || OrderMagicNumber() != g_var_93 || OrderSymbol() != g_var_336 || OrderType() != 0 )   continue;
          tmp_var_102 = tmp_var_102 + 1;
          
        }
        if ( tmp_var_102 == 0 )
        {
          tmp_var_104 = 0;
          for (tmp_var_105 = OrdersTotal() ; tmp_var_105 >= 0 ; tmp_var_105 = tmp_var_105 - 1)
          {
            if ( OrderSelect(tmp_var_105,0,0) != true || OrderMagicNumber() != g_var_93 || OrderSymbol() != g_var_336 || OrderType() != 1 )   continue;
            tmp_var_104 = tmp_var_104 + 1;
            
          }
          if ( tmp_var_104 == 0 )
          {
            tmp_var_106 = false;
            for (tmp_var_107 = 0 ; tmp_var_107 < g_var_199 ; tmp_var_107 = tmp_var_107 + 1)
            {
              if ( !(g_var_196[tmp_var_107][0]>0.0) )   continue;
              tmp_var_106 = false;
              for (tmp_var_108 = OrdersTotal() ; tmp_var_108 >= 0 ; tmp_var_108 = tmp_var_108 - 1)
              {
                if ( OrderSelect(tmp_var_108,0,0) != true )   continue;
                
                if ( ( OrderType() != 0 && OrderType() != 1 ) || !(OrderTicket()==g_var_196[tmp_var_107][0]) )   continue;
                tmp_var_106 = true;
                
              }
              if ( tmp_var_106 )   continue;
              g_var_196[tmp_var_107][0] = 0.0;
              g_var_196[tmp_var_107][1] = 0.0;
              
            }
          }
        }
      }
      for (l_var_9 = 0 ; l_var_9 < g_var_86 ; l_var_9 ++)
      {
        TGR_15(); 
      }
    }
    TGR_29(); 
    if ( g_var_267 != Hour() )
    {
      g_var_267 = Hour() ;
      tmp_var_109 = false;
      for (tmp_var_110 = 0 ; tmp_var_110 < 100 ; tmp_var_110 = tmp_var_110 + 1)
      {
        tmp_var_111 = g_var_198[tmp_var_110][0];
        tmp_var_109 = false;
        for (tmp_var_112 = OrdersTotal() ; tmp_var_112 >= 0 ; tmp_var_112 = tmp_var_112 - 1)
        {
          if ( !(OrderSelect(tmp_var_112,0,0)) )   continue;
          tmp_var_113 = OrderTicket();
          if ( tmp_var_111 != tmp_var_113 )   continue;
          tmp_var_109 = true;
          
        }
        if ( tmp_var_109 )   continue;
        g_var_198[tmp_var_110][0] = 0.0;
        g_var_198[tmp_var_110][1] = 0.0;
        
      }
    }
  }
  if ( g_var_62 )
  {
    tmp_var_114="Current spread: " + string(NormalizeDouble(g_var_1 / g_var_229,1)) + "\nPending Buy Order: ";
    tmp_var_115 = 0;
    for (tmp_var_116 = OrdersTotal() ; tmp_var_116 >= 0 ; tmp_var_116 = tmp_var_116 - 1)
    {
      if ( OrderSelect(tmp_var_116,0,0) != true || OrderMagicNumber() != g_var_93 || OrderSymbol() != g_var_336 || OrderType() != 4 )   continue;
      tmp_var_115 = tmp_var_115 + 1;
      
    }
    tmp_var_114 = tmp_var_114 + string(tmp_var_115);
    tmp_var_114 = tmp_var_114 + "\nPending Sell Orders: ";
    tmp_var_117 = 0;
    for (tmp_var_118 = OrdersTotal() ; tmp_var_118 >= 0 ; tmp_var_118 = tmp_var_118 - 1)
    {
      if ( OrderSelect(tmp_var_118,0,0) != true || OrderMagicNumber() != g_var_93 || OrderSymbol() != g_var_336 || OrderType() != 5 )   continue;
      tmp_var_117 = tmp_var_117 + 1;
      
    }
    tmp_var_114 = tmp_var_114 + string(tmp_var_117);
    Comment(tmp_var_114); 
  }
  return(0); 
}
//TGR_7 <<==--------   --------

void TGR_8()
{
  int       l_var_1;
//----- -----
  double     tmp_var_1;
  long       tmp_var_2;
  int        tmp_var_3;
  double     tmp_var_4;
  long       tmp_var_5;
  int        tmp_var_6;
  double     tmp_var_7;
  long       tmp_var_8;
  int        tmp_var_9;
  double     tmp_var_10;
  long       tmp_var_11;
  int        tmp_var_12;
  int        tmp_var_13;

  for (l_var_1 = 0 ; l_var_1 < g_var_200 ; l_var_1 ++)
  {
    if ( !(g_var_197[l_var_1][0]>0.0) )   continue;
    
    if ( g_var_197[l_var_1][1]==4.0 && MarketInfo(g_var_336,MODE_ASK)<g_var_197[l_var_1][0] - g_var_221 )
    {
      Print("Restoring pending buy-order"); 
      g_var_230 = OrderSend(g_var_336,4,g_var_197[l_var_1][2],g_var_197[l_var_1][0],int(g_var_38 * g_var_229),g_var_197[l_var_1][0] - (g_var_100 + g_var_64) * g_var_229,g_var_101 * g_var_229 + g_var_197[l_var_1][0],g_var_334,g_var_93,g_var_302 + 0x2A300,Green) ;
      g_var_280 = false ;
      tmp_var_1 = g_var_197[l_var_1][0];
      tmp_var_2 = g_var_230;
      for (tmp_var_3 = 0 ; tmp_var_3 < 100 ; tmp_var_3 = tmp_var_3 + 1)
      {
        if ( !(g_var_198[tmp_var_3][0]==0.0) )   continue;
        g_var_198[tmp_var_3][0] = tmp_var_2;
        g_var_198[tmp_var_3][1] = tmp_var_1;
        break;
        
      }
      if ( g_var_230 <= 0 )
      {
        if ( GetLastError() == 132 )
        {
          ResetLastError();
          if(1==0) 
          {
            do
            {
              Sleep(2500); 
              g_var_230 = OrderSend(g_var_336,4,g_var_197[l_var_1][2],g_var_197[l_var_1][0],int(g_var_38 * g_var_229),g_var_197[l_var_1][0] - (g_var_100 + g_var_64) * g_var_229,g_var_101 * g_var_229 + g_var_197[l_var_1][0],g_var_334,g_var_93,g_var_302 + 0x2A300,Green) ;
              g_var_280 = false ;
              tmp_var_4 = g_var_197[l_var_1][0];
              tmp_var_5 = g_var_230;
              for (tmp_var_6 = 0 ; tmp_var_6 < 100 ; tmp_var_6 = tmp_var_6 + 1)
              {
                if ( !(g_var_198[tmp_var_6][0]==0.0) )   continue;
                g_var_198[tmp_var_6][0] = tmp_var_5;
                g_var_198[tmp_var_6][1] = tmp_var_4;
                break;
                
              }
            }
            while(GetLastError() == 132);
            
          }
        }
        Print("error: \'" + TGR_21(GetLastError()) + "\' when setting entry order"); 
      }
    }
    if ( !(g_var_197[l_var_1][1]==5.0) || !(MarketInfo(g_var_336,MODE_BID)>g_var_197[l_var_1][0] + g_var_221) )   continue;
    Print("Restoring pending sell-order"); 
    g_var_230 = OrderSend(g_var_336,5,g_var_197[l_var_1][2],g_var_197[l_var_1][0],int(g_var_38 * g_var_229),(g_var_100 + g_var_64) * g_var_229 + g_var_197[l_var_1][0],g_var_197[l_var_1][0] - g_var_101 * g_var_229,g_var_334,g_var_93,g_var_302 + 0x2A300,Green) ;
    g_var_281 = false ;
    tmp_var_7 = g_var_197[l_var_1][0];
    tmp_var_8 = g_var_230;
    for (tmp_var_9 = 0 ; tmp_var_9 < 100 ; tmp_var_9 = tmp_var_9 + 1)
    {
      if ( !(g_var_198[tmp_var_9][0]==0.0) )   continue;
      g_var_198[tmp_var_9][0] = tmp_var_8;
      g_var_198[tmp_var_9][1] = tmp_var_7;
      break;
      
    }
    if ( g_var_230 > 0 )   continue;
    
    if ( GetLastError() == 132 )
    {
      ResetLastError();
      if(1==0) 
      {
        do
        {
          Sleep(2500); 
          g_var_230 = OrderSend(g_var_336,5,g_var_197[l_var_1][2],g_var_197[l_var_1][0],int(g_var_38 * g_var_229),(g_var_100 + g_var_64) * g_var_229 + g_var_197[l_var_1][0],g_var_197[l_var_1][0] - g_var_101 * g_var_229,g_var_334,g_var_93,g_var_302 + 0x2A300,Green) ;
          g_var_281 = false ;
          tmp_var_10 = g_var_197[l_var_1][0];
          tmp_var_11 = g_var_230;
          for (tmp_var_12 = 0 ; tmp_var_12 < 100 ; tmp_var_12 = tmp_var_12 + 1)
          {
            if ( !(g_var_198[tmp_var_12][0]==0.0) )   continue;
            g_var_198[tmp_var_12][0] = tmp_var_11;
            g_var_198[tmp_var_12][1] = tmp_var_10;
            break;
            
          }
        }
        while(GetLastError() == 132);
        
      }
    }
    Print("error: \'" + TGR_21(GetLastError()) + "\' when setting entry order"); 
    
  }
  for (tmp_var_13 = 0 ; tmp_var_13 < g_var_200 ; tmp_var_13 = tmp_var_13 + 1)
  {
    g_var_197[tmp_var_13][0] = 0.0;
    g_var_197[tmp_var_13][1] = 0.0;
    g_var_197[tmp_var_13][2] = 0.0;
  }
}
//TGR_8 <<==--------   --------

bool TGR_9()
{
  int       l_var_2;
  int       l_var_3;
  int       l_var_4;
//----- -----
  long       tmp_var_1;
  int        tmp_var_2;
  long       tmp_var_3;
  int        tmp_var_4;
  double     tmp_var_5;
  double     tmp_var_6;
  long       tmp_var_7;
  int        tmp_var_8;
  long       tmp_var_9;
  int        tmp_var_10;

  for (l_var_2 = OrdersTotal() ; l_var_2 >= 0 ; l_var_2 --)
  {
    if ( OrderSelect(l_var_2,0,0) != true )   continue;
    
    if ( ( OrderMagicNumber() != g_var_93 && OrderMagicNumber() != g_var_96 ) || OrderSymbol() != g_var_336 )   continue;
    
    if ( OrderType() == 4 && OrderOpenPrice()<g_var_36 * g_var_229 + MarketInfo(g_var_336,MODE_ASK) && MarketInfo(g_var_336,MODE_ASK)<OrderOpenPrice() - g_var_309 )
    {
      if ( g_var_37>0.0 )
      {
        Print("Spread too high..(" + string(g_var_1) + ") storing and deleting order " + string(OrderTicket())); 
        for (l_var_3 = 0 ; l_var_3 < g_var_200 ; l_var_3 ++)
        {
          if ( g_var_197[l_var_3][0]==0.0 )
          {
            Print("Storing pending order nr " + string(OrderTicket())); 
            g_var_197[l_var_3][1] = OrderType();
            g_var_197[l_var_3][0] = OrderOpenPrice();
            g_var_197[l_var_3][2] = OrderLots();
            break;
          }
        }
        tmp_var_1 = OrderTicket();
        for (tmp_var_2 = 0 ; tmp_var_2 < 100 ; tmp_var_2 = tmp_var_2 + 1)
        {
          if ( !(g_var_198[tmp_var_2][0]==tmp_var_1) )   continue;
          g_var_198[tmp_var_2][0] = 0.0;
          g_var_198[tmp_var_2][1] = 0.0;
          break;
          
        }
        OrderDelete(OrderTicket(),Green); 
      }
      else
      {
        Print("Spread too high..(" + string(g_var_1) + ") deleting order " + string(OrderTicket())); 
        tmp_var_3 = OrderTicket();
        for (tmp_var_4 = 0 ; tmp_var_4 < 100 ; tmp_var_4 = tmp_var_4 + 1)
        {
          if ( !(g_var_198[tmp_var_4][0]==tmp_var_3) )   continue;
          g_var_198[tmp_var_4][0] = 0.0;
          g_var_198[tmp_var_4][1] = 0.0;
          break;
          
        }
        OrderDelete(OrderTicket(),Green); 
      }
    }
    if ( OrderType() != 5 )   continue;
    tmp_var_5 = OrderOpenPrice();
    if ( !(tmp_var_5>MarketInfo(g_var_336,MODE_BID) - g_var_36 * g_var_229) )   continue;
    tmp_var_6 = MarketInfo(g_var_336,MODE_BID);
    if ( !(tmp_var_6>OrderOpenPrice() + g_var_309) )   continue;
    
    if ( g_var_37>0.0 )
    {
      Print("Spread too high..(" + string(g_var_1) + ") storing and deleting order " + string(OrderTicket())); 
      for (l_var_4 = 0 ; l_var_4 < g_var_200 ; l_var_4 ++)
      {
        if ( g_var_197[l_var_4][0]==0.0 )
        {
          Print("Storing pending order nr " + string(OrderTicket())); 
          g_var_197[l_var_4][1] = OrderType();
          g_var_197[l_var_4][0] = OrderOpenPrice();
          g_var_197[l_var_4][2] = OrderLots();
          break;
        }
      }
      tmp_var_7 = OrderTicket();
      for (tmp_var_8 = 0 ; tmp_var_8 < 100 ; tmp_var_8 = tmp_var_8 + 1)
      {
        if ( !(g_var_198[tmp_var_8][0]==tmp_var_7) )   continue;
        g_var_198[tmp_var_8][0] = 0.0;
        g_var_198[tmp_var_8][1] = 0.0;
        break;
        
      }
      OrderDelete(OrderTicket(),Green); 
       continue;
    }
    Print("Spread too high..(" + string(g_var_1) + ") deleting order " + string(OrderTicket())); 
    tmp_var_9 = OrderTicket();
    for (tmp_var_10 = 0 ; tmp_var_10 < 100 ; tmp_var_10 = tmp_var_10 + 1)
    {
      if ( !(g_var_198[tmp_var_10][0]==tmp_var_9) )   continue;
      g_var_198[tmp_var_10][0] = 0.0;
      g_var_198[tmp_var_10][1] = 0.0;
      break;
      
    }
    OrderDelete(OrderTicket(),Green); 
    
  }
  return(false); 
}
//TGR_9 <<==--------   --------

void TGR_10( double arg_0,int arg_1)
{
  double    l_var_1;
  double    l_var_2;
  double    l_var_3;
  double    l_var_4;
  double    l_var_5;
  double    l_var_6;
  double    l_var_7;
//----- -----

  l_var_1 = g_var_223[g_var_328] ;
  l_var_2 = g_var_223[g_var_328] ;
  g_var_401 = AccountInfoDouble(ACCOUNT_BALANCE) ;
  if ( UseEquity )
  {
    g_var_401 = AccountInfoDouble(ACCOUNT_EQUITY) ;
  }
  if ( ForceBalanceToUse>0.0 )
  {
    g_var_401 = ForceBalanceToUse ;
  }
  if ( OnlyUp && g_var_402>g_var_401 )
  {
    g_var_401 = g_var_402 ;
  }
  if ( g_var_401>g_var_402 )
  {
    g_var_402 = g_var_401 ;
  }
  l_var_3 = arg_0 ;
  if ( ( g_var_190 == 2 || g_var_190 == 4 ) )
  {
    l_var_3 = arg_0 / 10.0 ;
  }
  if ( Risk <  999 && Risk >  0 )
  {
    l_var_4 = Risk ;
    l_var_5 = l_var_4 / 1000.0 * g_var_401 ;
    if ( MarketInfo(g_var_336,MODE_LOTSTEP)==0.1 )
    {
      l_var_2 = NormalizeDouble(arg_1 * 0.01 * (l_var_5 / (MarketInfo(g_var_336,MODE_TICKVALUE) * l_var_3) * 0.1),1) ;
    }
    if ( MarketInfo(g_var_336,MODE_LOTSTEP)==0.01 )
    {
      l_var_2 = NormalizeDouble(arg_1 * 0.01 * (l_var_5 / (MarketInfo(g_var_336,MODE_TICKVALUE) * l_var_3) * 0.1),2) ;
    }
  }
  if ( Risk == 999 )
  {
    l_var_6 = g_var_148 / 100.0 * g_var_401 ;
    if ( MarketInfo(g_var_336,MODE_LOTSTEP)==0.1 )
    {
      l_var_2 = NormalizeDouble(arg_1 * 0.01 * (l_var_6 / (MarketInfo(g_var_336,MODE_TICKVALUE) * l_var_3) * 0.1),1) ;
    }
    if ( MarketInfo(g_var_336,MODE_LOTSTEP)==0.01 )
    {
      l_var_2 = NormalizeDouble(arg_1 * 0.01 * (l_var_6 / (MarketInfo(g_var_336,MODE_TICKVALUE) * l_var_3) * 0.1),2) ;
    }
  }
  if ( Risk == 0 )
  {
    if ( MarketInfo(g_var_336,MODE_LOTSTEP)==0.1 )
    {
       l_var_2 = NormalizeDouble(arg_1 * 0.01 * StartLotsRuntime,1) ;
    }
    if ( MarketInfo(g_var_336,MODE_LOTSTEP)==0.01 )
    {
       l_var_2 = NormalizeDouble(arg_1 * 0.01 * StartLotsRuntime,2) ;
    }
  }
  if ( Risk == 9999 )
  {
    if ( MarketInfo(g_var_336,MODE_LOTSTEP)==0.1 )
    {
      l_var_2 = NormalizeDouble(arg_1 * 0.01 * (g_var_401 / g_var_145 * 0.01),1) ;
    }
    if ( MarketInfo(g_var_336,MODE_LOTSTEP)==0.01 )
    {
      l_var_2 = NormalizeDouble(arg_1 * 0.01 * (g_var_401 / g_var_145 * 0.01),2) ;
    }
  }
  if ( Risk == 1234 )
  {
    if ( UseWeightedLots )
    {
      if ( g_var_397==0.0 )
      {
        g_var_397 = 100000.0 ;
      }
      g_var_146 = MaxAllowedDD / g_var_398 ;
      if ( SymbolInfoDouble(g_var_336,36)==0.1 )
      {
        l_var_2 = NormalizeDouble(g_var_146 / g_var_397 * g_var_401 / 100.0 * 0.01,1) ;
      }
      if ( SymbolInfoDouble(g_var_336,36)==0.01 )
      {
        l_var_2 = NormalizeDouble(g_var_146 / g_var_397 * g_var_401 / 100.0 * 0.01,2) ;
      }
    }
    else
    {
      if ( g_var_397==0.0 )
      {
        g_var_397 = 100000.0 ;
      }
      l_var_7 = TGR_36(g_var_401) ;
      if ( g_var_19 == 0 )
      {
        g_var_145 = g_var_385 / (MaxAllowedDD / 100.0) ;
      }
      if ( g_var_19 == 1 )
      {
        g_var_145 = g_var_386 / (MaxAllowedDD / 100.0) ;
      }
      if ( g_var_19 == 2 )
      {
        g_var_145 = g_var_387 / (MaxAllowedDD / 100.0) ;
      }
      if ( g_var_19 == 3 )
      {
        g_var_145 = g_var_388 / (MaxAllowedDD / 100.0) ;
      }
      if ( g_var_19 == 4 )
      {
        g_var_145 = g_var_389 / (MaxAllowedDD / 100.0) ;
      }
      if ( SymbolInfoDouble(g_var_336,36)==0.1 )
      {
        l_var_2 = NormalizeDouble(arg_1 * 0.01 * (l_var_7 / g_var_145 * 0.01),1) ;
      }
      if ( SymbolInfoDouble(g_var_336,36)==0.01 )
      {
        l_var_2 = NormalizeDouble(arg_1 * 0.01 * (l_var_7 / g_var_145 * 0.01),2) ;
      }
    }
  }
  if ( Risk == 3 )
  {
    if ( SymbolInfoDouble(g_var_336,36)==0.1 )
    {
      l_var_2 = NormalizeDouble(MaxRiskPerStrategy_ / g_var_397 * g_var_401 / 100.0 * 0.01,1) ;
    }
    if ( SymbolInfoDouble(g_var_336,36)==0.01 )
    {
      l_var_2 = NormalizeDouble(MaxRiskPerStrategy_ / g_var_397 * g_var_401 / 100.0 * 0.01,2) ;
    }
  }
  l_var_2 = l_var_2 * g_var_9 ;
  if ( l_var_2<MarketInfo(g_var_336,MODE_LOTSTEP) )
  {
    l_var_2 = MarketInfo(g_var_336,MODE_LOTSTEP) ;
  }
  if ( l_var_2>g_var_141 )
  {
    l_var_2 = g_var_141 ;
  }
  if ( l_var_2<MarketInfo(g_var_336,MODE_MINLOT) )
  {
    l_var_2 = MarketInfo(g_var_336,MODE_MINLOT) ;
  }
  if ( l_var_2>MarketInfo(g_var_336,MODE_MAXLOT) && MarketInfo(g_var_336,MODE_MAXLOT)!=0.0 )
  {
    l_var_2 = MarketInfo(g_var_336,MODE_MAXLOT) ;
  }
  if ( MarketInfo(g_var_336,MODE_LOTSTEP)==0.1 )
  {
    g_var_223[g_var_328] = NormalizeDouble((MathFloor(l_var_2 * 10.0)) / 10.0,1);
    return;
  }
  g_var_223[g_var_328] = NormalizeDouble(MathFloor(l_var_2 * 100.0) / 100.0,2);
}
//TGR_10 <<==--------   --------

double TGR_11( int arg_0)
{
  bool      l_var_2 = false;
  bool      l_var_3 = false;
  bool      l_var_4;
  int       l_var_5;
  int       l_var_6;
  int       l_var_7;
//----- -----
  double     tmp_var_1;
  int        tmp_var_2;
  double     tmp_var_3;
  int        tmp_var_4;
  double     tmp_var_5;
  int        tmp_var_6;
  bool       tmp_var_7;

  l_var_4 = false ;
  l_var_5=g_var_74 + 1;
  do
  {
    l_var_3 = true ;
    l_var_4 = true ;
    for (l_var_6 = l_var_5 ; l_var_6 >= l_var_5 - g_var_74 ; l_var_6 --)
    {
      if ( iHigh(g_var_336,arg_0,l_var_6)>iHigh(g_var_336,arg_0,l_var_5) )
      {
        l_var_4 = false ;
      }
    }
    for (l_var_7 = l_var_5 ; l_var_7 <= l_var_5 + g_var_73 ; l_var_7 ++)
    {
      if ( iHigh(g_var_336,arg_0,l_var_7)>iHigh(g_var_336,arg_0,l_var_5) )
      {
        l_var_3 = false ;
      }
    }
    if ( l_var_4 && l_var_3 && iHigh(g_var_336,arg_0,l_var_5)>g_var_80 * g_var_229 + MarketInfo(g_var_336,MODE_ASK) )
    {
      tmp_var_1 = iHigh(g_var_336,arg_0,l_var_5);
      tmp_var_2 = l_var_5;
      tmp_var_3 = iHigh(g_var_336,g_var_71,0);
      for (tmp_var_4 = 1 ; tmp_var_4 <= tmp_var_2 ; tmp_var_4 = tmp_var_4 + 1)
      {
        if ( iHigh(g_var_336,g_var_71,tmp_var_4)>tmp_var_3 )
        {
          tmp_var_3 = iHigh(g_var_336,g_var_71,tmp_var_4);
        }
      }
      if ( tmp_var_1>=tmp_var_3 )
      {
        tmp_var_5 = NormalizeDouble(iHigh(g_var_336,arg_0,l_var_5),g_var_190);
        tmp_var_7=false; 
        for (tmp_var_6 = OrdersTotal() ; tmp_var_6 >= 0 ; tmp_var_6 = tmp_var_6 - 1)
        {
          if ( OrderSelect(tmp_var_6,0,0) != true || OrderMagicNumber() != g_var_93 || OrderSymbol() != g_var_336 || OrderType() != 4 || !(MathAbs(OrderOpenPrice() - (g_var_83 * g_var_229 + tmp_var_5))<g_var_88 * g_var_229) )   continue;
          tmp_var_7 = true;
           break;
          
        }
        if ( !(tmp_var_7) && ( !(g_var_75) || !(iClose(g_var_336,arg_0,l_var_5 - 1)>iHigh(g_var_336,arg_0,l_var_5) - g_var_80 * g_var_229) ) )
        {
          l_var_2 = true ;
          g_var_262 = NormalizeDouble(iHigh(g_var_336,arg_0,l_var_5),g_var_190) ;
          g_var_265 = l_var_5 ;
          break;
        }
      }
    }
    l_var_5 ++;
    if ( l_var_5 <= g_var_77 )   continue;
    g_var_262 = 0.0 ;
    break;
    
  }
  while(!(l_var_2));
  
  return(g_var_262); 
}
//TGR_11 <<==--------   --------

double TGR_12( int arg_0)
{
  bool      l_var_2 = false;
  bool      l_var_3 = false;
  bool      l_var_4;
  int       l_var_5;
  int       l_var_6;
  int       l_var_7;
//----- -----
  double     tmp_var_1;
  int        tmp_var_2;
  double     tmp_var_3;
  int        tmp_var_4;
  double     tmp_var_5;
  int        tmp_var_6;
  bool       tmp_var_7;

  l_var_4 = false ;
  l_var_5=g_var_74 + 1;
  do
  {
    l_var_3 = true ;
    l_var_4 = true ;
    for (l_var_6 = l_var_5 ; l_var_6 >= l_var_5 - g_var_74 ; l_var_6 --)
    {
      if ( iLow(g_var_336,arg_0,l_var_6)<iLow(g_var_336,arg_0,l_var_5) )
      {
        l_var_4 = false ;
      }
    }
    for (l_var_7 = l_var_5 ; l_var_7 <= l_var_5 + g_var_73 ; l_var_7 ++)
    {
      if ( iLow(g_var_336,arg_0,l_var_7)<iLow(g_var_336,arg_0,l_var_5) )
      {
        l_var_3 = false ;
      }
    }
    if ( l_var_4 && l_var_3 && iLow(g_var_336,arg_0,l_var_5)<MarketInfo(g_var_336,MODE_BID) - g_var_80 * g_var_229 )
    {
      tmp_var_1 = iLow(g_var_336,arg_0,l_var_5);
      tmp_var_2 = l_var_5;
      tmp_var_3 = iLow(g_var_336,g_var_71,0);
      for (tmp_var_4 = 1 ; tmp_var_4 <= tmp_var_2 ; tmp_var_4 = tmp_var_4 + 1)
      {
        if ( iLow(g_var_336,g_var_71,tmp_var_4)<tmp_var_3 )
        {
          tmp_var_3 = iLow(g_var_336,g_var_71,tmp_var_4);
        }
      }
      if ( tmp_var_1<=tmp_var_3 )
      {
        tmp_var_5 = NormalizeDouble(iLow(g_var_336,arg_0,l_var_5),g_var_190);
        tmp_var_7=false; 
        for (tmp_var_6 = OrdersTotal() ; tmp_var_6 >= 0 ; tmp_var_6 = tmp_var_6 - 1)
        {
          if ( OrderSelect(tmp_var_6,0,0) != true || OrderMagicNumber() != g_var_93 || OrderSymbol() != g_var_336 || OrderType() != 5 || !(MathAbs(OrderOpenPrice() - (tmp_var_5 - g_var_84 * g_var_229))<g_var_88 * g_var_229) )   continue;
          tmp_var_7 = true;
           break;
          
        }
        if ( !(tmp_var_7) && ( !(g_var_75) || !(iClose(g_var_336,arg_0,l_var_5 - 1)<g_var_80 * g_var_229 + iLow(g_var_336,arg_0,l_var_5)) ) )
        {
          l_var_2 = true ;
          g_var_261 = NormalizeDouble(iLow(g_var_336,arg_0,l_var_5),g_var_190) ;
          g_var_266 = l_var_5 ;
          break;
        }
      }
    }
    l_var_5 ++;
    if ( l_var_5 <= g_var_77 )   continue;
    g_var_261 = 0.0 ;
    break;
    
  }
  while(!(l_var_2));
  
  return(g_var_261); 
}
//TGR_12 <<==--------   --------

double TGR_13( int arg_0,int arg_1,int arg_2)
{
  bool      l_var_2 = false;
  double    l_var_3 = 0.0;
  bool      l_var_4 = false;
  bool      l_var_5;
  int       l_var_6;
  int       l_var_7;
  int       l_var_8;
//----- -----

  l_var_5 = false ;
  l_var_6=arg_2 + 1;
  do
  {
    l_var_4 = true ;
    l_var_5 = true ;
    for (l_var_7 = l_var_6 ; l_var_7 >= l_var_6 - arg_2 ; l_var_7 --)
    {
      if ( iHigh(g_var_336,arg_0,l_var_7)>iHigh(g_var_336,arg_0,l_var_6) )
      {
        l_var_5 = false ;
      }
    }
    for (l_var_8 = l_var_6 ; l_var_8 <= l_var_6 + arg_1 ; l_var_8 ++)
    {
      if ( iHigh(g_var_336,arg_0,l_var_8)>iHigh(g_var_336,arg_0,l_var_6) )
      {
        l_var_4 = false ;
      }
    }
    if ( l_var_5 && l_var_4 && iHigh(g_var_336,arg_0,l_var_6)>g_var_221 * g_var_229 + MarketInfo(g_var_336,MODE_ASK) )
    {
      l_var_2 = true ;
      l_var_3 = NormalizeDouble(iHigh(g_var_336,arg_0,l_var_6),g_var_190) ;
      break;
    }
    l_var_6 ++;
    if ( l_var_6 <= g_var_118 )   continue;
    l_var_3 = 9999.0 ;
    break;
    
  }
  while(!(l_var_2));
  
  return(l_var_3); 
}
//TGR_13 <<==--------   --------

double TGR_14( int arg_0,int arg_1,int arg_2)
{
  bool      l_var_2 = false;
  double    l_var_3 = 0.0;
  bool      l_var_4 = false;
  bool      l_var_5;
  int       l_var_6;
  int       l_var_7;
  int       l_var_8;
//----- -----

  l_var_5 = false ;
  l_var_6=arg_2 + 1;
  do
  {
    l_var_4 = true ;
    l_var_5 = true ;
    for (l_var_7 = l_var_6 ; l_var_7 >= l_var_6 - arg_2 ; l_var_7 --)
    {
      if ( iLow(g_var_336,arg_0,l_var_7)<iLow(g_var_336,arg_0,l_var_6) )
      {
        l_var_5 = false ;
      }
    }
    for (l_var_8 = l_var_6 ; l_var_8 <= l_var_6 + arg_1 ; l_var_8 ++)
    {
      if ( iLow(g_var_336,arg_0,l_var_8)<iLow(g_var_336,arg_0,l_var_6) )
      {
        l_var_4 = false ;
      }
    }
    if ( l_var_5 && l_var_4 && iLow(g_var_336,arg_0,l_var_6)<MarketInfo(g_var_336,MODE_BID) - g_var_221 * g_var_229 )
    {
      l_var_2 = true ;
      l_var_3 = NormalizeDouble(iLow(g_var_336,arg_0,l_var_6),g_var_190) ;
      break;
    }
    l_var_6 ++;
    if ( l_var_6 <= g_var_118 )   continue;
    l_var_3 = 0.0 ;
    break;
    
  }
  while(!(l_var_2));
  
  return(l_var_3); 
}
//TGR_14 <<==--------   --------

void TGR_15()
{
  int       l_var_1;
//----- -----
  long       tmp_var_1;
  long       tmp_var_2;
  int        tmp_var_3;
  int        tmp_var_4;
  int        tmp_var_5;
  int        tmp_var_6;
  int        tmp_var_7;
  int        tmp_var_8;
  int        tmp_var_9;
  int        tmp_var_10;
  int        tmp_var_11;
  int        tmp_var_12;

  if ( g_var_213 )
  {
    g_var_268 = iMA(g_var_336,0,g_var_214,0,1,0,1) ;
    g_var_269 = iMA(g_var_336,0,g_var_217,0,1,0,1) ;
  }
  TGR_10(g_var_100,g_var_92); 
  if ( g_var_223[g_var_328]>g_var_141 )
  {
    g_var_223[g_var_328] = g_var_141;
  }
  if ( g_var_89 >  0 )
  {
    g_var_302=TimeCurrent() + g_var_234;
  }
  if ( Virtual_expiration )
  {
    g_var_302 = 0 ;
    for (l_var_1 = OrdersTotal() ; l_var_1 >= 0 ; l_var_1 --)
    {
      if ( OrderSelect(l_var_1,0,0) != true || OrderMagicNumber() != g_var_93 || OrderSymbol() != g_var_336 )   continue;
      
      if ( ( OrderType() != 4 && OrderType() != 5 ) )   continue;
      tmp_var_1 = TimeCurrent();
      tmp_var_2 = OrderOpenTime() + g_var_234;
      if ( tmp_var_1 < tmp_var_2 )   continue;
      OrderDelete(OrderTicket(),Red); 
      
    }
  }
  tmp_var_3 = 0;
  for (tmp_var_4 = OrdersTotal() ; tmp_var_4 >= 0 ; tmp_var_4 = tmp_var_4 - 1)
  {
    if ( OrderSelect(tmp_var_4,0,0) != true || OrderMagicNumber() != g_var_93 || OrderSymbol() != g_var_336 || OrderType() != 0 )   continue;
    tmp_var_3 = tmp_var_3 + 1;
    
  }
  if ( tmp_var_3 <  g_var_87 )
  {
    if(!TGR_16(1)) __TGREntryDebug("buy pending skipped");
  }
  else
  {
    tmp_var_5 = 1;
    for (tmp_var_6 = OrdersTotal() ; tmp_var_6 >= 0 ; tmp_var_6 = tmp_var_6 - 1)
    {
      if ( OrderSelect(tmp_var_6,0,0) != true || OrderMagicNumber() != g_var_93 || OrderSymbol() != g_var_336 || OrderType() != 4 )   continue;
      OrderDelete(OrderTicket(),0xFFFFFFFF); 
      
    }
    if ( tmp_var_5 == 2 )
    {
      for (tmp_var_7 = OrdersTotal() ; tmp_var_7 >= 0 ; tmp_var_7 = tmp_var_7 - 1)
      {
        if ( OrderSelect(tmp_var_7,0,0) != true || OrderMagicNumber() != g_var_96 || OrderSymbol() != g_var_336 || OrderType() != 4 )   continue;
        OrderDelete(OrderTicket(),0xFFFFFFFF); 
        
      }
    }
  }
  tmp_var_8 = 0;
  for (tmp_var_9 = OrdersTotal() ; tmp_var_9 >= 0 ; tmp_var_9 = tmp_var_9 - 1)
  {
    if ( OrderSelect(tmp_var_9,0,0) != true || OrderMagicNumber() != g_var_93 || OrderSymbol() != g_var_336 || OrderType() != 1 )   continue;
    tmp_var_8 = tmp_var_8 + 1;
    
  }
  if ( tmp_var_8 <  g_var_87 )
  {
    if(!TGR_17(1)) __TGREntryDebug("sell pending skipped");
    return;
  }
  tmp_var_10 = 1;
  for (tmp_var_11 = OrdersTotal() ; tmp_var_11 >= 0 ; tmp_var_11 = tmp_var_11 - 1)
  {
    if ( OrderSelect(tmp_var_11,0,0) != true || OrderMagicNumber() != g_var_93 || OrderSymbol() != g_var_336 || OrderType() != 5 )   continue;
    OrderDelete(OrderTicket(),0xFFFFFFFF); 
    
  }
  if ( tmp_var_10 != 2 )   return;
  for (tmp_var_12 = OrdersTotal() ; tmp_var_12 >= 0 ; tmp_var_12 = tmp_var_12 - 1)
  {
    if ( OrderSelect(tmp_var_12,0,0) != true || OrderMagicNumber() != g_var_96 || OrderSymbol() != g_var_336 || OrderType() != 5 )   continue;
    OrderDelete(OrderTicket(),0xFFFFFFFF); 
    
  }
}
//TGR_15 <<==--------   --------

bool TGR_16( int arg_0)
{
  bool      l_var_2;
  double    l_var_3;
  double    l_var_4;
  double    l_var_5;
  double    l_var_6;
//----- -----
  bool       tmp_var_1;
  int        tmp_var_2;
  double     tmp_var_3;
  int        tmp_var_4;
  bool       tmp_var_5;
  int        tmp_var_6;
  int        tmp_var_7;
  double     tmp_var_8;
  int        tmp_var_9;
  double     tmp_var_10;
  int        tmp_var_11;
  bool       tmp_var_12;
  bool       tmp_var_13;
  int        tmp_var_14;
  bool       tmp_var_15;
  int        tmp_var_16;
  double     tmp_var_17;
  long       tmp_var_18;
  int        tmp_var_19;

  if ( !(AllowBuyTrades) )
  {
    return(false); 
  }
  if ( g_var_218 )
  {
    tmp_var_1 = false;
  }
  else
  {
    tmp_var_1 = false; 
    for (tmp_var_2 = 0 ; tmp_var_2 < OrdersTotal() ; tmp_var_2 = tmp_var_2 + 1)
    {
      if ( OrderSelect(tmp_var_2,0,0) != true || OrderType() != 0 || OrderMagicNumber() != g_var_93 || OrderSymbol() != g_var_336 )   continue;
      tmp_var_1 = true;
       break;
      
    }
  }
  if ( tmp_var_1 == true )
  {
    return(false); 
  }
  if ( g_var_213 && g_var_268<g_var_269 )
  {
    return(false); 
  }
  if ( arg_0 == 1 )
  {
    TGR_11(g_var_71); 
    l_var_2 = false ;
    tmp_var_3 = g_var_262;
    tmp_var_5 = false; 
    for (tmp_var_4 = OrdersTotal() ; tmp_var_4 >= 0 ; tmp_var_4 = tmp_var_4 - 1)
    {
      if ( OrderSelect(tmp_var_4,0,0) != true || OrderMagicNumber() != g_var_93 || OrderSymbol() != g_var_336 || OrderType() != 4 || !(MathAbs(OrderOpenPrice() - (g_var_83 * g_var_229 + tmp_var_3))<g_var_88 * g_var_229) )   continue;
      tmp_var_5 = true;
       break;
      
    }
    if ( !(tmp_var_5) )
    {
      tmp_var_6 = 0;
      for (tmp_var_7 = OrdersTotal() ; tmp_var_7 >= 0 ; tmp_var_7 = tmp_var_7 - 1)
      {
        if ( OrderSelect(tmp_var_7,0,0) != true || OrderMagicNumber() != g_var_93 || OrderSymbol() != g_var_336 || OrderType() != 4 )   continue;
        tmp_var_6 = tmp_var_6 + 1;
        
      }
      if ( tmp_var_6 == g_var_86 )
      {
        tmp_var_8 = 9999.0;
        for (tmp_var_9 = OrdersTotal() ; tmp_var_9 >= 0 ; tmp_var_9 = tmp_var_9 - 1)
        {
          if ( OrderSelect(tmp_var_9,0,0) != true || OrderMagicNumber() != g_var_93 || OrderSymbol() != g_var_336 || OrderType() != 4 || !(OrderOpenPrice()<tmp_var_8) )   continue;
          tmp_var_8 = OrderOpenPrice();
          
        }
        if ( g_var_262>tmp_var_8 )
        {
          return(false); 
        }
      }
      g_var_264 = g_var_262 ;
      l_var_2 = true ;
      g_var_188 = NormalizeDouble(g_var_262,g_var_190) ;
    }
    if ( g_var_188==0.0 )
    {
      return(false); 
    }
    if ( l_var_2 )
    {
      g_var_247 = g_var_129 ;
      l_var_3 = NormalizeDouble(g_var_83 * g_var_229 + g_var_188,g_var_190) ;
      tmp_var_10 = l_var_3;
      tmp_var_12 = false; 
      for (tmp_var_11 = OrdersTotal() ; tmp_var_11 >= 0 ; tmp_var_11 = tmp_var_11 - 1)
      {
        if ( OrderSelect(tmp_var_11,0,0) != true || OrderMagicNumber() != g_var_93 || OrderSymbol() != g_var_336 || OrderType() != 4 || !(OrderOpenPrice()<=tmp_var_10) )   continue;
        tmp_var_12 = true;
         break;
        
      }
      if ( tmp_var_12 )
      {
        return(false); 
      }
      g_var_310 = l_var_3 ;
      if ( !(g_var_67) )
      {
        if ( CheckMargin && AccountFreeMarginCheck(g_var_336,0,g_var_223[g_var_328])<=0.0 )
        {
          Print("Free margin not sufficient for setting order with lotsize " + string(g_var_223[g_var_328]) + "..."); 
          return(false); 
        }
        l_var_4 = NormalizeDouble(g_var_15 * g_var_229 + l_var_3,g_var_190) ;
        l_var_5 = NormalizeDouble(l_var_3 - (g_var_100 + g_var_64) * g_var_229,g_var_190) ;
        l_var_6 = NormalizeDouble(g_var_101 * g_var_229 + l_var_3,g_var_190) ;
        if ( g_var_223[g_var_328]<SymbolInfoDouble(g_var_336,34) )
        {
          Print("Volume is less than the minimal allowed SYMBOL_VOLUME_MIN=" + string(SymbolInfoDouble(g_var_336,34))); 
          tmp_var_13 = false;
        }
        else
        {
          if ( g_var_223[g_var_328]>SymbolInfoDouble(g_var_336,35) )
          {
            Print("Volume is greater than the maximal allowed SYMBOL_VOLUME_MAX=" + string(SymbolInfoDouble(g_var_336,35))); 
            tmp_var_13 = false;
          }
          else
          {
            if ( MathAbs(NormalizeDouble(g_var_223[g_var_328] / SymbolInfoDouble(g_var_336,36),0) * SymbolInfoDouble(g_var_336,36) - g_var_223[g_var_328])>0.0000001 )
            {
              Print("Volume " + string(g_var_223[g_var_328]) + " is not a multiple of the minimal step SYMBOL_VOLUME_STEP=" + string(SymbolInfoDouble(g_var_336,36))); 
              tmp_var_13 = false;
            }
            else
            {
              tmp_var_13 = true;
            }
          }
        }

        tmp_var_14 = AccountInfoInteger(ACCOUNT_LIMIT_ORDERS);
        if ( tmp_var_14 == 0 )
        {
          tmp_var_15 = true;
        }
        else
        {
          tmp_var_15 = OrdersTotal()<tmp_var_14;
        }
        if ( ( !(tmp_var_13) || !(tmp_var_15) ) )
        {
          return(false); 
        }
        if ( MarketInfo(g_var_336,MODE_ASK)<l_var_4 - g_var_309 * g_var_229 && MarketInfo(g_var_336,MODE_ASK)<l_var_4 - g_var_221 * g_var_229 )
        {
          if ( !(setSL_TP_After_Entry) )
          {
            g_var_230 = OrderSend(g_var_336,4,g_var_223[g_var_328],l_var_4,int(g_var_38 * g_var_229),l_var_5,l_var_6,g_var_334,g_var_93,g_var_302,Green) ;
          }
          else
          {
            g_var_230 = OrderSend(g_var_336,4,g_var_223[g_var_328],l_var_4,int(g_var_38 * g_var_229),0.0,0.0,g_var_334,g_var_93,g_var_302,Green) ;
          }
          g_var_280 = false ;
          if ( g_var_230 <= 0 )
          {
            tmp_var_16 = GetLastError();
            if ( tmp_var_16 == 132 )
            {
              ResetLastError();
              if(1==0) 
              {
                do
                {
                  Sleep(2500); 
                  if ( !(setSL_TP_After_Entry) )
                  {
                    tmp_var_16 = g_var_38 * g_var_229;
                    g_var_230 = OrderSend(g_var_336,4,g_var_223[g_var_328],l_var_4,tmp_var_16,l_var_5,l_var_6,g_var_334,g_var_93,g_var_302,Green) ;
                  }
                  else
                  {
                    g_var_230 = OrderSend(g_var_336,4,g_var_223[g_var_328],l_var_4,int(g_var_38 * g_var_229),0.0,0.0,g_var_334,g_var_93,g_var_302,Green) ;
                  }
                  g_var_280 = false ;
                }
                while(GetLastError() == 132);
                
              }
            }
            Print("error: \'" + TGR_21(GetLastError()) + "\' when setting entry order"); 
          }
          else
          {
            tmp_var_17 = l_var_3;
            tmp_var_18 = g_var_230;
            for (tmp_var_19 = 0 ; tmp_var_19 < 100 ; tmp_var_19 = tmp_var_19 + 1)
            {
              if ( !(g_var_198[tmp_var_19][0]==0.0) )   continue;
              g_var_198[tmp_var_19][0] = tmp_var_18;
              g_var_198[tmp_var_19][1] = tmp_var_17;
              break;
              
            }
          }
        }
      }
      return(true); 
    }
  }
  return(false); 
}
//TGR_16 <<==--------   --------

bool TGR_17( int arg_0)
{
  bool      l_var_2;
  double    l_var_3;
  double    l_var_4;
  double    l_var_5;
  double    l_var_6;
//----- -----
  bool       tmp_var_1;
  int        tmp_var_2;
  double     tmp_var_3;
  int        tmp_var_4;
  bool       tmp_var_5;
  int        tmp_var_6;
  int        tmp_var_7;
  double     tmp_var_8;
  int        tmp_var_9;
  double     tmp_var_10;
  int        tmp_var_11;
  bool       tmp_var_12;
  bool       tmp_var_13;
  int        tmp_var_14;
  bool       tmp_var_15;
  int        tmp_var_16;
  double     tmp_var_17;
  long       tmp_var_18;
  int        tmp_var_19;

  if ( !(AllowSellTrades) )
  {
    return(false); 
  }
  if ( g_var_218 )
  {
    tmp_var_1 = false;
  }
  else
  {
    tmp_var_1 = false; 
    for (tmp_var_2 = 0 ; tmp_var_2 < OrdersTotal() ; tmp_var_2 = tmp_var_2 + 1)
    {
      if ( OrderSelect(tmp_var_2,0,0) != true || OrderType() != 1 || OrderMagicNumber() != g_var_93 || OrderSymbol() != g_var_336 )   continue;
      tmp_var_1 = true;
       break;
      
    }
  }
  if ( tmp_var_1 == true )
  {
    return(false); 
  }
  if ( g_var_213 && g_var_268>g_var_269 )
  {
    return(false); 
  }
  if ( arg_0 == 1 )
  {
    TGR_12(g_var_71); 
    l_var_2 = false ;
    tmp_var_3 = g_var_261;
    tmp_var_5 = false; 
    for (tmp_var_4 = OrdersTotal() ; tmp_var_4 >= 0 ; tmp_var_4 = tmp_var_4 - 1)
    {
      if ( OrderSelect(tmp_var_4,0,0) != true || OrderMagicNumber() != g_var_93 || OrderSymbol() != g_var_336 || OrderType() != 5 || !(MathAbs(OrderOpenPrice() - (tmp_var_3 - g_var_84 * g_var_229))<g_var_88 * g_var_229) )   continue;
      tmp_var_5 = true;
       break;
      
    }
    if ( !(tmp_var_5) )
    {
      tmp_var_6 = 0;
      for (tmp_var_7 = OrdersTotal() ; tmp_var_7 >= 0 ; tmp_var_7 = tmp_var_7 - 1)
      {
        if ( OrderSelect(tmp_var_7,0,0) != true || OrderMagicNumber() != g_var_93 || OrderSymbol() != g_var_336 || OrderType() != 5 )   continue;
        tmp_var_6 = tmp_var_6 + 1;
        
      }
      if ( tmp_var_6 == g_var_86 )
      {
        tmp_var_8 = 0.0;
        for (tmp_var_9 = OrdersTotal() ; tmp_var_9 >= 0 ; tmp_var_9 = tmp_var_9 - 1)
        {
          if ( OrderSelect(tmp_var_9,0,0) != true || OrderMagicNumber() != g_var_93 || OrderSymbol() != g_var_336 || OrderType() != 5 || !(OrderOpenPrice()>tmp_var_8) )   continue;
          tmp_var_8 = OrderOpenPrice();
          
        }
        if ( g_var_261<tmp_var_8 )
        {
          return(false); 
        }
      }
      g_var_263 = g_var_261 ;
      l_var_2 = true ;
      g_var_189 = NormalizeDouble(g_var_261,g_var_190) ;
    }
    if ( g_var_189==0.0 )
    {
      return(false); 
    }
    if ( l_var_2 )
    {
      g_var_247 = g_var_129 ;
      l_var_3 = NormalizeDouble(g_var_189 - g_var_84 * g_var_229,g_var_190) ;
      tmp_var_10 = l_var_3;
      tmp_var_12 = false; 
      for (tmp_var_11 = OrdersTotal() ; tmp_var_11 >= 0 ; tmp_var_11 = tmp_var_11 - 1)
      {
        if ( OrderSelect(tmp_var_11,0,0) != true || OrderMagicNumber() != g_var_93 || OrderSymbol() != g_var_336 || OrderType() != 5 || !(OrderOpenPrice()>=tmp_var_10) )   continue;
        tmp_var_12 = true;
         break;
        
      }
      if ( tmp_var_12 )
      {
        return(false); 
      }
      g_var_311 = l_var_3 ;
      if ( !(g_var_67) )
      {
        if ( CheckMargin && AccountFreeMarginCheck(g_var_336,1,g_var_223[g_var_328])<=0.0 )
        {
          Print("Free margin not sufficient for setting order with lotsize " + string(g_var_223[g_var_328]) + "..."); 
          return(false); 
        }
        l_var_4 = NormalizeDouble(l_var_3 - g_var_15 * g_var_229,g_var_190) ;
        l_var_5 = NormalizeDouble((g_var_100 + g_var_64) * g_var_229 + l_var_3,g_var_190) ;
        l_var_6 = NormalizeDouble(l_var_3 - g_var_101 * g_var_229,g_var_190) ;
        if ( g_var_223[g_var_328]<SymbolInfoDouble(g_var_336,34) )
        {
          Print("Volume is less than the minimal allowed SYMBOL_VOLUME_MIN=" + string(SymbolInfoDouble(g_var_336,34))); 
          tmp_var_13 = false;
        }
        else
        {
          if ( g_var_223[g_var_328]>SymbolInfoDouble(g_var_336,35) )
          {
            Print("Volume is greater than the maximal allowed SYMBOL_VOLUME_MAX=" + string(SymbolInfoDouble(g_var_336,35))); 
            tmp_var_13 = false;
          }
          else
          {
            if ( MathAbs(NormalizeDouble(g_var_223[g_var_328] / SymbolInfoDouble(g_var_336,36),0) * SymbolInfoDouble(g_var_336,36) - g_var_223[g_var_328])>0.0000001 )
            {
              Print("Volume " + string(g_var_223[g_var_328]) + " is not a multiple of the minimal step SYMBOL_VOLUME_STEP=" + string(SymbolInfoDouble(g_var_336,36))); 
              tmp_var_13 = false;
            }
            else
            {
              tmp_var_13 = true;
            }
          }
        }

        tmp_var_14 = AccountInfoInteger(ACCOUNT_LIMIT_ORDERS);
        if ( tmp_var_14 == 0 )
        {
          tmp_var_15 = true;
        }
        else
        {
          tmp_var_15 = OrdersTotal()<tmp_var_14;
        }
        if ( ( !(tmp_var_13) || !(tmp_var_15) ) )
        {
          return(false); 
        }
        if ( MarketInfo(g_var_336,MODE_BID)>g_var_309 * g_var_229 + l_var_4 && MarketInfo(g_var_336,MODE_BID)>g_var_221 * g_var_229 + l_var_4 )
        {
          if ( !(setSL_TP_After_Entry) )
          {
            g_var_230 = OrderSend(g_var_336,5,g_var_223[g_var_328],l_var_4,int(g_var_38 * g_var_229),l_var_5,l_var_6,g_var_334,g_var_93,g_var_302,Red) ;
          }
          else
          {
            g_var_230 = OrderSend(g_var_336,5,g_var_223[g_var_328],l_var_4,int(g_var_38 * g_var_229),0.0,0.0,g_var_334,g_var_93,g_var_302,Red) ;
          }
          g_var_281 = false ;
          if ( g_var_230 <= 0 )
          {
            tmp_var_16 = GetLastError();
            if ( tmp_var_16 == 132 )
            {
              ResetLastError();
              if(1==0) 
              {
                do
                {
                  Sleep(2500); 
                  if ( !(setSL_TP_After_Entry) )
                  {
                    tmp_var_16 = g_var_38 * g_var_229;
                    g_var_230 = OrderSend(g_var_336,5,g_var_223[g_var_328],l_var_4,tmp_var_16,l_var_5,l_var_6,g_var_334,g_var_93,g_var_302,Red) ;
                  }
                  else
                  {
                    g_var_230 = OrderSend(g_var_336,5,g_var_223[g_var_328],l_var_4,int(g_var_38 * g_var_229),0.0,0.0,g_var_334,g_var_93,g_var_302,Red) ;
                  }
                  g_var_281 = false ;
                }
                while(GetLastError() == 132);
                
              }
            }
            Print("error: \'" + TGR_21(GetLastError()) + "\' when setting entry order"); 
          }
          else
          {
            tmp_var_17 = l_var_3;
            tmp_var_18 = g_var_230;
            for (tmp_var_19 = 0 ; tmp_var_19 < 100 ; tmp_var_19 = tmp_var_19 + 1)
            {
              if ( !(g_var_198[tmp_var_19][0]==0.0) )   continue;
              g_var_198[tmp_var_19][0] = tmp_var_18;
              g_var_198[tmp_var_19][1] = tmp_var_17;
              break;
              
            }
          }
        }
      }
    }
  }
  return(false); 
}
//TGR_17 <<==--------   --------

bool TGR_18()
{
  bool      l_var_2 = false;
  bool      l_var_3 = false;
  double    l_var_4;
  double    l_var_5;
  int       l_var_6;
  double    l_var_7;
  double    l_var_8;
  long      l_var_9;
  double    l_var_10;
  string    l_var_11;
  double    l_var_12;
  datetime  l_var_13;
  int       l_var_14;
  int       l_var_15;
  string    l_var_16;
  double    l_var_17;
  double    l_var_18;
  bool      l_var_19;
  bool      l_var_20;
  double    l_var_21;
  bool      l_var_22;
  double    l_var_23;
  double    l_var_24;
  double    l_var_25;
  double    l_var_26;
  double    l_var_27;
  int       l_var_28;
  double    l_var_29;
//----- -----
  int        tmp_var_1;
  long       tmp_var_2;
  int        tmp_var_3;
  double     tmp_var_4;
  double     tmp_var_5;
  long       tmp_var_6;
  int        tmp_var_7;
  long       tmp_var_8;
  int        tmp_var_9;
  int        tmp_var_10;
  string     tmp_var_11;
  double     tmp_var_12;
  int        tmp_var_13;
  long       tmp_var_14;
  double     tmp_var_15;
  int        tmp_var_16;
  long       tmp_var_17;
  long       tmp_var_18;
  int        tmp_var_19;
  int        tmp_var_20;
  int        tmp_var_21;
  string     tmp_var_22;
  long       tmp_var_23;
  double     tmp_var_24;
  double     tmp_var_25;
  int        tmp_var_26;
  double     tmp_var_27;
  bool       tmp_var_28;
  int        tmp_var_29;
  int        tmp_var_30;
  double     tmp_var_31;
  long       tmp_var_32;
  int        tmp_var_33;
  long       tmp_var_34;
  double     tmp_var_35;
  double     tmp_var_36;
  int        tmp_var_37;
  double     tmp_var_38;
  bool       tmp_var_39;
  int        tmp_var_40;
  int        tmp_var_41;
  double     tmp_var_42;
  long       tmp_var_43;
  int        tmp_var_44;

  l_var_4 = 0.0 ;
  l_var_5 = 0.0 ;
  for (l_var_6 = 0 ; l_var_6 < OrdersTotal() ; l_var_6 ++)
  {
    if ( OrderSelect(l_var_6,0,0) == true )
    {
      l_var_2 = false ;
      l_var_7 = NormalizeDouble(OrderStopLoss(),g_var_190) ;
      l_var_8 = NormalizeDouble(OrderTakeProfit(),g_var_190) ;
      l_var_9 = OrderTicket() ;
      l_var_10 = NormalizeDouble(OrderOpenPrice(),g_var_190) ;
      l_var_11 = OrderComment() ;
      l_var_12 = OrderLots() ;
      l_var_13 = OrderOpenTime() ;
      l_var_14 = OrderType() ;
      l_var_15 = OrderMagicNumber() ;
      l_var_16 = OrderSymbol() ;
      if ( ( l_var_14 == 4 || l_var_14 == 2 ) && g_var_69 == 2 && ( g_var_95 == 0 || (g_var_95 == 1 && l_var_16 == g_var_336) ) && ( l_var_15 == g_var_96 || g_var_96 == 0 ) && ( l_var_11 == g_var_97 || g_var_97 == "" ) )
      {
        if ( ( l_var_7==0.0 || l_var_7==0.0 ) )
        {
          l_var_7 = NormalizeDouble(l_var_10 - g_var_100 * g_var_229,g_var_190) ;
          OrderModify(l_var_9,l_var_10,l_var_7,l_var_8,0,Green); 
        }
        if ( ( l_var_8==0.0 || l_var_8==0.0 ) )
        {
          l_var_8 = NormalizeDouble(g_var_101 * g_var_229 + l_var_10,g_var_190) ;
          OrderModify(l_var_9,l_var_10,l_var_7,l_var_8,0,Green); 
        }
      }
      if ( l_var_14 == 0 && ( ( l_var_15 == g_var_93 && g_var_69 == 1 && l_var_16 == g_var_336 ) || (g_var_69 == 2 && ( g_var_95 == 0 || (g_var_95 == 1 && l_var_16 == g_var_336) ) && ( l_var_15 == g_var_96 || g_var_96 == 0 ) && (l_var_11 == g_var_97 || g_var_97 == "")) ) )
      {
        if ( ( l_var_7==0.0 || l_var_7==0.0 ) )
        {
          l_var_7 = NormalizeDouble(l_var_10 - g_var_100 * g_var_229,g_var_190) ;
          OrderModify(l_var_9,l_var_10,l_var_7,l_var_8,0,Green); 
        }
        if ( ( l_var_8==0.0 || l_var_8==0.0 ) )
        {
          l_var_8 = NormalizeDouble(g_var_101 * g_var_229 + l_var_10,g_var_190) ;
          OrderModify(l_var_9,l_var_10,l_var_7,l_var_8,0,Green); 
        }
        if ( g_var_53 && iTime(g_var_336,g_var_52,g_var_51) <= l_var_13 && iTime(g_var_336,g_var_52,0) >  l_var_13 && iClose(g_var_336,g_var_52,1)<iOpen(g_var_336,g_var_52,1) && iClose(g_var_336,g_var_52,1)<l_var_10 )
        {
          OrderClose(l_var_9,l_var_12,MarketInfo(g_var_336,MODE_BID),0,Red); 
          Print("closing candle confirmation"); 
        }
        if ( g_var_55 && iTime(g_var_336,g_var_54,g_var_51) <= l_var_13 && iTime(g_var_336,g_var_54,0) >  l_var_13 && iClose(g_var_336,g_var_54,1)<iOpen(g_var_336,g_var_54,1) && iClose(g_var_336,g_var_54,1)<l_var_10 )
        {
          OrderClose(l_var_9,l_var_12,MarketInfo(g_var_336,MODE_BID),0,Red); 
          Print("closing candle confirmation"); 
        }
        if ( g_var_57 && iTime(g_var_336,g_var_56,g_var_51) <= l_var_13 && iTime(g_var_336,g_var_56,0) >  l_var_13 && iClose(g_var_336,g_var_56,1)<iOpen(g_var_336,g_var_56,1) && iClose(g_var_336,g_var_56,1)<l_var_10 )
        {
          OrderClose(l_var_9,l_var_12,MarketInfo(g_var_336,MODE_BID),0,Red); 
          Print("closing candle confirmation"); 
        }
        if ( g_var_59 && iTime(g_var_336,g_var_58,g_var_51) <= l_var_13 && iTime(g_var_336,g_var_58,0) >  l_var_13 && iClose(g_var_336,g_var_58,1)<iOpen(g_var_336,g_var_58,1) && iClose(g_var_336,g_var_58,1)<l_var_10 )
        {
          OrderClose(l_var_9,l_var_12,MarketInfo(g_var_336,MODE_BID),0,Red); 
          Print("closing candle confirmation"); 
        }
        if ( g_var_61 && iTime(g_var_336,g_var_60,g_var_51) <= l_var_13 && iTime(g_var_336,g_var_60,0) >  l_var_13 && iClose(g_var_336,g_var_60,1)<iOpen(g_var_336,g_var_60,1) && iClose(g_var_336,g_var_60,1)<l_var_10 )
        {
          OrderClose(l_var_9,l_var_12,MarketInfo(g_var_336,MODE_BID),0,Red); 
          Print("closing candle confirmation"); 
        }
        g_var_247 = g_var_129 ;
        if ( g_var_133 >  0 && TimeCurrent() >  l_var_13 + g_var_133 * 60 )
        {
          g_var_247 = g_var_134 ;
        }
        tmp_var_1 = g_var_190;
        tmp_var_2 = l_var_9;
        for (tmp_var_3 = 0 ; tmp_var_3 < 100 ; tmp_var_3 = tmp_var_3 + 1)
        {
          if ( !(g_var_198[tmp_var_3][0]==tmp_var_2) )   continue;
          tmp_var_4 = g_var_198[tmp_var_3][1];
          break;
          
        }
        tmp_var_4 = 0.0;
        l_var_17 = NormalizeDouble(tmp_var_4,tmp_var_1) ;
        if ( l_var_17==0.0 )
        {
          tmp_var_5 = l_var_10;
          tmp_var_6 = l_var_9;
          for (tmp_var_7 = 0 ; tmp_var_7 < 100 ; tmp_var_7 = tmp_var_7 + 1)
          {
            if ( !(g_var_198[tmp_var_7][0]==0.0) )   continue;
            g_var_198[tmp_var_7][0] = tmp_var_6;
            g_var_198[tmp_var_7][1] = tmp_var_5;
            break;
            
          }
          l_var_17 = l_var_10 ;
        }
        else
        {
          l_var_17 = l_var_17 - g_var_85 * g_var_229 ;
        }
        l_var_18 = l_var_10 - l_var_17 ;
        l_var_19 = false ;
        if ( l_var_17>0.0 - g_var_85 * g_var_229 && l_var_18>g_var_38 * g_var_229 )
        {
          l_var_19 = true ;
          if ( g_var_39 == 2 )
          {
            g_var_247 = -1000.0 ;
            Print("SlippageMode 2 active"); 
          }
        }
        if ( g_var_43 )
        {
          l_var_5 = l_var_17 ;
        }
        else
        {
          l_var_5 = l_var_10 ;
        }
        if ( l_var_7<NormalizeDouble(l_var_10 - (g_var_100 + g_var_64) * g_var_229 - g_var_1,g_var_190) )
        {
          l_var_7 = NormalizeDouble(l_var_10 - (g_var_100 + g_var_64) * g_var_229 - g_var_1,g_var_190) ;
          OrderModify(l_var_9,l_var_10,l_var_7,l_var_8,0,0xFFFFFFFF); 
        }
        if ( MarketInfo(g_var_336,MODE_BID)<l_var_10 - (g_var_100 + g_var_64) * g_var_229 - g_var_1 )
        {
          RefreshRates(); 
          OrderClose(OrderTicket(),OrderLots(),MarketInfo(g_var_336,MODE_BID),g_var_1,Red); 
          return(true); 
        }
        l_var_20 = false ;
        if ( g_var_159 )
        {
          tmp_var_8 = l_var_9;
          tmp_var_9 = 0;
          for (tmp_var_10 = OrdersTotal() ; tmp_var_10 >= 0 ; tmp_var_10 = tmp_var_10 - 1)
          {
            if ( OrderSelect(tmp_var_10,0,0) != true || OrderMagicNumber() != g_var_168 || OrderSymbol() != g_var_336 )   continue;
            tmp_var_11 = OrderComment();
            if ( tmp_var_11 != IntegerToString(tmp_var_8,0,32) )   continue;
            tmp_var_9 = tmp_var_9 + 1;
            
          }
          l_var_21 = tmp_var_9 ;
          l_var_22 = false ;
          if ( !(g_var_194) )
          {
            g_var_194 = true ;
            g_var_192 = 0 ;
          }
          if ( l_var_21==0.0 )
          {
            g_var_192 = 0 ;
          }
          if ( MathFloor(l_var_21 / 2.0)==l_var_21 / 2.0 )
          {
            g_var_192 = 0 ;
          }
          else
          {
            g_var_192 = 1 ;
          }
          if ( g_var_194 )
          {
            if ( l_var_21>0.0 )
            {
              tmp_var_12 = AccountEquity();
              if ( tmp_var_12>AccountBalance() + g_var_163 )
              {
                for (tmp_var_13 = OrdersTotal() ; tmp_var_13 >= 0 ; tmp_var_13 = tmp_var_13 - 1)
                {
                  if ( OrderSelect(tmp_var_13,0,0) != true )   continue;
                  
                  if ( ( OrderMagicNumber() != g_var_93 && OrderMagicNumber() != g_var_169 && OrderMagicNumber() != g_var_168 ) )   continue;
                  
                  if ( OrderType() == 0 )
                  {
                    OrderClose(OrderTicket(),OrderLots(),MarketInfo(g_var_336,MODE_BID),g_var_38,Red); 
                  }
                  if ( OrderType() != 1 )   continue;
                  OrderClose(OrderTicket(),OrderLots(),MarketInfo(g_var_336,MODE_ASK),g_var_38,Red); 
                  
                }
              }
            }
            if ( l_var_21>0.0 )
            {
              tmp_var_14 = l_var_9;
              tmp_var_15 = 0.0;
              for (tmp_var_16 = OrdersTotal() ; tmp_var_16 >= 0 ; tmp_var_16 = tmp_var_16 - 1)
              {
                if ( OrderSelect(tmp_var_16,0,0) != true )   continue;
                tmp_var_17 = OrderTicket();
                if ( tmp_var_17 != tmp_var_14 )
                {
                  tmp_var_11 = OrderComment();
                if ( tmp_var_11 != IntegerToString(tmp_var_14,0,32) )   continue;
                }
                tmp_var_15 = tmp_var_15 + OrderProfit();
                
              }
              if ( tmp_var_15>g_var_163 )
              {
                Print("Closing zone"); 
                tmp_var_18 = l_var_9;
                for (tmp_var_19 = OrdersTotal() ; tmp_var_19 >= 0 ; tmp_var_19 = tmp_var_19 - 1)
                {
                  if ( OrderSelect(tmp_var_19,0,0) != true )   continue;
                  
                  if ( OrderMagicNumber() == g_var_93 && OrderTicket() == tmp_var_18 )
                  {
                    OrderClose(OrderTicket(),OrderLots(),MarketInfo(g_var_336,MODE_BID),3,Red); 
                  }
                  if ( OrderMagicNumber() != g_var_168 )   continue;
                  tmp_var_11 = OrderComment();
                  if ( tmp_var_11 != IntegerToString(tmp_var_18,0,32) )   continue;
                  
                  if ( OrderType() == 0 )
                  {
                    OrderClose(OrderTicket(),OrderLots(),MarketInfo(g_var_336,MODE_BID),g_var_38,Red); 
                  }
                  if ( OrderType() != 1 )   continue;
                  OrderClose(OrderTicket(),OrderLots(),MarketInfo(g_var_336,MODE_ASK),g_var_38,Red); 
                  
                }
                g_var_194 = false ;
                l_var_20 = true ;
              }
            }
            else
            {
              l_var_23 = l_var_12 * g_var_165 ;
              if ( g_var_164 == 2 )
              {
                l_var_23 = (l_var_21 + 1.0) * l_var_12 + l_var_12 ;
              }
              if ( g_var_164 == 3 )
              {
                l_var_23 = l_var_12 * (MathPow(g_var_165,l_var_21 + 1.0)) ;
              }
              if ( g_var_192 == 0 )
              {
                l_var_24 = l_var_21 * g_var_161 * g_var_229 + (l_var_17 - g_var_160 * g_var_229) ;
                if ( l_var_24>l_var_17 - g_var_162 * g_var_229 )
                {
                  l_var_24 = l_var_17 - g_var_162 * g_var_229 ;
                }
                if ( MarketInfo(g_var_336,MODE_BID)<l_var_24 )
                {
                  if ( l_var_21>=g_var_166 )
                  {
                    for (tmp_var_20 = OrdersTotal() ; tmp_var_20 >= 0 ; tmp_var_20 = tmp_var_20 - 1)
                    {
                      if ( OrderSelect(tmp_var_20,0,0) != true )   continue;
                      
                      if ( OrderMagicNumber() == g_var_93 && OrderTicket() == l_var_9 )
                      {
                        OrderClose(OrderTicket(),OrderLots(),MarketInfo(g_var_336,MODE_BID),3,Red); 
                      }
                      if ( OrderMagicNumber() != g_var_168 )   continue;
                      tmp_var_11 = OrderComment();
                      if ( tmp_var_11 != IntegerToString(l_var_9,0,32) )   continue;
                      
                      if ( OrderType() == 0 )
                      {
                        OrderClose(OrderTicket(),OrderLots(),MarketInfo(g_var_336,MODE_BID),g_var_38,Red); 
                      }
                      if ( OrderType() != 1 )   continue;
                      OrderClose(OrderTicket(),OrderLots(),MarketInfo(g_var_336,MODE_ASK),g_var_38,Red); 
                      
                    }
                  }
                  else
                  {
                    OrderSend(g_var_336,1,l_var_23,MarketInfo(g_var_336,MODE_BID),g_var_38,0.0,0.0,IntegerToString(l_var_9,0,32),g_var_168,0,Green); 
                    g_var_192 = 1 ;
                    l_var_22 = true ;
                  }
                }
              }
              else
              {
                l_var_25 = l_var_17 ;
                if ( MarketInfo(g_var_336,MODE_ASK)>l_var_17 )
                {
                  if ( l_var_21>=g_var_166 )
                  {
                    for (tmp_var_21 = OrdersTotal() ; tmp_var_21 >= 0 ; tmp_var_21 = tmp_var_21 - 1)
                    {
                      if ( OrderSelect(tmp_var_21,0,0) != true )   continue;
                      
                      if ( OrderMagicNumber() == g_var_93 && OrderTicket() == l_var_9 )
                      {
                        OrderClose(OrderTicket(),OrderLots(),MarketInfo(g_var_336,MODE_BID),3,Red); 
                      }
                      if ( OrderMagicNumber() != g_var_168 )   continue;
                      tmp_var_22 = OrderComment();
                      if ( tmp_var_22 != IntegerToString(l_var_9,0,32) )   continue;
                      
                      if ( OrderType() == 0 )
                      {
                        OrderClose(OrderTicket(),OrderLots(),MarketInfo(g_var_336,MODE_BID),g_var_38,Red); 
                      }
                      if ( OrderType() != 1 )   continue;
                      OrderClose(OrderTicket(),OrderLots(),MarketInfo(g_var_336,MODE_ASK),g_var_38,Red); 
                      
                    }
                  }
                  else
                  {
                    OrderSend(g_var_336,0,l_var_23,MarketInfo(g_var_336,MODE_ASK),g_var_38,0.0,0.0,IntegerToString(l_var_9,0,32),g_var_168,0,Green); 
                    g_var_192 = 0 ;
                    l_var_22 = true ;
                  }
                }
              }
            }
          }
          if ( ( l_var_21>0.0 || l_var_22 ) )
          {
            l_var_20 = true ;
          }
        }
        if ( !(l_var_20) )
        {
          if ( ( g_var_63 == 1 || (g_var_63 != 3 && g_var_63 != 2) ) )
          {
            tmp_var_23 = l_var_9;
            tmp_var_24 = g_var_100;
            tmp_var_25 = l_var_10;
            tmp_var_26 = 1;
            tmp_var_27 = 0.0;
            tmp_var_28 = false;
            for (tmp_var_29 = 0 ; tmp_var_29 < g_var_199 ; tmp_var_29 = tmp_var_29 + 1)
            {
              if ( g_var_196[tmp_var_29][0]==tmp_var_23 )
              {
                tmp_var_27 = g_var_196[tmp_var_29][1];
                tmp_var_28 = true;
                break;
              }
            }
            if ( !(tmp_var_28) )
            {
              if ( tmp_var_26 == 1 )
              {
                tmp_var_27 = NormalizeDouble(tmp_var_25 - tmp_var_24 * g_var_229,g_var_190);
              }
              if ( tmp_var_26 == 2 )
              {
                tmp_var_27 = NormalizeDouble(tmp_var_24 * g_var_229 + tmp_var_25,g_var_190);
              }
              for (tmp_var_30 = 0 ; tmp_var_30 < g_var_199 ; tmp_var_30 = tmp_var_30 + 1)
              {
                if ( g_var_196[tmp_var_30][0]==0.0 )
                {
                  g_var_196[tmp_var_30][0] = tmp_var_23;
                  g_var_196[tmp_var_30][1] = tmp_var_27;
                  break;
                }
              }
            }
            g_var_191 = tmp_var_27 ;
            l_var_4 = g_var_191 ;
            if ( MarketInfo(g_var_336,MODE_BID)<l_var_4 )
            {
              Print("Closing with virtual SL"); 
              RefreshRates(); 
              OrderClose(l_var_9,l_var_12,MarketInfo(g_var_336,MODE_BID),g_var_1,0xFFFFFFFF); 
              return(true); 
            }
            if ( g_var_125>0.0 && TimeCurrent() >= l_var_13 + g_var_304 && MarketInfo(g_var_336,MODE_BID)>NormalizeDouble(g_var_126 * g_var_229 + (l_var_7 + g_var_337),g_var_190) && MarketInfo(g_var_336,MODE_BID)<l_var_8 - g_var_309 )
            {
              l_var_7 = NormalizeDouble(MarketInfo(g_var_336,MODE_BID) - g_var_126 * g_var_229,g_var_190) ;
              if ( l_var_7<MarketInfo(g_var_336,MODE_BID) - g_var_221 )
              {
                g_var_230 = OrderModify(l_var_9,l_var_10,l_var_7,l_var_8,0,0xFFFFFFFF) ;
                if ( g_var_230 <= 0 )
                {
                  Print("TrailStop error: \'" + TGR_21(GetLastError()) + "\' when setting trailing Exit_TrailSL_after_X_Minutes_size loss.  Trying again!"); 
                }
                l_var_2 = true ;
              }
            }
            if ( g_var_103>0.0 && MarketInfo(g_var_336,MODE_BID)>NormalizeDouble((g_var_103 + g_var_106) * g_var_229 + (l_var_7 + g_var_337),g_var_190) && MarketInfo(g_var_336,MODE_BID)>NormalizeDouble(g_var_104 * g_var_229 + l_var_5,g_var_190) && MarketInfo(g_var_336,MODE_BID)<l_var_8 - g_var_309 && l_var_7<NormalizeDouble(g_var_105 * g_var_229 + l_var_10,g_var_190) )
            {
              l_var_7 = NormalizeDouble(MarketInfo(g_var_336,MODE_BID) - g_var_103 * g_var_229,g_var_190) ;
              if ( l_var_7<MarketInfo(g_var_336,MODE_BID) - g_var_221 )
              {
                g_var_230 = OrderModify(l_var_9,l_var_10,l_var_7,l_var_8,0,0xFFFFFFFF) ;
                if ( g_var_230 <= 0 )
                {
                  Print("TrailStop error: \'" + TGR_21(GetLastError()) + "\' when setting trailing Exit_stop loss.  Trying again!"); 
                }
                else
                {
                  l_var_26 = NormalizeDouble(g_var_107 / 100.0 * g_var_223[g_var_328],2) ;
                  if ( l_var_26<l_var_12 && l_var_26>=MarketInfo(g_var_336,MODE_LOTSTEP) )
                  {
                    OrderClose(l_var_9,l_var_26,MarketInfo(g_var_336,MODE_BID),g_var_38,Red); 
                    return(true); 
                  }
                }
                l_var_2 = true ;
              }
            }
            if ( g_var_108>0.0 && MarketInfo(g_var_336,MODE_ASK)<NormalizeDouble(l_var_8 - g_var_337 - g_var_108 * g_var_229,g_var_190) && MarketInfo(g_var_336,MODE_ASK)<NormalizeDouble(l_var_5 - g_var_109 * g_var_229,g_var_190) && MarketInfo(g_var_336,MODE_BID)<l_var_8 - g_var_309 )
            {
              l_var_8 = NormalizeDouble(MarketInfo(g_var_336,MODE_BID) + g_var_108 * g_var_229,g_var_190) ;
              if ( l_var_8>MarketInfo(g_var_336,MODE_ASK) + g_var_221 )
              {
                g_var_230 = OrderModify(l_var_9,l_var_10,l_var_7,l_var_8,0,0xFFFFFFFF) ;
                if ( g_var_230 <= 0 )
                {
                  Print("TrailStop error: \'" + TGR_21(GetLastError()) + "\' when setting trailing Exit_TP.  Trying again!"); 
                }
                else
                {
                  l_var_27 = NormalizeDouble(g_var_107 / 100.0 * g_var_223[g_var_328],2) ;
                  if ( l_var_27<l_var_12 && l_var_27>=SymbolInfoDouble(g_var_336,34) )
                  {
                    OrderClose(l_var_9,l_var_27,MarketInfo(g_var_336,MODE_BID),g_var_38,Red); 
                    return(true); 
                  }
                }
                l_var_2 = true ;
              }
            }
            if ( l_var_19 && g_var_39 == 1 && g_var_41>0.0 && MarketInfo(g_var_336,MODE_BID)>NormalizeDouble(g_var_41 * g_var_229 + (l_var_7 + g_var_337),g_var_190) && MarketInfo(g_var_336,MODE_BID)>NormalizeDouble(g_var_40 * g_var_229 + l_var_17,g_var_190) && MarketInfo(g_var_336,MODE_BID)<l_var_8 - g_var_309 && l_var_7<NormalizeDouble(g_var_42 * g_var_229 + l_var_10,g_var_190) )
            {
              l_var_7 = NormalizeDouble(MarketInfo(g_var_336,MODE_BID) - g_var_41 * g_var_229,g_var_190) ;
              if ( l_var_7<MarketInfo(g_var_336,MODE_BID) - g_var_221 )
              {
                g_var_230 = OrderModify(l_var_9,l_var_10,l_var_7,l_var_8,0,0xFFFFFFFF) ;
                if ( g_var_230 <= 0 )
                {
                  Print("TrailStop error: \'" + TGR_21(GetLastError()) + "\' when setting Slip TL.  Trying again!"); 
                }
                else
                {
                  Print("Slippage control active"); 
                }
                l_var_2 = true ;
              }
            }
            if ( g_var_119 >  0 && g_var_120 >= 0 && UseHL_TrailingSL && g_var_242[g_var_328]>NormalizeDouble(l_var_7 + g_var_221 + g_var_337,g_var_190) && g_var_242[g_var_328]<MarketInfo(g_var_336,MODE_BID) - g_var_121 * g_var_229 && ( g_var_242[g_var_328]<l_var_10 || !(g_var_116) ) && g_var_242[g_var_328]<NormalizeDouble(MarketInfo(g_var_336,MODE_BID) - g_var_122 * g_var_229 - g_var_221 - g_var_337,g_var_190) && MarketInfo(g_var_336,MODE_BID)<l_var_8 - g_var_309 )
            {
              l_var_7 = NormalizeDouble(g_var_242[g_var_328],g_var_190) ;
              if ( l_var_7<MarketInfo(g_var_336,MODE_BID) - g_var_221 )
              {
                g_var_230 = OrderModify(l_var_9,l_var_10,l_var_7,l_var_8,0,0xFFFFFFFF) ;
                if ( g_var_230 <= 0 )
                {
                  Print("error: \'" + TGR_21(GetLastError()) + "\' when modifying stoploss"); 
                }
                l_var_2 = true ;
              }
            }
            if ( g_var_113>0.0 && MarketInfo(g_var_336,MODE_BID)>NormalizeDouble(g_var_113 * g_var_229 + l_var_10,g_var_190) && NormalizeDouble(g_var_114 * g_var_229 + l_var_10,g_var_190)>l_var_7 + g_var_337 && MarketInfo(g_var_336,MODE_BID)>NormalizeDouble(g_var_114 * g_var_229 + l_var_10 + g_var_221,g_var_190) && MarketInfo(g_var_336,MODE_BID)<l_var_8 - g_var_309 )
            {
              l_var_7 = NormalizeDouble(g_var_114 * g_var_229 + l_var_10,g_var_190) ;
              if ( l_var_7<MarketInfo(g_var_336,MODE_BID) - g_var_221 )
              {
                g_var_230 = OrderModify(l_var_9,l_var_10,l_var_7,l_var_8,0,0xFFFFFFFF) ;
                if ( g_var_230 <= 0 )
                {
                  Print("error when setting breakeven: \'" + TGR_21(GetLastError()) + "\' ..\'Exit_BE_start\' to close to \'Exit_BE_extra_pips\' ..trying again!"); 
                }
                l_var_2 = true ;
              }
            }
            if ( !(l_var_2) && ( g_var_128 == 1 || (g_var_128 == 2 && g_var_131 * g_var_229 + l_var_7<=g_var_132 * g_var_229 + (l_var_5 + g_var_1)) ) )
            {
              g_var_250 ++;
              if ( MarketInfo(g_var_336,MODE_BID)>g_var_131 * g_var_229 + l_var_7 + g_var_221 && MarketInfo(g_var_336,MODE_BID)<l_var_8 - g_var_309 && ( g_var_129==0.0 || MarketInfo(g_var_336,MODE_BID)>g_var_247 * g_var_229 + l_var_5 ) && g_var_250 >= g_var_130 && NormalizeDouble(g_var_131 * g_var_229 + l_var_7,g_var_190)>l_var_7 )
              {
                g_var_250 = 0 ;
                l_var_7 = NormalizeDouble(g_var_131 * g_var_229 + l_var_7,g_var_190) ;
                OrderModify(l_var_9,l_var_10,l_var_7,l_var_8,0,0xFFFFFFFF); 
                l_var_2 = true ;
              }
            }
            g_var_191 = l_var_7 ;
            if ( MarketInfo(g_var_336,MODE_BID)<l_var_7 )
            {
              Print("Closing with virtual SL"); 
              RefreshRates(); 
              OrderClose(l_var_9,l_var_12,MarketInfo(g_var_336,MODE_BID),g_var_1,0xFFFFFFFF); 
              return(true); 
            }
            if ( NormalizeDouble(l_var_4,g_var_190)!=NormalizeDouble(g_var_191,g_var_190) )
            {
              tmp_var_31 = NormalizeDouble(g_var_191,g_var_190);
              tmp_var_32 = l_var_9;
              for (tmp_var_33 = 0 ; tmp_var_33 < g_var_199 ; tmp_var_33 = tmp_var_33 + 1)
              {
                if ( g_var_196[tmp_var_33][0]==tmp_var_32 )
                {
                  g_var_196[tmp_var_33][1] = tmp_var_31;
                  break;
                }
              }
            }
            if ( l_var_2 && g_var_135 )
            {
              return(true); 
            }
          }
          if ( ( g_var_63 == 2 || g_var_63 == 3 ) )
          {
            tmp_var_34 = l_var_9;
            tmp_var_35 = g_var_100;
            tmp_var_36 = l_var_10;
            tmp_var_37 = 1;
            tmp_var_38 = 0.0;
            tmp_var_39 = false;
            for (tmp_var_40 = 0 ; tmp_var_40 < g_var_199 ; tmp_var_40 = tmp_var_40 + 1)
            {
              if ( g_var_196[tmp_var_40][0]==tmp_var_34 )
              {
                tmp_var_38 = g_var_196[tmp_var_40][1];
                tmp_var_39 = true;
                break;
              }
            }
            if ( !(tmp_var_39) )
            {
              if ( tmp_var_37 == 1 )
              {
                tmp_var_38 = NormalizeDouble(tmp_var_36 - tmp_var_35 * g_var_229,g_var_190);
              }
              if ( tmp_var_37 == 2 )
              {
                tmp_var_38 = NormalizeDouble(tmp_var_35 * g_var_229 + tmp_var_36,g_var_190);
              }
              for (tmp_var_41 = 0 ; tmp_var_41 < g_var_199 ; tmp_var_41 = tmp_var_41 + 1)
              {
                if ( g_var_196[tmp_var_41][0]==0.0 )
                {
                  g_var_196[tmp_var_41][0] = tmp_var_34;
                  g_var_196[tmp_var_41][1] = tmp_var_38;
                  break;
                }
              }
            }
            g_var_191 = tmp_var_38 ;
            l_var_4 = g_var_191 ;
            if ( MarketInfo(g_var_336,MODE_BID)<=l_var_4 )
            {
              RefreshRates(); 
              OrderClose(l_var_9,l_var_12,MarketInfo(g_var_336,MODE_BID),g_var_1,0xFFFFFFFF); 
              return(true); 
            }
            l_var_28 = TimeCurrent() - g_var_319 ;
            if ( l_var_28 >= g_var_65 )
            {
              if ( NormalizeDouble(g_var_191,g_var_190)>l_var_7 + g_var_337 )
              {
                OrderModify(l_var_9,l_var_10,NormalizeDouble(g_var_191,g_var_190),l_var_8,0,0xFFFFFFFF); 
              }
              g_var_319 = TimeCurrent() ;
            }
            if ( g_var_125>0.0 && TimeCurrent() >= l_var_13 + g_var_304 && MarketInfo(g_var_336,MODE_BID)>g_var_126 * g_var_229 + (g_var_191 + g_var_337) && MarketInfo(g_var_336,MODE_BID)<l_var_8 - g_var_309 )
            {
              l_var_2 = true ;
              g_var_191 = MarketInfo(g_var_336,MODE_BID) - g_var_126 * g_var_229 ;
            }
            if ( g_var_103>0.0 && MarketInfo(g_var_336,MODE_BID)>(g_var_103 + g_var_106) * g_var_229 + (g_var_191 + g_var_337) && MarketInfo(g_var_336,MODE_BID)>g_var_104 * g_var_229 + l_var_5 && g_var_191<g_var_105 * g_var_229 + l_var_10 )
            {
              l_var_2 = true ;
              g_var_191 = MarketInfo(g_var_336,MODE_BID) - g_var_103 * g_var_229 ;
              l_var_29 = NormalizeDouble(g_var_107 / 100.0 * g_var_223[g_var_328],2) ;
              if ( l_var_29<l_var_12 && l_var_29>=MarketInfo(g_var_336,MODE_LOTSTEP) )
              {
                OrderClose(l_var_9,l_var_29,MarketInfo(g_var_336,MODE_BID),g_var_38,Red); 
                return(true); 
              }
            }
            if ( l_var_19 && g_var_39 == 1 && g_var_41>0.0 && MarketInfo(g_var_336,MODE_BID)>g_var_41 * g_var_229 + (g_var_191 + g_var_337) && MarketInfo(g_var_336,MODE_BID)>g_var_40 * g_var_229 + l_var_17 && MarketInfo(g_var_336,MODE_BID)<l_var_8 - g_var_309 && g_var_191<g_var_42 * g_var_229 + l_var_10 )
            {
              Print("Slippage control active"); 
              l_var_2 = true ;
              g_var_191 = MarketInfo(g_var_336,MODE_BID) - g_var_41 * g_var_229 ;
            }
            if ( g_var_119 >  0 && g_var_120 >= 0 && g_var_242[g_var_328]>g_var_191 + g_var_221 + g_var_337 && ( g_var_242[g_var_328]<l_var_10 || !(g_var_116) ) && g_var_242[g_var_328]<MarketInfo(g_var_336,MODE_BID) - g_var_122 * g_var_229 - g_var_221 - g_var_337 && MarketInfo(g_var_336,MODE_BID)<l_var_8 - g_var_309 )
            {
              g_var_191 = g_var_242[g_var_328] ;
              l_var_2 = true ;
            }
            if ( g_var_113>0.0 && g_var_63 == 3 && MarketInfo(g_var_336,MODE_BID)>g_var_113 * g_var_229 + l_var_10 && g_var_114 * g_var_229 + l_var_10>l_var_7 + g_var_337 && MarketInfo(g_var_336,MODE_BID)>g_var_114 * g_var_229 + l_var_10 + g_var_221 && MarketInfo(g_var_336,MODE_BID)<l_var_8 - g_var_309 && NormalizeDouble(g_var_114 * g_var_229 + l_var_10,g_var_190)>OrderStopLoss() )
            {
              g_var_191 = NormalizeDouble(g_var_114 * g_var_229 + l_var_10,g_var_190) ;
              g_var_230 = OrderModify(l_var_9,l_var_10,g_var_191,l_var_8,0,0xFFFFFFFF) ;
              if ( g_var_230 <= 0 )
              {
                Print("error when setting breakeven: \'" + TGR_21(GetLastError()) + "\' ..\'Exit_BE_start\' to close to \'Exit_BE_extra_pips\' ..trying again!"); 
              }
              l_var_2 = true ;
            }
            if ( g_var_113>0.0 && g_var_63 == 2 && MarketInfo(g_var_336,MODE_BID)>g_var_113 * g_var_229 + l_var_10 && g_var_114 * g_var_229 + l_var_10>g_var_191 + g_var_337 && MarketInfo(g_var_336,MODE_BID)>g_var_114 * g_var_229 + l_var_10 + g_var_221 && MarketInfo(g_var_336,MODE_BID)<l_var_8 - g_var_309 )
            {
              g_var_191 = g_var_114 * g_var_229 + l_var_10 ;
              l_var_2 = true ;
            }
            if ( !(l_var_2) && ( g_var_128 == 1 || (g_var_128 == 2 && g_var_131 * g_var_229 + g_var_191<=g_var_132 * g_var_229 + (l_var_5 + g_var_1)) ) )
            {
              g_var_250 ++;
              if ( MarketInfo(g_var_336,MODE_BID)>g_var_131 * g_var_229 + g_var_191 + g_var_221 && MarketInfo(g_var_336,MODE_BID)<l_var_8 - g_var_309 && ( g_var_129==0.0 || MarketInfo(g_var_336,MODE_BID)>g_var_247 * g_var_229 + l_var_5 ) && g_var_250 >= g_var_130 )
              {
                g_var_250 = 0 ;
                g_var_191 = g_var_131 * g_var_229 + g_var_191 ;
                l_var_2 = true ;
              }
            }
            if ( MarketInfo(g_var_336,MODE_BID)<=g_var_191 )
            {
              RefreshRates(); 
              OrderClose(l_var_9,l_var_12,MarketInfo(g_var_336,MODE_BID),g_var_1,0xFFFFFFFF); 
              return(true); 
            }
            if ( NormalizeDouble(l_var_4,g_var_190)!=NormalizeDouble(g_var_191,g_var_190) )
            {
              tmp_var_42 = NormalizeDouble(g_var_191,g_var_190);
              tmp_var_43 = l_var_9;
              for (tmp_var_44 = 0 ; tmp_var_44 < g_var_199 ; tmp_var_44 = tmp_var_44 + 1)
              {
                if ( g_var_196[tmp_var_44][0]==tmp_var_43 )
                {
                  g_var_196[tmp_var_44][1] = tmp_var_42;
                  break;
                }
              }
            }
          }
        }
      }
      if ( l_var_2 )
      {
        l_var_3 = true ;
      }
    }
    if ( l_var_2 )
    {
      l_var_3 = true ;
    }
  }
  return(l_var_3); 
}
//TGR_18 <<==--------   --------

bool TGR_19()
{
  bool      l_var_2 = false;
  bool      l_var_3 = false;
  double    l_var_4;
  double    l_var_5;
  int       l_var_6;
  double    l_var_7;
  double    l_var_8;
  long      l_var_9;
  double    l_var_10;
  string    l_var_11;
  double    l_var_12;
  datetime  l_var_13;
  int       l_var_14;
  int       l_var_15;
  string    l_var_16;
  double    l_var_17;
  double    l_var_18;
  bool      l_var_19;
  bool      l_var_20;
  double    l_var_21;
  bool      l_var_22;
  double    l_var_23;
  double    l_var_24;
  double    l_var_25;
  double    l_var_26;
  double    l_var_27;
  int       l_var_28;
  double    l_var_29;
//----- -----
  int        tmp_var_1;
  long       tmp_var_2;
  int        tmp_var_3;
  double     tmp_var_4;
  double     tmp_var_5;
  long       tmp_var_6;
  int        tmp_var_7;
  long       tmp_var_8;
  int        tmp_var_9;
  int        tmp_var_10;
  string     tmp_var_11;
  double     tmp_var_12;
  int        tmp_var_13;
  long       tmp_var_14;
  double     tmp_var_15;
  int        tmp_var_16;
  long       tmp_var_17;
  long       tmp_var_18;
  int        tmp_var_19;
  int        tmp_var_20;
  int        tmp_var_21;
  string     tmp_var_22;
  long       tmp_var_23;
  double     tmp_var_24;
  double     tmp_var_25;
  int        tmp_var_26;
  double     tmp_var_27;
  bool       tmp_var_28;
  int        tmp_var_29;
  int        tmp_var_30;
  double     tmp_var_31;
  long       tmp_var_32;
  int        tmp_var_33;
  long       tmp_var_34;
  double     tmp_var_35;
  double     tmp_var_36;
  int        tmp_var_37;
  double     tmp_var_38;
  bool       tmp_var_39;
  int        tmp_var_40;
  int        tmp_var_41;
  double     tmp_var_42;
  long       tmp_var_43;
  int        tmp_var_44;

  l_var_4 = 0.0 ;
  l_var_5 = 0.0 ;
  for (l_var_6 = 0 ; l_var_6 < OrdersTotal() ; l_var_6 ++)
  {
    if ( OrderSelect(l_var_6,0,0) == true )
    {
      l_var_2 = false ;
      l_var_7 = NormalizeDouble(OrderStopLoss(),g_var_190) ;
      l_var_8 = NormalizeDouble(OrderTakeProfit(),g_var_190) ;
      l_var_9 = OrderTicket() ;
      l_var_10 = NormalizeDouble(OrderOpenPrice(),g_var_190) ;
      l_var_11 = OrderComment() ;
      l_var_12 = OrderLots() ;
      l_var_13 = OrderOpenTime() ;
      l_var_14 = OrderType() ;
      l_var_15 = OrderMagicNumber() ;
      l_var_16 = OrderSymbol() ;
      if ( ( l_var_14 == 5 || l_var_14 == 3 ) && g_var_69 == 2 && ( g_var_95 == 0 || (g_var_95 == 1 && l_var_16 == g_var_336) ) && ( l_var_15 == g_var_96 || g_var_96 == 0 ) && ( l_var_11 == g_var_97 || g_var_97 == "" ) )
      {
        if ( ( l_var_7==0.0 || l_var_7==0.0 ) )
        {
          l_var_7 = NormalizeDouble(g_var_100 * g_var_229 + l_var_10,g_var_190) ;
          OrderModify(l_var_9,l_var_10,l_var_7,l_var_8,0,Green); 
        }
        if ( ( l_var_8==0.0 || l_var_8==0.0 ) )
        {
          l_var_8 = NormalizeDouble(l_var_10 - g_var_101 * g_var_229,g_var_190) ;
          OrderModify(l_var_9,l_var_10,l_var_7,l_var_8,0,Green); 
        }
      }
      if ( l_var_14 == 1 && ( ( l_var_15 == g_var_93 && g_var_69 == 1 && l_var_16 == g_var_336 ) || (g_var_69 == 2 && ( g_var_95 == 0 || (g_var_95 == 1 && l_var_16 == g_var_336) ) && ( l_var_15 == g_var_96 || g_var_96 == 0 ) && (l_var_11 == g_var_97 || g_var_97 == "")) ) )
      {
        if ( ( l_var_7==0.0 || l_var_7==0.0 ) )
        {
          l_var_7 = NormalizeDouble(g_var_100 * g_var_229 + l_var_10,g_var_190) ;
          OrderModify(l_var_9,l_var_10,l_var_7,l_var_8,0,Green); 
        }
        if ( ( l_var_8==0.0 || l_var_8==0.0 ) )
        {
          l_var_8 = NormalizeDouble(l_var_10 - g_var_101 * g_var_229,g_var_190) ;
          OrderModify(l_var_9,l_var_10,l_var_7,l_var_8,0,Green); 
        }
        if ( g_var_53 && iTime(g_var_336,g_var_52,g_var_51) <= l_var_13 && iTime(g_var_336,g_var_52,0) >  l_var_13 && iClose(g_var_336,g_var_52,1)>iOpen(g_var_336,g_var_52,1) && iClose(g_var_336,g_var_52,1)>l_var_10 )
        {
          OrderClose(l_var_9,l_var_12,MarketInfo(g_var_336,MODE_ASK),0,Red); 
          Print("closing candle confirmation"); 
        }
        if ( g_var_55 && iTime(g_var_336,g_var_54,g_var_51) <= l_var_13 && iTime(g_var_336,g_var_54,0) >  l_var_13 && iClose(g_var_336,g_var_54,1)>iOpen(g_var_336,g_var_54,1) && iClose(g_var_336,g_var_54,1)>l_var_10 )
        {
          OrderClose(l_var_9,l_var_12,MarketInfo(g_var_336,MODE_ASK),0,Red); 
          Print("closing candle confirmation"); 
        }
        if ( g_var_57 && iTime(g_var_336,g_var_56,g_var_51) <= l_var_13 && iTime(g_var_336,g_var_56,0) >  l_var_13 && iClose(g_var_336,g_var_56,1)>iOpen(g_var_336,g_var_56,1) && iClose(g_var_336,g_var_56,1)>l_var_10 )
        {
          OrderClose(l_var_9,l_var_12,MarketInfo(g_var_336,MODE_ASK),0,Red); 
          Print("closing candle confirmation"); 
        }
        if ( g_var_59 && iTime(g_var_336,g_var_58,g_var_51) <= l_var_13 && iTime(g_var_336,g_var_58,0) >  l_var_13 && iClose(g_var_336,g_var_58,1)>iOpen(g_var_336,g_var_58,1) && iClose(g_var_336,g_var_58,1)>l_var_10 )
        {
          OrderClose(l_var_9,l_var_12,MarketInfo(g_var_336,MODE_ASK),0,Red); 
          Print("closing candle confirmation"); 
        }
        if ( g_var_61 && iTime(g_var_336,g_var_60,g_var_51) <= l_var_13 && iTime(g_var_336,g_var_60,0) >  l_var_13 && iClose(g_var_336,g_var_60,1)>iOpen(g_var_336,g_var_60,1) && iClose(g_var_336,g_var_60,1)>l_var_10 )
        {
          OrderClose(l_var_9,l_var_12,MarketInfo(g_var_336,MODE_ASK),0,Red); 
          Print("closing candle confirmation"); 
        }
        g_var_247 = g_var_129 ;
        if ( g_var_133 >  0 && TimeCurrent() >  l_var_13 + g_var_133 * 60 )
        {
          g_var_247 = g_var_134 ;
        }
        tmp_var_1 = g_var_190;
        tmp_var_2 = l_var_9;
        for (tmp_var_3 = 0 ; tmp_var_3 < 100 ; tmp_var_3 = tmp_var_3 + 1)
        {
          if ( !(g_var_198[tmp_var_3][0]==tmp_var_2) )   continue;
          tmp_var_4 = g_var_198[tmp_var_3][1];
          break;
          
        }
        tmp_var_4 = 0.0;
        l_var_17 = NormalizeDouble(tmp_var_4,tmp_var_1) ;
        if ( l_var_17==0.0 )
        {
          tmp_var_5 = l_var_10;
          tmp_var_6 = l_var_9;
          for (tmp_var_7 = 0 ; tmp_var_7 < 100 ; tmp_var_7 = tmp_var_7 + 1)
          {
            if ( !(g_var_198[tmp_var_7][0]==0.0) )   continue;
            g_var_198[tmp_var_7][0] = tmp_var_6;
            g_var_198[tmp_var_7][1] = tmp_var_5;
            break;
            
          }
          l_var_17 = l_var_10 ;
        }
        else
        {
          l_var_17 = l_var_17 - g_var_85 * g_var_229 ;
        }
        l_var_18 = l_var_17 - l_var_10 ;
        l_var_19 = false ;
        if ( l_var_17>g_var_85 * g_var_229 && l_var_18>g_var_38 * g_var_229 )
        {
          l_var_19 = true ;
          if ( g_var_39 == 2 )
          {
            g_var_247 = -1000.0 ;
            Print("Slippage Mode 2 active"); 
          }
        }
        if ( g_var_43 )
        {
          l_var_5 = l_var_17 ;
        }
        else
        {
          l_var_5 = l_var_10 ;
        }
        if ( l_var_7>NormalizeDouble((g_var_100 + g_var_64) * g_var_229 + l_var_10 + g_var_1,g_var_190) )
        {
          l_var_7 = NormalizeDouble((g_var_100 + g_var_64) * g_var_229 + l_var_10 + g_var_1,g_var_190) ;
          OrderModify(l_var_9,l_var_10,l_var_7,l_var_8,0,0xFFFFFFFF); 
        }
        if ( MarketInfo(g_var_336,MODE_ASK)>(g_var_100 + g_var_64) * g_var_229 + l_var_10 + g_var_1 )
        {
          RefreshRates(); 
          OrderClose(OrderTicket(),OrderLots(),MarketInfo(g_var_336,MODE_ASK),g_var_1,Red); 
          return(true); 
        }
        l_var_20 = false ;
        if ( g_var_159 )
        {
          tmp_var_8 = l_var_9;
          tmp_var_9 = 0;
          for (tmp_var_10 = OrdersTotal() ; tmp_var_10 >= 0 ; tmp_var_10 = tmp_var_10 - 1)
          {
            if ( OrderSelect(tmp_var_10,0,0) != true || OrderMagicNumber() != g_var_169 || OrderSymbol() != g_var_336 )   continue;
            tmp_var_11 = OrderComment();
            if ( tmp_var_11 != IntegerToString(tmp_var_8,0,32) )   continue;
            tmp_var_9 = tmp_var_9 + 1;
            
          }
          l_var_21 = tmp_var_9 ;
          l_var_22 = false ;
          if ( !(g_var_195) )
          {
            g_var_195 = true ;
            g_var_193 = 1 ;
          }
          if ( l_var_21==0.0 )
          {
            g_var_193 = 1 ;
          }
          if ( MathFloor(l_var_21 / 2.0)==l_var_21 / 2.0 )
          {
            g_var_193 = 1 ;
          }
          else
          {
            g_var_193 = 0 ;
          }
          if ( g_var_195 )
          {
            if ( l_var_21>0.0 )
            {
              tmp_var_12 = AccountEquity();
              if ( tmp_var_12>AccountBalance() + g_var_163 )
              {
                for (tmp_var_13 = OrdersTotal() ; tmp_var_13 >= 0 ; tmp_var_13 = tmp_var_13 - 1)
                {
                  if ( OrderSelect(tmp_var_13,0,0) != true )   continue;
                  
                  if ( ( OrderMagicNumber() != g_var_93 && OrderMagicNumber() != g_var_169 && OrderMagicNumber() != g_var_168 ) )   continue;
                  
                  if ( OrderType() == 0 )
                  {
                    OrderClose(OrderTicket(),OrderLots(),MarketInfo(g_var_336,MODE_BID),g_var_38,Red); 
                  }
                  if ( OrderType() != 1 )   continue;
                  OrderClose(OrderTicket(),OrderLots(),MarketInfo(g_var_336,MODE_ASK),g_var_38,Red); 
                  
                }
              }
            }
            if ( l_var_21>0.0 )
            {
              tmp_var_14 = l_var_9;
              tmp_var_15 = 0.0;
              for (tmp_var_16 = OrdersTotal() ; tmp_var_16 >= 0 ; tmp_var_16 = tmp_var_16 - 1)
              {
                if ( OrderSelect(tmp_var_16,0,0) != true )   continue;
                tmp_var_17 = OrderTicket();
                if ( tmp_var_17 != tmp_var_14 )
                {
                  tmp_var_11 = OrderComment();
                if ( tmp_var_11 != IntegerToString(tmp_var_14,0,32) )   continue;
                }
                tmp_var_15 = tmp_var_15 + OrderProfit();
                
              }
              if ( tmp_var_15>g_var_163 )
              {
                Print("Closing zone"); 
                tmp_var_18 = l_var_9;
                for (tmp_var_19 = OrdersTotal() ; tmp_var_19 >= 0 ; tmp_var_19 = tmp_var_19 - 1)
                {
                  if ( OrderSelect(tmp_var_19,0,0) != true )   continue;
                  
                  if ( OrderMagicNumber() == g_var_93 && OrderTicket() == tmp_var_18 )
                  {
                    OrderClose(OrderTicket(),OrderLots(),MarketInfo(g_var_336,MODE_ASK),3,Red); 
                  }
                  if ( OrderMagicNumber() != g_var_169 )   continue;
                  tmp_var_11 = OrderComment();
                  if ( tmp_var_11 != IntegerToString(tmp_var_18,0,32) )   continue;
                  
                  if ( OrderType() == 0 )
                  {
                    OrderClose(OrderTicket(),OrderLots(),MarketInfo(g_var_336,MODE_BID),g_var_38,Red); 
                  }
                  if ( OrderType() != 1 )   continue;
                  OrderClose(OrderTicket(),OrderLots(),MarketInfo(g_var_336,MODE_ASK),g_var_38,Red); 
                  
                }
                g_var_195 = false ;
                l_var_20 = true ;
              }
            }
            else
            {
              l_var_23 = l_var_12 * g_var_165 ;
              if ( g_var_164 == 2 )
              {
                l_var_23 = (l_var_21 + 1.0) * l_var_12 + l_var_12 ;
              }
              if ( g_var_164 == 3 )
              {
                l_var_23 = l_var_12 * (MathPow(g_var_165,l_var_21 + 1.0)) ;
              }
              if ( g_var_193 == 0 )
              {
                l_var_24 = l_var_17 ;
                if ( MarketInfo(g_var_336,MODE_BID)<l_var_17 )
                {
                  if ( l_var_21>=g_var_166 )
                  {
                    for (tmp_var_20 = OrdersTotal() ; tmp_var_20 >= 0 ; tmp_var_20 = tmp_var_20 - 1)
                    {
                      if ( OrderSelect(tmp_var_20,0,0) != true )   continue;
                      
                      if ( OrderMagicNumber() == g_var_93 && OrderTicket() == l_var_9 )
                      {
                        OrderClose(OrderTicket(),OrderLots(),MarketInfo(g_var_336,MODE_ASK),3,Red); 
                      }
                      if ( OrderMagicNumber() != g_var_169 )   continue;
                      tmp_var_11 = OrderComment();
                      if ( tmp_var_11 != IntegerToString(l_var_9,0,32) )   continue;
                      
                      if ( OrderType() == 0 )
                      {
                        OrderClose(OrderTicket(),OrderLots(),MarketInfo(g_var_336,MODE_BID),g_var_38,Red); 
                      }
                      if ( OrderType() != 1 )   continue;
                      OrderClose(OrderTicket(),OrderLots(),MarketInfo(g_var_336,MODE_ASK),g_var_38,Red); 
                      
                    }
                  }
                  else
                  {
                    OrderSend(g_var_336,1,l_var_23,MarketInfo(g_var_336,MODE_BID),g_var_38,0.0,0.0,IntegerToString(l_var_9,0,32),g_var_169,0,Green); 
                    g_var_193 = 1 ;
                    l_var_22 = true ;
                  }
                }
              }
              else
              {
                l_var_25 = g_var_160 * g_var_229 + l_var_17 - l_var_21 * g_var_161 * g_var_229 ;
                if ( l_var_25<g_var_162 * g_var_229 + l_var_17 )
                {
                  l_var_25 = g_var_162 * g_var_229 + l_var_17 ;
                }
                if ( MarketInfo(g_var_336,MODE_ASK)>l_var_25 )
                {
                  if ( l_var_21>=g_var_166 )
                  {
                    for (tmp_var_21 = OrdersTotal() ; tmp_var_21 >= 0 ; tmp_var_21 = tmp_var_21 - 1)
                    {
                      if ( OrderSelect(tmp_var_21,0,0) != true )   continue;
                      
                      if ( OrderMagicNumber() == g_var_93 && OrderTicket() == l_var_9 )
                      {
                        OrderClose(OrderTicket(),OrderLots(),MarketInfo(g_var_336,MODE_ASK),3,Red); 
                      }
                      if ( OrderMagicNumber() != g_var_169 )   continue;
                      tmp_var_22 = OrderComment();
                      if ( tmp_var_22 != IntegerToString(l_var_9,0,32) )   continue;
                      
                      if ( OrderType() == 0 )
                      {
                        OrderClose(OrderTicket(),OrderLots(),MarketInfo(g_var_336,MODE_BID),g_var_38,Red); 
                      }
                      if ( OrderType() != 1 )   continue;
                      OrderClose(OrderTicket(),OrderLots(),MarketInfo(g_var_336,MODE_ASK),g_var_38,Red); 
                      
                    }
                  }
                  else
                  {
                    OrderSend(g_var_336,0,l_var_23,MarketInfo(g_var_336,MODE_ASK),g_var_38,0.0,0.0,IntegerToString(l_var_9,0,32),g_var_169,0,Green); 
                    g_var_193 = 0 ;
                    l_var_22 = true ;
                  }
                }
              }
            }
          }
          if ( ( l_var_21>0.0 || l_var_22 ) )
          {
            l_var_20 = true ;
          }
        }
        if ( !(l_var_20) )
        {
          if ( ( g_var_63 == 1 || (g_var_63 != 2 && g_var_63 != 3) ) )
          {
            tmp_var_23 = l_var_9;
            tmp_var_24 = g_var_100;
            tmp_var_25 = l_var_10;
            tmp_var_26 = 2;
            tmp_var_27 = 0.0;
            tmp_var_28 = false;
            for (tmp_var_29 = 0 ; tmp_var_29 < g_var_199 ; tmp_var_29 = tmp_var_29 + 1)
            {
              if ( g_var_196[tmp_var_29][0]==tmp_var_23 )
              {
                tmp_var_27 = g_var_196[tmp_var_29][1];
                tmp_var_28 = true;
                break;
              }
            }
            if ( !(tmp_var_28) )
            {
              if ( tmp_var_26 == 1 )
              {
                tmp_var_27 = NormalizeDouble(tmp_var_25 - tmp_var_24 * g_var_229,g_var_190);
              }
              if ( tmp_var_26 == 2 )
              {
                tmp_var_27 = NormalizeDouble(tmp_var_24 * g_var_229 + tmp_var_25,g_var_190);
              }
              for (tmp_var_30 = 0 ; tmp_var_30 < g_var_199 ; tmp_var_30 = tmp_var_30 + 1)
              {
                if ( g_var_196[tmp_var_30][0]==0.0 )
                {
                  g_var_196[tmp_var_30][0] = tmp_var_23;
                  g_var_196[tmp_var_30][1] = tmp_var_27;
                  break;
                }
              }
            }
            g_var_191 = tmp_var_27 ;
            l_var_4 = g_var_191 ;
            if ( MarketInfo(g_var_336,MODE_ASK)>l_var_4 )
            {
              Print("Closing with virtual SL"); 
              RefreshRates(); 
              OrderClose(l_var_9,l_var_12,MarketInfo(g_var_336,MODE_ASK),g_var_1,0xFFFFFFFF); 
              return(true); 
            }
            if ( g_var_125>0.0 && TimeCurrent() >= l_var_13 + g_var_304 && MarketInfo(g_var_336,MODE_ASK)<l_var_7 - g_var_337 - g_var_126 * g_var_229 && MarketInfo(g_var_336,MODE_ASK)>l_var_8 + g_var_309 && NormalizeDouble(MarketInfo(g_var_336,MODE_ASK) + g_var_126 * g_var_229,g_var_190)<l_var_7 )
            {
              l_var_7 = NormalizeDouble(MarketInfo(g_var_336,MODE_ASK) + g_var_126 * g_var_229,g_var_190) ;
              if ( l_var_7>MarketInfo(g_var_336,MODE_ASK) + g_var_221 )
              {
                g_var_230 = OrderModify(l_var_9,l_var_10,l_var_7,l_var_8,0,0xFFFFFFFF) ;
                if ( g_var_230 <= 0 )
                {
                  Print("TrailStop error: \'" + TGR_21(GetLastError()) + "\' when setting trailing Exit_TrailSL_after_X_Minutes_size loss.  Trying again!"); 
                }
                l_var_2 = true ;
              }
            }
            if ( g_var_103>0.0 && MarketInfo(g_var_336,MODE_ASK)<l_var_7 - g_var_337 - (g_var_103 + g_var_106) * g_var_229 && MarketInfo(g_var_336,MODE_ASK)<l_var_5 - g_var_104 * g_var_229 && MarketInfo(g_var_336,MODE_ASK)>l_var_8 + g_var_309 && l_var_7>l_var_10 - g_var_105 * g_var_229 && NormalizeDouble(g_var_103 * g_var_229 + MarketInfo(g_var_336,MODE_ASK),g_var_190)<l_var_7 )
            {
              l_var_7 = NormalizeDouble(MarketInfo(g_var_336,MODE_ASK) + g_var_103 * g_var_229,g_var_190) ;
              if ( l_var_7>MarketInfo(g_var_336,MODE_ASK) + g_var_221 )
              {
                g_var_230 = OrderModify(l_var_9,l_var_10,l_var_7,l_var_8,0,0xFFFFFFFF) ;
                if ( g_var_230 <= 0 )
                {
                  Print("TrailStop error: \'" + TGR_21(GetLastError()) + "\' when setting trailing Exit_stop loss.  Trying again!"); 
                }
                else
                {
                  l_var_26 = NormalizeDouble(g_var_107 / 100.0 * g_var_223[g_var_328],2) ;
                  if ( l_var_26<l_var_12 && l_var_26>=MarketInfo(g_var_336,MODE_LOTSTEP) )
                  {
                    OrderClose(l_var_9,l_var_26,MarketInfo(g_var_336,MODE_ASK),g_var_38,Red); 
                    return(true); 
                  }
                }
                l_var_2 = true ;
              }
            }
            if ( g_var_108>0.0 && MarketInfo(g_var_336,MODE_BID)>NormalizeDouble(g_var_108 * g_var_229 + (l_var_8 + g_var_337),g_var_190) && Bid>NormalizeDouble(g_var_109 * g_var_229 + l_var_5,g_var_190) && MarketInfo(g_var_336,MODE_BID)>l_var_8 + g_var_309 )
            {
              l_var_8 = NormalizeDouble(MarketInfo(g_var_336,MODE_BID) - g_var_108 * g_var_229,g_var_190) ;
              if ( l_var_8<MarketInfo(g_var_336,MODE_BID) - g_var_221 )
              {
                g_var_230 = OrderModify(l_var_9,l_var_10,l_var_7,l_var_8,0,0xFFFFFFFF) ;
                if ( g_var_230 <= 0 )
                {
                  Print("TrailStop error: \'" + TGR_21(GetLastError()) + "\' when setting trailing Exit_TP.  Trying again!"); 
                }
                else
                {
                  l_var_27 = NormalizeDouble(g_var_107 / 100.0 * g_var_223[g_var_328],2) ;
                  if ( l_var_27<l_var_12 && l_var_27>=SymbolInfoDouble(g_var_336,34) )
                  {
                    OrderClose(l_var_9,l_var_27,MarketInfo(g_var_336,MODE_ASK),g_var_38,Red); 
                    return(true); 
                  }
                }
                l_var_2 = true ;
              }
            }
            if ( l_var_19 && g_var_39 == 1 && g_var_41>0.0 && MarketInfo(g_var_336,MODE_ASK)<l_var_7 - g_var_337 - g_var_41 * g_var_229 && MarketInfo(g_var_336,MODE_ASK)<l_var_17 - g_var_40 * g_var_229 && MarketInfo(g_var_336,MODE_ASK)>l_var_8 + g_var_309 && l_var_7>l_var_10 - g_var_42 * g_var_229 && NormalizeDouble(MarketInfo(g_var_336,MODE_ASK) + g_var_41 * g_var_229,g_var_190)<l_var_7 )
            {
              l_var_7 = NormalizeDouble(MarketInfo(g_var_336,MODE_ASK) + g_var_41 * g_var_229,g_var_190) ;
              if ( l_var_7>MarketInfo(g_var_336,MODE_ASK) + g_var_221 )
              {
                g_var_230 = OrderModify(l_var_9,l_var_10,l_var_7,l_var_8,0,0xFFFFFFFF) ;
                if ( g_var_230 <= 0 )
                {
                  Print("TrailStop error: \'" + TGR_21(GetLastError()) + "\' when setting Slip TL.  Trying again!"); 
                }
                else
                {
                  Print("Slippage controle active"); 
                }
                l_var_2 = true ;
              }
            }
            if ( g_var_119 >  0 && g_var_120 >= 0 && UseHL_TrailingSL && g_var_241[g_var_328]<l_var_7 - g_var_221 - g_var_337 && g_var_241[g_var_328]>g_var_121 * g_var_229 + MarketInfo(g_var_336,MODE_ASK) && ( g_var_241[g_var_328]>l_var_10 || !(g_var_116) ) && g_var_241[g_var_328]>g_var_122 * g_var_229 + MarketInfo(g_var_336,MODE_ASK) + g_var_221 + g_var_337 && MarketInfo(g_var_336,MODE_ASK)>l_var_8 + g_var_309 && NormalizeDouble(g_var_241[g_var_328],g_var_190)<l_var_7 )
            {
              l_var_7 = NormalizeDouble(g_var_241[g_var_328],g_var_190) ;
              if ( l_var_7>MarketInfo(g_var_336,MODE_ASK) + g_var_221 )
              {
                g_var_230 = OrderModify(l_var_9,l_var_10,l_var_7,l_var_8,0,0xFFFFFFFF) ;
                if ( g_var_230 <= 0 )
                {
                  Print("error: \'" + TGR_21(GetLastError()) + "\' when modifying stoploss"); 
                }
                l_var_2 = true ;
              }
            }
            if ( g_var_113>0.0 && MarketInfo(g_var_336,MODE_ASK)<l_var_10 - g_var_113 * g_var_229 && l_var_10 - g_var_114 * g_var_229<l_var_7 - g_var_337 && MarketInfo(g_var_336,MODE_ASK)<l_var_10 - g_var_114 * g_var_229 - g_var_221 && MarketInfo(g_var_336,MODE_ASK)>l_var_8 + g_var_309 && NormalizeDouble(l_var_10 - g_var_114 * g_var_229,g_var_190)<l_var_7 )
            {
              l_var_7 = NormalizeDouble(l_var_10 - g_var_114 * g_var_229,g_var_190) ;
              if ( l_var_7>MarketInfo(g_var_336,MODE_ASK) + g_var_221 )
              {
                g_var_230 = OrderModify(l_var_9,l_var_10,l_var_7,l_var_8,0,0xFFFFFFFF) ;
                if ( g_var_230 <= 0 )
                {
                  Print("error when setting breakeven: \'" + TGR_21(GetLastError()) + "\' ..\'Exit_BE_start\' to close to \'Exit_BE_extra_pips\' ..trying again!"); 
                }
                l_var_2 = true ;
              }
            }
            if ( !(l_var_2) && ( g_var_128 == 1 || (g_var_128 == 2 && l_var_7 - g_var_131 * g_var_229>=l_var_5 - g_var_1 - g_var_132 * g_var_229) ) )
            {
              g_var_250 ++;
              if ( MarketInfo(g_var_336,MODE_ASK)<l_var_7 - g_var_131 * g_var_229 - g_var_221 && MarketInfo(g_var_336,MODE_ASK)>l_var_8 + g_var_309 && ( g_var_129==0.0 || MarketInfo(g_var_336,MODE_ASK)<l_var_5 - g_var_247 * g_var_229 ) && g_var_250 >= g_var_130 && NormalizeDouble(l_var_7 - g_var_131 * g_var_229,g_var_190)<l_var_7 )
              {
                g_var_250 = 0 ;
                l_var_7 = NormalizeDouble(l_var_7 - g_var_131 * g_var_229,g_var_190) ;
                OrderModify(l_var_9,l_var_10,l_var_7,l_var_8,0,0xFFFFFFFF); 
                l_var_2 = true ;
              }
            }
            g_var_191 = l_var_7 ;
            if ( MarketInfo(g_var_336,MODE_ASK)>l_var_7 )
            {
              Print("Closing with virtual SL"); 
              RefreshRates(); 
              OrderClose(l_var_9,l_var_12,MarketInfo(g_var_336,MODE_ASK),g_var_1,0xFFFFFFFF); 
              return(true); 
            }
            if ( NormalizeDouble(l_var_4,g_var_190)!=NormalizeDouble(g_var_191,g_var_190) )
            {
              tmp_var_31 = NormalizeDouble(g_var_191,g_var_190);
              tmp_var_32 = l_var_9;
              for (tmp_var_33 = 0 ; tmp_var_33 < g_var_199 ; tmp_var_33 = tmp_var_33 + 1)
              {
                if ( g_var_196[tmp_var_33][0]==tmp_var_32 )
                {
                  g_var_196[tmp_var_33][1] = tmp_var_31;
                  break;
                }
              }
            }
            if ( l_var_2 && g_var_135 )
            {
              return(true); 
            }
          }
          if ( ( g_var_63 == 2 || g_var_63 == 3 ) )
          {
            tmp_var_34 = l_var_9;
            tmp_var_35 = g_var_100;
            tmp_var_36 = l_var_10;
            tmp_var_37 = 2;
            tmp_var_38 = 0.0;
            tmp_var_39 = false;
            for (tmp_var_40 = 0 ; tmp_var_40 < g_var_199 ; tmp_var_40 = tmp_var_40 + 1)
            {
              if ( g_var_196[tmp_var_40][0]==tmp_var_34 )
              {
                tmp_var_38 = g_var_196[tmp_var_40][1];
                tmp_var_39 = true;
                break;
              }
            }
            if ( !(tmp_var_39) )
            {
              if ( tmp_var_37 == 1 )
              {
                tmp_var_38 = NormalizeDouble(tmp_var_36 - tmp_var_35 * g_var_229,g_var_190);
              }
              if ( tmp_var_37 == 2 )
              {
                tmp_var_38 = NormalizeDouble(tmp_var_35 * g_var_229 + tmp_var_36,g_var_190);
              }
              for (tmp_var_41 = 0 ; tmp_var_41 < g_var_199 ; tmp_var_41 = tmp_var_41 + 1)
              {
                if ( g_var_196[tmp_var_41][0]==0.0 )
                {
                  g_var_196[tmp_var_41][0] = tmp_var_34;
                  g_var_196[tmp_var_41][1] = tmp_var_38;
                  break;
                }
              }
            }
            g_var_191 = tmp_var_38 ;
            l_var_4 = g_var_191 ;
            if ( MarketInfo(g_var_336,MODE_ASK)>=l_var_4 )
            {
              RefreshRates(); 
              OrderClose(l_var_9,l_var_12,MarketInfo(g_var_336,MODE_ASK),g_var_1,0xFFFFFFFF); 
              return(true); 
            }
            l_var_28 = TimeCurrent() - g_var_319 ;
            if ( l_var_28 >= g_var_65 )
            {
              if ( NormalizeDouble(g_var_191,g_var_190)<l_var_7 - g_var_337 )
              {
                OrderModify(l_var_9,l_var_10,NormalizeDouble(g_var_191,g_var_190),l_var_8,0,0xFFFFFFFF); 
              }
              g_var_319 = TimeCurrent() ;
            }
            if ( g_var_125>0.0 && TimeCurrent() >= l_var_13 + g_var_304 && MarketInfo(g_var_336,MODE_ASK)<g_var_191 - g_var_337 - g_var_126 * g_var_229 && MarketInfo(g_var_336,MODE_ASK)>l_var_8 + g_var_309 )
            {
              g_var_191 = MarketInfo(g_var_336,MODE_ASK) + g_var_126 * g_var_229 ;
              l_var_2 = true ;
            }
            if ( g_var_103>0.0 && MarketInfo(g_var_336,MODE_ASK)<g_var_191 - g_var_337 - (g_var_103 + g_var_106) * g_var_229 && MarketInfo(g_var_336,MODE_ASK)<l_var_5 - g_var_104 * g_var_229 && g_var_191>l_var_10 - g_var_105 * g_var_229 )
            {
              g_var_191 = g_var_103 * g_var_229 + MarketInfo(g_var_336,MODE_ASK) ;
              l_var_29 = NormalizeDouble(g_var_107 / 100.0 * g_var_223[g_var_328],2) ;
              if ( l_var_29<l_var_12 && l_var_29>=MarketInfo(g_var_336,MODE_LOTSTEP) )
              {
                OrderClose(l_var_9,l_var_29,MarketInfo(g_var_336,MODE_BID),g_var_38,Red); 
                return(true); 
              }
              l_var_2 = true ;
            }
            if ( l_var_19 && g_var_39 == 1 && g_var_41>0.0 && MarketInfo(g_var_336,MODE_ASK)<g_var_191 - g_var_337 - g_var_41 * g_var_229 && MarketInfo(g_var_336,MODE_ASK)<l_var_17 - g_var_40 * g_var_229 && MarketInfo(g_var_336,MODE_ASK)>l_var_8 + g_var_309 && g_var_191>l_var_10 - g_var_42 * g_var_229 )
            {
              Print("Slippage controle active"); 
              l_var_2 = true ;
              g_var_191 = MarketInfo(g_var_336,MODE_ASK) + g_var_41 * g_var_229 ;
            }
            if ( g_var_119 >  0 && g_var_120 >= 0 && g_var_241[g_var_328]<g_var_191 - g_var_221 - g_var_337 && ( g_var_241[g_var_328]>l_var_10 || !(g_var_116) ) && g_var_241[g_var_328]>g_var_122 * g_var_229 + MarketInfo(g_var_336,MODE_ASK) + g_var_221 + g_var_337 && MarketInfo(g_var_336,MODE_ASK)>l_var_8 + g_var_309 )
            {
              g_var_191 = g_var_241[g_var_328] ;
              l_var_2 = true ;
            }
            if ( g_var_113>0.0 && g_var_63 == 3 && MarketInfo(g_var_336,MODE_ASK)<l_var_10 - g_var_113 * g_var_229 && l_var_10 - g_var_114 * g_var_229<l_var_7 - g_var_337 && MarketInfo(g_var_336,MODE_ASK)<l_var_10 - g_var_114 * g_var_229 - g_var_221 && MarketInfo(g_var_336,MODE_ASK)>l_var_8 + g_var_309 && NormalizeDouble(l_var_10 - g_var_114 * g_var_229,g_var_190)<g_var_191 )
            {
              g_var_191 = NormalizeDouble(l_var_10 - g_var_114 * g_var_229,g_var_190) ;
              g_var_230 = OrderModify(l_var_9,l_var_10,g_var_191,l_var_8,0,0xFFFFFFFF) ;
              if ( g_var_230 <= 0 )
              {
                Print("error when setting breakeven: \'" + TGR_21(GetLastError()) + "\' ..\'Exit_BE_start\' to close to \'Exit_BE_extra_pips\' ..trying again!"); 
              }
              l_var_2 = true ;
            }
            if ( g_var_113>0.0 && g_var_63 == 2 && MarketInfo(g_var_336,MODE_ASK)<l_var_10 - g_var_113 * g_var_229 && l_var_10 - g_var_114 * g_var_229<g_var_191 - g_var_337 && MarketInfo(g_var_336,MODE_ASK)<l_var_10 - g_var_114 * g_var_229 - g_var_221 && MarketInfo(g_var_336,MODE_ASK)>l_var_8 + g_var_309 )
            {
              g_var_191 = l_var_10 - g_var_114 * g_var_229 ;
              l_var_2 = true ;
            }
            if ( !(l_var_2) && ( g_var_128 == 1 || (g_var_128 == 2 && g_var_191 - g_var_131 * g_var_229>=l_var_5 - g_var_1 - g_var_132 * g_var_229) ) )
            {
              g_var_250 ++;
              if ( MarketInfo(g_var_336,MODE_ASK)<g_var_191 - g_var_131 * g_var_229 - g_var_221 && MarketInfo(g_var_336,MODE_ASK)>l_var_8 + g_var_309 && ( g_var_129==0.0 || MarketInfo(g_var_336,MODE_ASK)<l_var_5 - g_var_247 * g_var_229 ) && g_var_250 >= g_var_130 )
              {
                g_var_250 = 0 ;
                g_var_191 = g_var_191 - g_var_131 * g_var_229 ;
                l_var_2 = true ;
              }
            }
            if ( MarketInfo(g_var_336,MODE_ASK)>=g_var_191 )
            {
              RefreshRates(); 
              OrderClose(l_var_9,l_var_12,MarketInfo(g_var_336,MODE_ASK),g_var_1,0xFFFFFFFF); 
              return(true); 
            }
            if ( NormalizeDouble(l_var_4,g_var_190)!=NormalizeDouble(g_var_191,g_var_190) )
            {
              tmp_var_42 = NormalizeDouble(g_var_191,g_var_190);
              tmp_var_43 = l_var_9;
              for (tmp_var_44 = 0 ; tmp_var_44 < g_var_199 ; tmp_var_44 = tmp_var_44 + 1)
              {
                if ( g_var_196[tmp_var_44][0]==tmp_var_43 )
                {
                  g_var_196[tmp_var_44][1] = tmp_var_42;
                  break;
                }
              }
            }
          }
        }
      }
      if ( l_var_2 )
      {
        l_var_3 = true ;
      }
    }
    if ( l_var_2 )
    {
      l_var_3 = true ;
    }
  }
  return(l_var_3); 
}
//TGR_19 <<==--------   --------