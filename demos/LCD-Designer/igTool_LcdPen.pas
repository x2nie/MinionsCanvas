unit igTool_LcdPen;

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
  TigToolLcdPen = class(TigTool)
  private
    FMouseButtonDown : Boolean;
    FLastDotIndex : TPoint;
    FLastDot : TRect;
    FLastColor : TColor32;
  protected
    //Events. Polymorpism.
    procedure MouseDown(Sender: TigPaintBox; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer; Layer: TigLayer); override;
    procedure MouseMove(Sender: TigPaintBox; Shift: TShiftState; X,
      Y: Integer; Layer: TigLayer); override;
    procedure MouseUp(Sender: TigPaintBox; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer; Layer: TigLayer); override;
  public

  published 

  end;



implementation

uses
  Forms, //for debug : application.mainform
  Math, igLiquidCrystal;
{ TigToolBrushSimple }

procedure TigToolLcdPen.MouseDown(Sender: TigPaintBox;
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

    //FLastDot := MakeRect(-1,-1,-1,-1);//impossible LCD coordinate. to make first MouseMove runnable
    FLastDot := LLayer.BlockCoordinateLocation(LBmpXY.X, LBmpXY.Y);

    {}
    if Button=mbLeft then
      FLastColor := clWhite32
    else
      FLastColor := 0;

    FLastDotIndex := LLayer.DotIndex(FLastDot);

    LLayer.BitPlane.PixelS[FLastDotIndex.X, FLastDotIndex.Y] :=  FLastColor;

    LRect.TopLeft     := FLastDotIndex;
    LRect.BottomRight := FLastDotIndex;
    InflateRect(LRect, 1,1);
    LLayer.BitPlane.Changed(LRect);
    Layer.Changed(LLayer.AreaChanged);
    //Layer.Changed(LRect);
    //MouseMove(Sender, Shift, X,Y, Layer);
  end;
end;

procedure TigToolLcdPen.MouseMove(Sender: TigPaintBox; Shift: TShiftState;
  X, Y: Integer; Layer: TigLayer);
var
  LRect,LDot  : TRect;
  LPoint,P2 : TPoint;
  LLayer : TigLiquidCrystal;
begin
  if Layer is TigLiquidCrystal then
  begin
    LPoint := Sender.ControlToBitmap( Point(X, Y) );
    LLayer := TigLiquidCrystal(Layer);
    LDot := LLayer.BlockCoordinateLocation(LPoint.X, LPoint.Y);
    //Application.MainForm.Caption := format('mouse X:%d,  Y:%d    cx:%d, cy:%d',[X,Y, LPoint.X, LPoint.Y]);
    with LDot do Application.MainForm.Caption := format('X:%d,  Y:%d    cx:%d, cy:%d',[Left, Top, Right, Bottom]);
  end
  else Application.MainForm.Caption := 'non lcd';


  if FMouseButtonDown then
  begin
    LPoint := Sender.ControlToBitmap( Point(X, Y) );


    LLayer := TigLiquidCrystal(Layer);
    LDot := LLayer.BlockCoordinateLocation(LPoint.X, LPoint.Y);

    //don't bother more if we are in the same dot
    if not EqualRect(LDot, FLastDot) then
    begin

      {LRect.Left  := Min(LPoint.X, FLastPoint.X);
      LRect.Top   := Min(LPoint.Y, FLastPoint.Y);
      LRect.Right := Max(LPoint.X, FLastPoint.X);
      LRect.Bottom:= Max(LPoint.Y, FLastPoint.Y);
      InflateRect(LRect,1,1);}


      FLastDotIndex := LLayer.DotIndex(FLastDot);
      P2 := LLayer.DotIndex(LDot);


      LLayer.BitPlane.LineS(FLastDotIndex.X, FLastDotIndex.Y, P2.X, P2.Y, FLastColor);
      FLastDotIndex := P2;
      Layer.Changed(LLayer.AreaChanged);
      FLastDot := LDot;
    end;
  end;


end;

procedure TigToolLcdPen.MouseUp(Sender: TigPaintBox; Button: TMouseButton;
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
