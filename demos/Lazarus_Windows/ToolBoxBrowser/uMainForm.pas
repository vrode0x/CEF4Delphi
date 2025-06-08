﻿unit uMainForm;

{$MODE Delphi}

{$I ..\..\..\source\cef.inc}

interface

uses
  LCLIntf, LCLType, LMessages, Messages, SysUtils, Variants, Classes, Graphics,
  Controls, Forms, Dialogs, StdCtrls, ExtCtrls;

const
  CEFBROWSER_CREATED          = WM_APP + $100;
  CEFBROWSER_CHILDDESTROYED   = WM_APP + $101;
  CEFBROWSER_DESTROY          = WM_APP + $102;
  CEFBROWSER_INITIALIZED      = WM_APP + $103;

type

  { TMainForm }

  TMainForm = class(TForm)
    ButtonPnl: TPanel;
    Edit1: TEdit;
    Button1: TButton;
    procedure CEFSentinel1Close(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    // Variables to control when can we destroy the form safely
    FCanClose : boolean;  // Set to True when all the child forms are closed
    FClosing  : boolean;  // Set to True in the CloseQuery event.

    procedure CreateToolboxChild(const ChildCaption, URL: string);
    procedure CloseAllChildForms;
    function  GetChildClosing : boolean;
    function  GetChildFormCount : integer;

  protected
    procedure ChildDestroyedMsg(var aMessage : TMessage); message CEFBROWSER_CHILDDESTROYED;
    procedure CEFInitializedMsg(var aMessage : TMessage); message CEFBROWSER_INITIALIZED;

  public
    function CloseQuery: Boolean; override;

    property ChildClosing : boolean read GetChildClosing;
    property ChildFormCount : integer read GetChildFormCount;
  end;

var
  MainForm: TMainForm;

procedure CreateGlobalCEFApp;

implementation

{$R *.lfm}

uses
  uChildForm, uCEFApplication;

// Destruction steps
// =================
// 1. Destroy all child forms
// 2. Wait until all the child forms are closed before closing the main form.

procedure GlobalCEFApp_OnContextInitialized;
begin
  if (MainForm <> nil) and MainForm.HandleAllocated then
    PostMessage(MainForm.Handle, CEFBROWSER_INITIALIZED, 0, 0);
end;

procedure CreateGlobalCEFApp;
begin
  GlobalCEFApp                      := TCefApplication.Create;
  GlobalCEFApp.OnContextInitialized := GlobalCEFApp_OnContextInitialized;
  GlobalCEFApp.SetCurrentDir        := True;
end;

procedure TMainForm.CreateToolboxChild(const ChildCaption, URL: string);
var
  TempChild : TChildForm;
begin
  TempChild          := TChildForm.Create(self);
  TempChild.Caption  := ChildCaption;
  TempChild.Homepage := URL;
  TempChild.Show;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  FCanClose := False;
  FClosing  := False;
end;

procedure TMainForm.CEFSentinel1Close(Sender: TObject);
begin

end;

procedure TMainForm.CloseAllChildForms;
var
  i : integer;
  TempComponent : TComponent;
begin
  i := pred(ComponentCount);

  while (i >= 0) do
    begin
      TempComponent := Components[i];

      if (TempComponent <> nil) and
         (TempComponent is TChildForm) and
         not(TChildForm(Components[i]).Closing) then
        PostMessage(TChildForm(Components[i]).Handle, WM_CLOSE, 0, 0);

      dec(i);
    end;
end;

function TMainForm.GetChildClosing : boolean;
var
  i : integer;
  TempComponent : TComponent;
begin
  Result := false;
  i      := pred(ComponentCount);

  while (i >= 0) do
    begin
      TempComponent := Components[i];

      if (TempComponent <> nil) and
         (TempComponent is TChildForm) then
        begin
          if TChildForm(Components[i]).Closing then
            begin
              Result := True;
              exit;
            end
           else
            dec(i);
        end
       else
        dec(i);
    end;
end;

function TMainForm.GetChildFormCount : integer;
var
  i : integer;
  TempComponent : TComponent;
begin
  Result := 0;
  i      := pred(ComponentCount);

  while (i >= 0) do
    begin
      TempComponent := Components[i];

      if (TempComponent <> nil) and
         (TempComponent is TChildForm) then
        inc(Result);

      dec(i);
    end;
end;

procedure TMainForm.Button1Click(Sender: TObject);
begin
  CreateToolboxChild('Browser', Edit1.Text);
end;

procedure TMainForm.ChildDestroyedMsg(var aMessage : TMessage);
begin
  // If there are no more child forms we start the sentinel
  if FClosing and (ChildFormCount = 0) then
    begin
      FCanClose := True;
      PostMessage(Handle, WM_CLOSE, 0, 0);
    end;
end;

function TMainForm.CloseQuery: Boolean;
begin
  if FClosing or ChildClosing then
    Result := FCanClose
   else
    begin
      FClosing := True;

      if (ChildFormCount = 0) then
        Result := True
       else
        begin
          Result          := False;
          Edit1.Enabled   := False;
          Button1.Enabled := False;

          CloseAllChildForms;
        end;
    end;
end;

procedure TMainForm.CEFInitializedMsg(var aMessage : TMessage);
begin
  Caption           := 'ToolBox Browser';
  ButtonPnl.Enabled := True;
  cursor            := crDefault;
end;

procedure TMainForm.FormShow(Sender: TObject);
begin
  if (GlobalCEFApp <> nil) and GlobalCEFApp.GlobalContextInitialized then
    begin
      Caption           := 'ToolBox Browser';
      ButtonPnl.Enabled := True;
      cursor            := crDefault;
    end;
end;

end.
