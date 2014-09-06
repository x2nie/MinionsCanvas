unit igSwatch_ListView;

(* ***** BEGIN LICENSE BLOCK *****
 * Version: MPL 1.1/LGPL 2.1/GPL 2.0
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
 * The Original Code is Gradient Editor.
 *
 * The Initial Developer of the Original Code are
 *
 * Ma Xiaoguang and Ma Xiaoming < gmbros@hotmail.com >
 * x2nie - Fathony Luthfillah  <x2nie@yahoo.com>
 *
 * Contributor(s):
 *
 * Alternatively, the contents of this file may be used under the terms of
 * either the GNU General Public License Version 2 or later (the "GPL"), or
 * the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
 * in which case the provisions of the GPL or the LGPL are applicable instead
 * of those above. If you wish to allow use of your version of this file only
 * under the terms of either the GPL or the LGPL, and not to allow others to
 * use your version of this file under the terms of the MPL, indicate your
 * decision by deleting the provisions above and replace them with the notice
 * and other provisions required by the GPL or the LGPL. If you do not delete
 * the provisions above, a recipient may use your version of this file under
 * the terms of any one of the MPL, the GPL or the LGPL.
 * ***** END LICENSE BLOCK ***** *)

interface

uses
  Classes, igGrid, igGrid_ListView, igSwatch;

type
  TigSwatchListView = class(TigGridListView)
  private
    function GetSwatchList: TigSwatchList;
    procedure SetSwatchList(const Value: TigSwatchList);
  protected
    //for universal file dialog
    function  ItemListClass : TigGridListClass; override;
  public

  published
    property Align;
    property AutoSize;
    property Anchors;
    property Color;
    property ParentColor;

    property GrowFlow ;
    property SwatchList : TigSwatchList read GetSwatchList write SetSwatchList;
    property ThumbWidth ;
    property ThumbHeight ;
    property ParentShowHint;
    property PopupMenu;
    property RepaintMode;
    property Scale;
    property ScaleMode;
    property ShowHint;
    property TabOrder;
    property TabStop;
    property Visible;
    property CellBorderStyle;
    property GridOptions;
    property FrameColor;
    property SelectedColor;
    property ItemIndex;

    property OnChange;
    property OnMouseDown;    
  end;

  
procedure Register;

implementation


procedure Register;
begin
  RegisterComponents('miniGlue', [TigSwatchListView]);
end;


{ TigSwatchListView }

function TigSwatchListView.GetSwatchList: TigSwatchList;
begin
  Result := ItemList as TigSwatchList;
end;

function TigSwatchListView.ItemListClass: TigGridListClass;
begin
  result := TigSwatchList;
end;

procedure TigSwatchListView.SetSwatchList(const Value: TigSwatchList);
begin
  ItemList := Value;
end;

end.
