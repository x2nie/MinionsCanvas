unit icGrid_ListView_Layers;

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
 * The Initial Developer of this unit are
 *
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
  Classes, Controls,
  GR32, GR32_Image, GR32_Layers,
  igGrid
  ;

type

  TicCustomGridBasedViewLayer = class(TCustomLayer)
  private
    FPosition: TFloatPoint;
    FScaled: Boolean;
    FIsDragging : Boolean;
    
    //function GetGridBasedView: TicGridView;
    procedure SetPosition(const Value: TFloatPoint);
    procedure SetScaled(const Value: Boolean);
  protected
    //property GridBasedView : TicGridView read GetGridBasedView;
    function GetAdjustedPosition: TFloatRect; 
    function DoHitTest(X, Y: Integer): Boolean; override;
  public
    property Position : TFloatPoint read FPosition write SetPosition; //LeftTop
    property Scaled: Boolean read FScaled write SetScaled;
  end;

  TicGridLayer = class(TicCustomGridBasedViewLayer)
  private
    //FBitmap: TBitmap32;
    //FAlphaHit: Boolean;
    FCropped: Boolean;
    procedure BitmapAreaChanged(Sender: TObject; const Area: TRect; const Info: Cardinal);
    procedure SetCropped(Value: Boolean);
    function GetBitmap: TBitmap32;
  protected
    procedure Paint(Buffer: TBitmap32); override;
    procedure ForcePaint(Buffer: TBitmap32);
    //property GridBasedView : TicGridView read GetGridBasedView;
    property Bitmap: TBitmap32 read GetBitmap;
  public
    constructor Create(ALayerCollection: TLayerCollection); override;
    destructor Destroy; override;
    //property AlphaHit: Boolean read FAlphaHit write FAlphaHit;
    property Cropped: Boolean read FCropped write SetCropped;
  end;

  TicSelectedLayer = class(TicCustomGridBasedViewLayer)
  private
    FChildLayer: TicCustomGridBasedViewLayer;
    FOldPosition : TFloatPoint;
    FDragPos : TPoint;
    FDragItem : TicGridItem;
    procedure SetChildLayer(const Value: TicCustomGridBasedViewLayer);
  protected
    procedure Paint(Buffer: TBitmap32); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
  public
    constructor Create(ALayerCollection: TLayerCollection); override;
    property ChildLayer: TicCustomGridBasedViewLayer read FChildLayer write SetChildLayer;
  end;

implementation
uses
  SysUtils,Math, GR32_Resamplers, GR32_RepaintOpt,
  igGrid_ListView,
  igPaintFuncs
  ;

type
  TImage32Access = class(TCustomImage32);
  TicGridListViewAccess = class(TicGridListView);
  TicGridListAccess = class(TicGridList);


function GetGridBasedView(Layer:TicCustomGridBasedViewLayer): TicGridListViewAccess;
begin
  Result := nil;
  if Assigned(Layer) then
  with Layer do
    if (LayerCollection.Owner is TicGridListView)
    //and Assigned(TicGridListView(LayerCollection.Owner).GridBaseds)
    //and TicGridListView(LayerCollection.Owner).GridBaseds.GridBaseds.IsValidIndex(Index)
    then
      Result := TicGridListViewAccess(LayerCollection.Owner);
end;

function GetGridBasedItem(Layer:TicCustomGridBasedViewLayer): TicGridItem ;
var
  LGV : TicGridListViewAccess;
  LItem : TicGridItem;
  LList : TicGridListAccess;
begin
  Result := nil;
  LGV := GetGridBasedView(Layer);
  if Assigned(LGV) then
  begin
    LList := TicGridListAccess(LGV.ItemList);
    if LList.IsValidIndex(Layer.Index) then
    begin
      Result := LList.Collection.Items[Layer.Index] as TicGridItem;
    end;
  end;
end;

{ TicGridLayer }

procedure TicGridLayer.BitmapAreaChanged(Sender: TObject; const Area: TRect; const Info: Cardinal);
var
  T: TRect;
  ScaleX, ScaleY: TFloat;
  Width: Integer;
begin
{  if Bitmap.Empty then Exit;

  if Assigned(LayerCollection) and ((FLayerOptions and LOB_NO_UPDATE) = 0) then
  begin
    with GetAdjustedPosition do
    begin
      // TODO : Optimize me!
      ScaleX := (Right - Left) / FBitmap.Width;
      ScaleY := (Bottom - Top) / FBitmap.Height;

      T.Left := Floor(Left + Area.Left * ScaleX);
      T.Top := Floor(Top + Area.Top * ScaleY);
      T.Right := Ceil(Left + Area.Right * ScaleX);
      T.Bottom := Ceil(Top + Area.Bottom * ScaleY);
    end;

    Width := Trunc(FBitmap.Resampler.Width) + 1;
    InflateArea(T, Width, Width);

    Changed(T);
  end;
  }
end;

constructor TicGridLayer.Create(ALayerCollection: TLayerCollection);
begin
  inherited;
  //FBitmap := TBitmap32.Create;
  //FBitmap.OnAreaChanged := BitmapAreaChanged;
  LayerOptions := LOB_VISIBLE or LOB_MOUSE_EVENTS;
end;


destructor TicGridLayer.Destroy;
begin
  //FBitmap.Free;
  inherited;
end;

procedure TicGridLayer.Paint(Buffer: TBitmap32);
var
  SrcRect, DstRect, ClipRect, TempRect: TRect;
  ImageRect: TRect;
  LayerWidth, LayerHeight: TFloat;
begin
  if not FIsDragging then
  begin
    FPosition := GetGridBasedView(Self).MatrixPosition(self.Index);
    ForcePaint(Buffer);
  end;
end;

procedure TicGridLayer.ForcePaint(Buffer: TBitmap32);
    //we can't use Bitmap32.FrameRectS(), because they decrase width & height
    //we use our own drawrect that is meet our precission.
    procedure igFrameGridS(Bmp :TBitmap32; R :TRect; Value:TColor32);
    begin
      with R do
      begin
        //top
        //if R.Top = 0 then
          Bmp.HorzLineS(Left,Top,Right,Value);
        //left
        //if R.Left = 0 then
          Bmp.VertLineS(Left,Top,Bottom,Value);
        //right
        Bmp.VertLineS(Right,Top,Bottom,Value);
        //bottom
        Bmp.HorzLineS(Left,Bottom,Right,Value);
      end;
    end;

var
  SrcRect, DstRect, ClipRect, TempRect: TRect;
  LBorderRect,ImageRect: TRect;
  LayerWidth, LayerHeight: TFloat;
  LGV : TicGridListViewAccess;
begin

  if Bitmap.Empty then Exit;
  DstRect := MakeRect(GetAdjustedPosition);
  LBorderRect := DstRect;
  ClipRect := Buffer.ClipRect;
  IntersectRect(TempRect, ClipRect, DstRect);
  if IsRectEmpty(TempRect) then Exit;

  LGV := GetGridBasedView(self);
  DstRect := LGV.CellRect(DstRect);
  SrcRect := MakeRect(0, 0, Bitmap.Width, Bitmap.Height);
  if Cropped and (LayerCollection.Owner is TCustomImage32) and
    not (TImage32Access(LayerCollection.Owner).PaintToMode) then
  begin
    with DstRect do
    begin
      LayerWidth := Right - Left;
      LayerHeight := Bottom - Top;
    end;
    if (LayerWidth < 0.5) or (LayerHeight < 0.5) then Exit;
    ImageRect := TCustomImage32(LayerCollection.Owner).GetBitmapRect;
    IntersectRect(ClipRect, ClipRect, ImageRect);
  end;
  //OffsetRect(DstRect,self.Index * 10,self.Index * 10);
  StretchTransfer(Buffer, DstRect, ClipRect, Bitmap, SrcRect,    Bitmap.Resampler, Bitmap.DrawMode, Bitmap.OnPixelCombine);
  //with DstRect do  Buffer.Textout(left,top,inttostr(self.index));

  //
   //Inc(LBorderRect.Right);
   //Inc(LBorderRect.Bottom);
  igFrameGridS(Buffer,LBorderRect,clBlack32);
  if LGV.CellBorderStyle = borSwatch then
  begin
    //is selected?
    //if (goSelection in LGV.GridOptions) and (Self.Index = LGV.ItemIndex) then
    if (goSelection in LGV.GridOptions) and (Self = LGV.Selection) then
      igFrameGridS(Buffer,LBorderRect,Color32(LGV.SelectedColor))
    //else
      //gmFrameGridS(Buffer,LBorderRect,Color32(LGV.FrameColor))
  end
  else if LGV.CellBorderStyle = borContrasGrid then
  begin
    //InflateRect(Result,-2,-2);
    InflateRect(LBorderRect,-1,-1);
    //is selected?
    //if (goSelection in LGV.GridOptions) and (Self.Index = LGV.ItemIndex) then
    if (goSelection in LGV.GridOptions) and (Self = LGV.Selection) then
      //Buffer.FillRectS(LBorderRect, Color32(FSelectedColor))
      igFrameGridS(Buffer,LBorderRect,Color32(LGV.SelectedColor))
    else
      igFrameGridS(Buffer,LBorderRect,Color32(LGV.FrameColor))

  end;
 //StretchTransfer(Buffer, DstRect, ClipRect, Bitmap, SrcRect,    Bitmap.Resampler, Bitmap.DrawMode, Bitmap.OnPixelCombine);
end;


procedure TicGridLayer.SetCropped(Value: Boolean);
begin
  if Value <> FCropped then
  begin
    FCropped := Value;
    Changed;
  end;
end;



function TicGridLayer.GetBitmap: TBitmap32;
var
  LGV : TicGridListViewAccess;
  LItem : TicGridItem;
begin
  Result := nil;
  LItem := GetGridBasedItem(self);
  if Assigned(LItem) then
  begin
    LGV := GetGridBasedView(self);
    Result := LItem.CachedBitmap(LGV.CellWidth, LGV.CellHeight);
  end;

  {LGV := GetGridBasedView(self);
  if Assigned(LGV) then
  begin
    LItem := TicGridListAccess(LGV.ItemList).Collection.Items[self.Index] as TicGridItem;
    Result := LItem.CachedBitmap(LGV.ThumbWidth, LGV.ThumbHeight);
  end;}
end;


{ TicCustomGridBasedViewLayer }

function TicCustomGridBasedViewLayer.DoHitTest(X, Y: Integer): Boolean;
begin
  with GetAdjustedPosition do
    Result := (X >= Left) and (X < Right) and (Y >= Top) and (Y < Bottom);
end;

function TicCustomGridBasedViewLayer.GetAdjustedPosition: TFloatRect;
var
  ScaleX, ScaleY, ShiftX, ShiftY: TFloat;
  LGV : TicGridListViewAccess;
begin
  LGV  := GetGridBasedView(Self);
  if Assigned(LGV) then
  begin
    if Scaled then
    begin
      LayerCollection.GetViewportShift(ShiftX, ShiftY);
      LayerCollection.GetViewportScale(ScaleX, ScaleY);

      with Result,FPosition do
      begin
        Left := X * ScaleX + ShiftX;
        Top := Y * ScaleY + ShiftY;
        Right := (X + LGV.ThumbWidth -1) * ScaleX + ShiftX;
        Bottom := (Y + LGV.ThumbHeight -1) * ScaleY + ShiftY;
      end;
    end
    else
      with FPosition do
      Result := FloatRect(
        X, Y,
        X + LGV.ThumbWidth, Y + LGV.ThumbHeight);
  end
  else
      with FPosition do
      Result := FloatRect(
        X, Y,
        X+6, Y+6); // x2nie has no better idea if layer has no imgView


end;

{ we want to use this unit inself of GridBasedView, so we drop this property.
function TicCustomGridBasedViewLayer.GetGridBasedView: TicGridListView;
begin
  Result := nil;
  if (LayerCollection.Owner is TicGridListView)
  and Assigned(TicGridListView(LayerCollection.Owner).GridBaseds)
  and TicGridListView(LayerCollection.Owner).GridBaseds.GridBaseds.IsValidIndex(Self.Index)
  then
    Result := TicGridListView(LayerCollection.Owner);
end;}

procedure TicCustomGridBasedViewLayer.SetPosition(const Value: TFloatPoint);
begin
  if (FPosition.X <> Value.X) or (FPosition.Y <> Value.Y) then
  begin
    Changing;
    FPosition := Value;
    Changed;
  end;
end;

procedure TicCustomGridBasedViewLayer.SetScaled(const Value: Boolean);
begin
  if Value <> FScaled then
  begin
    Changing;
    FScaled := Value;
    Changed;
  end;
end;

{ TicSelectedLayer }

constructor TicSelectedLayer.Create(ALayerCollection: TLayerCollection);
begin
  inherited;
  LayerOptions := LOB_VISIBLE or LOB_MOUSE_EVENTS;

end;

procedure TicSelectedLayer.MouseDown(Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  LGV : TicGridListViewAccess;
begin
  LGV := GetGridBasedView(self);
  //update the DragState first.
  FIsDragging := goDragable in LGV.GridOptions; //True;
  FChildLayer.FIsDragging := self.FIsDragging;

  FDragItem := GetGridBasedItem(self.FChildLayer);
  if FIsDragging then
  begin
    FOldPosition := FPosition;
    FDragPos := Point(X,Y); //Point( FloatPoint(X - FPosition.X, Y - FPosition.Y) );
  end;
  inherited;


end;

procedure TicSelectedLayer.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  LGV : TicGridListViewAccess;
  LIndex : integer;
begin
  if FIsDragging then
  begin
    LGV := GetGridBasedView(self);
    Lindex := LGV.MatrixIndex(x,y);
    if (LIndex <> FChildLayer.Index) and LGV.ItemList.IsValidIndex(LIndex) then
    begin
      FDragItem.Collection.BeginUpdate;
      FDragItem.Index := LIndex;
      FDragItem.Collection.EndUpdate;
      FChildLayer.Index := LIndex;
      LGV.ForceFullInvalidate;

    end;  
    Position := FloatPoint(
      FOldPosition.X + X - FDragPos.X,
      FOldPosition.Y + Y - FDragPos.Y );
    ChildLayer.Position := Position;
    //ChildLayer.Changed;
//    Changed(MakeRect(GetAdjustedPosition));
    //Update(MakeRect(GetAdjustedPosition));
  end;  
  inherited;
end;

procedure TicSelectedLayer.MouseUp(Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  LGV : TicGridListView;
begin
  inherited;
  if FIsDragging then
  begin
    FIsDragging := False;
    FChildLayer.FIsDragging := False;
    FDragItem := nil;
    LGV := GetGridBasedView(self);
    FPosition := LGV.MatrixPosition(FChildLayer.Index);
    ChildLayer.Position := FPosition;
    LGV.ForceFullInvalidate;
  end;
end;

procedure TicSelectedLayer.Paint(Buffer: TBitmap32);
var
  DstRect : TRect;
begin
  DstRect := MakeRect(GetAdjustedPosition);
  TicGridLayer(ChildLayer).ForcePaint(Buffer);
  Buffer.FrameRectS(DstRect, clWhite32);
end;

procedure TicSelectedLayer.SetChildLayer(
  const Value: TicCustomGridBasedViewLayer);
begin
  if Assigned(FChildLayer) then
    RemoveNotification(FChildLayer);
    
  FChildLayer := Value;
  if Assigned(Value) then
  begin
    Position := Value.Position;
    Scaled := Value.Scaled;
    AddNotification(FChildLayer);
  end;
end;

end.
