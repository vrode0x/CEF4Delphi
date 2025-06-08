program TinyBrowser2;

{$MODE Delphi}

uses
  Interfaces,
  uCEFApplication,
  uTinyBrowser2 in 'uTinyBrowser2.pas';

// CEF needs to set the LARGEADDRESSAWARE ($20) flag which allows 32-bit processes to use up to 3GB of RAM.
{$IFDEF WIN32}{$SetPEFlags $20}{$ENDIF}

{$R *.res}

begin
  CreateGlobalCEFApp;

  if GlobalCEFApp.StartMainProcess then
    begin
      GlobalCEFApp.RunMessageLoop;
      DestroyTinyBrowser;
    end;

  DestroyGlobalCEFApp;
end.
