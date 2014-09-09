unit bivTheme_Standard;

(* ***** BEGIN LICENSE BLOCK *****
 * Version: MPL 1.1 or LGPL 2.1 with linking exception
 *
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * Alternatively, the contents of this file may be used under the terms of the
 * Free Pascal modified version of the GNU Lesser General Public License
 * Version 2.1 (the "FPC modified LGPL License"), in which case the provisions
 * of this license are applicable instead of those above.
 * Please see the file LICENSE.txt for additional information concerning this
 * license.
 *
 * The Original Code is bivTheme_Standard
 *
 * The Initial Developer of the Original Code is
 * x2nie < x2nie [at] yahoo [dot] com >
 *
 * Contributor(s):
 *
 * ***** END LICENSE BLOCK ***** *)

interface

uses
  Classes, Controls, Windows,
  GR32,GR32_Layers, Forms, StdCtrls, ExtCtrls,
  bivGrid;

type

  TbivTheme_Standard = class(TbivTheme)
  private
    FScrollValOld,
    FScrollValNew : Integer;

    procedure OnVertScroll(Sender: TObject; ScrollCode: TScrollCode; var ScrollPos: Integer);
    procedure OnHorzScroll(Sender: TObject; ScrollCode: TScrollCode; var ScrollPos: Integer);

  protected
    pnlVert, pnlHorz, pnlDummy: TPanel;
    sbVert: TScrollBar;
    sbHorz: TScrollBar;
    procedure InitUi; override;
    procedure CalculateLayout; override;

    procedure CellAfterPaint(ABuffer: TBitmap32; AIndex: Integer; ARect: TRect);  override;
    procedure PaintBackground(ABuffer: TBitmap32; StageNum: Integer); override;   // PST_CLEAR_BACKGND
    procedure PaintControlFrame(ABuffer: TBitmap32; StageNum: Integer); override;     // PST_CONTROL_FRAME

    procedure AdjustClientRect(var ARect: TRect); override;

  public
    destructor Destroy; override;

  published 

  end;


implementation

uses
  Graphics;  

type
  TbivGridAccess = class(TbivGrid);



{ TbivTheme_Standard }

procedure TbivTheme_Standard.AdjustClientRect(var ARect: TRect);
begin
  InflateRect(ARect, -2, -2); //reduce "client area" by our doube-beveled border
end;

procedure TbivTheme_Standard.CalculateLayout;
var
  L: Single;
begin
  with TbivGridAccess(Grid) do
  begin
    //CellHeight := MIN_THUMBNAIL_SPAN + PicHeight + Grid.Buffer.TextHeight('Hg') + 10 + MIN_THUMBNAIL_SPAN;  
    pnlVert.Visible := CanScrollDown or CanScrollUp;
    if pnlVert.Visible then
    begin
      sbVert.Position := FViewportOffset.Y;
      sbVert.Max := FWorkSize.Y;
      sbVert.PageSize := ClientHeight;
    end;
  end;
end;

procedure TbivTheme_Standard.CellAfterPaint(ABuffer: TBitmap32;
  AIndex: Integer; ARect: TRect);
begin
  if Grid.CellUnderMouse <> AIndex then Exit;
  
  Frame3D(ABuffer.Canvas, ARect, cl3DLight,cl3DDkShadow, 1 );
  Frame3D(ABuffer.Canvas, ARect, clBtnHighlight, clBtnShadow, 1 );
end;

destructor TbivTheme_Standard.Destroy;
begin

  inherited;
end;

procedure TbivTheme_Standard.InitUi;
var
  w, h: integer;

begin
  w := GetSystemMetrics(SM_CXVSCROLL); // Width of a vertical scrollbar...
  h := GetSystemMetrics(SM_CXHSCROLL); // Width of a horizontal scrollbar...

  //Grid.ControlStyle := Grid.ControlStyle + [csFramed];
  pnlHorz := TPanel.Create(Self);
  pnlHorz.Parent := Grid;
  pnlHorz.Align := alBottom;
  pnlHorz.BevelInner := TBevelCut(0);
  pnlHorz.BevelOuter := TBevelCut(0);
  pnlHorz.Height := h;
  //pnlHorz.ParentBackground := false;
  pnlHorz.Visible := false;


  pnlVert := TPanel.Create(Self);
  pnlVert.Parent := Grid;
  pnlVert.Align := alRight;
  pnlVert.BevelInner := TBevelCut(0);
  pnlVert.BevelOuter := TBevelCut(0);
  pnlVert.Width := w;
  //pnlVert.ParentBackground := false;
  pnlVert.Visible := false;
  pnlDummy := TPanel.Create(pnlHorz);
  pnlDummy.Parent := pnlHorz;
  pnlDummy.Align := alRight;
  pnlDummy.BevelInner := TBevelCut(0);
  pnlDummy.BevelOuter := TBevelCut(0);
  pnlDummy.Width := w;
  //pnlDummy.ParentBackground := false;
  pnlDummy.Visible := false;
  sbVert := TScrollBar.Create(pnlVert);
  sbVert.Parent := pnlVert;
  sbVert.Kind := sbVertical;
  sbVert.LargeChange := 1;
  sbVert.SmallChange := 1;
  sbVert.Align := alClient;
  sbVert.OnScroll := OnVertScroll;
  sbVert.TabStop := false;
  sbVert.Visible := true;
  sbHorz := TScrollBar.Create(pnlHorz);
  sbHorz.Parent := pnlHorz;
  sbHorz.Kind := sbHorizontal;
  sbHorz.LargeChange := 1;
  sbHorz.SmallChange := 1;
  sbHorz.Align := alClient;
  sbHorz.OnScroll := OnHorzScroll;
  sbHorz.TabStop := false;
  sbHorz.Visible := true;
  //hsbVisible := false;
  //vsbVisible := false;


  Self.CalculateLayout;
end;

procedure TbivTheme_Standard.OnHorzScroll(Sender: TObject;
  ScrollCode: TScrollCode; var ScrollPos: Integer);
begin
  Grid.Invalidate;
end;

procedure TbivTheme_Standard.OnVertScroll(Sender: TObject;
  ScrollCode: TScrollCode; var ScrollPos: Integer);
var FScrollPos : Integer;  
begin
  FScrollValOld := FScrollValNew;
  FScrollValNew := ScrollPos;
  FScrollPos := FScrollValOld - FScrollValNew;
  if FScrollValOld <> FScrollValNew then
  begin
    {if IsEditing then
      SetFocus;
    IsEditing := False;}
    TbivGridAccess(Grid).FViewportOffset.Y := ScrollPos;
    Grid.Invalidate;
  end;
end;

procedure TbivTheme_Standard.PaintBackground(ABuffer: TBitmap32;
  StageNum: Integer);
begin
  ABuffer.Clear(Color32(clWindow));
end;

procedure TbivTheme_Standard.PaintControlFrame(ABuffer: TBitmap32;
  StageNum: Integer);
var R : TRect;
  H,S : TColor;
begin
  R := Grid.ClientRect;
  //InflateRect(R,-1,-1);
  Frame3D(ABuffer.Canvas, R, clBtnShadow, clBtnHighlight ,1 );
  //InflateRect(R,-1,-1);
  Frame3D(ABuffer.Canvas, R, cl3DDkShadow, cl3DLight,1 );
end;

end.
