unit igTool_LcdLine;

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
  igBase, igLayers;

type
  TigToolLcdLine = class(TigTool)
  private
    FMouseButtonDown : Boolean;
    FFirstDotIndex : TPoint;
    FLastDot : TRect;
    FLastColor : TColor32;
    FTempBmp : TBitmap32;
  protected
    //Events. Polymorpism.
    procedure MouseDown(Sender: TigPaintBox; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer; Layer: TigLayer); override;
    procedure MouseMove(Sender: TigPaintBox; Shift: TShiftState; X,
      Y: Integer; Layer: TigLayer); override;
    procedure MouseUp(Sender: TigPaintBox; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer; Layer: TigLayer); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published 

  end;



implementation

uses
  Forms, //for debug : application.mainform
  Math, igLiquidCrystal;
{ TigToolBrushSimple }

constructor TigToolLcdLine.Create(AOwner: TComponent);
begin
  inherited;
  FTempBmp := TBitmap32.Create;
end;

destructor TigToolLcdLine.Destroy;
begin
  FTempBmp.Free;
  inherited;
end;

procedure TigToolLcdLine.MouseDown(Sender: TigPaintBox;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer;
  Layer: TigLayer);
var
  LRect  : TRect;
  LBmpXY : TPoint;
  LLayer : TigLiquidCrystal;
begin
  if (Layer is TigLiquidCrystal) and (Button in [mbLeft,mbRight]) then
  begin
    FMouseButtonDown := True;
    LBmpXY := Sender.ControlToBitmap( Point(X, Y) );
    LLayer := TigLiquidCrystal(Layer);

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

      LLayer.BitPlane.PixelS[FFirstDotIndex.X, FFirstDotIndex.Y] :=  FLastColor;

      LRect.TopLeft     := FFirstDotIndex;
      LRect.BottomRight := FFirstDotIndex;
      InflateRect(LRect, 1,1);
      LLayer.BitPlane.Changed(LRect);
      Layer.Changed(LLayer.AreaChanged);
      //Layer.Changed(LRect);
      //MouseMove(Sender, Shift, X,Y, Layer);
    end;
  end;
end;

procedure TigToolLcdLine.MouseMove(Sender: TigPaintBox; Shift: TShiftState;
  X, Y: Integer; Layer: TigLayer);
var
  LDot  : TRect;
  LPoint,LLastDotIndex : TPoint;
  LLayer : TigLiquidCrystal;
begin
  if Layer is TigLiquidCrystal then
  begin
    LPoint := Sender.ControlToBitmap( Point(X, Y) );
    LLayer := TigLiquidCrystal(Layer);
    LDot := LLayer.BlockCoordinateLocation(LPoint.X, LPoint.Y, True);
    //Application.MainForm.Caption := format('mouse X:%d,  Y:%d    cx:%d, cy:%d',[X,Y, LPoint.X, LPoint.Y]);
    with LDot do Application.MainForm.Caption := format('X:%d,  Y:%d    cx:%d, cy:%d',[Left, Top, Right, Bottom]);
  end
  else Application.MainForm.Caption := 'non lcd';


  if FMouseButtonDown then
  begin
    LPoint := Sender.ControlToBitmap( Point(X, Y) );


    LLayer := TigLiquidCrystal(Layer);
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
      

      //LLayer.BitPlane.LineS( P2.X, P2.Y, FLastDotIndex.X, FLastDotIndex.Y,FLastColor);

      LLayer.BitPlane.PixelS[LLastDotIndex.X, LLastDotIndex.Y] :=  FLastColor;
      LLayer.BitPlane.Canvas.Pen.Color := WinColor(FLastColor);
      LLayer.BitPlane.Canvas.MoveTo( FFirstDotIndex.X, FFirstDotIndex.Y);
      LLayer.BitPlane.Canvas.LineTo( LLastDotIndex.X, LLastDotIndex.Y);
      
      //FFirstDotIndex := LLastDotIndex;
      Layer.Changed(LLayer.AreaChanged);
      //FLastDot := LDot;
    end;
  end;


end;

procedure TigToolLcdLine.MouseUp(Sender: TigPaintBox; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer; Layer: TigLayer);
var cmd : TigCmdLayer_Modify;  
begin
  if FMouseButtonDown then
  begin
    FMouseButtonDown := False;

    cmd := TigCmdLayer_Modify.Create(GIntegrator.ActivePaintBox.UndoRedo);
    cmd.ChangedLayer(Layer);
    
    GIntegrator.ActivePaintBox.UndoRedo.AddUndo(cmd,'LCD Pencil paint');
    GIntegrator.InvalidateListeners;
  end;
end;

end.
