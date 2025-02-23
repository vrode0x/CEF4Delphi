unit uEncapsulatedBrowser;

{$I ..\..\..\source\cef.inc}

interface

uses
  {$IFDEF DELPHI16_UP}
  System.SyncObjs, System.SysUtils,
  {$ELSE}
  SyncObjs, SysUtils,
  {$ENDIF}
  uCEFTypes, uCEFBrowserThread;

type
  TEncapsulatedBrowser = class
    protected
      FThread       : TCEFBrowserThread;
      FWidth        : integer;
      FHeight       : integer;
      FDelayMs      : integer;
      FScale        : single;
      FSnapshotPath : ustring;
      FErrorText    : ustring;
      FFirst        : boolean;

      procedure Thread_OnError(Sender: TObject);
      procedure Thread_OnSnapshotAvailable(Sender: TObject);

    public
      constructor Create(aWidth, aHeight : integer);
      destructor  Destroy; override;
      procedure   LoadURL(const aURL : ustring);
      function    UpdateBrowserSize(aNewWidth, aNewHeight : integer): boolean;

      property Width           : integer    read FWidth;
      property Height          : integer    read FHeight;
      property DelayMs         : integer    read FDelayMs        write FDelayMs;
      property Scale           : single     read FScale          write FScale;
      property SnapshotPath    : ustring    read FSnapshotPath   write FSnapshotPath;
      property ErrorText       : ustring    read FErrorText;
  end;

procedure CreateGlobalCEFApp;
function  WaitForMainAppEvent : boolean;
procedure WriteResult;

implementation

uses
  uCEFApplication;

var
  MainAppEvent        : TEvent;
  EncapsulatedBrowser : TEncapsulatedBrowser = nil;

procedure GlobalCEFApp_OnContextInitialized;
var
  TempParam, TempURL : ustring;
begin
  TempURL := '';

  // This demo reads the "/url" parameter to load it as the default URL in the browser.
  // For example : ConsoleBrowser2.exe /url=https://www.briskbard.com
  if (ParamCount > 0) then
    begin
      TempParam := paramstr(1);

      if (Copy(TempParam, 1, 5) = '/url=') then
        begin
          TempURL := trim(Copy(TempParam, 6, length(TempParam)));
          if (length(TempURL) > 0) then WriteLn('Loading ' + TempURL);
        end;
    end;

  if (length(TempURL) = 0) then
    begin
      TempURL := 'https://www.google.com';
      WriteLn('No URL has been specified. Using the default...');
    end;

  EncapsulatedBrowser := TEncapsulatedBrowser.Create(1024, 768);
  EncapsulatedBrowser.LoadURL(TempURL);
end;

function WaitForMainAppEvent : boolean;
begin
  Result := True;

  // Wait for 1 minute max.
  if (MainAppEvent.WaitFor(60000) = wrTimeout) then
    begin
      WriteLn('Timeout expired!');
      Result := False;
    end;
end;

procedure WriteResult;
begin
  if (EncapsulatedBrowser = nil) then
    WriteLn('There was a problem in the browser initialization')
   else
    if (length(EncapsulatedBrowser.ErrorText) > 0) then
      WriteLn(EncapsulatedBrowser.ErrorText)
     else
      WriteLn('Snapshot saved successfully as ' + EncapsulatedBrowser.SnapshotPath);
end;

procedure CreateGlobalCEFApp;
begin
  GlobalCEFApp                            := TCefApplication.Create;
  GlobalCEFApp.WindowlessRenderingEnabled := True;
  GlobalCEFApp.ShowMessageDlg             := False;                    // This demo shouldn't show any window, just console messages.
  GlobalCEFApp.BrowserSubprocessPath      := 'ConsoleBrowser2_sp.exe'; // This is the other EXE for the CEF subprocesses. It's on the same directory as this app.
  GlobalCEFApp.BlinkSettings              := 'hideScrollbars';         // This setting removes all scrollbars to capture a cleaner snapshot
  GlobalCEFApp.OnContextInitialized       := GlobalCEFApp_OnContextInitialized;

{
  // In case you use a custom directory for the CEF binaries you have to set these properties
  // here and in the subprocess
  GlobalCEFApp.FrameworkDirPath     := 'c:\cef';
  GlobalCEFApp.ResourcesDirPath     := 'c:\cef';
  GlobalCEFApp.LocalesDirPath       := 'c:\cef\locales';
  GlobalCEFApp.SetCurrentDir        := True;
}

  GlobalCEFApp.StartMainProcess;
end;

constructor TEncapsulatedBrowser.Create(aWidth, aHeight : integer);
begin
  inherited Create;

  FFirst         := True;
  FThread        := nil;
  FWidth         := aWidth;
  FHeight        := aHeight;
  FDelayMs       := 500;
  FScale         := 1;    // This is the relative scale to a 96 DPI screen. It's calculated with the formula : scale = custom_DPI / 96
  FSnapshotPath  := 'snapshot.bmp';
  FErrorText     := '';
end;

destructor TEncapsulatedBrowser.Destroy;
begin
  if (FThread <> nil) then
    begin
      if FThread.TerminateBrowserThread then
        FThread.WaitFor;

      FreeAndNil(FThread);
    end;

  inherited Destroy;
end;

procedure TEncapsulatedBrowser.LoadURL(const aURL : ustring);
begin
  if (FThread = nil) then
    begin
      FThread                     := TCEFBrowserThread.Create(aURL, FWidth, FHeight, FDelayMs, FScale);
      FThread.OnError             := Thread_OnError;
      FThread.OnSnapshotAvailable := Thread_OnSnapshotAvailable;
      FThread.Start;
    end
   else
    FThread.LoadUrl(aURL);
end;

function TEncapsulatedBrowser.UpdateBrowserSize(aNewWidth, aNewHeight : integer): boolean;
begin
  FWidth  := aNewWidth;
  FHeight := aNewHeight;
  Result  := assigned(FThread) and
             FThread.UpdateBrowserSize(aNewWidth, aNewHeight);
end;

procedure TEncapsulatedBrowser.Thread_OnError(Sender: TObject);
begin
  // This code is executed in the TCEFBrowserThread thread context while the main application thread is waiting for MainAppEvent.

  FErrorText := 'Error';

  if (FThread.ErrorCode <> 0) then
    FErrorText := FErrorText + ' ' + inttostr(FThread.ErrorCode);

  FErrorText := FErrorText + ' : ' + FThread.ErrorText;

  if (length(FThread.FailedUrl) > 0) then
    FErrorText := FErrorText + ' - ' + FThread.FailedUrl;

  if assigned(MainAppEvent) then
    MainAppEvent.SetEvent;
end;

procedure TEncapsulatedBrowser.Thread_OnSnapshotAvailable(Sender: TObject);
begin
  // This code is executed in the TCEFBrowserThread thread context while the main application thread is waiting for MainAppEvent.

  // Enable this block to test UpdateBrowserSize
  {
  if FFirst then
    begin
      FFirst := False;
      if UpdateBrowserSize(800, 600) then
        LoadURL('https://www.bing.com');
      exit;
    end;
  }

  if (FThread = nil) or not(FThread.SaveSnapshotToFile(FSnapshotPath)) then
    FErrorText := 'There was an error copying the snapshot';

  if assigned(MainAppEvent) then
    MainAppEvent.SetEvent;
end;

initialization
  MainAppEvent := TEvent.Create;

finalization
  MainAppEvent.Free;
  if (EncapsulatedBrowser <> nil) then FreeAndNil(EncapsulatedBrowser);

end.
