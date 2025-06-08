﻿unit uWebpageSnapshot;

{$MODE Delphi}

{$I ..\..\..\source\cef.inc}

interface

uses
  LCLIntf, LCLType, LMessages, Messages, SysUtils, Variants, Classes,
  Graphics, Controls, Forms, Dialogs, StdCtrls, ComCtrls, ExtCtrls,
  uCEFBrowserThread;

type
  TWebpageSnapshotFrm = class(TForm)
    StatusBar1: TStatusBar;
    Image1: TImage;
    NavigationPnl: TPanel;
    GoBtn: TButton;
    AddressEdt: TEdit;
    procedure GoBtnClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);

  private
    FThread : TCEFBrowserThread;

    procedure Thread_OnError(Sender: TObject);
    procedure Thread_OnSnapshotAvailable(Sender: TObject);
  end;

var
  WebpageSnapshotFrm: TWebpageSnapshotFrm;

// This demo shows how to encapsulate a browser without user interface in a thread.

// The thread in the uCEFBrowserThread unit has a browser in "off-screen" mode
// and it takes a snapshot when the browser has loaded a web page.

// The thread triggers the TCEFBrowserThread.OnSnapshotAvailable when the main thread
// can copy the snapshot in a bitmap.

// If there's an error loading the page then TCEFBrowserThread.OnError will be
// triggered and the error information will be available in the
// TCEFBrowserThread.ErrorCode, TCEFBrowserThread.ErrorText and
// TCEFBrowserThread.FailedUrl properties.

// The TCEFBrowserThread.Create constructor has the default URL, virtual screen size,
// virtual screen scale and a delay as parameters. The delay is applied after the browser
// has finished loading the main frame and before taking the snapshot.

procedure CreateGlobalCEFApp;

implementation

{$R *.lfm}

uses
  uCEFApplication;

procedure CreateGlobalCEFApp;
begin
  GlobalCEFApp                            := TCefApplication.Create;
  GlobalCEFApp.WindowlessRenderingEnabled := True;
  GlobalCEFApp.SetCurrentDir              := True;
end;

procedure TWebpageSnapshotFrm.GoBtnClick(Sender: TObject);
begin
  StatusBar1.Panels[0].Text := 'Loading...';
  screen.cursor := crAppStart;

  if (FThread = nil) then
    begin
      FThread                     := TCEFBrowserThread.Create(AddressEdt.Text, 1024, 768);
      FThread.OnError             := Thread_OnError;
      FThread.OnSnapshotAvailable := Thread_OnSnapshotAvailable;
      FThread.SyncEvents          := True;
      FThread.Start;
    end
   else
    FThread.LoadUrl(AddressEdt.Text);
end;

procedure TWebpageSnapshotFrm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if (FThread <> nil) then
    begin
      if FThread.TerminateBrowserThread then
        FThread.WaitFor;

      FreeAndNil(FThread);
    end;

  CanClose := True;
end;

procedure TWebpageSnapshotFrm.FormCreate(Sender: TObject);
begin
  FThread := nil;
end;

procedure TWebpageSnapshotFrm.Thread_OnError(Sender: TObject);
begin
  StatusBar1.Panels[0].Text := 'Error ' + inttostr(FThread.ErrorCode) + ' : ' + FThread.ErrorText + ' - ' + FThread.FailedUrl;
  screen.cursor := crDefault;
end;

procedure TWebpageSnapshotFrm.Thread_OnSnapshotAvailable(Sender: TObject);
var
  TempBitmap : TBitmap;
begin
  TempBitmap    := nil;
  screen.cursor := crDefault;

  if (FThread <> nil) and FThread.CopySnapshot(TempBitmap) then
    begin
      Image1.Picture.Assign(TempBitmap);
      StatusBar1.Panels[0].Text := 'Snapshot copied successfully';
      TempBitmap.Free;
    end
   else
    StatusBar1.Panels[0].Text := 'There was an error copying the snapshot';
end;

end.
