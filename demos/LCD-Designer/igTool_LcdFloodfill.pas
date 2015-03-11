unit igTool_LcdFloodfill;

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
  TigToolLcdFloodfill = class(TigTool)
  private
    

  protected
    //Events. Polymorpism.
    procedure MouseDown(Sender: TigPaintBox; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer; Layer: TigLayer); override;
  public
    constructor Create(AOwner: TComponent); override;
  published 

  end;



implementation

uses
  Forms, //for debug : application.mainform
  Math, igLiquidCrystal;
{ TigToolBrushSimple }

constructor TigToolLcdFloodfill.Create(AOwner: TComponent);
begin
  inherited;
  Cursor := crCross;
end;

procedure TigToolLcdFloodfill.MouseDown(Sender: TigPaintBox;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer;
  Layer: TigLayer);
var
  BRect, LDot, LAreaChanged  : TRect;
  LRect  : TRect;
  LBmpXY : TPoint;
  LLayer : TigLiquidCrystal;
  LCmd : TigCmdLayer_Modify;
  C : TColor32;
  LDotIndex : TPoint;

    // http://www.codeproject.com/Articles/6017/QuickFill-An-efficient-flood-fill-algorithm
    // Fill background with given color
    procedure SeedFill_1(X,Y: Integer; fill_color: TColor32);
    begin
      if PtInRect(BRect, Point(X,Y)) and (fill_color <> LLayer.BitPlane[x,y]) then  // sample pixel color
      begin
        LLayer.BitPlane[x,y] := fill_color;

        with LAreaChanged do
        begin
          Left := Min(X, Left);
          Top  := Min(Y,Top);
          Right:= Max(X,Right);
          Bottom:=Max(Y,Bottom);
        end;

        SeedFill_1(x,y,fill_color);
        SeedFill_1(x-1,y,fill_color);
        SeedFill_1(x+1,y,fill_color);
        SeedFill_1(x,y-1,fill_color);
        SeedFill_1(x,y+1,fill_color);
      end;
    end;
begin
  if (Layer is TigLiquidCrystal) and (Button in [mbLeft,mbRight]) then
  begin
    LCmd := TigCmdLayer_Modify.Create(GIntegrator.ActivePaintBox.UndoRedo);
    LCmd.ChangingLayer(Layer);


    LBmpXY := Sender.ControlToBitmap( Point(X, Y) );
    LLayer := TigLiquidCrystal(Layer);


    //Allow invalid point for later use in mousemove to draw stright line from this
    LDot := LLayer.BlockCoordinateLocation(LBmpXY.X, LBmpXY.Y, True);
    if Button=mbLeft then
      C := clWhite32
    else
      C := 0;

    LDotIndex := LLayer.DotIndex(LDot);

    //dont allow invalid point, since we actually modify pixel
    LRect := LLayer.BlockCoordinateLocation(LBmpXY.X, LBmpXY.Y, False);
    if not EqualRect(LRect, GInvalidRect) then
    begin
      {}
      with LLayer.BitPlane do
      begin
        BRect := BoundsRect; // MakeRect(0,0, Width-1, Height-1); <-- doesn't compatible with PtInRect()
        LAreaChanged := MakeRect(Width-1, Height-1, 0,0); //impossible rect
      end;



      LLayer.BitPlane.BeginUpdate;//prevent redraw
      //LLayer.BitPlane.PixelS[LDotIndex.X, LDotIndex.Y] :=  C;
      SeedFill_1(LDotIndex.X, LDotIndex.Y, C);
      LLayer.BitPlane.EndUpdate;

      //LRect.TopLeft     := LDotIndex;
      //LRect.BottomRight := LDotIndex;
      //InflateRect(LRect, 1,1);
      //LLayer.BitPlane.Changed(LRect);
      LLayer.RebuildDots(LAreaChanged);
      Layer.Changed(LLayer.AreaChanged);
      //Layer.Changed(LRect);
      //MouseMove(Sender, Shift, X,Y, Layer);

      LCmd.ChangedLayer(Layer);
      GIntegrator.ActivePaintBox.UndoRedo.AddUndo(LCmd,'LCD Floodfill');
      GIntegrator.InvalidateListeners;

    end
    else
      Application.MainForm.Caption := 'outside lcd range!';
  end;
end;





end.
