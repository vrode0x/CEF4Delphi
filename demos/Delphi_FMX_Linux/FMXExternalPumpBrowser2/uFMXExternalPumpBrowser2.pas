unit uFMXExternalPumpBrowser2;

{$I ..\..\..\source\cef.inc}

interface

uses
  System.Types, System.UITypes, System.Classes, System.SyncObjs,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.Edit, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Graphics, FMX.Layouts, FMX.DialogService,
  uCEFFMXChromium, uCEFFMXBufferPanel, uCEFFMXWorkScheduler,
  uCEFInterfaces, uCEFTypes, uCEFConstants, uCEFChromiumCore, FMX.ComboEdit;

type
  TJSDialogInfo = record
    OriginUrl         : ustring;
    MessageText       : ustring;
    DefaultPromptText : ustring;
    DialogType        : TCefJsDialogType;
    Callback          : ICefJsDialogCallback;
  end;

  TFMXExternalPumpBrowserFrm = class(TForm)
    AddressPnl: TPanel;
    chrmosr: TFMXChromium;
    Timer1: TTimer;
    SaveDialog1: TSaveDialog;
    Panel1: TFMXBufferPanel;
    Layout1: TLayout;
    GoBtn: TButton;
    SnapshotBtn: TButton;
    StatusBar1: TStatusBar;
    StatusLbl: TLabel;
    AddressCb: TComboEdit;

    procedure GoBtnClick(Sender: TObject);
    procedure GoBtnEnter(Sender: TObject);

    procedure Panel1Enter(Sender: TObject);
    procedure Panel1Exit(Sender: TObject);
    procedure Panel1Resize(Sender: TObject);
    procedure Panel1MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure Panel1MouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure Panel1MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
    procedure Panel1MouseLeave(Sender: TObject);
    procedure Panel1MouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean);

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormHide(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);

    procedure chrmosrPaint(Sender: TObject; const browser: ICefBrowser; type_: TCefPaintElementType; dirtyRectsCount: NativeUInt; const dirtyRects: PCefRectArray; const buffer: Pointer; width, height: Integer);
    procedure chrmosrGetViewRect(Sender: TObject; const browser: ICefBrowser; var rect: TCefRect);
    procedure chrmosrGetScreenPoint(Sender: TObject; const browser: ICefBrowser; viewX, viewY: Integer; var screenX, screenY: Integer; out Result: Boolean);
    procedure chrmosrGetScreenInfo(Sender: TObject; const browser: ICefBrowser; var screenInfo: TCefScreenInfo; out Result: Boolean);
    procedure chrmosrPopupShow(Sender: TObject; const browser: ICefBrowser; show: Boolean);
    procedure chrmosrPopupSize(Sender: TObject; const browser: ICefBrowser; const rect: PCefRect);
    procedure chrmosrBeforeClose(Sender: TObject; const browser: ICefBrowser);
    procedure chrmosrTooltip(Sender: TObject; const browser: ICefBrowser; var text: ustring; out Result: Boolean);
    procedure chrmosrBeforePopup(Sender: TObject; const browser: ICefBrowser; const frame: ICefFrame; popup_id: Integer; const targetUrl, targetFrameName: ustring; targetDisposition: TCefWindowOpenDisposition; userGesture: Boolean; const popupFeatures: TCefPopupFeatures; var windowInfo: TCefWindowInfo; var client: ICefClient; var settings: TCefBrowserSettings; var extra_info: ICefDictionaryValue; var noJavascriptAccess: Boolean; var Result: Boolean);
    procedure chrmosrAfterCreated(Sender: TObject; const browser: ICefBrowser);
    procedure chrmosrCursorChange(Sender: TObject; const browser: ICefBrowser; cursor_: TCefCursorHandle; cursorType: TCefCursorType; const customCursorInfo: PCefCursorInfo; var aResult: Boolean);
    procedure chrmosrLoadingStateChange(Sender: TObject; const browser: ICefBrowser; isLoading, canGoBack, canGoForward: Boolean);
    procedure chrmosrLoadError(Sender: TObject; const browser: ICefBrowser; const frame: ICefFrame; errorCode: TCefErrorCode; const errorText, failedUrl: ustring);
    procedure chrmosrBeforeContextMenu(Sender: TObject; const browser: ICefBrowser; const frame: ICefFrame; const params: ICefContextMenuParams; const model: ICefMenuModel);
    procedure chrmosrJsdialog(Sender: TObject; const browser: ICefBrowser; const originUrl: ustring; dialogType: TCefJsDialogType; const messageText, defaultPromptText: ustring; const callback: ICefJsDialogCallback; out suppressMessage, Result: Boolean);

    procedure Timer1Timer(Sender: TObject);
    procedure AddressEdtEnter(Sender: TObject);

    procedure SnapshotBtnClick(Sender: TObject);
    procedure SnapshotBtnEnter(Sender: TObject);

  protected
    FPopUpBitmap       : TBitmap;
    FPopUpRect         : TRect;
    FShowPopUp         : boolean;
    FResizing          : boolean;
    FPendingResize     : boolean;
    FCanClose          : boolean;
    FClosing           : boolean;
    FResizeCS          : TCriticalSection;
    FJSDialogInfo      : TJSDialogInfo;
    {$IFDEF DELPHI17_UP}
    FMouseWheelService : IFMXMouseService;
    {$ENDIF}

    procedure LoadURL;
    function  getModifiers(Shift: TShiftState): TCefEventFlags; overload;
    function  getModifiers(Button: TMouseButton; Shift: TShiftState): TCefEventFlags; overload;
    function  GetButton(Button: TMouseButton): TCefMouseButtonType;
    function  GetMousePosition(var aPoint : TPointF) : boolean;
    procedure ShowPendingJSDialog;

  public
    procedure DoResize;
    procedure NotifyMoveOrResizeStarted;
    procedure SendCaptureLostEvent;
    procedure SetBounds(ALeft: Integer; ATop: Integer; AWidth: Integer; AHeight: Integer); override;
    procedure SendCEFKeyEvent(const aCefEvent : TCefKeyEvent);
  end;

var
  FMXExternalPumpBrowserFrm : TFMXExternalPumpBrowserFrm;

// This is a simple browser using FireMonkey components in OSR mode (off-screen rendering)
// and a external message pump.

// All FMX applications using CEF4Delphi should add the $(FrameworkType) conditional define
// in the project options to avoid duplicated resources.
// This demo has that define in the menu option :
// Project -> Options -> Building -> Delphi compiler -> Conditional defines (All configurations)

// This is the destruction sequence in OSR mode :
// 1- FormCloseQuery sets CanClose to the initial FCanClose value (False) and
//    calls chrmosr.CloseBrowser(True).
// 2- chrmosr.CloseBrowser(True) will trigger chrmosr.OnClose and the default
//    implementation will destroy the internal browser immediately, which will
//    trigger the chrmosr.OnBeforeClose event.
// 3- chrmosr.OnBeforeClose sets FCanClose to True and enables the timer to
//    close the form after a few milliseconds.

implementation

{$R *.fmx}

uses
  System.SysUtils, System.Math, FMX.Platform, FMX.Platform.Linux, FMX.DialogService.Async,
  uCEFMiscFunctions, uCEFApplication, uCEFLinuxTypes, uCEFLinuxConstants,
  uCEFLinuxFunctions;

function GTKKeyPress(Widget: PGtkWidget; Event: PGdkEventKey; Data: gPointer) : GBoolean; cdecl;
var
  TempCefEvent : TCefKeyEvent;
begin
  if FMXExternalPumpBrowserFrm.Panel1.IsFocused then
    begin
      GdkEventKeyToCEFKeyEvent(Event, TempCefEvent);

      if (Event^._type = GDK_KEY_PRESS) then
        begin
          TempCefEvent.kind := KEYEVENT_RAWKEYDOWN;
          FMXExternalPumpBrowserFrm.SendCEFKeyEvent(TempCefEvent);
          TempCefEvent.kind := KEYEVENT_CHAR;
          FMXExternalPumpBrowserFrm.SendCEFKeyEvent(TempCefEvent);
        end
       else
        begin
          TempCefEvent.kind := KEYEVENT_KEYUP;
          FMXExternalPumpBrowserFrm.SendCEFKeyEvent(TempCefEvent);
        end;

      Result := True;
    end
   else
    Result := False;
end;

procedure ConnectKeyPressReleaseEvents(const aWidget : PGtkWidget);
begin
  g_signal_connect(aWidget, 'key-press-event',   TGCallback(@GTKKeyPress), nil);
  g_signal_connect(aWidget, 'key-release-event', TGCallback(@GTKKeyPress), nil);
end;

procedure TFMXExternalPumpBrowserFrm.FormActivate(Sender: TObject);
var
  TempError : string;
begin
  if not(FCanClose) and ((GlobalCEFApp = nil) or not(GlobalCEFApp.LibLoaded)) then
    begin
      FCanClose := True;
      FClosing  := True;
      TempError := 'CEF binaries missing!';

      if (GlobalCEFApp = nil) then
        TempError := TempError + CRLF + CRLF + 'GlobalCEFApp was not created!'
       else
        if (length(GlobalCEFApp.MissingLibFiles) > 0) then
        TempError := TempError + CRLF + CRLF +
                     'The missing files are :' + CRLF +
                     trim(GlobalCEFApp.MissingLibFiles);

      TDialogService.MessageDialog(TempError, TMsgDlgType.mtError,
        [TMsgDlgBtn.mbOK], TMsgDlgBtn.mbOK, 0,
        procedure(const AResult: TModalResult)
        begin
          Timer1.Enabled := True;
        end);
    end
   else
    if not(chrmosr.Initialized) then
      begin
        ConnectKeyPressReleaseEvents(TLinuxWindowHandle(Handle).NativeHandle);

        // opaque white background color
        chrmosr.Options.BackgroundColor := CefColorSetARGB($FF, $FF, $FF, $FF);

        if not(chrmosr.CreateBrowser) then
          Timer1.Enabled := True;
      end;
end;

procedure TFMXExternalPumpBrowserFrm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := FCanClose;

  if not(FClosing) then
    begin
      FClosing                 := True;
      Visible                  := False;
      AddressPnl.Enabled       := False;
      FJSDialogInfo.Callback   := nil;

      chrmosr.CloseBrowser(True);
    end;
end;

procedure TFMXExternalPumpBrowserFrm.FormCreate(Sender: TObject);
begin
  FPopUpBitmap    := nil;
  FPopUpRect      := rect(0, 0, 0, 0);
  FShowPopUp      := False;
  FResizing       := False;
  FPendingResize  := False;
  FCanClose       := False;
  FClosing        := False;
  FResizeCS       := TCriticalSection.Create;

  FJSDialogInfo.OriginUrl         := '';
  FJSDialogInfo.MessageText       := '';
  FJSDialogInfo.DefaultPromptText := '';
  FJSDialogInfo.DialogType        := JSDIALOGTYPE_ALERT;
  FJSDialogInfo.Callback          := nil;

  chrmosr.DefaultURL := AddressCb.Text;

  {$IFDEF DELPHI17_UP}
  if TPlatformServices.Current.SupportsPlatformService(IFMXMouseService) then
    FMouseWheelService := TPlatformServices.Current.GetPlatformService(IFMXMouseService) as IFMXMouseService;
  {$ENDIF}
end;

procedure TFMXExternalPumpBrowserFrm.FormDestroy(Sender: TObject);
begin
  FResizeCS.Free;

  if (FPopUpBitmap <> nil) then
    FreeAndNil(FPopUpBitmap);
end;

procedure TFMXExternalPumpBrowserFrm.FormHide(Sender: TObject);
begin
  chrmosr.SetFocus(False);
  chrmosr.WasHidden(True);
end;

procedure TFMXExternalPumpBrowserFrm.FormShow(Sender: TObject);
begin
  chrmosr.WasHidden(False);
  chrmosr.SetFocus(True);
end;

procedure TFMXExternalPumpBrowserFrm.GoBtnClick(Sender: TObject);
begin
  LoadURL;
end;

procedure TFMXExternalPumpBrowserFrm.LoadURL;
begin
  FResizeCS.Acquire;
  FResizing      := False;
  FPendingResize := False;
  FResizeCS.Release;

  chrmosr.LoadURL(AddressCb.Text);
end;

procedure TFMXExternalPumpBrowserFrm.GoBtnEnter(Sender: TObject);
begin
  if (chrmosr <> nil) then chrmosr.SetFocus(False);
end;

procedure TFMXExternalPumpBrowserFrm.Panel1Enter(Sender: TObject);
begin
  if (chrmosr <> nil) then chrmosr.SetFocus(True);
end;

procedure TFMXExternalPumpBrowserFrm.Panel1Exit(Sender: TObject);
begin
  if (chrmosr <> nil) then chrmosr.SetFocus(False);
end;

function TFMXExternalPumpBrowserFrm.GetMousePosition(var aPoint : TPointF) : boolean;
begin
  {$IFDEF DELPHI17_UP}
  if (FMouseWheelService <> nil) then
    begin
      aPoint := FMouseWheelService.GetMousePos;
      Result := True;
    end
   else
 {$ENDIF}
    begin
      aPoint.x := 0;
      aPoint.y := 0;
      Result   := False;
    end;
end;

procedure TFMXExternalPumpBrowserFrm.Panel1MouseLeave(Sender: TObject);
var
  TempEvent  : TCefMouseEvent;
  TempPoint  : TPointF;
begin
  if GetMousePosition(TempPoint) then
    begin
      TempPoint := Panel1.ScreenToClient(TempPoint);

      TempEvent.x         := round(TempPoint.x);
      TempEvent.y         := round(TempPoint.y);
      TempEvent.modifiers := EVENTFLAG_NONE;

      chrmosr.SendMouseMoveEvent(@TempEvent, True);
    end;
end;

procedure TFMXExternalPumpBrowserFrm.Panel1MouseMove(Sender : TObject;
                                                     Shift  : TShiftState;
                                                     X, Y   : Single);
var
  TempEvent : TCefMouseEvent;
begin
  if not(ssTouch in Shift) then
    begin
      TempEvent.x         := round(x);
      TempEvent.y         := round(y);
      TempEvent.modifiers := getModifiers(Shift);

      chrmosr.SendMouseMoveEvent(@TempEvent, False);
    end;
end;

procedure TFMXExternalPumpBrowserFrm.Panel1MouseUp(Sender : TObject;
                                                   Button : TMouseButton;
                                                   Shift  : TShiftState;
                                                   X, Y   : Single);
var
  TempEvent : TCefMouseEvent;
  TempCount : integer;
begin
  if not(ssTouch in Shift) then
    begin
      TempEvent.x         := round(X);
      TempEvent.y         := round(Y);
      TempEvent.modifiers := getModifiers(Button, Shift);

      if (Button = TMouseButton.mbRight) then
        begin
          // We move the event point slightly so the mouse is over the context menu
          TempEvent.x := TempEvent.x - 5;
          TempEvent.y := TempEvent.y - 5;
        end;

      if (ssDouble in Shift) then
        TempCount := 2
       else
        TempCount := 1;

      chrmosr.SendMouseClickEvent(@TempEvent, GetButton(Button), True, TempCount);
    end;
end;

procedure TFMXExternalPumpBrowserFrm.Panel1MouseDown(Sender : TObject;
                                                     Button : TMouseButton;
                                                     Shift  : TShiftState;
                                                     X, Y   : Single);
var
  TempEvent : TCefMouseEvent;
  TempCount : integer;
begin
  if not(ssTouch in Shift) then
    begin
      TempEvent.x         := round(X);
      TempEvent.y         := round(Y);
      TempEvent.modifiers := getModifiers(Button, Shift);

      if (Button = TMouseButton.mbRight) then
        begin
          // We set the focus in another control as a workaround to show the context
          // menu when we click the right mouse button.
          GoBtn.SetFocus;

          // We move the event point slightly so the mouse is over the context menu
          TempEvent.x := TempEvent.x - 5;
          TempEvent.y := TempEvent.y - 5;
        end
       else
        Panel1.SetFocus;

      if (ssDouble in Shift) then
        TempCount := 2
       else
        TempCount := 1;

      chrmosr.SendMouseClickEvent(@TempEvent, GetButton(Button), False, TempCount);
    end;
end;

procedure TFMXExternalPumpBrowserFrm.Panel1MouseWheel(    Sender      : TObject;
                                                          Shift       : TShiftState;
                                                          WheelDelta  : Integer;
                                                      var Handled     : Boolean);
var
  TempEvent : TCefMouseEvent;
  TempPoint : TPointF;
begin
  if Panel1.IsFocused and GetMousePosition(TempPoint) then
    begin
      TempPoint           := Panel1.ScreenToClient(TempPoint);
      TempEvent.x         := round(TempPoint.x);
      TempEvent.y         := round(TempPoint.y);
      TempEvent.modifiers := getModifiers(Shift);

      chrmosr.SendMouseWheelEvent(@TempEvent, 0, WheelDelta);
    end;
end;

procedure TFMXExternalPumpBrowserFrm.Panel1Resize(Sender: TObject);
begin
  DoResize;
end;

procedure TFMXExternalPumpBrowserFrm.Timer1Timer(Sender: TObject);
begin
  Timer1.Enabled := False;

  if FClosing then
    close
   else
    if not(chrmosr.CreateBrowser) then
      Timer1.Enabled := True;
end;

procedure TFMXExternalPumpBrowserFrm.AddressEdtEnter(Sender: TObject);
begin
  if (chrmosr <> nil) then
    chrmosr.SetFocus(False);
end;

procedure TFMXExternalPumpBrowserFrm.chrmosrAfterCreated(Sender: TObject; const browser: ICefBrowser);
begin
  // Now the browser is fully initialized we can enable the UI.
  Caption            := 'FMX External Pump Browser 2';
  AddressPnl.Enabled := True;
end;

procedure TFMXExternalPumpBrowserFrm.chrmosrBeforeClose(Sender: TObject; const browser: ICefBrowser);
begin
  FCanClose := True;
  TThread.ForceQueue(nil, procedure
                          begin
                            close;
                          end);
end;

procedure TFMXExternalPumpBrowserFrm.chrmosrBeforeContextMenu(      Sender  : TObject;
                                                              const browser : ICefBrowser;
                                                              const frame   : ICefFrame;
                                                              const params  : ICefContextMenuParams;
                                                              const model   : ICefMenuModel);
begin
  // This demo doesn't implement the print events.
  // See the "Lazarus_Linux/MiniBrowser" demo to know how to print in Linux.
  if (model <> nil) then
    model.Remove(MENU_ID_PRINT);
end;

procedure TFMXExternalPumpBrowserFrm.chrmosrBeforePopup(      Sender             : TObject;
                                                        const browser            : ICefBrowser;
                                                        const frame              : ICefFrame;
                                                               popup_id          : Integer;
                                                        const targetUrl          : ustring;
                                                        const targetFrameName    : ustring;
                                                              targetDisposition  : TCefWindowOpenDisposition;
                                                              userGesture        : Boolean;
                                                        const popupFeatures      : TCefPopupFeatures;
                                                        var   windowInfo         : TCefWindowInfo;
                                                        var   client             : ICefClient;
                                                        var   settings           : TCefBrowserSettings;
                                                        var   extra_info         : ICefDictionaryValue;
                                                        var   noJavascriptAccess : Boolean;
                                                        var   Result             : Boolean);
begin
  // For simplicity, this demo blocks all popup windows and new tabs
  Result := (targetDisposition in [CEF_WOD_NEW_FOREGROUND_TAB, CEF_WOD_NEW_BACKGROUND_TAB, CEF_WOD_NEW_POPUP, CEF_WOD_NEW_WINDOW]);
end;

procedure TFMXExternalPumpBrowserFrm.chrmosrCursorChange(      Sender           : TObject;
                                                         const browser          : ICefBrowser;
                                                               cursor_          : TCefCursorHandle;
                                                               cursorType       : TCefCursorType;
                                                         const customCursorInfo : PCefCursorInfo;
                                                         var   aResult          : Boolean);
begin
  Panel1.Cursor := CefCursorToWindowsCursor(cursorType);
  aResult       := True;
end;

procedure TFMXExternalPumpBrowserFrm.chrmosrGetScreenInfo(      Sender     : TObject;
                                                          const browser    : ICefBrowser;
                                                          var   screenInfo : TCefScreenInfo;
                                                          out   Result     : Boolean);
var
  TempRect : TCEFRect;
begin
  TempRect.x      := 0;
  TempRect.y      := 0;
  TempRect.width  := round(Panel1.Width);
  TempRect.height := round(Panel1.Height);

  screenInfo.device_scale_factor := Panel1.ScreenScale;
  screenInfo.depth               := 0;
  screenInfo.depth_per_component := 0;
  screenInfo.is_monochrome       := Ord(False);
  screenInfo.rect                := TempRect;
  screenInfo.available_rect      := TempRect;

  Result := True;
end;

procedure TFMXExternalPumpBrowserFrm.chrmosrGetScreenPoint(      Sender  : TObject;
                                                           const browser : ICefBrowser;
                                                                 viewX   : Integer;
                                                                 viewY   : Integer;
                                                           var   screenX : Integer;
                                                           var   screenY : Integer;
                                                           out   Result  : Boolean);
var
  TempScreenPt, TempViewPt : TPoint;
begin
  // TFMXBufferPanel.ClientToScreen applies the scale factor. No need to call LogicalToDevice to set TempViewPt.
  TempViewPt.x := viewX;
  TempViewPt.y := viewY;
  TempScreenPt := Panel1.ClientToScreen(TempViewPt);
  screenX      := TempScreenPt.x;
  screenY      := TempScreenPt.y;
  Result       := True;
end;

procedure TFMXExternalPumpBrowserFrm.chrmosrGetViewRect(      Sender  : TObject;
                                                        const browser : ICefBrowser;
                                                        var   rect    : TCefRect);
begin
  rect.x      := 0;
  rect.y      := 0;
  rect.width  := round(Panel1.Width);
  rect.height := round(Panel1.Height);
end;

procedure TFMXExternalPumpBrowserFrm.chrmosrJsdialog(      Sender            : TObject;
                                                     const browser           : ICefBrowser;
                                                     const originUrl         : ustring;
                                                           dialogType        : TCefJsDialogType;
                                                     const messageText       : ustring;
                                                     const defaultPromptText : ustring;
                                                     const callback          : ICefJsDialogCallback;
                                                     out   suppressMessage   : Boolean;
                                                     out   Result            : Boolean);
begin
  FJSDialogInfo.OriginUrl         := originUrl;
  FJSDialogInfo.DialogType        := dialogType;
  FJSDialogInfo.MessageText       := messageText;
  FJSDialogInfo.DefaultPromptText := defaultPromptText;
  FJSDialogInfo.Callback          := callback;

  Result             := True;
  suppressMessage    := False;

  TThread.ForceQueue(nil, ShowPendingJSDialog);
end;

procedure TFMXExternalPumpBrowserFrm.ShowPendingJSDialog;
var
  TempCaption : string;
begin
  if FClosing or (FJSDialogInfo.Callback = nil) then exit;

  TempCaption := 'JavaScript message from : ' + FJSDialogInfo.OriginUrl;

  case FJSDialogInfo.DialogType of
    JSDIALOGTYPE_CONFIRM :
      begin
        TempCaption := TempCaption + CRLF + CRLF + FJSDialogInfo.MessageText;
        TDialogServiceAsync.MessageDialog(TempCaption,
                                          TMsgDlgType.mtConfirmation,
                                          [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo],
                                          TMsgDlgBtn.mbYes,
                                          0,
                                          procedure(const AResult: TModalResult)
                                          begin
                                            FJSDialogInfo.Callback.cont(AResult in [mrOk, mrYes], '');
                                            FJSDialogInfo.Callback := nil;
                                          end);
      end;

    JSDIALOGTYPE_PROMPT :
      TDialogServiceAsync.InputQuery(TempCaption,
                                     [FJSDialogInfo.MessageText],
                                     [FJSDialogInfo.DefaultPromptText],
                                     procedure(const AResult: TModalResult; const AValues: array of string)
                                     begin
                                       FJSDialogInfo.Callback.cont(AResult in [mrOk, mrYes], AValues[0]);
                                       FJSDialogInfo.Callback := nil;
                                     end);

    else // JSDIALOGTYPE_ALERT
      begin
        TempCaption := TempCaption + CRLF + CRLF + FJSDialogInfo.MessageText;
        TDialogServiceAsync.ShowMessage(TempCaption);
        FJSDialogInfo.Callback := nil;
      end;
  end;
end;

procedure TFMXExternalPumpBrowserFrm.chrmosrLoadError(Sender: TObject; const browser: ICefBrowser; const frame: ICefFrame; errorCode: TCefErrorCode; const errorText, failedUrl: ustring);
var
  TempString : ustring;
begin
  if (errorCode = ERR_ABORTED) then
    exit;

  TempString := '<html><body bgcolor="white">' +
                '<h2>Failed to load URL ' + failedUrl +
                ' with error ' + errorText +
                ' (' + inttostr(errorCode) + ').</h2></body></html>';

  chrmosr.LoadString(TempString, frame);
end;

procedure TFMXExternalPumpBrowserFrm.chrmosrLoadingStateChange(      Sender       : TObject;
                                                               const browser      : ICefBrowser;
                                                                     isLoading    : Boolean;
                                                                     canGoBack    : Boolean;
                                                                     canGoForward : Boolean);
begin
  if isLoading then
    StatusLbl.Text := 'Loading...'
   else
    StatusLbl.Text := '';
end;

procedure TFMXExternalPumpBrowserFrm.chrmosrPaint(      Sender          : TObject;
                                                  const browser         : ICefBrowser;
                                                        type_           : TCefPaintElementType;
                                                        dirtyRectsCount : NativeUInt;
                                                  const dirtyRects      : PCefRectArray;
                                                  const buffer          : Pointer;
                                                        width           : Integer;
                                                        height          : Integer);
var
  src, dst: PByte;
  i, j, TempLineSize, TempSrcOffset, TempDstOffset, SrcStride, TempWidth, TempHeight : Integer;
  n : NativeUInt;
  {$IFNDEF DELPHI17_UP}
  TempScanlineSize, DstStride : integer;
  {$ENDIF}
  TempBufferBits : Pointer;
  TempForcedResize : boolean;
  TempBitmapData : TBitmapData;
  TempBitmap : TBitmap;
  TempSrcRect, TempDstRect : TRectF;
begin
  try
    FResizeCS.Acquire;
    TempForcedResize := False;

    if Panel1.BeginBufferDraw then
      try
        if (type_ = PET_POPUP) then
          begin
            if (FPopUpBitmap = nil) or
               (width  <> FPopUpBitmap.Width) or
               (height <> FPopUpBitmap.Height) then
              begin
                if (FPopUpBitmap <> nil) then FPopUpBitmap.Free;

                FPopUpBitmap             := TBitmap.Create(width, height);
                {$IFDEF DELPHI17_UP}
                FPopUpBitmap.BitmapScale := Panel1.ScreenScale;
                {$ENDIF}
              end;

            TempWidth        := FPopUpBitmap.Width;
            TempHeight       := FPopUpBitmap.Height;
            {$IFNDEF DELPHI17_UP}
            TempScanlineSize := FPopUpBitmap.BytesPerLine;
            {$ENDIF}
            TempBitmap       := FPopUpBitmap;
          end
         else
          begin
            TempForcedResize := Panel1.UpdateBufferDimensions(Width, Height) or not(Panel1.BufferIsResized(False));
            TempWidth        := Panel1.BufferWidth;
            TempHeight       := Panel1.BufferHeight;
            {$IFNDEF DELPHI17_UP}
            TempScanlineSize := Panel1.ScanlineSize;
            {$ENDIF}
            TempBitmap       := Panel1.Buffer;
          end;


        if (TempBitmap <> nil) {$IFDEF DELPHI17_UP}and TempBitmap.Map(TMapAccess.ReadWrite, TempBitmapData){$ENDIF} then
          begin
            try
              {$IFNDEF DELPHI17_UP}
              TempBufferBits := TempBitmapData.StartLine;
              DstStride      := TempScanlineSize;
              {$ENDIF}
              SrcStride      := Width * SizeOf(TRGBQuad);

              n := 0;

              while (n < dirtyRectsCount) do
                begin
                  if (dirtyRects[n].x >= 0) and (dirtyRects[n].y >= 0) then
                    begin
                      TempLineSize := min(dirtyRects[n].width, TempWidth - dirtyRects[n].x) * SizeOf(TRGBQuad);

                      if (TempLineSize > 0) then
                        begin
                          TempSrcOffset := ((dirtyRects[n].y * Width) + dirtyRects[n].x) * SizeOf(TRGBQuad);

                          {$IFDEF DELPHI17_UP}
                          TempDstOffset := (dirtyRects[n].x * SizeOf(TRGBQuad));
                          {$ELSE}
                          TempDstOffset := (dirtyRects[n].y * TempScanlineSize) + (dirtyRects[n].x * SizeOf(TRGBQuad));
                          {$ENDIF}

                          src := @PByte(buffer)[TempSrcOffset];
                          {$IFNDEF DELPHI17_UP}
                          dst := @PByte(TempBufferBits)[TempDstOffset];
                          {$ENDIF}

                          i := 0;
                          j := min(dirtyRects[n].height, TempHeight - dirtyRects[n].y);

                          while (i < j) do
                            begin
                              {$IFDEF DELPHI17_UP}
                              TempBufferBits := TempBitmapData.GetScanline(dirtyRects[n].y + i);
                              dst            := @PByte(TempBufferBits)[TempDstOffset];
                              {$ENDIF}

                              Move(src^, dst^, TempLineSize);

                              {$IFNDEF DELPHI17_UP}
                              inc(dst, DstStride);
                              {$ENDIF}
                              inc(src, SrcStride);
                              inc(i);
                            end;
                        end;
                    end;

                  inc(n);
                end;

              Panel1.InvalidatePanel;
            finally
              {$IFDEF DELPHI17_UP}
              TempBitmap.Unmap(TempBitmapData);
              {$ENDIF}
            end;

            if FShowPopup and (FPopUpBitmap <> nil) then
              begin
                TempSrcRect := RectF(0, 0,
                                     min(FPopUpRect.Width,  FPopUpBitmap.Width),
                                     min(FPopUpRect.Height, FPopUpBitmap.Height));

                TempDstRect.Left   := FPopUpRect.Left / GlobalCEFApp.DeviceScaleFactor;
                TempDstRect.Top    := FPopUpRect.Top  / GlobalCEFApp.DeviceScaleFactor;
                TempDstRect.Right  := TempDstRect.Left + (TempSrcRect.Width  / GlobalCEFApp.DeviceScaleFactor);
                TempDstRect.Bottom := TempDstRect.Top  + (TempSrcRect.Height / GlobalCEFApp.DeviceScaleFactor);

                Panel1.BufferDraw(FPopUpBitmap, TempSrcRect, TempDstRect);
              end;
          end;

        if (type_ = PET_VIEW) then
          begin
            if TempForcedResize or FPendingResize then
              TThread.ForceQueue(nil, DoResize);

            FResizing      := False;
            FPendingResize := False;
          end;
      finally
        Panel1.EndBufferDraw;
      end;
  finally
    FResizeCS.Release;
  end;
end;

procedure TFMXExternalPumpBrowserFrm.chrmosrPopupShow(      Sender  : TObject;
                                                      const browser : ICefBrowser;
                                                            show    : Boolean);
begin
  if show then
    FShowPopUp := True
   else
    begin
      FShowPopUp := False;
      FPopUpRect := rect(0, 0, 0, 0);

      chrmosr.Invalidate(PET_VIEW);
    end;
end;

procedure TFMXExternalPumpBrowserFrm.chrmosrPopupSize(      Sender  : TObject;
                                                      const browser : ICefBrowser;
                                                      const rect    : PCefRect);
begin
  if (GlobalCEFApp <> nil) then
    begin
      LogicalToDevice(rect^, GlobalCEFApp.DeviceScaleFactor);

      FPopUpRect.Left   := rect.x;
      FPopUpRect.Top    := rect.y;
      FPopUpRect.Right  := rect.x + rect.width  - 1;
      FPopUpRect.Bottom := rect.y + rect.height - 1;
    end;
end;

procedure TFMXExternalPumpBrowserFrm.chrmosrTooltip(      Sender  : TObject;
                                                    const browser : ICefBrowser;
                                                    var   text    : ustring;
                                                    out   Result  : Boolean);
begin
  Panel1.Hint     := text;
  Panel1.ShowHint := (length(text) > 0);
  Result          := True;
end;

procedure TFMXExternalPumpBrowserFrm.DoResize;
begin
  if (chrmosr = nil) or not(chrmosr.Initialized) then
    exit;

  try
    if (FResizeCS <> nil) then
      begin
        FResizeCS.Acquire;

        if FResizing then
          FPendingResize := True
         else
          if Panel1.BufferIsResized then
            chrmosr.Invalidate(PET_VIEW)
           else
            begin
              FResizing := True;
              chrmosr.WasResized;
            end;
      end;
  finally
    if (FResizeCS <> nil) then FResizeCS.Release;
  end;
end;

procedure TFMXExternalPumpBrowserFrm.SetBounds(ALeft, ATop, AWidth, AHeight: Integer);
var
  PositionChanged: Boolean;
begin
  PositionChanged := (ALeft <> Left) or (ATop <> Top);

  inherited SetBounds(ALeft, ATop, AWidth, AHeight);

  if PositionChanged then NotifyMoveOrResizeStarted;
end;

procedure TFMXExternalPumpBrowserFrm.SendCEFKeyEvent(const aCefEvent : TCefKeyEvent);
begin
  chrmosr.SendKeyEvent(@aCefEvent);
end;

procedure TFMXExternalPumpBrowserFrm.NotifyMoveOrResizeStarted;
begin
  if (chrmosr <> nil) then chrmosr.NotifyMoveOrResizeStarted;
end;

procedure TFMXExternalPumpBrowserFrm.SendCaptureLostEvent;
begin
  if (chrmosr <> nil) then chrmosr.SendCaptureLostEvent;
end;

function TFMXExternalPumpBrowserFrm.getModifiers(Shift: TShiftState): TCefEventFlags;
begin
  Result := EVENTFLAG_NONE;

  if (ssShift  in Shift) then Result := Result or EVENTFLAG_SHIFT_DOWN;
  if (ssAlt    in Shift) then Result := Result or EVENTFLAG_ALT_DOWN;
  if (ssCtrl   in Shift) then Result := Result or EVENTFLAG_CONTROL_DOWN;
  if (ssLeft   in Shift) then Result := Result or EVENTFLAG_LEFT_MOUSE_BUTTON;
  if (ssRight  in Shift) then Result := Result or EVENTFLAG_RIGHT_MOUSE_BUTTON;
  if (ssMiddle in Shift) then Result := Result or EVENTFLAG_MIDDLE_MOUSE_BUTTON;
end;

function TFMXExternalPumpBrowserFrm.getModifiers(Button: TMouseButton; Shift: TShiftState): TCefEventFlags;
begin
  Result := getModifiers(shift);

  case Button of
    TMouseButton.mbLeft   : Result := Result or EVENTFLAG_LEFT_MOUSE_BUTTON;
    TMouseButton.mbRight  : Result := Result or EVENTFLAG_RIGHT_MOUSE_BUTTON;
    TMouseButton.mbMiddle : Result := Result or EVENTFLAG_MIDDLE_MOUSE_BUTTON;
  end;
end;

function TFMXExternalPumpBrowserFrm.GetButton(Button: TMouseButton): TCefMouseButtonType;
begin
  case Button of
    TMouseButton.mbRight  : Result := MBT_RIGHT;
    TMouseButton.mbMiddle : Result := MBT_MIDDLE;
    else                    Result := MBT_LEFT;
  end;
end;

procedure TFMXExternalPumpBrowserFrm.SnapshotBtnClick(Sender: TObject);
begin
  if SaveDialog1.Execute then Panel1.SaveToFile(SaveDialog1.FileName);
end;

procedure TFMXExternalPumpBrowserFrm.SnapshotBtnEnter(Sender: TObject);
begin
  chrmosr.SetFocus(False);
end;

end.
