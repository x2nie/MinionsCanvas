unit icLayersListBox;

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
 *
 * The Initial Developer of this unit are
 *   Ma Xiaoguang and Ma Xiaoming < gmbros[at]hotmail[dot]com >
 *
 * Contributor(s):
 *   x2nie  < x2nie[at]yahoo[dot]com >
 *
 * ***** END LICENSE BLOCK ***** *)

interface

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}


uses
{ Delphi }
  Types, Windows, Controls, Classes,
{ Graphics32 }
  GR32, GR32_Image, GR32_Layers, GR32_RangeBars,
{ miniGlue lib }
  icBase, icLayers, icLayerPanelManager;

type
  TicLayersListBox = class(TicLayerPanelManager)
  private
  protected
    FAgent : TicAgent;                    //integrator's event listener
    FLayerList : TLayerCollection;       //to compare between last & current 
    procedure ActivePaintBoxSwitched(Sender: TObject);
    procedure SoInvalidate(Sender: TObject; ALayer: TicLayer);
    procedure InvalidateEvent(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    
    property Agent: TicAgent read FAgent; //read only. for internal access
  published
    property Align;
  end;
  
implementation

{ TicLayersListBox }

procedure TicLayersListBox.ActivePaintBoxSwitched(Sender: TObject);
begin
  //set visual layers to new active paintbox
  if Assigned(GIntegrator.ActivePaintBox) then
  begin
    //remove event
    ///`if Assigned(LayerList) and  (LayerList <> GIntegrator.ActivePaintBox.LayerList) then
      ///LayerList.OnLayerChanged := nil;

    //install event
    Self.LayerList := GIntegrator.ActivePaintBox.Layers;
    ///LayerList.OnLayerChanged := SoInvalidate;
  end
  else
  begin
    //remove event
    //if Assigned(LayerList) and not (csDestroying in LayerList.code then
      //LayerList.OnLayerChanged := nil;

    self.LayerList := nil;
  end;
end;

constructor TicLayersListBox.Create(AOwner: TComponent);
begin
  inherited;
  FAgent := TicAgent.Create(Self); //autodestroy
  FAgent.OnActivePaintBoxSwitch := self.ActivePaintBoxSwitched;
  FAgent.OnInvalidateListener := InvalidateEvent;
end;

procedure TicLayersListBox.InvalidateEvent(Sender: TObject);
begin
  Invalidate;
end;

procedure TicLayersListBox.SoInvalidate(Sender: TObject;ALayer: TicLayer);
begin
  //Invalidate;
end;

end.
