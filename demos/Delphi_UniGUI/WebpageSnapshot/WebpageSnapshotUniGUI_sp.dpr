program WebpageSnapshotUniGUI_sp;

uses
  uCEFApplicationCore;

const
  IMAGE_FILE_LARGE_ADDRESS_AWARE = $0020;

// CEF needs to set the LARGEADDRESSAWARE ($20) flag which allows 32-bit processes to use up to 3GB of RAM.
{$IFDEF WIN32}{$SetPEFlags IMAGE_FILE_LARGE_ADDRESS_AWARE}{$ENDIF}

begin
  GlobalCEFApp                            := TCefApplicationCore.Create;
  GlobalCEFApp.WindowlessRenderingEnabled := True;
  GlobalCEFApp.ShowMessageDlg             := False;
  GlobalCEFApp.BlinkSettings              := 'hideScrollbars';

  GlobalCEFApp.StartSubProcess;
  DestroyGlobalCEFApp;
end.

