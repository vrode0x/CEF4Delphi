unit uChildForm;

{$I ..\..\..\source\cef.inc}

interface

uses
  {$IFDEF DELPHI16_UP}
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics, Vcl.Menus,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, System.Types, Vcl.ComCtrls, Vcl.ClipBrd,
  System.UITypes,
  {$ELSE}
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Menus,
  Controls, Forms, Dialogs, StdCtrls, ExtCtrls, Types, ComCtrls, ClipBrd,
  {$ENDIF}
  uMainForm, uCEFChromium, uCEFWindowParent, uCEFInterfaces, uCEFConstants, uCEFTypes,
  uCEFWinControl, uCEFChromiumCore;

type
  TChildForm = class(TForm)
    Panel1: TPanel;
    Edit1: TEdit;
    Button1: TButton;
    Chromium1: TChromium;
    CEFWindowParent1: TCEFWindowParent;
    StatusBar1: TStatusBar;

    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);

    procedure Button1Click(Sender: TObject);

    procedure Chromium1AfterCreated(Sender: TObject; const browser: ICefBrowser);
    procedure Chromium1BeforeClose(Sender: TObject; const browser: ICefBrowser);
    procedure Chromium1LoadingStateChange(Sender: TObject; const browser: ICefBrowser; isLoading, canGoBack, canGoForward: Boolean);
    procedure Chromium1StatusMessage(Sender: TObject; const browser: ICefBrowser; const value: ustring);
    procedure Chromium1BeforePopup(Sender: TObject; const browser: ICefBrowser; const frame: ICefFrame; popup_id: Integer; const targetUrl, targetFrameName: ustring; targetDisposition: TCefWindowOpenDisposition; userGesture: Boolean; const popupFeatures: TCefPopupFeatures; var windowInfo: TCefWindowInfo; var client: ICefClient; var settings: TCefBrowserSettings; var extra_info: ICefDictionaryValue; var noJavascriptAccess: Boolean; var Result: Boolean);

  private
    // Variables to control when can we destroy the form safely
    FCanClose : boolean;  // Set to True in TChromium.OnBeforeClose
    FClosing  : boolean;  // Set to True in the CloseQuery event.

  protected
    procedure BrowserCreatedMsg(var aMessage : TMessage); message CEFBROWSER_CREATED;
    procedure WMMove(var aMessage : TWMMove); message WM_MOVE;
    procedure WMMoving(var aMessage : TMessage); message WM_MOVING;
    procedure WMEnterMenuLoop(var aMessage: TMessage); message WM_ENTERMENULOOP;
    procedure WMExitMenuLoop(var aMessage: TMessage); message WM_EXITMENULOOP;

  public
    property Closing   : boolean    read FClosing;
  end;

implementation

{$R *.dfm}

// Destruction steps
// =================
// 1. FormCloseQuery sets CanClose to FALSE, destroys CEFWindowParent1 and calls TChromium.CloseBrowser which triggers the TChromium.OnBeforeClose event.
// 2. TChromium.OnBeforeClose sets FCanClose := True and sends WM_CLOSE to the form.

uses
  uCEFRequestContext, uCEFApplication;

procedure TChildForm.Button1Click(Sender: TObject);
begin
  Chromium1.LoadURL(Edit1.Text);
end;

procedure TChildForm.Chromium1AfterCreated(Sender: TObject; const browser: ICefBrowser);
begin
  PostMessage(Handle, CEFBROWSER_CREATED, 0, 0);
end;

procedure TChildForm.Chromium1BeforeClose(Sender: TObject; const browser: ICefBrowser);
begin
  FCanClose := True;
  PostMessage(Handle, WM_CLOSE, 0, 0);
end;

procedure TChildForm.Chromium1BeforePopup(Sender: TObject;
  const browser: ICefBrowser; const frame: ICefFrame; popup_id: Integer;
  const targetUrl, targetFrameName: ustring; targetDisposition: TCefWindowOpenDisposition;
  userGesture: Boolean; const popupFeatures: TCefPopupFeatures;
  var windowInfo: TCefWindowInfo; var client: ICefClient;
  var settings: TCefBrowserSettings; var extra_info: ICefDictionaryValue;
  var noJavascriptAccess: Boolean;
  var Result: Boolean);
begin
  // For simplicity, this demo blocks all popup windows and new tabs
  Result := (targetDisposition in [CEF_WOD_NEW_FOREGROUND_TAB, CEF_WOD_NEW_BACKGROUND_TAB, CEF_WOD_NEW_POPUP, CEF_WOD_NEW_WINDOW]);
end;

procedure TChildForm.Chromium1LoadingStateChange(Sender: TObject; const browser: ICefBrowser; isLoading, canGoBack, canGoForward: Boolean);
begin
  if isLoading then
    begin
      StatusBar1.Panels[0].Text := 'Loading...';
      cursor := crAppStart;
    end
   else
    begin
      StatusBar1.Panels[0].Text := '';
      cursor := crDefault;
    end;
end;

procedure TChildForm.Chromium1StatusMessage(Sender: TObject; const browser: ICefBrowser; const value: ustring);
begin
  StatusBar1.Panels[1].Text := value;
end;

procedure TChildForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
end;

procedure TChildForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := (Chromium1.BrowserId =  0) or FCanClose;

  if not(FClosing) and Panel1.Enabled then
    begin
      FClosing       := True;
      Panel1.Enabled := False;
      Chromium1.CloseBrowser(True);
      CEFWindowParent1.Free;
    end;
end;

procedure TChildForm.FormCreate(Sender: TObject);
begin
  FCanClose := False;
  FClosing  := False;
end;

procedure TChildForm.FormDestroy(Sender: TObject);
begin
  // Tell the main form that a child has been destroyed.
  // The main form will check if this was the last child to close itself
  PostMessage(MainForm.Handle, CEFBROWSER_CHILDDESTROYED, 0, 0);
end;

procedure TChildForm.FormShow(Sender: TObject);
var
  TempContext : ICefRequestContext;
  TempCache : string;
begin
  try
    // The new request context overrides several GlobalCEFApp properties like :
    // cache, AcceptLanguageList, PersistSessionCookies, PersistUserPreferences and
    // IgnoreCertificateErrors

    // If you use an empty cache path, CEF will use in-memory cache.

    // The cache directories of all the browsers *MUST* be a subdirectory of
    // GlobalCEFApp.RootCache unless you use a blank cache (in-memory).

    if MainForm.NewContextChk.Checked then
      begin
        if MainForm.IncognitoChk.Checked then
          TempCache := ''
         else
          TempCache := GlobalCEFApp.RootCache + '\cache' + inttostr(MainForm.BrowserCount);

        TempContext := TCefRequestContextRef.New(TempCache, '', '', False, False, Chromium1.ReqContextHandler)
      end
     else
      TempContext := nil;

    {
    // This would be a good place to set the proxy server settings for all your child
    // browsers if you use a proxy
    Chromium1.ProxyType     := CEF_PROXYTYPE_FIXED_SERVERS;
    Chromium1.ProxyScheme   := psHTTP;
    Chromium1.ProxyServer   := '1.2.3.4';
    Chromium1.ProxyPort     := 1234;
    Chromium1.ProxyUsername := '';
    Chromium1.ProxyPassword := '';
    }

    Chromium1.DefaultURL := Edit1.Text;
    Chromium1.CreateBrowser(CEFWindowParent1, '', TempContext);
  finally
    TempContext := nil;
  end;
end;

procedure TChildForm.WMMove(var aMessage : TWMMove);
begin
  inherited;

  if (Chromium1 <> nil) then Chromium1.NotifyMoveOrResizeStarted;
end;

procedure TChildForm.WMMoving(var aMessage : TMessage);
begin
  inherited;

  if (Chromium1 <> nil) then Chromium1.NotifyMoveOrResizeStarted;
end;

procedure TChildForm.WMEnterMenuLoop(var aMessage: TMessage);
begin
  inherited;

  if (aMessage.wParam = 0) and (GlobalCEFApp <> nil) then GlobalCEFApp.OsmodalLoop := True;
end;

procedure TChildForm.WMExitMenuLoop(var aMessage: TMessage);
begin
  inherited;

  if (aMessage.wParam = 0) and (GlobalCEFApp <> nil) then GlobalCEFApp.OsmodalLoop := False;
end;

procedure TChildForm.BrowserCreatedMsg(var aMessage : TMessage);
begin
  CEFWindowParent1.UpdateSize;
  Panel1.Enabled := True;
end;

end.
