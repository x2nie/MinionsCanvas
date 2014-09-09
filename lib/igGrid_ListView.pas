unit igGrid_ListView;

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
 * x2nie - Fathony Luthfillah  <x2nie@yahoo.com>
 *
 * Contributor(s):
 *
 * HintShow is taken from ColorPickerButton.pas written by
 *    Dipl. Ing. Mike Lischke (public@lischke-online.de) (c) 1999
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
  {$IFDEF FPC}
  LCLIntf, LCLType, LMessages, Types,
{$ELSE}
  Windows, Messages,
{$ENDIF}
{ Standard }
  SysUtils,
  Classes, Controls, Graphics, Forms,
{ Graphics32 }
  GR32, GR32_Image, GR32_Layers,
{ GraphicsMagic }
  igCore_Items,
  igGrid, igCore_Viewer, 
  igGrid_ListView_Layers;


type
  TigGridOption = (goDragable, goSelection, goRightClickSelect); //show selected or not
  TigGridOptions = set of TigGridOption;

  TigCellBorderStyle = (borSwatch, borContrasGrid, borNone);

  TigGridListView = class(TigCoreViewer,IGridBasedListSupport)
  private
    FChangeLink      : TigGridChangeLink;
    FItemList        : TigGridList; //link only
    FTempItemList    : TigGridList; //for universal file dialog
    FGrowFlow        : TigGridFlow;
    FThumbWidth      : Integer;
    FThumbHeight     : Integer;
    FRBLayer         : TigSelectedLayer;
    FSelection       : TigCustomGridBasedViewLayer;
    FGridOptions     : TigGridOptions;
    FCellBorderStyle : TigCellBorderStyle;
    FFrameColor      : TColor;
    FSelectedColor   : TColor;
    FItemIndex       : TigGridIndex;
    FOnChange        : TNotifyEvent;

    procedure InvalidateSize;
    procedure SynchronizeLayers;
    procedure SetGrowFlow(const AValue: TigGridFlow);
    procedure SetItemList(const AValue: TigGridList);
    procedure SetThumbHeight(const AValue: Integer);
    procedure SetThumbWidth(const AValue: Integer);
    procedure SetSelection(const AValue: TigCustomGridBasedViewLayer);
    procedure SetGridOptions(const AValue: TigGridOptions);
    procedure SetCellBorderStyle(const AValue: TigCellBorderStyle);
    procedure SetFrameColor(const AValue: TColor);
    procedure SetSelectedColor(const AValue: TColor);
    procedure SetItemIndex(const AValue: TigGridIndex);
    {$IFDEF FPC}
    procedure CMHintShow(var Message: TLMessage); message CM_HINTSHOW;
    {$ELSE}
    procedure CMHintShow(var Message: TMessage); message CM_HINTSHOW;
    {$ENDIF}
    procedure Clear;
    
    procedure LayerMouseDown(Sender: TObject; Buttons: TMouseButton;
      Shift: TShiftState; X, Y: Integer);

    { IGridBasedListSupport }
    function GetGridBasedList: TigGridList;

  protected
    //for universal file dialog
    function  ItemListClass : TigGridListClass; virtual; abstract;
    procedure LoadFromFile(const FileName: string); override;
    function GetReaderFilter : string; override;
    function GetWriterFilter : string; override;

    function CanAutoSize(var ANewWidth, ANewHeight: Integer): Boolean; override;

    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer; Layer: TCustomLayer); override;

    procedure MouseUp(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer; Layer: TCustomLayer); override;

    //for paint layer
    function CellHeight: Integer;
    function CellWidth: Integer;
    function CellRect(const ARect: TRect): TRect;

    procedure ItemListChangedHandler(Sender: TObject);

    property Selection : TigCustomGridBasedViewLayer read FSelection    write SetSelection;
    property GrowFlow        : TigGridFlow        read FGrowFlow        write SetGrowFlow      default ZWidth2Bottom;
    property ItemList        : TigGridList   read GetGridBasedList write SetItemList;
    property ThumbWidth      : Integer            read FThumbWidth      write SetThumbWidth    default 32;
    property ThumbHeight     : Integer            read FThumbHeight     write SetThumbHeight   default 32;
    property ItemIndex       : TigGridIndex  read FItemIndex       write SetItemIndex     default -1;
    property GridOptions     : TigGridOptions     read FGridOptions     write SetGridOptions   default [goSelection];
    property CellBorderStyle : TigCellBorderStyle read FCellBorderStyle write SetCellBorderStyle;
    property FrameColor      : TColor             read FFrameColor      write SetFrameColor    default clWhite;
    property SelectedColor   : TColor             read FSelectedColor   write SetSelectedColor default clBlack;
    property OnChange        : TNotifyEvent       read FOnChange        write FOnChange;
  public
    constructor Create(AOwner: TComponent); override;

    procedure Resize; override;
    procedure SetThumbSize(const AValue: Integer); overload;
    procedure SetThumbSize(const AWidth, AHeight: Integer); overload;
    
    function MatrixPosition(const AIndex: Integer): TFloatPoint;
    function MatrixIndex(AX, AY: Integer): integer;
  published 

  end;

  TigGridListViewClass = class of TigGridListView;

implementation

uses
  Math, TypInfo;

type
  TLayerCollectionAccess = class(TLayerCollection);
  TLayerAccess           = class(TCustomLayer);
  TGridListAccess   = class(TigGridList);


{ TigGridListView }

constructor TigGridListView.Create(AOwner: TComponent);
begin
  inherited;

  FChangeLink          := TigGridChangeLink.Create;
  FChangeLink.OnChange := ItemListChangedHandler;

  FThumbWidth    := 32;
  FThumbHeight   := 32;
  FFrameColor    := clWhite;
  FSelectedColor := clBlack;
  FItemIndex     := -1;
  FGridOptions   := [goSelection];
  ShowHint       := True;
end;

function TigGridListView.CanAutoSize(
  var ANewWidth, ANewHeight: Integer): Boolean;
var
  W, H: Integer;
begin
  Result := True;
  W      := 0;
  H      := 0;
  
  if ( not Assigned(FItemList) ) or
     ( FItemList.Count <= 0 ) then
  begin
    Exit;
  end;
  
  case FGrowFlow of
    ZWidth2Bottom:
      begin
        W := ANewWidth div ThumbWidth;
        H := Ceil(FItemList.Count / w);
      end;

    NHeight2Right:
      begin
        H := ANewHeight div ThumbHeight;
        W := Ceil(FItemList.Count / h);
      end;

    OSquaredGrow:
      begin
        W := Ceil(Sqrt(FItemList.Count));
        H := W;
      end;
  end;

  W := Max(W,1) * ThumbWidth +1;
  H := Max(H,1) * ThumbHeight +1;

  if not (csDesigning in ComponentState) or (W > 0) and (H > 0) then
  begin
    if Align in [alNone, alLeft, alRight] then
    begin
      ANewWidth := W;
    end;

    if Align in [alNone, alTop, alBottom] then
    begin
      ANewHeight := H;
    end;
  end;
end;

function TigGridListView.CellHeight: Integer;
begin
  case FCellBorderStyle of
    borSwatch:
      begin
        Result := ThumbHeight - 1;
      end;
      
    borContrasGrid:
      begin
        Result := ThumbHeight - 2;
      end;
      
    borNone:
      begin
        Result := ThumbHeight;
      end;
  end;
end;

function TigGridListView.CellRect(const ARect: TRect): TRect;
begin
  Result := ARect;

  if FCellBorderStyle = borSwatch then
  begin
    Dec(Result.Right);
    Dec(Result.Bottom);
    OffsetRect(Result, 1, 1);
  end
  else if FCellBorderStyle = borContrasGrid then
  begin
    InflateRect(Result, -2, -2);
    Inc(Result.Right);
    Inc(Result.Bottom);
  end;
end;

function TigGridListView.CellWidth: Integer;
begin
  case FCellBorderStyle of
    borSwatch:
      begin
        Result := ThumbWidth - 1;
      end;

    borContrasGrid:
      begin
        Result := ThumbWidth - 2;
      end;

    borNone:
      begin
        Result := ThumbWidth;
      end;
  end;
end;

{$IFDEF FPC}
procedure TigGridListView.CMHintShow(var Message: TLMessage);
begin

end;
{$ELSE}
procedure TigGridListView.CMHintShow(var Message: TMessage);
// determine hint message (tooltip) and out-of-hint rect

var
  LHoverIndex : Integer;
  LLayer      : TCustomLayer;
  LItem       : TigGridItem;
begin
  with TCMHintShow(Message) do
  begin
    if not ShowHint then
    begin
      Message.Result := 1;
    end
    else
    begin
      with HintInfo^ do
      begin
        // show that we want a hint
        Result := 0;
        LLayer := TLayerCollectionAccess(Layers).FindLayerAtPos(CursorPos.X, CursorPos.Y, LOB_VISIBLE);

        if Assigned(LLayer) then
        begin
          if LLayer = FRBLayer then
          begin
            LLayer := FRBLayer.ChildLayer;
          end;
          
          LHoverIndex := LLayer.Index;
          if Assigned(FItemList) and FItemList.IsValidIndex(LHoverIndex) then
          begin
            LItem       := TGridListAccess(FItemList).Collection.Items[LHoverIndex] as TigGridItem;
            HintStr     := LItem.GetHint;
            HideTimeout := 5000;
          end
        end;
        
        // make the hint follow the mouse
        CursorRect := Rect(CursorPos.X, CursorPos.Y, CursorPos.X, CursorPos.Y);
      end;
    end;
  end;
end;
{$ENDIF}

procedure TigGridListView.Clear;
begin
  FRBLayer   := nil;
  FSelection := nil;
  FItemIndex := -1;

  Self.Layers.Clear;
end;

function TigGridListView.GetGridBasedList: TigGridList;
begin
  Result := FItemList;
end;

procedure TigGridListView.InvalidateSize;
var
  Z : integer;
begin
  BeginUpdate;
  AdjustSize;

  if Assigned(FItemList) then
  begin
    Z := 0;

    if Assigned(FRBLayer) then
    begin
      Z := 1;
    end;
    
    Inc(Z, FItemList.Count);

    if Z <> Layers.Count then
    begin
      SynchronizeLayers;
    end;
  end
  else
  begin
    FRBLayer   := nil;
    FSelection := nil;
    
    Layers.Clear;
  end;
   
  EndUpdate;
  Invalidate;
end;

procedure TigGridListView.ItemListChangedHandler(Sender: TObject);
begin
  if Assigned(Sender) and (Sender = FItemList) then
  begin
    if Assigned(FRBLayer) then
    begin
      if FItemList.Count <> (Self.Layers.Count - 1) then
      begin
        Self.Clear;
      end;
    end
    else
    begin
      if FItemList.Count <> Self.Layers.Count then
      begin
        Self.Clear;
      end;
    end;

    InvalidateSize;
  end;
end;

procedure TigGridListView.LayerMouseDown(Sender: TObject;
  Buttons: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  Selection := TigCustomGridBasedViewLayer(Sender);
end;

function TigGridListView.MatrixIndex(AX, AY: Integer): integer;
var
  LCols, LRows, LCellX, LCellY : Integer;
begin
  Result := -1;

  if ( not Assigned(FItemList) ) or
     ( FItemList.Count <= 0 ) then
  begin
    Exit;
  end;

  case FGrowFlow of
    ZWidth2Bottom :
      begin
        LCols := Width div ThumbWidth;
        if AX > (LCols * ThumbWidth) then
        begin
          Exit;
        end;

        LRows := Ceil(FItemList.Count / LCols);
        if AY > (LRows * ThumbHeight) then
        begin
          Exit;
        end;

        LCellX := AX div ThumbWidth;
        LCellY := AY div ThumbHeight;
        Result := LCols * LcellY + LCellX;
        
        if not FItemList.IsValidIndex(Result) then
          Result := -1;
      end;
      
    NHeight2Right :
      begin
        LRows := Height div ThumbHeight;
        if AY > (LRows * ThumbHeight) then
        begin
          Exit;
        end;

        LCols := Ceil(FItemList.Count / LRows);
        if AX > (LCols * ThumbWidth) then
        begin
          Exit;
        end;

        LCellY := AY div ThumbHeight;
        LCellX := AX div ThumbWidth;
        Result := LRows * LCellX + LCellY;

        if not FItemList.IsValidIndex(Result) then
          Result := -1;
      end;
      
    OSquaredGrow :
      begin
        LCols := Ceil(Sqrt(FItemList.Count));
        LRows := LCols;
      end;
  end;
end;

function TigGridListView.MatrixPosition(const AIndex: Integer): TFloatPoint;
var
  x, y,w,h : Integer;
begin
  x := 0;
  y := 0;
  with GetViewportRect do
  begin
    W := Right;
    H := Bottom;
  end;

  if Assigned(FItemList) and FItemList.IsValidIndex(AIndex) then
  begin
    case FGrowFlow of
      OSquaredGrow,
      XStretchInnerGrow,
      ZWidth2Bottom :
        begin
          x := AIndex mod (W div FThumbWidth);
          y := Floor(AIndex  / (W div FThumbWidth));
        end;

      NHeight2Right :
        begin
          x := Floor(AIndex / (H div FThumbHeight));
          y := AIndex mod (H div FThumbHeight);
        end;
    end;
    
    Result := FloatPoint(x * FThumbWidth, y * FThumbHeight);
  end
  else
    Result := FloatPoint(-FThumbWidth, -FThumbHeight);
end;

procedure TigGridListView.MouseDown(Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer);
begin
  if Layer = nil then
  begin
    Layer := TLayerCollectionAccess(Layers).FindLayerAtPos(X, Y, LOB_VISIBLE);
  end
  else
  if Assigned(FRBLayer) and Assigned(FRBLayer.ChildLayer) then
  begin
    FRBLayer.Position := MatrixPosition(FRBLayer.ChildLayer.Index);
    Layer             := FRBLayer;
    FItemIndex        := FRBLayer.ChildLayer.Index;

    TLayerCollectionAccess(Layers).MouseListener := FRBLayer;
    TLayerAccess(FRBLayer).MouseDown(Button,Shift, X, Y);
  end;

  inherited MouseDown(Button, Shift, X, Y, Layer);
end;

procedure TigGridListView.MouseUp(Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer);
var
  LLayer : TCustomLayer;
begin
  inherited; //do OnMouseUp

  if Button = mbLeft then
  begin
    if not Assigned(Selection) then
    begin
      ItemIndex := -1;
    end
    else
    begin
      LLayer := Selection;

      if LLayer = FRBLayer then
      begin
        LLayer := FRBLayer.ChildLayer;
      end;

      if not Assigned(LLayer) then //has no child?
        ItemIndex := -1
      else
        ItemIndex := LLayer.Index
    end;
  end;
end;

procedure TigGridListView.Resize;
var
  LItemIndex : Integer;
begin
  inherited;

  LItemIndex := Self.ItemIndex;
  Self.Clear;
  
  SynchronizeLayers;
  Invalidate;

  ItemIndex := LItemIndex;
end;

procedure TigGridListView.SetCellBorderStyle(
  const AValue: TigCellBorderStyle);
begin
  FCellBorderStyle := AValue;
  Invalidate;
end;

procedure TigGridListView.SetFrameColor(const AValue: TColor);
begin
  FFrameColor := AValue;
  Invalidate;
end;

procedure TigGridListView.SetGridOptions(const AValue: TigGridOptions);
begin
  FGridOptions := AValue;
  Invalidate;
end;

procedure TigGridListView.SetGrowFlow(const AValue: TigGridFlow);
begin
  FGrowFlow := AValue;

  if not (csLoading in ComponentState) then
    InvalidateSize;
end;

procedure TigGridListView.SetItemIndex(const AValue: TigGridIndex);
begin
  if FItemIndex <> AValue then
  begin
    FItemIndex := AValue;

    if Assigned(FItemList) and (FItemList.IsValidIndex(FItemIndex)) then
    begin
      Selection := TigCustomGridBasedViewLayer(Self.Layers[FItemIndex]);
    end
    else
    begin
      Selection := nil;
    end;

    Invalidate;

    if Assigned(FOnChange) then
    begin
      FOnChange(Self);
    end;
  end;
end;

procedure TigGridListView.SetItemList(const AValue: TigGridList);
begin
  if FItemList <> nil then
  begin
    FItemList.UnRegisterChanges(FChangeLink);
    FItemList.RemoveFreeNotification(Self);
  end;
  
  FItemList := AValue;
  if FItemList <> nil then
  begin
    FItemList.RegisterChanges(FChangeLink);
    FItemList.FreeNotification(Self);
  end;
  
  InvalidateSize;
end;

procedure TigGridListView.SetSelectedColor(const AValue: TColor);
begin
  FSelectedColor := AValue;
  Invalidate;
end;

procedure TigGridListView.SetSelection(
  const AValue: TigCustomGridBasedViewLayer);

    procedure LInvalidateSelection();
    var
      LLayer     : TCustomLayer;
      LLastIndex : Integer;
    begin
      //set current ItemIndex
      LLastIndex := ItemIndex;

      if Assigned(FSelection) then
        FItemIndex := FSelection.Index
      else
        FItemIndex := -1;

      //update last index
      if Assigned(ItemList) and ItemList.IsValidIndex(LLastIndex)  then
      begin
        LLayer := Layers[LLastIndex];
        TLayerAccess(LLayer).Changed();
      end;

      //update current index
      if Assigned(ItemList) and ItemList.IsValidIndex(FItemIndex)  then
      begin
        LLayer := Layers[FItemIndex];
        TLayerAccess(LLayer).Changed();
      end;
    end;

begin
  if AValue <> FSelection then
  begin
    if FRBLayer <> nil then
    begin
      FRBLayer.ChildLayer   := nil;
      FRBLayer.LayerOptions := LOB_NO_UPDATE;
      
      Invalidate;
    end;

    FSelection := AValue;
    //InvalidateSelection();

    if AValue <> nil then
    begin
      if FRBLayer = nil then
      begin
        FRBLayer := TigSelectedLayer.Create(Layers);
      end
      else
      begin
        FRBLayer.BringToFront;
      end;
      
      FRBLayer.ChildLayer   := AValue;
      FRBLayer.LayerOptions := LOB_VISIBLE or LOB_MOUSE_EVENTS or LOB_NO_UPDATE;
    end;
  end;
end;

procedure TigGridListView.SetThumbHeight(const AValue: Integer);
var
  LItemIndex : Integer;
begin
  LItemIndex := Self.ItemIndex;
  Self.Clear;
  
  FThumbHeight := AValue;
  InvalidateSize;

  Self.ItemIndex := LItemIndex;
end;

procedure TigGridListView.SetThumbSize(const AValue: Integer);
begin
  SetThumbSize(AValue, AValue);
end;

procedure TigGridListView.SetThumbSize(const AWidth, AHeight: Integer);
var
  LItemIndex : Integer;
begin
  LItemIndex := Self.ItemIndex;
  Self.Clear;

  FThumbHeight := AWidth;
  FThumbWidth  := AHeight;
  InvalidateSize;

  Self.ItemIndex := LItemIndex;
end;

procedure TigGridListView.SetThumbWidth(const AValue: Integer);
var
  LItemIndex : Integer;
begin
  LItemIndex := Self.ItemIndex;
  Self.Clear;

  FThumbWidth := AValue;
  InvalidateSize;

  Self.ItemIndex := LItemIndex;
end;

procedure TigGridListView.SynchronizeLayers;
var
  RBAvailable : Boolean;
  LGL         : TigCustomGridBasedViewLayer;
begin
  if not Assigned(FItemList) or (FItemList.Count = 0) then
  begin
    Selection := nil;
    FRBLayer  := nil;
    
    Layers.Clear;
  end
  else
  begin
    BeginUpdate;
    try
      RBAvailable := Assigned(FRBLayer);

      if RBAvailable then
      begin
        if FRBLayer.ChildLayer = nil then
          RBAvailable := False;
      end;

      //decrease
      while Layers.Count > FItemList.Count do
      begin
        FSelection := nil;
        Layers.Delete(Layers.Count - 1);
      end;

      //increase
      while Layers.Count < FItemList.Count do
      begin
        LGL             := TigGridLayer.Create(Layers);
        LGL.OnMouseDown := LayerMouseDown;
      end;

      //fixup position
      if RBAvailable then
      begin
        FRBLayer            := TigSelectedLayer.Create(Layers);
        FRBLayer.ChildLayer := Selection;
        FRBLayer.Position   := MatrixPosition(Selection.Index);
      end;

    finally
      EndUpdate;
    end;
  end;
end;

procedure TigGridListView.LoadFromFile(const FileName: string);
begin
  if not Assigned(FTempItemList) then
    FTempItemList := ItemListClass.Create(Self);
  ItemList := FTempItemList;
  FTempItemList.Clear;
  FTempItemList.LoadFromFile(FileName);
end;

function TigGridListView.GetReaderFilter: string;
begin
  ItemListClass.ReadersFilter;
end;

function TigGridListView.GetWriterFilter: string;
begin
  ItemListClass.WritersFilter;
end;


end.
