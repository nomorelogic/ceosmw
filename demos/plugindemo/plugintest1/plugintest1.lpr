{*****************************************************************}
{                                                                 }
{ by Marcello Basso - markbass72@gmail.com                        }
{                                                                 }
{ ... work in progress ...                                        }
{                                                                 }
{*****************************************************************}

library plugintest1;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Classes,
  { you can add units after this }
  ceosmw, ceostestplugin;

exports
   GetCeosPluginMethods;

end.

