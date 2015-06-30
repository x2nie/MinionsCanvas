unit icTool_LcdLine;

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
 * The Initial Developer of the Original Code is
 *   x2nie  < x2nie[at]yahoo[dot]com >
 *
 *
 * Contributor(s):
 *
 *
 * ***** END LICENSE BLOCK ***** *)

interface

uses
  Classes, Controls, SysUtils,
  GR32,
  icBase, icLayers;

type
  TicToolLcdLine = class(TicTool)
  private
    FCmd : TicCmdLayer_Modify;
  
    FMouseButtonDown : Boolean;
    FFirstDotIndex : TPoint;
    FLastDot : TRect;
    //used when current rect is smaller than previous rect, for also update prior rect
    FLastBitPlanPaintedRect: TRect;
    FLastColor : TColor32;
    FTempBmp : TBitmap32;
  protected
    //Events. Polymorpism.
    procedure MouseDown(Sender: TicPaintBox; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer; Layer: TicLayer); override;
    procedure MouseMove(Sender: TicPaintBox; Shift: TShiftState; X,
      Y: Integer; Layer: TicLayer); override;
    procedure MouseUp(Sender: TicPaintBox; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer; Layer: TicLayer); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published 

  end;



implementation

uses
  Forms, //for debug : application.mainform
  Math, icLiquidCrystal;
{ TicToolBrushSimple }

constructor TicToolLcdLine.Create(AOwner: TComponent);
begin
  inherited;
  Cursor := crCross;
  FTempBmp := TBitmap32.Create;
end;

destructor TicToolLcdLine.Destroy;
begin
  FTempBmp.Free;
  inherited;
end;

procedure TicToolLcdLine.MouseDown(Sender: TicPaintBox;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer;
  Layer: TicLayer);
var
  LRect  : TRect;
  LBmpXY : TPoint;
  LLayer : TicLiquidCrystal;
begin
  if (Layer is TicLiquidCrystal) and (Button in [mbLeft,mbRight]) then
  begin
    FCmd := TicCmdLayer_Modify.Create(GIntegrator.ActivePaintBox.UndoRedo);
    FCmd.ChangingLayer(Layer);
  
    FMouseButtonDown := True;
    LBmpXY := Sender.ControlToBitmap( Point(X, Y) );
    LLayer := TicLiquidCrystal(Layer);

    FTempBmp.Assign(LLayer.BitPlane);

    //Allow invalid point for later use in mousemove to draw stright line from this
    FLastDot := LLayer.BlockCoordinateLocation(LBmpXY.X, LBmpXY.Y, True);
    if Button=mbLeft then
      FLastColor := clWhite32
    else
      FLastColor := 0;

    FFirstDotIndex := LLayer.DotIndex(FLastDot);

    //dont allow invalid point, since we actually modify pixel
    LRect := LLayer.BlockCoordinateLocation(LBmpXY.X, LBmpXY.Y, False);
    if not EqualRect(LRect, GInvalidRect) then
    begin
      {}

      LLayer.BitPlane.BeginUpdate;//prevent redraw
      LLayer.BitPlane.PixelS[FFirstDotIndex.X, FFirstDotIndex.Y] :=  FLastColor;
      LLayer.BitPlane.EndUpdate;

      LRect.TopLeft     := FFirstDotIndex;
      LRect.BottomRight := FFirstDotIndex;
      //InflateRect(LRect, 1,1);
      //LLayer.BitPlane.Changed(LRect);
      LLayer.RebuildDots(LRect);
      Layer.Changed(LLayer.AreaChanged);
      //Layer.Changed(LRect);
      //MouseMove(Sender, Shift, X,Y, Layer);
    end
    else
      Application.MainForm.Caption := 'outside lcd range!';
  end;
end;


type
  TicLiquidCrystal1 = class(TicLiquidCrystal);

procedure TicToolLcdLine.MouseMove(Sender: TicPaintBox; Shift: TShiftState;
  X, Y: Integer; Layer: TicLayer);
  procedure MyUnionRect(out Rect: TRect; const R1, R2: TRect);
  begin
    Rect := R1;
    if not IsRectEmpty(R2) then
    begin
      if R2.Left < R1.Left then Rect.Left := R2.Left;
      if R2.Top < R1.Top then Rect.Top := R2.Top;
      if R2.Right > R1.Right then Rect.Right := R2.Right;
      if R2.Bottom > R1.Bottom then Rect.Bottom := R2.Bottom;
    end;
    //Result := not IsRectEmpty(Rect);
    //if not Result then Rect := ZERO_RECT;
  end;
var
  LDot, R,R2  : TRect;
  P,P2,LPoint,LLastDotIndex : TPoint;
  LLayer : TicLiquidCrystal;
begin
  if Layer is TicLiquidCrystal then
  begin
    LPoint := Sender.ControlToBitmap( Point(X, Y) );
    LLayer := TicLiquidCrystal(Layer);
    LDot := LLayer.BlockCoordinateLocation(LPoint.X, LPoint.Y, True);
    LLastDotIndex := LLayer.DotIndex(LDot);

    //Application.MainForm.Caption := format('mouse X:%d,  Y:%d    cx:%d, cy:%d',[X,Y, LPoint.X, LPoint.Y]);
    with LDot, LLastDotIndex do Application.MainForm.Caption := format('X:%d,  Y:%d    cx:%d, cy:%d  DI.x:%d, DI.y:%d  Upd:%d',[Left, Top, Right, Bottom, X,Y, TicLiquidCrystal1(LLayer).UpdateCount]);
    //with LLastDotIndex do  R := LLayer.DotPixelRect(X, Y);    Application.MainForm.Caption := format('(%d, %d)   %d, %d, %d, %d',[LPoint.X,LPoint.Y,  r.Left, r.Right, r.Top, r.Bottom]);
  end
  else Application.MainForm.Caption := 'non lcd';


  if FMouseButtonDown then
  begin
    LPoint := Sender.ControlToBitmap( Point(X, Y) );


    LLayer := TicLiquidCrystal(Layer);
    LDot := LLayer.BlockCoordinateLocation(LPoint.X, LPoint.Y, True);

    //don't bother more if we are in the same dot
    if not EqualRect(LDot, FLastDot) and not EqualRect(LDot, GInvalidRect) then
    begin

      {LRect.Left  := Min(LPoint.X, FLastPoint.X);
      LRect.Top   := Min(LPoint.Y, FLastPoint.Y);
      LRect.Right := Max(LPoint.X, FLastPoint.X);
      LRect.Bottom:= Max(LPoint.Y, FLastPoint.Y);
      InflateRect(LRect,1,1);}


      //FFirstDotIndex := LLayer.DotIndex(FLastDot);
      LLastDotIndex := LLayer.DotIndex(LDot);

      with LLayer.BitPlane do
      begin
        BeginUpdate;
        Assign(FTempBmp);
        EndUpdate;
      end;
      
      R := MakeRect(FFirstDotIndex.X, FFirstDotIndex.Y, LLastDotIndex.X, LLastDotIndex.Y);
      {if IsRectEmpty(R) then
      begin
        // CorrectRect(R);
        LPoint := R.TopLeft;
        R.TopLeft := R.BottomRight;
        R.BottomRight := LPoint;

      end;}
      LLayer.BitPlane.BeginUpdate;
      with R do
        LLayer.BitPlane.LineS( Left, Top, Right, Bottom ,FLastColor,True);
      LLayer.BitPlane.EndUpdate;

      {
      LLayer.BitPlane.PixelS[LLastDotIndex.X, LLastDotIndex.Y] :=  FLastColor;
      LLayer.BitPlane.Canvas.Pen.Color := WinColor(FLastColor);
      LLayer.BitPlane.Canvas.MoveTo( FFirstDotIndex.X, FFirstDotIndex.Y);
      LLayer.BitPlane.Canvas.LineTo( LLastDotIndex.X, LLastDotIndex.Y);
      }
      //FFirstDotIndex := LLastDotIndex;
      {
      R1 := LLayer.AreaChanged;
      if IsRectEmpty(R1) then
         CorrectRect(R1);

      UnionRect(R,R1, FLastBitPlanPaintedRect);
      Layer.Changed(R);
      FLastBitPlanPaintedRect := R1;
      }
      if IsRectEmpty(R) then
         CorrectRect(R);
      MyUnionRect(R2,R, FLastBitPlanPaintedRect);

      LLayer.RebuildDots(R2);
      
      Layer.Changed(LLayer.AreaChanged);
      FLastBitPlanPaintedRect := R;
      FLastDot := LDot;
    end;
  end;


end;

procedure TicToolLcdLine.MouseUp(Sender: TicPaintBox; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer; Layer: TicLayer);
begin
  if FMouseButtonDown then
  begin
    FMouseButtonDown := False;

    FCmd.ChangedLayer(Layer);
    GIntegrator.ActivePaintBox.UndoRedo.AddUndo(FCmd,'LCD Line paint');
    GIntegrator.InvalidateListeners;

  end;
end;

end.
