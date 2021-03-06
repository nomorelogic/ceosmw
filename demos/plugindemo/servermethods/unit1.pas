unit Unit1;

{$mode objfpc}{$H+}

interface


uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  Spin, ComCtrls, ceosserver, jsonparser, ceostypes, // fpjson,
  fphttpserver, db, BufDataset
  , ceosservermethods
  , ceospluginmethods
  {$IFDEF PLUGIN_VIA_DYNAMICDLL}
  ,DynLibs
  {$ENDIF}

  {$IFDEF PLUGIN_VIA_USES}
  , ceostestplugin
  {$ENDIF}
  ;

type

  { TForm1 }

  TForm1 = class(TForm)
    btnStart: TButton;
    btnStop: TButton;
    btnClear: TButton;
    DatasetDemo: TBufDataset;
    cbxRequestsCount: TCheckBox;
    CeosServer1: TCeosServer;
    cbxVerbose: TCheckBox;
    DatasetDemoCODIGO: TLongintField;
    DatasetDemoIDADE: TLongintField;
    DatasetDemoNOME: TStringField;
    Label1: TLabel;
    Memo1: TMemo;
    sePort: TSpinEdit;
    StatusBar1: TStatusBar;
    procedure btnStartClick(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
    procedure btnClearClick(Sender: TObject);
    procedure CeosServer1Exception(Sender: TObject; const E: exception);
    procedure CeosServer1GetRequest(Sender: TObject;
      const ARequest: TFPHTTPConnectionRequest;
      var AResponse: TFPHTTPConnectionResponse);
    procedure CeosServer1Request(Sender: TObject;
      const ARequest: TCeosRequestContent; var AResponse: TCeosResponseContent);
    procedure CeosServer1RequestError(Sender: TObject; const E: exception;
      var AResponse: TCeosResponseContent);
    procedure CeosServer1Start(Sender: TObject);
    procedure CeosServer1Stop(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { private declarations }

    {$IFDEF PLUGIN_VIA_DYNAMICDLL}
    pluginhandle: TLibHandle;
    {$ENDIF}

    RequestsCount: integer;
  public
    { public declarations }
    CeosServerPluginManager: TCeosServerPluginManager;

    procedure Log(msg: string);
  end;


var
  Form1: TForm1;

implementation

uses ceosconsts, ceosmessages, ceosjson;

{$R *.lfm}

{ TForm1 }

procedure TForm1.btnStartClick(Sender: TObject);
begin
  ceosserver1.port := sePort.value;

  ceosserver1.start;

  btnStart.enabled := not ceosserver1.Active;
  btnStop.enabled := ceosserver1.Active;
end;

procedure TForm1.btnStopClick(Sender: TObject);
begin
  DatasetDemo.close;

  ceosserver1.stop;

  btnStart.enabled := not ceosserver1.Active;
  btnStop.enabled := ceosserver1.Active;
end;

procedure TForm1.btnClearClick(Sender: TObject);
begin
  memo1.Clear;
  RequestsCount := 0;

  if cbxRequestsCount.Checked then
    StatusBar1.Panels[0].Text := 'Requests: 0'
  else
    StatusBar1.Panels[0].Text := '';

  if not CeosServer1.Active then
    StatusBar1.Panels[2].text := '';
end;

procedure TForm1.CeosServer1Exception(Sender: TObject; const E: exception);
begin
  Log(E.message);
end;

procedure TForm1.CeosServer1GetRequest(Sender: TObject;
  const ARequest: TFPHTTPConnectionRequest;
  var AResponse: TFPHTTPConnectionResponse);
begin
  Log(format('Get Request on %s',[ARequest.URI]));

  AResponse.Content := format('CeosMW %s - CeosServer Demo (URI: %s)',[CEOS_VERSION, ARequest.URI]);
end;

procedure TForm1.CeosServer1Request(Sender: TObject;
  const ARequest: TCeosRequestContent; var AResponse: TCeosResponseContent);
var
    i: integer;
begin

  if cbxVerbose.checked then
     Log(ARequest.AsJSON);

  i:=0;
  AResponse:=nil;
  while (i < CeosServerPluginManager.PluginList.Count) do begin
     CeosServerPluginManager.PluginList.Data[i].ProcessRequest(ARequest, AResponse);
     inc(i);
  end;

  if AResponse=nil then begin
     AResponse := JSONRPCError(ERR_UNKNOW_FUNCTION, ERROR_UNKNOW_FUNCTION);
  end;

  if cbxRequestsCount.checked then
  begin
    inc(RequestsCount);

    StatusBar1.Panels[0].text := format('Requests: %d',[RequestsCount]);
  end;
end;

procedure TForm1.CeosServer1RequestError(Sender: TObject; const E: exception;
  var AResponse: TCeosResponseContent);
begin
  Log(E.message);

  AResponse := JSONRPCError(ERR_REQUEST_ERROR,ERROR_REQUEST_ERROR);
end;

procedure TForm1.CeosServer1Start(Sender: TObject);
var pluginmethods: TCeosPluginMethods;

    procedure _LogPlugin;
    var sld: string;
    begin
      // log plugin info
      sld:='';
      with pluginmethods do begin
        case MemoryModel of
           mmUnknown: sld:=LibraryDescription+' Warning: memoey model unknown!';
           mmUses: sld:=LibraryDescription+' This plugin is compiled in application server.';
           mmStaticLink: sld:=LibraryDescription+' This plugin is working as a static linked lybrary.';
           mmDynamicLink: sld:=LibraryDescription+' This plugin is working as a dynamic linked lybrary.';
        end;
        Log(Format('. loaded plugin %s in projec %s rel %s.', [PluginName, LibraryName, LibraryRel]));
        Log('  ' + sld);
      end;
    end;

{$IFDEF PLUGIN_VIA_DYNAMICDLL}
var getpluginmethods: TGetCeosPluginMethods;
{$ENDIF}

begin
  Log('Start...');

  CeosServerPluginManager:=TCeosServerPluginManager.Create;


  pluginmethods:=GetCeosPluginMethods;

  {$IFDEF PLUGIN_VIA_USES}
  CeosServerPluginManager.PluginList.Add('servermethods', pluginmethods);
  {$ENDIF}

  {$IFDEF PLUGIN_VIA_STATICDLL}
  CeosServerPluginManager.PluginList.Add('staticplugmethods', pluginmethods);
  {$ENDIF}

  with pluginmethods do begin
    MemoryModel:={$IFDEF PLUGIN_VIA_USES}mmUses{$ENDIF}
                 {$IFDEF PLUGIN_VIA_STATICDLL}mmStaticLink{$ENDIF} ;
  end;
  _LogPlugin;


  {$IFDEF PLUGIN_VIA_DYNAMICDLL}
  // work in progress
  ln:='libserverplugin.'+SharedSuffix;
  pluginhandle:=LoadLibrary(ln);

  if pluginhandle = dynlibs.NilHandle then
     Caption := 'plugin not found!'
  else begin
     getpluginmethods:=TGetCeosPluginMethods(GetProcAddress(pluginhandle,'GetCeosPluginMethods'));
     pluginmethods:=getpluginmethods();
     with pluginmethods do begin
       MemoryModel:=mmDynamicLink;
     end;
     CeosServerPluginManager.PluginList.add('dynamicplugmethods', pluginmethods);
     _LogPlugin;
  end;
  {$ENDIF}


  StatusBar1.Panels[2].text := format('Start: %s',[datetimetostr(now)]);

  RequestsCount := 0;
  StatusBar1.Panels[0].text := format('Requests: %d',[RequestsCount]);
end;

procedure TForm1.CeosServer1Stop(Sender: TObject);
begin
  Log('Stop...');


  {$IFDEF PLUGIN_VIA_DYNAMICDLL}
  { // work in progress
  if pluginhandle <> dynlibs.NilHandle then
     FreeLibrary(pluginhandle);
  pluginhandle:=dynlibs.NilHandle;
  }
  {$ENDIF}


  FreeAndNil(CeosServerPluginManager);

  StatusBar1.Panels[2].text := StatusBar1.Panels[2].text + '       ' + format('Stop: %s',[datetimetostr(now)]);
end;

procedure TForm1.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  btnStop.Click;
  CloseAction:=caFree;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  CeosServerPluginManager:=nil;

  {$IFDEF PLUGIN_VIA_DYNAMICDLL}
  pluginhandle := dynlibs.NilHandle;
  {$ENDIF}
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  if Assigned(CeosServerPluginManager) then begin
     Log('Warning: CeosServerPluginManager exists on FormDestroy!');
     CeosServerPluginManager.Free;
  end;

  {$IFDEF PLUGIN_VIA_DYNAMICDLL}
  if pluginhandle <> dynlibs.NilHandle then
     FreeLibrary(pluginhandle);
  {$ENDIF}

end;

procedure TForm1.Log(msg: string);
begin

  if cbxVerbose.checked then
    memo1.lines.add(formatdatetime('hh:nn:ss:zzz',now) + #9 + msg);

end;


end.

