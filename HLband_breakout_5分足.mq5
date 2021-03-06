//+------------------------------------------------------------------+
//|                                              HLband_breakout2.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
//共通ライブラリ
#include <LibEA.mqh>

//-- トレンド計算のEMA期間手仕舞い 
input int FastMAPeriod = 20; //短期移動平均の期間
//input int SlowMAPeriod = 40; //長期移動平均の期間
input ENUM_TIMEFRAMES InpMATF = PERIOD_M30;   //移動平均線の時間足

//---ATRのパラメータ
//input ENUM_TIMEFRAMES InpATRTF = PERIOD_H1;   //ATRトレンド決定の時間足
//input int             InpATRPeriod  =100;           // ATR期間
//input double          InpATRCoeff   =1.5;          //レンジを決定するためのATR 係数

//---HLのパラメータ仕掛け
input ENUM_TIMEFRAMES InpHLTF = PERIOD_H1;   //HLトレンド決定の時間足
input int HLBandPeriod1 = 100; //HLバンドの期間
input int HLBandPeriod2=  10000; //HLバンドの期間
input double saipips = 10; // ミドルとの差異pips
input uint UPsaipips = 100; // ミドルとの差異pips
input uint DOWNsaipips = 10; // ミドルとの差異pips
//--- ボリバンチャネルパラメータ
input ENUM_TIMEFRAMES InpBBTF = PERIOD_M30;   //ボリンジャー値計算の時間足
input int InpBBPeriod = 20; //ボリンジャーバンド期間
input double InpBBDeviation = 2.0; //偏差

//含み益含み損益による決済用
input int TPpips = 200;       //利食い 値幅( pips)
input int SLpips = 50;       //損 切り 値幅( pips) 
input double TSpips = 80;    //建値ストップロス(pips)
input double nigepips = 40;  //建値逃げる(pips)
int profitpips = 0;
int maxpips0 = 0;
int minpips0 = 0;
int maxpips1 = 0;
int minpips1 = 0;
int maxpips2 = 0;
int minpips2 = 0;
int maxpips3 = 0;
int minpips3 = 0;
int maxpips4 = 0;
int minpips4 = 0;
int maxpips5 = 0;
int minpips5 = 0;

//試しに使ってみる
int noentry = 0;
double Lots = 0.1;
double HighLowRange = 0;
input int WaitMin = 60;   //待機時間(分)

//決済注文用コメント
string closecomment = "";

//ティック時実行関数
void Tick()
{
   //損切り・利食い決済
   if(isNewBar(_Symbol, PERIOD_M1)) //１分足の始値で判別
     {
     
   //トレイリングストップのセット
   //false ポジションがオープンした直後に、TSpipspipsだけ損失となる損切り注文をセットします。
   //true ポジションにTSpipspipsの含み益が発生するまで損切り注文をセットしません。
      TateneSetTrailingStop(true,0);
      TateneSetTrailingStop(true,1);
      TateneSetTrailingStop(true,2);
      TateneSetTrailingStop(true,3);
      TateneSetTrailingStop(true,4);
      TateneSetTrailingStop(true,5);     

      int sig_entry = EntrySignal(); //仕掛けシグナル
      int sig_filter = 0;
      if( sig_entry != 0 ) sig_filter = FilterSignal(sig_entry); //仕掛けフィルタ
      if( sig_filter != 0 )noentry = 1;
      int sig_exit = ExitSignal(); //手仕舞いシグナル
   //成行売買
   //ポジション0の成行売買
      MyOrderSendMarket( sig_filter, sig_exit, Lots, 0);
   //ポジション1の成行売買
      MyOrderSendMarket(WaitSignal(sig_filter, WaitMin, 0), sig_exit, Lots, 1);
   //ポジション2の成行売買
      MyOrderSendMarket(WaitSignal(sig_filter, WaitMin, 1), sig_exit, Lots, 2);
   //ポジション3の成行売買
      MyOrderSendMarket(WaitSignal(sig_filter, WaitMin, 2), sig_exit, Lots, 3);
   //ポジション4の成行売買
      MyOrderSendMarket(WaitSignal(sig_filter, WaitMin, 3), sig_exit, Lots, 4);
   //ポジション5の成行売買
      MyOrderSendMarket(WaitSignal(sig_filter, WaitMin, 4), sig_exit, Lots, 5);

   //決済後は、一度ミドルにタッチしないと発注をさせない
   if( noentry == 1 )
     {
      double iMALine = iMA(_Symbol, InpMATF, 20, 0, MODE_SMA, PRICE_CLOSE, 1);
      double   High1  = iHigh(Symbol(),PERIOD_M1,1); 
      double   Low1  = iLow(Symbol(),PERIOD_M1,1); 
      if(High1 >= iMALine && Low1 < iMALine )noentry = 0;
     }
   }
}


//仕掛けシグナル関数
int EntrySignal()
{

   //２本前のHLバンド
   double Hline2 = iCustom(_Symbol, InpHLTF, "MTF_HLBand",HLBandPeriod1,HLBandPeriod2,0,STO_LOWHIGH,InpHLTF, 0, 2); //短期
   double Lline2 = iCustom(_Symbol, InpHLTF, "MTF_HLBand",HLBandPeriod1,HLBandPeriod2,0,STO_LOWHIGH,InpHLTF, 1, 2); //短期
//   Comment("noentry/" + noentry ,
//           "Hline" + Hline2 );
     double   Close1  = iClose(Symbol(),PERIOD_M1,1); 
     double   Close2  = iClose(Symbol(),PERIOD_M1,2); 
   
   int ret = 0; //シグナルの初期化

   //買いシグナル
   if(Close2 <= Hline2 && Close1 > Hline2) ret = 1;
   //売りシグナル
   if(Close2 >= Lline2 && Close1 < Lline2) ret = -1;

/*
   //高値　安値がミドルから離れていると、損失が多くなるため20pipsいないに限定
   if( ret == 1 ){   
      double iMALine = iMA(_Symbol, InpMATF, 20, 0, MODE_SMA, PRICE_CLOSE, 1);
      double sai = PriceToPips(Hline2 - iMALine);
      if( sai > saipips && sai > 10 ) ret = 0;
   }
   if( ret == -1 ){   
      double iMALine = iMA(_Symbol, InpMATF, 20, 0, MODE_SMA, PRICE_CLOSE, 1);
      double sai = PriceToPips(iMALine - Lline2);
      if( sai > saipips && sai > 10 ) ret = 0;
   }


   //長期高値安値と同じプライスはエントリしない
   if( ret == 1 ){   
      double Hline3 = iCustom(_Symbol, InpHLTF, "MTF_HLBand",HLBandPeriod1,HLBandPeriod2,0,STO_LOWHIGH,InpHLTF, 2, 2); //長期
      uint HLsai = (uint)PriceToPips(Hline3 - Hline2);
      if( HLsai > UPsaipips || HLsai < DOWNsaipips ) ret = 0;
   }
   if( ret == -1 ){   
      double Lline3 = iCustom(_Symbol, InpHLTF, "MTF_HLBand",HLBandPeriod1,HLBandPeriod2,0,STO_LOWHIGH,InpHLTF, 3, 2); //長期
      uint HLsai = (uint)PriceToPips(Lline3 - Lline2);
      if( HLsai > UPsaipips || HLsai < DOWNsaipips ) ret = 0;
   }
*/

   if( noentry == 1 ) ret = 0;

   Comment( noentry,"高値" + (string)Hline2, " /安値" + (string)Lline2,"\n"
            "Close2" + (string)Close2," /Close1" + (string)Close1,"\n"
            );
            

   return ret; //シグナルの出力

}

//仕掛けフィルタ関数
int FilterSignal(int signal)
{
/*
   double BB_UPPER1 = iBands(_Symbol, InpBBTF, InpBBPeriod, InpBBDeviation, 0, PRICE_CLOSE, MODE_UPPER,1);
   double BB_LOWER1 = iBands(_Symbol, InpBBTF, InpBBPeriod, InpBBDeviation, 0, PRICE_CLOSE, MODE_LOWER,1);
// チャネルが狭すぎる場合に true を返す (レンジ表示) |

//--- 最後に完了した足の ATR 値を取得
   double atr = iATR(_Symbol,InpATRTF,InpATRPeriod, 1);
   int ret = 0; //シグナルの初期化

//--- チャネルの境界線を取得
   double ExtChannelRange = BB_UPPER1 - BB_LOWER1;
//---チャネル幅が ATR*係数より小さい場合はレンジ
   if( ExtChannelRange < (InpATRCoeff * atr )) ret = signal;
*/
//   return ret;
   return signal; //シグナルの出力★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★
}

//----------------
//手仕舞いシグナル関数
//
int ExitSignal()
{
   int ret = 0; //シグナルの初期化

   //１本前のHLバンド
//   double Hline1 = iCustom(_Symbol, InpHLTF, "HLBand", ExitPeriod, MODE_UPPER, 1);
//   double Lline1 = iCustom(_Symbol, InpHLTF, "HLBand", ExitPeriod, MODE_LOWER, 1);
     double   High1  = iHigh(Symbol(),PERIOD_M1,1); 
     double   High2  = iHigh(Symbol(),PERIOD_M1,2); 
     double   Low1  = iLow(Symbol(),PERIOD_M1,1); 
     double   Low2  = iLow(Symbol(),PERIOD_M1,2); 
//     double   High1_H1  = iHigh(Symbol(),PERIOD_H1,1); 
//     double   High2_H1  = iHigh(Symbol(),PERIOD_H1,2); 
//     double   Low1_H1  = iLow(Symbol(),PERIOD_H1,1); 
//     double   Low2_H1  = iLow(Symbol(),PERIOD_H1,2); 

   double MA_M1 = iMA(_Symbol, InpMATF, 20, 0, MODE_SMA, PRICE_CLOSE, 1);
//   double MA_H1 = iMA(_Symbol, PERIOD_H1, 20, 0, MODE_SMA, PRICE_CLOSE, 1);

   //売ったがうまくいかず買い決済
   if( Low2 < MA_M1 && High1 >= MA_M1) ret = 1;  //
//   if( Low2_H1 < MA_H1 && High1_H1 >= MA_H1) MyOrderClose(0);  //
   //買ったがうまくいかず売り決済
   if( High2 > MA_M1 && Low1 <= MA_M1) ret = -1;
//   if( High2_H1 > MA_H1 && Low1_H1 <= MA_H1) MyOrderClose(0);
   return ret; //シグナルの出力
}