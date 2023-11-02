var
WinForm : TclForm;
MobileForm : TclGameform;
baslaBtn,bitirBtn : TClProButton;
cekilisTimer,gameTimer,jiroskopTimer : TClTimer;
drawLbl,wordLbl,timerLbl,dogruLbl,pasLbl,puanLbl : TClProLabel;
cekilisDuration,Sound,gameDuration,sn,harekethizi,dogru,pas,puan : Integer;
QMemList : TclJSonQuery;
myDeviceManager : TclDeviceManager;
WinMQTT,MobileMQTT : TclMQTT;
MyWord : String;
myGameEngine : TclGameEngine;
SoundisTrue : Boolean;
DeviceMotionSensor : TClMotionSensor;
konum : TclProImage;
testLabelMin_X,testLabelMax_X : Single;
testLabelMin_Y,testLabelMax_Y : Single;
dogruImg,pasImg,anlatbakalimImg : TClProImage;



    ScoreTblListview : TClProListView;
    ScoreTblDesignerPanel : TClProListViewDesignerPanel;
    PnlScoreTbl,PnlMain,PnlCekilis : TclProPanel;
    LblScoreTitleName,UserName,UserScore,LblCekilisCikanIsim : TClProLabel;
    BtnCekilisYap, BtnSifirla, SortNumber : TclProButton;
    LblMainTitle : TclProImage;
  
    dataStringList : TclStringList;
    sortList:TclStringList;
    nameArr : TclArrayString;
    scoreArr : TclArrayInteger;
    qryPlayersData:TCLJSONQuery;
    jsonStr:string;

void ProcSound;                                 //SES ÇALAN PROSEDÜR
{
  MobileForm.PlayGameSound(Sound);
}

void MemberListMix;
{
  cekilisDuration=0;
  if (CekilisTimer.Enabled == False)
  {
    QMemList = Clomosy.DBCloudQueryWith(ftMembers,'','ISNULL(PMembers.Rec_Deleted,0)=0 ORDER BY NEWID()');     
    QMemList.Filter = 'Member_GUID <> '+QuotedStr('M961J83TO5');  
    QMemList.Filtered = True;                                         
  }                                                 //EXE NİN GUID SİNİ BURAYA YAZINIZ.
  cekilisTimer.Enabled = True;
  LblCekilisCikanIsim.Caption = '';
}
void ProcCekilis;                                         //ÇEKİLİŞ PROSEDÜRÜ
{
  Clomosy.ProcessMessages;
  BtnCekilisYap.Enabled=false;
  if(cekilisDuration==5)
  {
    BtnCekilisYap.Enabled=True;
    cekilisTimer.Enabled=False;
    WinMQTT.Send(QMemList.FieldByName('Member_GUID').AsString);
  }
  LblCekilisCikanIsim.Caption = QMemList.FieldByName('Member_Name').AsString;
  
  QMemList.Next;  
  if (QMemList.EOF)
  {
    QMemList.First;
  }
  Inc(cekilisDuration);
}

void refreshScoreTable;
{
  
    try
    {
      qryPlayersData = TCLJSONQuery.Create(nil);
      qryPlayersData = Clomosy.ClDataSetFromJSON(jsonStr);
      with qryPlayersData do
       {
       ScoreTblListview.clLoadProListViewDataFromDataset(qryPlayersData);
       }
    }
    except
    {
      ShowMessage('Exception Class: '+LastExceptionClassName+' Exception Message: '+LastExceptionMessage);
    }
  
  
  
   
}

void kazananClick
var
  i,j,tempIScore,TempScore, tempJScore :Integer;
  tempI,tempJ,TempName,tempIName, tempJName : String;
  ListI, ListJ:TclStringList;
{
  ListI = Clomosy.StringListNew;
  ListI.Delimiter = '=';
  
  ListJ = Clomosy.StringListNew;
  ListJ.Delimiter = '=';
   
  nameArr.RemoveAll;
  scoreArr.RemoveAll;
  
  //DİZİLERE İSİM VE PUANLAR TUTULDU.
  for (i = 0 to dataStringList.Count-1)
  {
      tempI = Clomosy.StringListItemString(dataStringList,i);
      ListI.DelimitedText = tempI;
    
      tempIScore = StrToInt(Clomosy.StringListItemString(ListI,1));
      tempIName = Clomosy.StringListItemString(ListI,0);
      
      nameArr.Add(tempIName);
      scoreArr.Add(tempIScore);
  }
  
  //SIRALAMAAA
  for (i = 0 to scoreArr.Count-1)
  {
    for (j = i+1 to scoreArr.Count-1)
    {
      //ShowMessage(scoreArr.GetItem(i));
      //ShowMessage(scoreArr.GetItem(j));
      
      if scoreArr.GetItem(i) < scoreArr.GetItem(j)
      {
        TempScore = scoreArr.GetItem(i);
        scoreArr.SetItem(i,scoreArr.GetItem(j));
        scoreArr.SetItem(j,TempScore);
        
        TempName = nameArr.GetItem(i);
        nameArr.SetItem(i,nameArr.GetItem(j));
        nameArr.SetItem(j,TempName);
      }
    }
  }
  //scoreMemo.Lines.Clear;
  dataStringList.Clear;
  jsonStr = '';
  jsonStr = '[';
  for (j= 0 to nameArr.Count-1)
  {
    dataStringList.Add(nameArr.GetItem(j)+' = '+IntToStr(scoreArr.GetItem(j))); //'+QuotedStr('https://clomosy.com/demos/explain_iron.png')+'
    jsonStr = jsonStr+'{"SortNumber":'+IntToStr(j+1)+'';
    jsonStr = jsonStr+',"UserName":"'+nameArr.GetItem(j)+'"';
    if (j == nameArr.Count-1)
    {
      jsonStr = jsonStr+',"UserScore":'+IntToStr(scoreArr.GetItem(j))+'}';
    }else
    {
      jsonStr = jsonStr+',"UserScore":'+IntToStr(scoreArr.GetItem(j))+'},';
    }
    
      
  }
  jsonStr = jsonStr+ ']';
  refreshScoreTable;
} 

void DeleteMemberList;
{
  ShowMessage('1');
  jsonStr = '[]';
  ShowMessage('2');
  refreshScoreTable;
  ShowMessage('3');
}

void WinMQTTPublishReceived;
{
  if(Not WinMQTT.Connected)         //MQTT BAĞLANTISI YOKSA TEKRAR BAĞLANAN PROSEDÜR
  {
    WinMQTT.Connect;
  }
  
  If (WinMQTT.ReceivedAlright)
  {
    dataStringList.Add(WinMQTT.ReceivedMessage);
    kazananClick;
      //scoreMemo.Lines.Add(SendMQTT.ReceivedMessage);
  }
}
void MobileMQTTPublishReceived;
{
  if(Not MobileMQTT.Connected)
  {
    MobileMQTT.Connect;
  }
  If (MobileMQTT.ReceivedAlright)
  {
    if(MobileMQTT.ReceivedMessage == Clomosy.AppUserGUID)
    {
      ShowMessage('Çeklişte sen çıktın');
      myDeviceManager.Vibrate(500);
      baslaBtn.Visible = True;
    }
    else
    {
      anlatbakalimImg.Visible = True;
      baslaBtn.Visible = False;
      wordLbl.Visible = False;
    }
  }
  
}
void createWord;                                              //KELİME ÜRETEN PROSEDÜR
{
  
  if(SoundisTrue)
  {
    ProcSound;
    SoundisTrue=False;
  }
  //TclButton(MobileForm.clFindComponent('BtnGoBack')).Visible=false;
  clComponent.SetupComponent(wordLbl,'{"TextSize":100}');
  MobileForm.SetFormBGImage('https://clomosy.com/demos/explain_bg2.png');
  anlatbakalimImg.Visible = False;
  gameTimer.Enabled = True;
  DeviceMotionSensor.Active = True;
  jiroskopTimer.Enabled = True;
  dogruImg.Visible = false;
  pasImg.Visible = false;
  timerLbl.Visible = True;
  myGameEngine = TclGameEngine.Create;
  MyWord = MyGameEngine.WordService('GETWORD:5','forkids');
  With Clomosy.ClDataSetFromJSON(MyWord) Do 
  {
      MyWord = FieldByName('Word').AsString;
      MyWord = AnsiUpperCase(MyWord);
      wordLbl.Visible = True;
      wordLbl.Caption=MyWord;
  }
}
void TrueBeforeSleep;                              //SLEEP ÖNCESİ DOĞRU İSE YAPILACAK İŞLEMLER PROSEDÜR
{ 
  myDeviceManager.Vibrate(50);
  jiroskopTimer.Enabled=False;
  gameTimer.Enabled=False;
  timerLbl.Visible=False;
  wordLbl.Visible = False;
  dogruImg.Visible = true;
  MobileForm.SetFormColor('#008d36','',clGNone);
  Inc(dogru);
  konum.Position.X = AlCenter;
  konum.Position.X = MobileForm.clWidth/2;
}
void FalseBeforeSleep;                            //SLEEP ÖNCESİ DOĞRU İSE YAPILACAK İŞLEMLER PROSEDÜR
{ 
  myDeviceManager.Vibrate(50);
  jiroskopTimer.Enabled=False;
  gameTimer.Enabled=False;
  timerLbl.Visible=False;
  wordLbl.Visible = False;
  pasImg.Visible = True;
  MobileForm.SetFormColor('#e20613','',clGNone);
  Inc(pas);
  konum.Position.X = AlCenter;
  konum.Position.X = MobileForm.clWidth/2;
}
void TrueOrFalseAfter;                                  //DOĞRU VEYA PAS YAPILDIKTAN SONRA YAPILACAK OLAN İŞLEMLER
{
  jiroskopTimer.Enabled=True;
  timerLbl.Visible=True;
  gameTimer.Enabled=True;
  createWord;
}
void beforeSleep;
{
  anlatbakalimImg.Visible=False;
  baslaBtn.Visible = False;
  clComponent.SetupComponent(wordLbl,'{"TextSize":45}');
  wordLbl.Caption='Oyun Başlıyor...';
  wordLbl.Visible = True;
  gameDuration=15;                             //OYUN SÜRESİ
  SoundisTrue=True;
}
void procSleep;                               //OYUN BAŞLARKEN BEKLEMEK İÇİN
{
  Clomosy.SleepAndCall(3000,'beforeSleep','createWord');
}
void bitirBtnClick;
{
  dogruLbl.Visible=False;
  pasLbl.Visible=False;
  puanLbl.Visible=False;
  bitirBtn.Visible=False;
  anlatbakalimImg.Visible=True;
  
}
void sonuclar;
{
  puan=((dogru*2)-(pas));
  dogruLbl.Caption='Doğru: '+IntToStr(dogru);
  pasLbl.Caption='Pas: '+IntToStr(pas);
  puanLbl.Caption='Puan: '+IntToStr(puan);
  bitirBtn.Visible=True;
  dogruLbl.Visible=True;
  pasLbl.Visible=True;
  puanLbl.Visible=True;
  MobileMQTT.Send(Clomosy.AppUserDisplayName+' = '+IntToStr(puan));
}
void timerShow;                                  // OYUN SÜRESİNİN EKRANA YAZILDIĞI PROSEDÜR
{
   gameTimer.Enabled = False;
   if (gameDuration == 0)                         //OYUN SÜRESİ BİTTİ İSE
   {
     //TclButton(MobileForm.clFindComponent('BtnGoBack')).Visible=True;
     MobileForm.SetFormBGImage('https://clomosy.com/demos/explain_bg.png');
     jiroskopTimer.Enabled = False;
     gameTimer.Enabled = False;
     DeviceMotionSensor.Active = False;
     wordLbl.Caption='';
     ProcSound;
     timerLbl.Caption = '';
     sonuclar;
     dogru=0;
     pas=0;
   }
   else //süre devam ediyorsa
   {
     Dec(gameDuration);
     sn = gameDuration;
     timerLbl.Caption = 'Süre: '+IntToStr(sn);
     gameTimer.Enabled = True;
   }
}
void procJiroskop;                                  //JİROSKOP PROSEDÜRÜ
const 
  harekethizi = 20;
{
  if(Clomosy.PlatformIsMobile == true)
  {
    if (MobileForm.clWidth<MobileForm.clHeight)//EKRAN DİKEY İSE
    {
      Case DeviceMotionSensor.GetDirectionX of {
      1:
      {
        konum.Position.X = konum.Position.X - harekethizi;
      }
      2:
      {
        konum.Position.X = konum.Position.X + harekethizi;
      }
      }
      if (konum.Position.X <= 0)  // ekran sol kenar taşma
      {
        Clomosy.SleepAndCall(2000,'TrueBeforeSleep','TrueOrFalseAfter');
      }
      else if (konum.Position.X >= MobileForm.clWidth) // ekran sağ kenar taşma
      {
        Clomosy.SleepAndCall(2000,'FalseBeforeSleep','TrueOrFalseAfter');
      }
    }
    else //ekran yatay ise
    {
      Case DeviceMotionSensor.GetDirectionY of 
      {
      1:
      {
        konum.Position.X = konum.Position.X - harekethizi;
      }
      2:
      {
        konum.Position.X = konum.Position.X + harekethizi;
      }
      }
      if (konum.Position.X <= 0)  // ekran sol kenar taşma
      {
        Clomosy.SleepAndCall(1000,'TrueBeforeSleep','TrueOrFalseAfter');
      }
      if (konum.Position.X >= MobileForm.clWidth) // ekran sağ kenar taşma
      {
        Clomosy.SleepAndCall(1000,'FalseBeforeSleep','TrueOrFalseAfter');
      }
    }
  }
}

void createDesignerPnlScreen
{
  //SIRALAMA NUMARASI
  SortNumber = WinForm.AddNewProButton(ScoreTblDesignerPanel,'SortNumber','');
  clComponent.SetupComponent(SortNumber,'{"Align" : "MostLeft","Width":70,"TextSize":25,"MarginLeft":10,"MarginTop":10,"MarginBottom":10,
  "TextVerticalAlign":"center", "TextHorizontalAlign":"center","TextBold":"yes","ImgUrl":"https://clomosy.com/demos/explain_iron.png","ImgFit":"yes"}'); //+IntToStr((ScoreTblDesignerPanel.Width*60)/100)+
  ScoreTblDesignerPanel.AddPanelObject(SortNumber,clText);
  
  
  //OYUNCU İSİM
  UserName = WinForm.AddNewProLabel(ScoreTblDesignerPanel,'UserName','Oyuncu İsim');
  clComponent.SetupComponent(UserName,'{"Align" : "Client","TextSize":18,"MarginLeft":10,
  "TextVerticalAlign":"center", "TextHorizontalAlign":"left","TextBold":"yes"}');
  ScoreTblDesignerPanel.AddPanelObject(UserName,clText1);
  UserName.Properties.AutoSize = True;
  
  //OYUNCU PUAN
  UserScore = WinForm.AddNewProLabel(ScoreTblDesignerPanel,'UserScore','Oyuncu Puan');
  clComponent.SetupComponent(UserScore,'{"Align" : "Right","TextSize":18,
  "TextVerticalAlign":"center", "TextHorizontalAlign":"center","TextBold":"yes","Width":60,"MarginRight":10}');
  ScoreTblDesignerPanel.AddPanelObject(UserScore,clText2);
  
  //AddDataToProListView;
}

void scoreTablePnlScreen
{
  LblScoreTitleName = WinForm.AddNewProLabel(PnlScoreTbl,'LblScoreTitleName','SKOR TABLOSU');
  clComponent.SetupComponent(LblScoreTitleName,'{"Align" : "MostTop","MarginTop":10,"MarginRight":5,"MarginLeft":5,"Height":40,"TextColor":"#000000","TextSize":20,"TextBold":"yes",
  "TextVerticalAlign":"center", "TextHorizontalAlign":"center","BorderColor":"#fbb03b","BorderWidth":3,"RoundHeight":10,"RoundWidth":10,"BackgroundColor":"#ffffff"}');
  
  ScoreTblListview = WinForm.AddNewProListView(PnlScoreTbl,'ScoreTblListview');
  ScoreTblListview.Properties.ItemSpace = 10;
  clComponent.SetupComponent(ScoreTblListview,'{"Align":"Client","MarginBottom":5,"MarginTop":5,"MarginRight":5,"MarginLeft":5,
  "ListType":"Cart","ItemColumnCount" : 1,"ItemHeight" : 80,"BorderColor":"#fbb03b", "BorderWidth":2,"RoundWidth":5, "RoundHeight":5,"BackgroundColor":"null"}');
  ScoreTblListview.SelfOwnMaterial.IsTransparent = False;
  ScoreTblListview.SelfOwnMaterial.BackColor.IsFill = True;
  ScoreTblListview.ListType = 'vertical';
  
  ScoreTblDesignerPanel = WinForm.AddNewProListViewDesignerPanel(ScoreTblListview,'ScoreTblDesignerPanel'); 
  clComponent.SetupComponent(ScoreTblDesignerPanel,'{"Align":"Top","Height":100,"BackgroundColor":"#ffffff","BorderColor":"null","BorderWidth":2,"RoundHeight":20,"RoundWidth":20}');
  ScoreTblListview.SetDesignerPanel(ScoreTblDesignerPanel);
  
  //DESİGNERPANEL İÇİNDEKİLER
  createDesignerPnlScreen;
}

{ //MAIN
  SoundisTrue=True;
  dogru=0;
  pas=0;

  
  if(not Clomosy.PlatformIsMobile)//WİN İSE
  {
    WinForm=TclForm.Create(self);
    WinForm.SetFormColor('#ad1c0b','#fd5a3b',clGVertical);
    
    dataStringList = Clomosy.StringListNew;
    sortList = Clomosy.StringListNew;
    nameArr = TClArrayString.Create;
    scoreArr = TClArrayInteger.Create;
      WinMQTT = WinForm.AddNewMQTTConnection(WinForm,'WinMQTT');
      WinForm.AddNewEvent(WinMQTT,tbeOnMQTTPublishReceived,'WinMQTTPublishReceived');
      WinMQTT.Channel = 'cekilis'; //project guid + channel
      WinMQTT.Connect;
    
    
    cekilisTimer= WinForm.AddNewTimer(WinForm,'CekilisTimer',100);
    cekilisTimer.Enabled = False;
    WinForm.AddNewEvent(cekilisTimer,tbeOnTimer,'ProcCekilis');
    
    
    LblMainTitle = WinForm.AddNewProImage(WinForm,'LblMainTitle');
    clComponent.SetupComponent(LblMainTitle,'{"Align" : "MostTop","MarginTop":10,"Height":80,
    "ImgUrl":"https://clomosy.com/demos/explain_title1.png", "ImgFit":"yes"}');
    
    //ANA PANEL
    PnlMain=WinForm.AddNewProPanel(WinForm,'PnlMain');
    clComponent.SetupComponent(PnlMain,'{"Align" : "Client"}');
    
    //SKOR TABLOSU PANELİ
    PnlScoreTbl=WinForm.AddNewProPanel(PnlMain,'PnlScoreTbl');
    clComponent.SetupComponent(PnlScoreTbl,'{"Align" : "Client","MarginLeft":10,"MarginRight":10}');
    
    
    //ÇEKİLİŞ BTUONLAR VE KİŞİ PANELİ
    PnlCekilis=WinForm.AddNewProPanel(PnlMain,'PnlCekilis');
    clComponent.SetupComponent(PnlCekilis,'{"Align" : "Right","MarginLeft":10,"MarginRight":10,"Width" :'+IntToStr((PnlMain.Width*40)/100)+'}');
    
    //SKOR TABLOSU PANEL İÇİ
    scoreTablePnlScreen;
    
    //ÇEKİLİŞ PANEL İÇİ
    LblCekilisCikanIsim = WinForm.AddNewProLabel(PnlCekilis,'LblCekilisCikanIsim','ÇEKİLEN OYUNCU');
    clComponent.SetupComponent(LblCekilisCikanIsim,'{"Align" : "MostTop","MarginTop":70,"Height":'+IntToStr(LblCekilisCikanIsim.Height*2)+',"TextColor":"#ffffff","TextSize":24,
    "TextVerticalAlign":"center", "TextHorizontalAlign":"center","TextBold":"yes","RoundHeight":10, "RoundWidth":10,"BorderColor":"#fbb03b","BorderWidth":3,"BackgroundColor":"null"}');
    
    BtnCekilisYap = WinForm.AddNewProButton(PnlCekilis,'BtnCekilisYap','ÇEKİLİŞ YAP');
    clComponent.SetupComponent(BtnCekilisYap,'{"Align" : "Top","MarginTop":100,"MarginLeft":20,"MarginRight":20,"Height":50,"RoundHeight":10, "RoundWidth":10,"BorderColor":"#fbb03b","BorderWidth":3,"BackgroundColor":"#ffffff","TextColor":"#000000","TextSize":20,"TextBold":"yes"}');
    WinForm.AddNewEvent(BtnCekilisYap,tbeOnClick,'MemberListMix');
    
    //BtnSifirla = WinForm.AddNewProButton(PnlCekilis,'BtnSifirla','SIFIRLA');
    //clComponent.SetupComponent(BtnSifirla,'{"Align" : "Top","MarginTop":20,"MarginLeft":20,"MarginRight":20,"Height":50,"RoundHeight":10, "RoundWidth":10,"BorderColor":"#fbb03b","BorderWidth":3,"BackgroundColor":"#ffffff","TextColor":"#000000","TextSize":20,"TextBold":"yes"}');
    //WinForm.AddNewEvent(BtnSifirla,tbeOnClick,'DeleteMemberList');
    
    
  
    WinForm.Run;
  }
  else                                            //MOBİLE İSE
  {
    myDeviceManager=TclDeviceManager.Create;
    
    MobileForm=TclGameform.Create(self);
    MobileForm.SetFormBGImage('https://clomosy.com/demos/explain_bg.png');
    
    MobileForm.LytTopBar.Visible=True;
    //TclProButton(MobileForm.clFindComponent('BtnGoBack')).Visible=True;
    
    MobileMQTT = MobileForm.AddNewMQTTConnection(MobileForm,'MobileMQTT');
    MobileForm.AddNewEvent(MobileMQTT,tbeOnMQTTPublishReceived,'MobileMQTTPublishReceived');
    MobileMQTT.Channel = 'cekilis';//project guid + channel
    MobileMQTT.Connect;
    
    baslaBtn = MobileForm.AddNewProButton(MobileForm,'baslaBtn','Başla');
    clComponent.SetupComponent(baslaBtn,'{"TextColor":"#ffffff","Height":100,"Width":50,"TextSize":25,"Align" : "MostBottom"}');
    MobileForm.AddNewEvent(baslaBtn,tbeOnClick,'procSleep');
    baslaBtn.Visible=false;
    
    bitirBtn = MobileForm.AddNewProButton(MobileForm,'bitirBtn','Bitir');
    clComponent.SetupComponent(bitirBtn,'{"TextColor":"#ffffff","Height":100,"Width":50,"TextSize":25,"Align" : "MostBottom"}');
    MobileForm.AddNewEvent(bitirBtn,tbeOnClick,'bitirBtnClick');
    bitirBtn.Visible=false;
    
    
    wordLbl = MobileForm.AddNewProLabel(MobileForm,'wordLbl','Anlatılacak Kelime');
    clComponent.SetupComponent(wordLbl,'{"TextVerticalAlign":"center", "TextHorizontalAlign":"center","Align" : "Center","TextColor": "#ffffff","Height":400,"Width":400,"TextSize":100}');
    wordLbl.Visible=False;
    
    timerLbl = MobileForm.AddNewProLabel(MobileForm,'timerLbl','');
    clComponent.SetupComponent(timerLbl,'{"TextVerticalAlign":"center", "TextHorizontalAlign":"center","Align" : "MostBottom","TextColor":"#ffffff","Height":100,"Width":50,"TextSize":25}');
    timerLbl.Visible = False;
    
    dogruLbl = MobileForm.AddNewProLabel(MobileForm,'dogruLbl','');
    clComponent.SetupComponent(dogruLbl,'{"TextVerticalAlign":"center", "TextHorizontalAlign":"center","MarginTop" : 50,"TextColor":"#ffffff","Height":150,"Width":150,"TextSize":20}');
    dogruLbl.Visible = False;
    
    pasLbl = MobileForm.AddNewProLabel(MobileForm,'pasLbl','');
    clComponent.SetupComponent(pasLbl,'{"TextVerticalAlign":"center", "TextHorizontalAlign":"center","MarginTop" : 100,"TextColor":"#ffffff","Height":150,"Width":150,"TextSize":20}');
    pasLbl.Visible = False;
    
    puanLbl = MobileForm.AddNewProLabel(MobileForm,'puanLbl','');
    clComponent.SetupComponent(puanLbl,'{"TextVerticalAlign":"center", "TextHorizontalAlign":"center","MarginTop" : 150,"TextColor":"#ffffff","Height":150,"Width":150,"TextSize":25}');
    puanLbl.Visible = False;
    
    
    MobileForm.AddGameAssetFromUrl('https://www.clomosy.com/game/assets/Win.wav');
    Sound = MobileForm.RegisterSound('Win.wav');
    MobileForm.PlayGameSound(Sound);
    MobileForm.SoundIsActive=True;
    
    DeviceMotionSensor = MobileForm.AddNewSensorsMotion(MobileForm,'DeviceMotionSensor');
    DeviceMotionSensor.Active = True;
    
    gameTimer= MobileForm.AddNewTimer(MobileForm,'gameTimer',1000);//ilk oyunda timer ı newliyoruz
    gameTimer.Enabled = False;
    MobileForm.AddNewEvent(gameTimer,tbeOnTimer,'timerShow');
    
    jiroskopTimer = MobileForm.AddNewTimer(MobileForm,'jiroskopTimer',300);
    jiroskopTimer.Interval = 40;
    MobileForm.AddNewEvent(jiroskopTimer,tbeOnTimer,'procJiroskop');
    
    konum = MobileForm.AddNewProImage(MobileForm,'konum');
    konum.clSetImage('https://clomosy.com/educa/ufo.png');
    konum.Width = 1;
    //konum.Align = AlCenter;
    
    testLabelMin_X = konum.Position.X;
    testLabelMax_X = testLabelMin_X + konum.Width;
    
    konum.Align = alNone;
    
    dogruImg = MobileForm.AddNewProImage(MobileForm,'dogruImg');
    clComponent.SetupComponent(dogruImg,'{"Align" : "Center","Height":200,"Width":200,"ImgUrl":"https://clomosy.com/demos/ThumbsUp.png", "ImgFit":"yes"}');
    dogruImg.Visible = false;
  
    pasImg = MobileForm.AddNewProImage(MobileForm,'pasImg');
    clComponent.SetupComponent(pasImg,'{"Align" : "Center","Height":200,"Width":200,"ImgUrl":"https://clomosy.com/demos/ThumbsDown.png", "ImgFit":"yes"}');
    pasImg.Visible = false;
    
    anlatbakalimImg = MobileForm.AddNewProImage(MobileForm,'anlatbakalimImg');
    clComponent.SetupComponent(anlatbakalimImg,'{"Align" : "Center","Height":200,"Width":200,"ImgUrl":"https://clomosy.com/demos/explain_title.png", "ImgFit":"yes"}');
    
    MobileForm.Run;
  }
}