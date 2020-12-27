// ************************************************************************
// ***************************** CEF4Delphi *******************************
// ************************************************************************
//
// CEF4Delphi is based on DCEF3 which uses CEF3 to embed a chromium-based
// browser in Delphi applications.
//
// The original license of DCEF3 still applies to CEF4Delphi.
//
// For more information about CEF4Delphi visit :
//         https://www.briskbard.com/index.php?lang=en&pageid=cef
//
//        Copyright � 2018 Salvador Diaz Fau. All rights reserved.
//
// ************************************************************************
// ************ vvvv Original license and comments below vvvv *************
// ************************************************************************
(*
 *                       Delphi Chromium Embedded 3
 *
 * Usage allowed under the restrictions of the Lesser GNU General Public License
 * or alternatively the restrictions of the Mozilla Public License 1.1
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for
 * the specific language governing rights and limitations under the License.
 *
 * Unit owner : Henri Gourvest <hgourvest@gmail.com>
 * Web site   : http://www.progdigy.com
 * Repository : http://code.google.com/p/delphichromiumembedded/
 * Group      : http://groups.google.com/group/delphichromiumembedded
 *
 * Embarcadero Technologies, Inc is not permitted to use or redistribute
 * this source code without explicit permission.
 *
 *)

unit uCEFWinControl;

{$IFDEF FPC}
  {$MODE OBJFPC}{$H+}
{$ENDIF}

{$IFNDEF CPUX64}{$ALIGN ON}{$ENDIF}
{$MINENUMSIZE 4}

{$I cef.inc}

interface

uses
  {$IFDEF DELPHI16_UP}
    {$IFDEF MSWINDOWS}WinApi.Windows, {$ENDIF} System.Classes, Vcl.Controls, Vcl.Graphics,
  {$ELSE}
    {$IFDEF MSWINDOWS}Windows,{$ENDIF} Classes, Forms, Controls, Graphics,
    {$IFDEF FPC}
    LCLProc, LCLType, LCLIntf, LResources, InterfaceBase,
    {$ENDIF}
  {$ENDIF}
  uCEFTypes, uCEFInterfaces;

type

  { TCEFWinControl }

  TCEFWinControl = class(TWinControl)
    protected
      function  GetChildWindowHandle : THandle; virtual;
      procedure DoOnResize; override; //vr
      procedure Resize; override;

    public
      function  TakeSnapshot(var aBitmap : TBitmap) : boolean;
      function  DestroyChildWindow : boolean;
      procedure CreateHandle; override;
      procedure InvalidateChildren;
      procedure UpdateSize;

      property  ChildWindowHandle : THandle   read GetChildWindowHandle;

    published
      property  Align;
      property  Anchors;
      property  Color;
      property  Constraints;
      property  TabStop;
      property  TabOrder;
      property  Visible;
      property  Enabled;
      property  ShowHint;
      property  Hint;
      property  OnResize;
      property  DoubleBuffered;
      {$IFDEF DELPHI12_UP}
      property  ParentDoubleBuffered;
      {$ENDIF}
  end;

implementation

uses
  uCEFMiscFunctions, uCEFClient, uCEFConstants;

function TCEFWinControl.GetChildWindowHandle : THandle;
begin
  if not(csDesigning in ComponentState) and HandleAllocated then
    Result := {$IFDEF WINDOWS}{//vr}GetWindow(Handle, GW_CHILD){$ELSE}0{$ENDIF}
   else
    Result := 0;
end;

procedure TCEFWinControl.CreateHandle;
begin
  inherited CreateHandle;
end;

procedure TCEFWinControl.InvalidateChildren;
begin
  if HandleAllocated then RedrawWindow(Handle, nil, 0, RDW_INVALIDATE or RDW_ALLCHILDREN);
end;

procedure TCEFWinControl.UpdateSize;
var
  TempRect : TRect;
  TempHWND : THandle;
begin
  TempHWND := ChildWindowHandle;
  if (TempHWND = 0) then exit;

  TempRect := GetClientRect;

  SetWindowPos(TempHWND, 0,
               0, 0, TempRect.right, TempRect.bottom,
               SWP_NOZORDER);
end;

function TCEFWinControl.TakeSnapshot(var aBitmap : TBitmap) : boolean;
var
  TempHWND   : HWND;
  TempDC     : HDC;
  TempRect   : TRect;
  TempWidth  : Integer;
  TempHeight : Integer;
begin
  Result := False;
  if (aBitmap = nil) then exit;

  TempHWND := ChildWindowHandle;
  if (TempHWND = 0) then exit;

  {$IFDEF WINDOWS}//vr
  {$IFDEF DELPHI16_UP}Winapi.{$ENDIF}Windows.GetClientRect(TempHWND, TempRect);
  {$ELSE}
  TempRect := GetClientRect;{$ENDIF}
  TempDC     := GetDC(TempHWND);
  TempWidth  := TempRect.Right  - TempRect.Left;
  TempHeight := TempRect.Bottom - TempRect.Top;

  aBitmap        := TBitmap.Create;
  aBitmap.Height := TempHeight;
  aBitmap.Width  := TempWidth;

  Result := BitBlt(aBitmap.Canvas.Handle, 0, 0, TempWidth, TempHeight,
                   TempDC, 0, 0, SRCCOPY);

  ReleaseDC(TempHWND, TempDC);
end;

function TCEFWinControl.DestroyChildWindow : boolean;
var
  TempHWND : HWND;
begin
  TempHWND := ChildWindowHandle;
  {$IFDEF WINDOWS}//vr
  Result   := (TempHWND <> 0) and DestroyWindow(TempHWND);
  {$ELSE}
  Result := False;//always TempHWND = 0;
  {$ENDIF}
end;

procedure TCEFWinControl.DoOnResize; //vr >>>
begin
  inherited DoOnResize;
  UpdateSize;
end;

procedure TCEFWinControl.Resize;
begin
  inherited Resize;

  //vr UpdateSize;
end;

end.
