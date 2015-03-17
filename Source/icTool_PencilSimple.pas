unit icTool_PencilSimple;

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
  TicToolPencilSimple = class(TicTool)
  private
    FLeftButtonDown : Boolean;
    FLastPoint : TPoint;
    FCmd : TicCmdLayer_Modify;
  protected
    //Events. Polymorpism.
    procedure MouseDown(Sender: TicPaintBox; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer; Layer: TicLayer); override;
    procedure MouseMove(Sender: TicPaintBox; Shift: TShiftState; X,
      Y: Integer; Layer: TicLayer); override;
    procedure MouseUp(Sender: TicPaintBox; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer; Layer: TicLayer); override;
  public

  published 

  end;



implementation

uses
  Math;
{ TicToolBrushSimple }

procedure TicToolPencilSimple.MouseDown(Sender: TicPaintBox;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer;
  Layer: TicLayer);
var
  LRect  : TRect;
begin
  if Button = mbLeft then
  begin
    FCmd := TicCmdLayer_Modify.Create(GIntegrator.ActivePaintBox.UndoRedo);
    FCmd.ChangingLayer(Layer);
  
    FLeftButtonDown := True;
    FLastPoint := Sender.ControlToBitmap( Point(X, Y) );

    LRect.TopLeft     := FLastPoint;
    LRect.BottomRight := FLastPoint;
    InflateRect(LRect, 1,1);

    TicBItmapLayer(Layer).LayerBitmap.Pixel[FLastPoint.X, FLastPoint.Y] :=  $7F000000;
    Layer.Changed(LRect);

  end;
end;

procedure TicToolPencilSimple.MouseMove(Sender: TicPaintBox; Shift: TShiftState;
  X, Y: Integer; Layer: TicLayer);
var
  LRect  : TRect;
  LPoint : TPoint;
begin

  if FLeftButtonDown then
  begin
    LPoint := Sender.ControlToBitmap( Point(X, Y) );

    LRect.Left  := Min(LPoint.X, FLastPoint.X);
    LRect.Top   := Min(LPoint.Y, FLastPoint.Y);
    LRect.Right := Max(LPoint.X, FLastPoint.X);
    LRect.Bottom:= Max(LPoint.Y, FLastPoint.Y);
    InflateRect(LRect,1,1);


    TicBItmapLayer(Layer).LayerBitmap.LineS(FLastPoint.X, FLastPoint.Y, LPoint.X, LPoint.Y, $7F000000);
    FLastPoint := LPoint;
    Layer.Changed(LRect);
  end;


end;

procedure TicToolPencilSimple.MouseUp(Sender: TicPaintBox; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer; Layer: TicLayer);
var cmd : TicCmdLayer_Modify;  
begin
  if FLeftButtonDown then
  begin
    FLeftButtonDown := False;

    FCmd.ChangedLayer(Layer);
    GIntegrator.ActivePaintBox.UndoRedo.AddUndo(FCmd,'Pencil paint');
    GIntegrator.InvalidateListeners;

  end;
end;

end.
