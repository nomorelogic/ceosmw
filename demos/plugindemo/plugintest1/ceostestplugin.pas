{*****************************************************************}
{                                                                 }
{ by Marcello Basso - markbass72@gmail.com                        }
{                                                                 }
{ ... work in progress ...                                        }
{                                                                 }
{*****************************************************************}

unit ceostestplugin;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  ceostypes, fpjson, jsonparser, ceospluginmethods, ceosjson;

type

  { TCeosTestPlugin }

  TCeosTestPlugin = class(TCeosPluginMethods)
  private
  public
     constructor Create;
  published
     function PluginTest1(Request: TCeosRequestContent): TJSONStringType;
  end;


function GetCeosPluginMethods: TCeosPluginMethods; {$IFDEF UNIX}cdecl;{$ELSE}stdcall;{$ENDIF}

implementation

function GetCeosPluginMethods: TCeosPluginMethods; {$IFDEF UNIX}cdecl;{$ELSE}stdcall;{$ENDIF}
begin
  result := TCeosPluginMethods(TCeosTestPlugin.Create);
end;

{ TCeosTestPlugin }

constructor TCeosTestPlugin.Create;
begin
  inherited Create;

  PluginName:='PluginTest1';
  MemoryModel:=mmUnknown;
  LibraryName:='ceostestplugin';
  LibraryDescription:='This is a demo ceosmw server plugin.';
end;

function TCeosTestPlugin.PluginTest1(Request: TCeosRequestContent
  ): TJSONStringType;
begin
  if Request = nil then
     result := 'Hello from ceostestplugin, method = nil.'
  else
     result := 'Hello from ceostestplugin, method = ' + Request.Method + '.';
end;

end.

