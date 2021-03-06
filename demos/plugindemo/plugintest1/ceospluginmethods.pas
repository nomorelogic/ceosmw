{*****************************************************************}
{                                                                 }
{ by Marcello Basso - markbass72@gmail.com                        }
{                                                                 }
{ ... work in progress ...                                        }
{                                                                 }
{*****************************************************************}

unit ceospluginmethods;

{$mode objfpc}{$H+}

interface
{$M+}

uses
  Classes, SysUtils, variants,
  // ceostypes, fpjson, jsonparser, ceosserver,
  ceosservermethods, fgl
  // , DynLibs
  ;

type

  // TFuncType = function(Request: TCeosRequestContent): TJSONStringType of object;
  TPluginMemoryModel = (mmUnknown, mmUses, mmStaticLink, mmDynamicLink);
  // TCeosPluginMethods = class;
  TPluginList = specialize TFPGMap<String,TCeosServerMethods>;


  { TCeosPluginMethods }

  TCeosPluginMethods = class(TCeosServerMethods)
  private
    FIsActive: boolean;
    FIsLoaded: boolean;
    FLibraryDescription: string;
    FLibraryName: string;
    FLibraryRel: string;
    FMemoryModel: TPluginMemoryModel;
    FPluginName: string;
  public
    constructor Create;
  published
    property IsActive: boolean read FIsActive write FIsActive;
    property IsLoaded: boolean read FIsLoaded write FIsLoaded;
    property PluginName: string read FPluginName write FPluginName;
    property MemoryModel: TPluginMemoryModel read FMemoryModel write FMemoryModel;
    property LibraryName: string read FLibraryName write FLibraryName;
    property LibraryRel: string read FLibraryRel write FLibraryRel;
    property LibraryDescription: string read FLibraryDescription write FLibraryDescription;
  end;


  { TCeosServerPluginManager }

  TCeosServerPluginManager = class

  private
    FPluginList: TPluginList;
  public
    constructor Create;
    destructor Destroy; override;
  published
    property PluginList:TPluginList read FPluginList write FPluginList;

  end;

  // declaration for static link library
  {$IFDEF PLUGIN_VIA_STATICDLL}
  function GetCeosPluginMethods: TCeosPluginMethods; {$IFDEF UNIX}cdecl;{$ELSE}stdcall;{$ENDIF}
  external 'libplugintest1.so';
  {$ENDIF}
  // declaration for dynamic link library
  {$IFDEF PLUGIN_VIA_DYNAMICDLL}
  TGetCeosPluginMethods=function:TCeosPluginMethods; {$IFDEF UNIX}cdecl;{$ELSE}stdcall;{$ENDIF}
  {$ENDIF}


implementation

// uses ceosjson, ceosconsts, ceosmessages;

{ TCeosPluginMethods }

constructor TCeosPluginMethods.Create;
begin
  inherited Create;

  FIsActive:=False;
  FIsLoaded:=False;
  FPluginName:='';
  FMemoryModel:=mmUnknown;
  FLibraryName:='';
  FLibraryRel:='0.3';
  FLibraryDescription:='';
end;

{ TCeosServerPluginManager }

constructor TCeosServerPluginManager.Create;
begin
  inherited Create;

  PluginList:=TPluginList.Create;
end;

destructor TCeosServerPluginManager.Destroy;
begin

  while PluginList.Count>0 do begin

    {$IFDEF PLUGIN_VIA_DYNAMICDLL}
    // not yet implemented...
    // if pluginhandle <> dynlibs.NilHandle then begin
    //    FreeLibrary(pluginhandle);
    //    pluginhandle := dynlibs.NilHandle;
    // end;
    {$ENDIF}

    PluginList.Data[0].Free;
    PluginList.Delete(0);
  end;

  PluginList.Free;

  inherited Destroy;
end;


end.

