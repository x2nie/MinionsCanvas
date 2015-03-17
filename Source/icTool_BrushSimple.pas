unit icTool_BrushSimple;

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
  TicToolBrushSimple = class(TicTool)
  private
    FLeftButtonDown : Boolean;
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

{ TicToolBrushSimple }

procedure TicToolBrushSimple.MouseDown(Sender: TicPaintBox;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer;
  Layer: TicLayer);
var
  LRect  : TRect;
  LPoint : TPoint;
begin
  if Button = mbLeft then
  begin
    FCmd := TicCmdLayer_Modify.Create(GIntegrator.ActivePaintBox.UndoRedo);
    FCmd.ChangingLayer(Layer);
    
    FLeftButtonDown := True;
    LPoint := Sender.ControlToBitmap( Point(X, Y) );

    LRect.Left   := LPoint.X - 10;
    LRect.Top    := LPoint.Y - 10;
    LRect.Right  := LPoint.X + 10;
    LRect.Bottom := LPoint.Y + 10;

    TicBItmapLayer(Layer).LayerBitmap.FillRectS(LRect, $7F000000);
    Layer.Changed(LRect);

  end;
end;

procedure TicToolBrushSimple.MouseMove(Sender: TicPaintBox; Shift: TShiftState;
  X, Y: Integer; Layer: TicLayer);
var
  LRect  : TRect;
  LPoint : TPoint;
begin
  LPoint := Sender.ControlToBitmap( Point(X, Y) );

  if FLeftButtonDown then
  begin
    LRect.Left   := LPoint.X - 10;
    LRect.Top    := LPoint.Y - 10;
    LRect.Right  := LPoint.X + 10;
    LRect.Bottom := LPoint.Y + 10;

    TicBItmapLayer(Layer).LayerBitmap.FillRectS(LRect, $7F000000);
    Layer.Changed(LRect);
  end;


end;

procedure TicToolBrushSimple.MouseUp(Sender: TicPaintBox; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer; Layer: TicLayer);
begin
  if FLeftButtonDown then
  begin
    FLeftButtonDown := False;
    FCmd.ChangedLayer(Layer);
    GIntegrator.ActivePaintBox.UndoRedo.AddUndo(FCmd,'Brush paint');    
    
    GIntegrator.InvalidateListeners;

    //Layer.UpdateLayerThumbnail;
    //Layer.Changed;
  end;
end;

end.
