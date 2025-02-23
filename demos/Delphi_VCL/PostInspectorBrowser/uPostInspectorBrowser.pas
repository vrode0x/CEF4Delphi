unit uPostInspectorBrowser;

{$I ..\..\..\source\cef.inc}

interface

uses
  {$IFDEF DELPHI16_UP}
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, System.SyncObjs,
  {$ELSE}
  Windows, Messages, SysUtils, Variants, Classes, Graphics,
  Controls, Forms, Dialogs, StdCtrls, ExtCtrls, SyncObjs,
  {$ENDIF}
  uCEFChromium, uCEFWindowParent, uCEFInterfaces, uCEFConstants, uCEFTypes,
  uCEFWinControl, uCEFChromiumCore;

const
  CEF_SHOWDATA  = WM_APP + $B00;

type
  TForm1 = class(TForm)
    AddressPnl: TPanel;
    GoBtn: TButton;
    Timer1: TTimer;
    Chromium1: TChromium;
    CEFWindowParent1: TCEFWindowParent;
    Memo1: TMemo;
    AddressCb: TComboBox;
    Splitter1: TSplitter;

    procedure GoBtnClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);

    procedure FormShow(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormDestroy(Sender: TObject);

    procedure Chromium1AfterCreated(Sender: TObject; const browser: ICefBrowser);
    procedure Chromium1BeforePopup(Sender: TObject; const browser: ICefBrowser; const frame: ICefFrame; popup_id: Integer; const targetUrl, targetFrameName: ustring; targetDisposition: TCefWindowOpenDisposition; userGesture: Boolean; const popupFeatures: TCefPopupFeatures; var windowInfo: TCefWindowInfo; var client: ICefClient; var settings: TCefBrowserSettings; var extra_info: ICefDictionaryValue; var noJavascriptAccess: Boolean; var Result: Boolean);
    procedure Chromium1BeforeClose(Sender: TObject; const browser: ICefBrowser);
    procedure Chromium1BeforeResourceLoad(Sender: TObject; const browser: ICefBrowser; const frame: ICefFrame; const request: ICefRequest; const callback: ICefCallback; out Result: TCefReturnValue);

  protected
    // Variables to control when can we destroy the form safely
    FCanClose : boolean;  // Set to True in TChromium.OnBeforeClose
    FClosing  : boolean;  // Set to True in the CloseQuery event.

    FRequestSL      : TStringList;
    FRequestCS      : TCriticalSection;

    // You have to handle this two messages to call NotifyMoveOrResizeStarted or some page elements will be misaligned.
    procedure WMMove(var aMessage : TWMMove); message WM_MOVE;
    procedure WMMoving(var aMessage : TMessage); message WM_MOVING;
    // You also have to handle these two messages to set GlobalCEFApp.OsmodalLoop
    procedure WMEnterMenuLoop(var aMessage: TMessage); message WM_ENTERMENULOOP;
    procedure WMExitMenuLoop(var aMessage: TMessage); message WM_EXITMENULOOP;

    procedure BrowserCreatedMsg(var aMessage : TMessage); message CEF_AFTERCREATED;
    procedure ShowDataMsg(var aMessage : TMessage); message CEF_SHOWDATA;

    procedure HandleRequest(const request : ICefRequest; aIsMain : boolean);
    procedure HandleHeaderMap(const request : ICefRequest);
    procedure HandlePostData(const request : ICefRequest);
    procedure HandlePostDataBytes(const aElement : ICefPostDataElement);
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

procedure CreateGlobalCEFApp;

implementation

{$R *.dfm}

uses
  uCEFApplication, uCefMiscFunctions, uCEFStringMultimap;

// This demo shows how to inspect the data sent in all requests for all the resources.

// We use the TChromium.OnBeforeResourceLoad event to handle the request but this event
// is executed in a different thread. This means that we have to protect the data with a
// critical section when we handle it.

// After the request has been handled we send a custom message to the form (CEF_SHOWDATA)
// to add the information to the TMemo safely in the main thread.

// Destruction steps
// =================
// 1. FormCloseQuery sets CanClose to FALSE, destroys CEFWindowParent1 and calls TChromium.CloseBrowser which triggers the TChromium.OnBeforeClose event.
// 2. TChromium.OnBeforeClose sets FCanClose := True and sends WM_CLOSE to the form.

procedure CreateGlobalCEFApp;
begin
  GlobalCEFApp                  := TCefApplication.Create;
  //GlobalCEFApp.LogFile          := 'cef.log';
  //GlobalCEFApp.LogSeverity      := LOGSEVERITY_VERBOSE;
end;

procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := FCanClose;

  if not(FClosing) then
    begin
      FClosing := True;
      Visible  := False;
      Chromium1.CloseBrowser(True);
      CEFWindowParent1.Free;
    end;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  FCanClose := False;
  FClosing  := False;

  Chromium1.DefaultURL := AddressCb.Text;

  FRequestSL := TStringList.Create;
  FRequestCS := TCriticalSection.Create;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  FRequestSL.Free;
  FRequestCS.Free;
end;

procedure TForm1.FormShow(Sender: TObject);
begin
  // You *MUST* call CreateBrowser to create and initialize the browser.
  // This will trigger the AfterCreated event when the browser is fully
  // initialized and ready to receive commands.

  // GlobalCEFApp.GlobalContextInitialized has to be TRUE before creating any browser
  // If it's not initialized yet, we use a simple timer to create the browser later.
  if not(Chromium1.CreateBrowser(CEFWindowParent1)) then Timer1.Enabled := True;
end;

procedure TForm1.Chromium1AfterCreated(Sender: TObject; const browser: ICefBrowser);
begin
  // Now the browser is fully initialized we can send a message to the main form to load the initial web page.
  PostMessage(Handle, CEF_AFTERCREATED, 0, 0);
end;

procedure TForm1.HandleRequest(const request : ICefRequest; aIsMain : boolean);
begin
  try
    if (FRequestCS <> nil) then FRequestCS.Acquire;

    if (FRequestSL <> nil) then
      begin
        FRequestSL.Add('--------------------');
        FRequestSL.Add('URL : ' + request.url);
        FRequestSL.Add('Method : ' + request.Method);
        FRequestSL.Add('Main frame : ' + BoolToStr(aIsMain, true));

        HandleHeaderMap(request);
        HandlePostData(request);

        PostMessage(Handle, CEF_SHOWDATA, 0, 0);
      end;
  finally
    if (FRequestCS <> nil) then FRequestCS.Release;
  end;
end;

procedure TForm1.HandleHeaderMap(const request : ICefRequest);
var
  TempHeaderMap : ICefStringMultimap;
  i             : NativeUInt;
begin
  try
    TempHeaderMap := TCefStringMultimapOwn.Create;
    request.GetHeaderMap(TempHeaderMap);

    if (TempHeaderMap <> nil) and (TempHeaderMap.Size > 0) then
      begin
        FRequestSL.Add('--------------------');
        FRequestSL.Add('Headers :');

        i := 0;

        while (i < TempHeaderMap.Size) do
          begin
            FRequestSL.Add(TempHeaderMap.Key[i] + '=' + TempHeaderMap.Value[i]);
            inc(i);
          end;
      end;
  except
    on e : exception do
      begin
        if CustomExceptionHandler('TForm1.HandleHeaderMap', e) then raise;
      end;
  end;
end;

procedure TForm1.HandlePostData(const request : ICefRequest);
var
  TempPostData  : ICefPostData;
  TempArray     : TCefPostDataElementArray;
  i             : integer;
begin
  TempArray := nil;

  try
    try
      TempPostData := request.PostData;

      if (TempPostData <> nil) and (TempPostData.GetElementCount > 0) then
        begin
          FRequestSL.Add('--------------------');
          FRequestSL.Add('POST data :');
          if TempPostData.HasExcludedElements then
            FRequestSL.Add('Has excluded elements! (For example, multi-part file upload data.)');

          TempPostData.GetElements(TempPostData.GetElementCount, TempArray);

          i := 0;
          while (i < length(TempArray)) do
            begin
              FRequestSL.Add('Element : ' + inttostr(i));
              FRequestSL.Add('Size : ' + inttostr(TempArray[i].GetBytesCount));

              case TempArray[i].GetType of
                PDE_TYPE_BYTES :
                  begin
                    FRequestSL.Add('Type : Bytes');
                    HandlePostDataBytes(TempArray[i]);
                  end;

                PDE_TYPE_FILE :
                  begin
                    FRequestSL.Add('Type : File');
                    // This element type can be read using a TBuffer like we do in HandlePostDataBytes
                  end

                else
                  FRequestSL.Add('Type : Empty');
              end;

              inc(i);
            end;

          // Set interfaces to nil to release them
          i := 0;
          while (i < length(TempArray)) do
            begin
              TempArray[i] := nil;
              inc(i);
            end;
        end;
    except
      on e : exception do
        if CustomExceptionHandler('TForm1.HandlePostData', e) then raise;
    end;
  finally
    if (TempArray <> nil) then
      begin
        Finalize(TempArray);
        TempArray := nil;
      end;
  end;
end;

procedure TForm1.HandlePostDataBytes(const aElement : ICefPostDataElement);
var
  TempStream : TStringStream;
  TempBuffer : TBytes;
  TempSize   : NativeUInt;
begin
  TempStream := nil;
  TempBuffer := nil;

  try
    try
      if (aElement <> nil) and (aElement.GetBytesCount > 0) then
        begin
          SetLength(TempBuffer, aElement.GetBytesCount);
          TempSize := aElement.GetBytes(aElement.GetBytesCount, @TempBuffer[0]);

          if (TempSize > 0) then
            begin
              TempStream := TStringStream.Create;
              TempStream.WriteBuffer(TempBuffer, TempSize);
              TempStream.Seek(0, soBeginning);
              FRequestSL.Add(TempStream.ReadString(TempSize));
            end;
        end;
    except
      on e : exception do
        if CustomExceptionHandler('TForm1.HandlePostDataBytes', e) then raise;
    end;
  finally
    if (TempStream <> nil) then FreeAndNil(TempStream);
    SetLength(TempBuffer, 0);
  end;
end;

procedure TForm1.Chromium1BeforeResourceLoad(Sender: TObject;
  const browser: ICefBrowser; const frame: ICefFrame;
  const request: ICefRequest; const callback: ICefCallback;
  out Result: TCefReturnValue);
begin
  // This event is called before a resource request is loaded.
  // The request object may be modified.
  if (frame <> nil) and frame.IsValid then
    HandleRequest(request, frame.IsMain);

  Result := RV_CONTINUE;
end;

procedure TForm1.ShowDataMsg(var aMessage : TMessage);
begin
  try
    if (FRequestCS <> nil) then FRequestCS.Acquire;

    if (FRequestSL <> nil) then
      begin
        Memo1.lines.AddStrings(FRequestSL);
        FRequestSL.Clear;
      end;
  finally
    if (FRequestCS <> nil) then FRequestCS.Release;
    // Scroll to the last memo line
    SendMessage(Memo1.Handle, EM_LINESCROLL, 0, Memo1.Lines.Count);
  end;
end;

procedure TForm1.Chromium1BeforeClose(Sender: TObject; const browser: ICefBrowser);
begin
  FCanClose := True;
  PostMessage(Handle, WM_CLOSE, 0, 0);
end;

procedure TForm1.Chromium1BeforePopup(Sender: TObject;
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

procedure TForm1.BrowserCreatedMsg(var aMessage : TMessage);
begin
  Caption            := 'POST Inspector Browser';
  AddressPnl.Enabled := True;
end;

procedure TForm1.GoBtnClick(Sender: TObject);
begin
  // This will load the URL in the edit box
  Chromium1.LoadURL(AddressCb.Text);
end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
  Timer1.Enabled := False;
  if not(Chromium1.CreateBrowser(CEFWindowParent1)) and not(Chromium1.Initialized) then
    Timer1.Enabled := True;
end;

procedure TForm1.WMMove(var aMessage : TWMMove);
begin
  inherited;

  if (Chromium1 <> nil) then Chromium1.NotifyMoveOrResizeStarted;
end;

procedure TForm1.WMMoving(var aMessage : TMessage);
begin
  inherited;

  if (Chromium1 <> nil) then Chromium1.NotifyMoveOrResizeStarted;
end;

procedure TForm1.WMEnterMenuLoop(var aMessage: TMessage);
begin
  inherited;

  if (aMessage.wParam = 0) and (GlobalCEFApp <> nil) then GlobalCEFApp.OsmodalLoop := True;
end;

procedure TForm1.WMExitMenuLoop(var aMessage: TMessage);
begin
  inherited;

  if (aMessage.wParam = 0) and (GlobalCEFApp <> nil) then GlobalCEFApp.OsmodalLoop := False;
end;

end.
