unit bivGrid;

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
 * The Original Code is bivGrid
 *
 * The Initial Developer of the Original Code is
 * x2nie < x2nie [at] yahoo [dot] com >
 *
 *
 * Contributor(s):
 *   Ma Xiaoguang and Ma Xiaoming < gmbros [at] hotmail [dot] com>
 *
 * ***** END LICENSE BLOCK ***** *)

interface

uses
{$IFDEF FPC}
  LCLIntf, LCLType, LMessages, Types,
{$ELSE}
  Windows, Messages,
{$ENDIF}
  Classes, Controls, SysUtils,
  GR32, GR32_Image, GR32_Layers 
{ BIV }
  {bivTheme,}
  //bivThumbnailCatalog,
  //bivImageFIleExt
  ;

type
  TbivTheme = class;
  TbivCustomGrid = class;
  //TCellStates = set of (csSelected, csHover);

  TCellPaintEvent = procedure(ABuffer: TBitmap32; AIndex: Integer; ARect: TRect) of object;
  TCellClickEvent = procedure(Sender: TbivCustomGrid; AIndex: Integer) of object;


  TbivOptions = class(TPersistent)
  private
    FGrid : TbivCustomGrid;
    FMultiSelect: Boolean;
    FListMode: Boolean;
    function GetPaintboxOption: TPaintBoxOptions;
    procedure SetPaintboxOption(const Value: TPaintBoxOptions);
    procedure SetMultiSelect(const Value: Boolean);
    procedure SetListMode(const Value: Boolean);
  public
    constructor Create(AGrid : TbivCustomGrid); virtual;
  published
    property PaintBox32 : TPaintBoxOptions read GetPaintboxOption write SetPaintboxOption;
    property MultiSelect : Boolean read FMultiSelect write SetMultiSelect;
    property ListMode : Boolean read FListMode write SetListMode; 

  end;

  //This VCL only about grid, not manage items
  TbivCustomGrid = class(TCustomPaintBox32)
  private
    FCellCount: Integer;
    FCellWidth: Integer;
    FCellHeight: Integer;
    FLastMousePos : TPoint;
    FTheme: TbivTheme;
    FOnChange: TNotifyEvent;
    FMaxVisibleCells: Integer;
    FPicWidth: Integer;
    FPicHeight: Integer;
    FOnCellClick: TCellClickEvent;

    procedure SetTheme(const Value: TbivTheme);
    procedure SetCellHeight(const Value: Integer);
    procedure SetCellWidth(const Value: Integer);
    procedure SetCellSelection(const Value: Integer);
    function  GetLegacyOptions : TPaintBoxOptions;
    procedure SetLegacyOptions(const Value: TPaintBoxOptions);

  protected
    FOptions        : TbivOptions;
    LayoutValid     : Boolean;
    FUpdateCount    : Integer;
    FRows           : Integer;
    FCols           : Integer;
    FViewportOffset : TPoint;  //offset
    FWorkSize       : TPoint;  //maximum scrollable
    FMargin         : TPoint;
    FMousePos       : TPoint;
    FCellUnderMouse : Integer;
    FCellSelection  : Integer; //selected cell index

    procedure SetOptions(const Value: TbivOptions);
    function GetCellCount: Integer; virtual;
    procedure SetCellCount(const Value: Integer); virtual;

    function GetItemAtXY(X,Y: Integer) : Integer;
    function CanScrollDown : Boolean;
    function CanScrollUp   : Boolean;

    procedure CheckLayout; virtual;
    procedure DoPaintBuffer; override;
    procedure DoCellPaint(ABuffer: TBitmap32; AIndex: Integer; ARect: TRect);  virtual; // called by Theme
    property  LegacyOptions : TPaintBoxOptions read GetLegacyOptions write SetLegacyOptions;
  protected
    {System}
    procedure AdjustClientRect(var Rect: TRect); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    function DoMouseWheelDown(Shift: TShiftState; MousePos: TPoint): Boolean; override; //call by system
    function DoMouseWheelUp(Shift: TShiftState; MousePos: TPoint): Boolean; override;   //call by system
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    
    procedure InvalidateLayout;
    procedure Resize; override;
    procedure Changed; virtual;

    procedure Scroll(Dx,Dy: Integer); virtual;
    //allow TForm to redirect the mousewheel to this
    procedure MouseWheelDown(Shift: TShiftState; MousePos: TPoint; var Handled: Boolean); virtual;
    procedure MouseWheelUp(Shift: TShiftState; MousePos: TPoint; var Handled: Boolean); virtual;
    procedure DefaultPaint(AIndex : Integer; Graphic: TBitmap32); virtual;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;

    function CellUnderMouse : Integer; virtual;
    function GetCellRect(ACellIndex : Integer): TRect;
    function IsVisible(ACellIndex : Integer):Boolean;
    function IsSelected(AIndex: Integer): Boolean; virtual;   //useful for rendering multiselect
    procedure SetSelected(AIndex: Integer); virtual; //useful in multi-select mode
    
    property MaxVisibleCells : Integer read FMaxVisibleCells;
    property CellWidth : Integer read FCellWidth write SetCellWidth;
    property CellHeight : Integer read FCellHeight write SetCellHeight;
    property PicWidth : Integer read FPicWidth write FPicWidth;
    property PicHeight : Integer read FPicHeight write FPicHeight;
    property Theme : TbivTheme read FTheme write SetTheme;
    property Margin : TPoint read FMargin write FMargin;
    property CellSelection : Integer read FCellSelection write SetCellSelection;
    property CellCount : Integer read GetCellCount write SetCellCount;

    property Options : TbivOptions read FOptions write SetOptions;

    property OnCellClick : TCellClickEvent read FOnCellClick write FOnCellClick;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;

  end;


  TbivGrid = class(TbivCustomGrid)
  private
    FOnCellPaint: TCellPaintEvent;
  protected
    procedure DoCellPaint(ABuffer: TBitmap32; AIndex: Integer; ARect: TRect);  override; // called by Theme
  published
    property CellCount;
    property Options;
    property OnCellPaint : TCellPaintEvent read FOnCellPaint write FOnCellPaint;
    //property OnCellClick : TCellClickEvent read FOnCellClick write FOnCellClick;
  end;

  TbivThemeOptions = set of (btHovering, btModes);

  TbivTheme = class(TComponent)
  private
    FGrid: TbivCustomGrid;
    procedure UiLayerChangeHandler(Sender: TObject);
    procedure UiLayerGetViewportShiftHandler(Sender: TObject; out ShiftX, ShiftY: TFloat);
    procedure SetGrid(const Value: TbivCustomGrid);

  protected
    FUiLayers: TLayerCollection;
    FPaintStages: TPaintStages;
    FPaintStageHandlers: array of TPaintStageHandler;
    FOptions: TbivThemeOptions;
    FPaintStageValid: Boolean;
    FItemMouseDown: Integer;

    procedure InitUi; virtual;
    procedure InitDefaultStages; virtual;
    procedure CheckPaintStage; virtual;
    procedure SetUiLayers(const AValue: TLayerCollection); virtual;
    procedure CalculateLayout; virtual;
    procedure CellBeforePaint(ABuffer: TBitmap32; AIndex: Integer; ARect: TRect);  virtual;
    procedure CellAfterPaint(ABuffer: TBitmap32; AIndex: Integer; ARect: TRect);  virtual;

    procedure PaintNothing(ABuffer: TBitmap32; StageNum: Integer);               // NOTHING, DUMMY PROC
    procedure PaintCustom(ABuffer: TBitmap32; StageNum: Integer); dynamic;       // PST_CUSTOM
    procedure PaintThumbnails(ABuffer: TBitmap32; StageNum: Integer); virtual;   // PST_DRAW_CELL
    procedure PaintBackground(ABuffer: TBitmap32; StageNum: Integer); virtual;   // PST_CLEAR_BACKGND
    procedure PaintUiLayers(ABuffer: TBitmap32; StageNum: Integer); virtual;     // PST_DRAW_UI_LAYERS
    procedure PaintControlFrame(ABuffer: TBitmap32; StageNum: Integer); virtual;     // PST_CONTROL_FRAME
    procedure PaintUI(ABuffer: TBitmap32; StageNum: Integer); virtual;
    procedure PaintCell(ABuffer: TBitmap32; AIndex: Integer; ARect: TRect);  virtual; // 3step: before,on,after
    procedure DoCellPaint(ABuffer: TBitmap32; AIndex: Integer; ARect: TRect);  virtual; // call OnCellPaint

    procedure AdjustClientRect(var ARect: TRect); virtual;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); virtual;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); virtual;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); virtual;
    procedure DoItemClick; virtual;
    procedure KeyDown(var Key: Word; Shift: TShiftState); virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure Paint(ABuffer: TBitmap32); virtual;
    function ThumbnailPlace(AWidth, AHight: Integer): TRect;
    procedure DefaultPaint(AIndex : Integer; Graphic: TBitmap32); virtual;

    property Grid : TbivCustomGrid read FGrid write SetGrid;
    property UiLayers : TLayerCollection read FUiLayers write SetUiLayers;
    property PaintStages : TPaintStages read FPaintStages;
    property PaintStageValid : Boolean read FPaintStageValid write FPaintStageValid;
  published
    property Options : TbivThemeOptions read FOptions write FOptions;
  end;

procedure GetScaledDimension(
  const AOldWidth, AOldHeight, ANewWidth, ANewHeight: Integer;
  var AScaledWidth, AScaledHeight: Integer);
    
const
  //PST_DRAW_LAYERS       = 5;   // Draw layers (Parameter = Layer Mask)
  PST_DRAW_CELL       = 9;   // Draw thumbnail cells
  PST_DRAW_UI_LAYERS  = 10;   // Draw layers (Parameter = Layer Mask)
  PST_DRAW_UI         = 11;   // Draw UI Navigations

  THUMBNAIL_SIZE      = 150;//256;//
  MIN_THUMBNAIL_SPAN  = 3;
  MAX_THUMBNAIL_SPAN  = 20;
  DEFAULT_WHEEL_DELTA = 32;
  SCROLL_THUMBSIZE    = 20;

  BUTTON_WIDTH  = 50;
  BUTTON_HEIGHT = 50;

implementation

uses
  Math, SyncObjs;

type
  TLayerAccess = class(TCustomLayer);
  TLayerCollectionAccess = class(TLayerCollection);
var
  UScrollLock : TCriticalSection;

{ Funcs }
// get scaled width/Height according to old width/height and new width/height
procedure GetScaledDimension(
  const AOldWidth, AOldHeight, ANewWidth, ANewHeight: Integer;
  var AScaledWidth, AScaledHeight: Integer);
var
  LWidthFactor  : Extended;
  LHeightFactor : Extended;
  LScaleFactor  : Extended;
  LScaling      : Boolean;
begin
  LScaleFactor := 0.0;
  LScaling     := False;

  AScaledWidth  := AOldWidth;
  AScaledHeight := AOldHeight;

  if (AOldWidth > ANewWidth) and (AOldHeight > ANewHeight) then
  begin
    LWidthFactor  := AOldWidth  / ANewWidth;
    LHeightFactor := AOldHeight / ANewHeight;

    if LWidthFactor >= LHeightFactor then
    begin
      LScaleFactor := LWidthFactor;
    end
    else
    begin
      LScaleFactor := LHeightFactor;
    end;

    LScaling := True;
  end
  else
  if (AOldWidth > ANewWidth) and (AOldHeight <= ANewHeight) then
  begin
    LScaleFactor := AOldWidth / ANewWidth;
    LScaling     := True;
  end
  else
  if (AOldWidth <= ANewWidth) and (AOldHeight > ANewHeight) then
  begin
    LScaleFactor := AOldHeight / ANewHeight;
    LScaling     := True;
  end;

  if LScaling then
  begin
    AScaledWidth  := Round(AOldWidth  / LScaleFactor);
    AScaledHeight := Round(AOldHeight / LScaleFactor);
  end;
end;
  
{ TbivGrid }

procedure TbivCustomGrid.AdjustClientRect(var Rect: TRect);
begin
  //inherited;
  FTheme.AdjustClientRect(Rect);
end;

function TbivCustomGrid.CanScrollDown: Boolean;
begin
  //Result := (FWorkSize.Y > Height) and (FViewportOffset.Y
  Result := FViewportOffset.Y + FWorkSize.Y > Height; 
end;

function TbivCustomGrid.CanScrollUp: Boolean;
begin
  Result := FViewportOffset.Y > 0;
end;

function TbivCustomGrid.CellUnderMouse: Integer;
begin
  if (FLastMousePos.X = FMousePos.X) and (FLastMousePos.Y = FMousePos.Y) then
  begin
    Result := FCellUnderMouse;
  end
  else
  begin
    FCellUnderMouse := GetItemAtXY(FMousePos.X, FMousePos.Y);
    FLastMousePos := FMousePos;
  end;

  Result := FCellUnderMouse;
end;

procedure TbivCustomGrid.Changed;
begin
  if FUpdateCount = 0 then
  begin
    Invalidate;

    if Assigned(FOnChange) then
      FOnChange(Self);
  end;
end;

procedure TbivCustomGrid.CheckLayout;
begin
  if LayoutValid then Exit;

  if FOptions.ListMode then
    FCols := 1
  else
    FCols := (Width - FMargin.X *2) div CellWidth;
    
  if FCols <= 0 then
    FCols := 1; //avoid error division by zero

  FPicWidth := CellWidth - MIN_THUMBNAIL_SPAN * 2;
  FPicHeight := CellHeight - MIN_THUMBNAIL_SPAN * 2;

  //Let give theme a chance to intervent above values (cols,rows,margin)
  FTheme.CalculateLayout();

  FRows := Ceil( CellCount / FCols);
  FWorkSize.Y := FRows * FCellHeight + FMargin.Y;

  //correct the visible cells. dont show blank if can show any cell.
  if FViewportOffset.Y > FWorkSize.Y - ClientHeight then
    FViewportOffset.Y := FWorkSize.Y - ClientHeight;

  //but also dont align cell to bottom, it must aligned top if too few cellCount
  if FViewportOffset.Y < 0 then
    FViewportOffset.Y := 0;

  FMaxVisibleCells := FCols * Ceil(ClientHeight / CellHeight);

  LayoutValid := True;
end;

constructor TbivCustomGrid.Create(AOwner: TComponent);
begin
  inherited;

  ControlStyle := [csAcceptsControls, csCaptureMouse, csClickEvents,
    csDoubleClicks, csReplicatable, csOpaque];
    
  inherited Options := [pboAutoFocus, pboWantArrowKeys];
  TabStop := True; //to receive Tabkey and focusable as default 
  
  FCellWidth := THUMBNAIL_SIZE;
  FCellHeight := THUMBNAIL_SIZE;
  FViewportOffset := Point(0,0);
  FMargin := Point(40,40);
  FCellSelection := -1;

  FOptions := TbivOptions.Create(Self);
  FTheme := TbivTheme.Create(self);
end;

destructor TbivCustomGrid.Destroy;
begin
  FTheme.Free;
  FOptions.Free;
  
  inherited;
end;

procedure TbivCustomGrid.DefaultPaint(AIndex: Integer; Graphic: TBitmap32);
begin
  FTheme.DefaultPaint(AIndex, Graphic);
end;

procedure TbivCustomGrid.KeyDown(var Key: Word; Shift: TShiftState);
begin
  inherited;

  Theme.KeyDown(Key, Shift);
end;

function TbivCustomGrid.DoMouseWheelDown(Shift: TShiftState;
  MousePos: TPoint): Boolean;
begin
  Self.MouseWheelDown(Shift, MousePos, Result);     //internal

  if Assigned(OnMouseWheelDown) then
    OnMouseWheelDown(Self, Shift, MousePos, Result); //external
end;

function TbivCustomGrid.DoMouseWheelUp(Shift: TShiftState;
  MousePos: TPoint): Boolean;
begin
  self.MouseWheelUp(Shift, MousePos, Result);     //internal

  if Assigned(OnMouseWheelUp) then
    OnMouseWheelUp(Self, Shift, MousePos, Result); //internal
end;

procedure TbivCustomGrid.DoPaintBuffer;
begin
  CheckLayout;
  Theme.CheckPaintStage;
  Theme.Paint(Buffer);

  // avoid calling inherited, we have a totally different behaviour here...
  BufferValid := True;
end;

function TbivCustomGrid.GetCellRect(ACellIndex: Integer): TRect;
var
  cy, cx, j, x, y : Integer;
begin
  Assert( (ACellIndex {<} <= Self.cellCount) ); //allow index 0 as dummy for first cell location
  CheckLayout;
  
  Result := MakeRect(0, 0, CellWidth-1, CellHeight-1);
  if Options.ListMode then
    Result.Right := ClientWidth;
  if ACellIndex >=0 then // It should not happen, but in debug mode
  begin
    cx := ACellIndex mod FCols; // column
    cy := ACellIndex div FCols; // row

    x := FMargin.X + cx * CellWidth  - FViewportOffset.X;
    y := FMargin.Y + cy * CellHeight - FViewportOffset.Y;
    OffsetRect(Result,x,y);
  end;
end;

function TbivCustomGrid.GetItemAtXY(X, Y: Integer): Integer;
var
  LRows, LCols, LCellWidth : Integer;
begin
  Result := -1;

  //1. Translate mousepos into margin_excluded.
  Dec(X, FMargin.X);
  Dec(Y, FMargin.Y);
  LCellWidth := CellWidth;
  if Options.ListMode then
    LCellWidth := ClientWidth;

  //2. Test wether mousepos above the window box.
  if (X +FViewportOffset.X >= 0) and
     (Y +FViewportOffset.Y >= 0) and
     (x < LCellWidth * FCols) and
     (Y < ClientHeight) then
  begin
    LRows := (Y + FViewportOffset.Y ) div CellHeight;
    LCols := (X + FViewportOffset.X ) div LCellWidth;

    Result := LRows * FCols + LCols;
    if Result >= CellCount then
      Result := -1;
  end;
end;

procedure TbivCustomGrid.InvalidateLayout;
begin
  LayoutValid := False;
end;

function TbivCustomGrid.IsVisible(ACellIndex: Integer): Boolean;
var
  R : TRect;
begin
  Result := False;
  R := GetCellRect(ACellIndex);
  with R do
  begin
    if ( (Top < ClientHeight) or (Bottom > 0) ) and
       ( (Left < ClientWidth) or (Right > 0) ) then
    begin
      Result := True;
    end;
  end;  
end;

procedure TbivCustomGrid.MouseDown(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
begin
  inherited;

  if TabStop and CanFocus then
    SetFocus;

  Theme.MouseDown(Button, Shift, X, Y);
end;

procedure TbivCustomGrid.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  inherited;

  Theme.MouseMove(Shift, X, Y);
end;

procedure TbivCustomGrid.MouseUp(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
begin
  inherited;

  Theme.MouseUp(Button, Shift, X, Y);
end;

procedure TbivCustomGrid.MouseWheelDown(Shift: TShiftState; MousePos: TPoint;
  var Handled: Boolean);
var
  LWheelDelta : Integer;  
begin
  Handled := CanScrollDown;
  
  if Handled then
  begin
    LWheelDelta := CellHeight;
    if ssCtrl in Shift then
      LWheelDelta := ClientHeight
    else if ssShift in Shift then
      LWheelDelta := CellHeight div 2;

    Scroll(0, LWheelDelta);
  end;
end;

procedure TbivCustomGrid.MouseWheelUp(Shift: TShiftState; MousePos: TPoint;
  var Handled: Boolean);
var
  LWheelDelta : Integer;
begin
  Handled := CanScrollUp;
  if Handled then
  begin
    LWheelDelta := CellHeight;
    if ssCtrl in Shift then
      LWheelDelta := ClientHeight
    else if ssShift in Shift then
      LWheelDelta := CellHeight div 2;

    Scroll(0, -LWheelDelta);
  end;
end;

procedure TbivCustomGrid.Resize;
begin
  InvalidateLayout;
  inherited;
end;

procedure TbivCustomGrid.Scroll(Dx, Dy: Integer);
var
  LastOffset : TPoint;
begin
  //gate for only single thread changing the viewport.
  //we avoid lost of context. so calling viewport must be queued 
  UScrollLock.Acquire;

  LastOffset := FViewportOffset;
  with FViewportOffset do
  begin
    inc(x, Dx);
    Inc(y, Dy);
    if x < 0 then
      x := 0;

    if y < 0 then
      y := 0
    else if y > FWorkSize.y - Height then
      Y := FWorkSize.Y - Height;

    if (LastOffset.X <> X) or (LastOffset.Y <> Y) then
    begin
      //update mousePos & CellUnderMouse
      FLastMousePos := Point(-1,-1);
      FTheme.CalculateLayout;
      Changed;
    end;
  end;
  UScrollLock.Release;
end;

procedure TbivCustomGrid.SetCellCount(const Value: Integer);
begin
  FCellCount := Value;
  InvalidateLayout;
  Changed;
end;

procedure TbivCustomGrid.SetCellHeight(const Value: Integer);
begin
  FCellHeight := Value;
  InvalidateLayout;
end;

procedure TbivCustomGrid.SetCellWidth(const Value: Integer);
begin
  FCellWidth := Value;
  InvalidateLayout;
end;

procedure TbivCustomGrid.SetTheme(const Value: TbivTheme);
begin
  if Assigned(FTheme) then
    FTheme.Free;
    
  FTheme := Value;
  //FTheme.PaintStageValid := False;
  InvalidateLayout; //such calculate scrollbars...
  Changed;  
end;

{ TbivGrid }

procedure TbivGrid.DoCellPaint(ABuffer: TBitmap32; AIndex: Integer;
  ARect: TRect);
begin
  if Assigned(OnCellPaint) then
    OnCellPaint(ABuffer, AIndex, ARect);
end;

{ TbivTheme }

procedure TbivTheme.AdjustClientRect(var ARect: TRect);
begin
  
end;

procedure TbivTheme.CalculateLayout;
begin

end;

procedure TbivTheme.CellAfterPaint(ABuffer: TBitmap32; AIndex: Integer;
  ARect: TRect);
begin

end;

procedure TbivTheme.CellBeforePaint(ABuffer: TBitmap32; AIndex: Integer;
  ARect: TRect);
begin
  //if csHover in AStates then
  if AIndex = Grid.CellUnderMouse then
      ABuffer.FillRectS(ARect, clGainsBoro32); //hover
  //if AIndex = Grid.CellSelection then
  if Grid.IsSelected(AIndex) then
    ABuffer.FillRectS(ARect, $55777777); //selected
end;

procedure TbivTheme.CheckPaintStage;
var
  PaintStageHandlerCount: Integer;
  I, J: Integer;
  DT, RT: Boolean;  
begin
  if PaintStageValid then
    Exit;
    
  SetLength(FPaintStageHandlers, FPaintStages.Count);
  PaintStageHandlerCount := 0;

  DT := csDesigning in ComponentState;
  RT := not DT;

  // compile list of paintstage handler methods
  for I := 0 to FPaintStages.Count - 1 do
  begin
    with FPaintStages[I]^ do
    begin
      if (DsgnTime and DT) or (RunTime and RT) then
      begin
        //FPaintStageNum[PaintStageHandlerCount] := I;
        case Stage of
          PST_CUSTOM: FPaintStageHandlers[PaintStageHandlerCount] := PaintCustom;
//          PST_CLEAR_BUFFER: FPaintStageHandlers[PaintStageHandlerCount] := ExecClearBuffer;
//          PST_CLEAR_BACKGND: FPaintStageHandlers[PaintStageHandlerCount] := ExecClearBackgnd;
//          PST_DRAW_BITMAP: FPaintStageHandlers[PaintStageHandlerCount] := ExecDrawBitmap;
//          PST_DRAW_LAYERS: FPaintStageHandlers[PaintStageHandlerCount] := ExecDrawLayers;
          PST_CONTROL_FRAME: FPaintStageHandlers[I] := PaintControlFrame;
//          PST_BITMAP_FRAME: FPaintStageHandlers[PaintStageHandlerCount] := ExecBitmapFrame;
          PST_CLEAR_BACKGND :  FPaintStageHandlers[I] := PaintBackground;
          PST_DRAW_CELL     :  FPaintStageHandlers[I] := PaintThumbnails;
          PST_DRAW_UI_LAYERS:  FPaintStageHandlers[I] := PaintUiLayers;
          PST_DRAW_UI       :  FPaintStageHandlers[I] := PaintUI;
        else
          //Dec(PaintStageHandlerCount); // this should not happen}
          FPaintStageHandlers[I] := PaintNothing;
        end;
        
        Inc(PaintStageHandlerCount);
      end
      else
        FPaintStageHandlers[I] := PaintNothing;
    end;
  end;
  
  PaintStageValid := True;
end;

constructor TbivTheme.Create(AOwner: TComponent);
begin
  inherited;
  if AOwner is TbivCustomGrid then
    FGrid := TbivCustomGrid(Owner);

  FUiLayers    := TLayerCollection.Create(FGrid);
  FPaintStages := TPaintStages.Create;
  
  if not (csDesigning in ComponentState) then
    InitUi;

  FPaintStages := TPaintStages.Create;
  InitDefaultStages;
end;

procedure TbivTheme.DefaultPaint(AIndex: Integer; Graphic: TBitmap32);
var
  Cell, Dst, Src, Def : TRect;
begin
  Src  := Graphic.BoundsRect;
  cell := Grid.GetCellRect(AIndex);
  Def  := Cell;

  InflateRect(Def,-MIN_THUMBNAIL_SPAN, -MIN_THUMBNAIL_SPAN);
  OffsetRect(Def, -Def.Left, -def.Top);
  //Dec(Def.Right, MIN_THUMBNAIL_SPAN *2);
  //Dec(Def.Bottom, MIN_THUMBNAIL_SPAN *2);
  Def.Right := Min(Src.Right, Def.Right);
  Def.Bottom := Min(Src.Bottom, Def.Bottom);

  Dst := Def;
  OffsetRect(Dst, cell.Left + ((cell.Right-cell.Left) - Def.Right)  div 2,
                  cell.Top  + ((cell.Bottom-cell.Top) - Def.Bottom) div 2 );

  Grid.Buffer.Draw(Dst, Src, Graphic);
end;

destructor TbivTheme.Destroy;
begin
  FUiLayers.Clear;
  FUiLayers.Free;

  FPaintStages.Clear;
  FPaintStages.Free;
  
  inherited;
end;

procedure TbivTheme.DoCellPaint(ABuffer: TBitmap32; AIndex: Integer;
  ARect: TRect);
var
  LThumb : TRect;
  LMargin : Integer;
begin
    //LThumb := ARect;
    //OffsetRect(LThumb, - LThumb.Left, - LThumb.Top);
    //InflateRect(LThumb, -MIN_THUMBNAIL_SPAN, -MIN_THUMBNAIL_SPAN);
    //GetScaledDimension(LThumb.Right, LThumb.Bottom, Grid.PicWidth, Grid.PicWidth, LThumb.Right, LTHumb.Bottom);

    LThumb := MakeRect(0,0,Grid.PicWidth, Grid.PicHeight);
    if Grid.Options.FListMode then
    begin
      LMargin := ((ARect.Bottom- ARect.Top) - LThumb.Bottom) div 2;
      OffsetRect(LThumb,
        ARect.Left + LMargin,
        ARect.Top  + LMargin
       );
    end
    else
      OffsetRect(LThumb,
        ARect.Left + ((ARect.Right- ARect.Left) - LThumb.Right)  div 2,
        ARect.Top  + ((ARect.Bottom- ARect.Top) - LThumb.Bottom) div 2
       );


    Grid.DoCellPaint(ABuffer, AIndex, LThumb);
end;

procedure TbivTheme.DoItemClick;
begin
  if Assigned(Grid.FOnCellClick) then
    Grid.FOnCellClick(Grid, Self.FItemMouseDown);
end;

procedure TbivTheme.KeyDown(var Key: Word; Shift: TShiftState);
var
  LNeedRefresh   : Boolean;
  LRowNo, LIndex : Integer;
  r              : TRect;
begin
  LNeedRefresh := False;
  
  case Key of
    VK_LEFT:
      begin
        if Grid.CellSelection > 0 then
        begin
          //Dec(Grid.FCellSelection);
          Grid.CellSelection := Grid.CellSelection - 1;
          LNeedRefresh := True;

          r := Grid.GetCellRect(Grid.CellSelection);
          if r.Top < 0 then
          begin
            Grid.Scroll(0, -Grid.CellHeight);
          end;
        end;
      end;

    VK_RIGHT:
      begin
        if ( Grid.CellSelection >= 0 ) and
           ( Grid.CellSelection < (Grid.CellCount - 1) ) then
        begin
          //Inc(Grid.FCellSelection);
          Grid.CellSelection := Grid.CellSelection + 1;

          LNeedRefresh := True;

          r := Grid.GetCellRect(Grid.CellSelection);
          if r.Top >= Grid.ClientHeight then
          begin
            Grid.Scroll(0, Grid.CellHeight);
          end;
        end;
      end;

    VK_UP:
      begin
        LRowNo := Grid.CellSelection div Grid.FCols;

        if LRowNo > 0 then
        begin
          //Dec(Grid.FCellSelection, Grid.FCols);
          Grid.CellSelection := Grid.CellSelection - Grid.FCols;

          LNeedRefresh := True;

          r := Grid.GetCellRect(Grid.CellSelection);
          if r.Top < 0 then
          begin
            Grid.Scroll(0, -Grid.CellHeight);
          end;
        end;
      end;

    VK_DOWN:
      begin
        LRowNo := Grid.CellSelection div Grid.FCols;

        if LRowNo < (Grid.FRows - 1) then
        begin
          LIndex := Grid.FCellSelection + Grid.FCols;

          if LIndex < (Grid.CellCount) then
          begin
            Grid.CellSelection := LIndex;
            LNeedRefresh        := True;

            r := Grid.GetCellRect(Grid.CellSelection);
            if r.Bottom >= Grid.ClientHeight then
            begin
              Grid.Scroll(0, Grid.CellHeight);
            end;
          end;
        end;
      end;
      { TODO -ox2nie -cfunctionality : 
Add more keyboard combination for multi-select such Shift+PgDown/Up
and be aware about range selection: shift+Left will release the current cell from selectionlist. }
  end;

  if LNeedRefresh then
  begin
    Grid.Invalidate();
  end;
end;

procedure TbivTheme.InitDefaultStages;
begin
  // background
  with PaintStages.Add^ do
  begin
    DsgnTime := True;
    RunTime := True;
    Stage := PST_CLEAR_BACKGND;
  end;

  // bitmap
  {with PaintStages.Add^ do
  begin
    DsgnTime := True;
    RunTime := True;
    Stage := PST_DRAW_BITMAP;
  end;}

  // bitmap frame
  {with PaintStages.Add^ do
  begin
    DsgnTime := True;
    RunTime := False;
    Stage := PST_BITMAP_FRAME;
  end;}

  //thumbnail cells
  with PaintStages.Add^ do
  begin
    DsgnTime := True;
    RunTime := True;
    Stage := PST_DRAW_CELL;
  end;

  // navigation layers
  with PaintStages.Add^ do
  begin
    DsgnTime := False;
    RunTime := True;
    Stage := PST_DRAW_UI_LAYERS; 
    Parameter := LOB_VISIBLE;
  end;
  
  // navigation overlay
  with PaintStages.Add^ do
  begin
    DsgnTime := False;
    RunTime := True;
    Stage := PST_DRAW_UI;
  end;

  // control frame
  with PaintStages.Add^ do
  begin
    DsgnTime := True;
    RunTime := True;
    Stage := PST_CONTROL_FRAME;
  end;  
end;

procedure TbivTheme.InitUi;
begin

end;

procedure TbivTheme.MouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
var
  LLayer : TCustomLayer;
begin
  inherited;

  FItemMouseDown := -1;
  if UiLayers.MouseEvents then
    LLayer := TLayerCollectionAccess(UiLayers).MouseDown(Button, Shift, X, Y)
  else
    LLayer := nil;

  if LLayer = nil then
  begin
    FItemMouseDown      := Grid.CellUnderMouse;
    //Grid.FCellSelection := FItemMouseDown;
    Grid.SetSelected(FItemMouseDown);
  end;

  // lock the capture only if mbLeft was pushed or any mouse listener was activated
  if (Button = mbLeft) or (TLayerCollectionAccess(UiLayers).MouseListener <> nil) then
  begin
    Grid.MouseCapture := True;
    Grid.Invalidate;
  end;
end;

procedure TbivTheme.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  LLayer: TCustomLayer;
  LLastHover: Integer;
begin
  inherited;

  //LLastHover := Grid.GetItemAtXY(Grid.FMousePos.X, Grid.FMousePos.Y);
  LLastHover := Grid.CellUnderMouse;
  
  if UiLayers.MouseEvents then
    LLayer := TLayerCollectionAccess(UiLayers).MouseMove(Shift, X, Y)
  else
    LLayer := nil;

  Grid.FMousePos := Point(X,Y);
  if LLastHover <> Grid.CellUnderMouse then // .GetItemAtXY(Grid.FMousePos.X, Grid.FMousePos.Y) then
    Grid.Invalidate; 
end;

procedure TbivTheme.MouseUp(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
var
  LLayer: TCustomLayer;
begin
  inherited;
  
  if UiLayers.MouseEvents then
    LLayer := TLayerCollectionAccess(UiLayers).MouseUp(Button, Shift, X, Y)
  else
    LLayer := nil;

  // unlock the capture using same criteria as was used to acquire it
  if (Button = mbLeft) or (TLayerCollectionAccess(UiLayers).MouseListener <> nil) then
    Grid.MouseCapture := False;

  if Grid.CellUnderMouse = FItemMouseDown then
    DoItemClick;
end;


procedure TbivTheme.Paint(ABuffer: TBitmap32);
var
  I: Integer;
begin
  ABuffer.BeginUpdate;
  begin
    ABuffer.ClipRect := Grid.GetViewportRect;
    
    for I := 0 to High(FPaintStageHandlers) do
      FPaintStageHandlers[I](ABuffer, I);

    ABuffer.ClipRect := Grid.GetViewportRect;
  end;

  ABuffer.EndUpdate;
end;

procedure TbivTheme.PaintBackground(ABuffer: TBitmap32; StageNum: Integer);
var
  C: TColor32;
begin
  C := Color32(Grid.Color);
  if Assigned(ABuffer) then
    ABuffer.Clear(C)
end;

procedure TbivTheme.PaintCell(ABuffer: TBitmap32; AIndex: Integer;
  ARect: TRect);
begin
  CellBeforePaint(ABuffer, AIndex, ARect);
  DoCellPaint(ABuffer, AIndex, ARect);
  CellAfterPaint(ABuffer, AIndex, ARect);
end;

procedure TbivTheme.PaintControlFrame(ABuffer: TBitmap32;
  StageNum: Integer);
begin

end;

procedure TbivTheme.PaintCustom(ABuffer: TBitmap32; StageNum: Integer);
begin

end;

procedure TbivTheme.PaintNothing(ABuffer: TBitmap32; StageNum: Integer);
begin
// do nothing!
// it is dummy for not found or invalid paint handler
end;

procedure TbivTheme.PaintThumbnails(ABuffer: TBitmap32; StageNum: Integer);
var
  R0,R : TRect;
  //LHoverI : Integer;
  cy, cx, i, j, x, y : Integer;
  //LCellStates : TCellStates;
begin
  if (Grid.CellCount > 0) {and Assigned(Grid.FOnCellPaint)} then
  begin
    //LHoverI := Grid.GetItemAtXY(Grid.FMousePos.X, Grid.FMousePos.Y);
    //R0  := MakeRect(0, 0, Grid.CellWidth-1, Grid.CellHeight-1);

    cy  := (Grid.FViewportOffset.Y - Grid.Fmargin.Y) div Grid.CellHeight; //first visible row
    i   := cy * Grid.FCols;              //first visible cell's index
    while (i < Grid.CellCount) do //(r.Bottom >= ClientHeight);
    begin
      if i >=0 then // It should not happen, but in debug mode
      begin
        {cx := i mod Grid.FCols; // column
        cy := i div Grid.FCols; // row

        x := Grid.FMargin.X + cx * Grid.CellWidth - Grid.FViewportOffset.X;
        y := Grid.FMargin.Y + cy * Grid.CellHeight - Grid.FViewportOffset.Y;
        R := R0; //copy}
        //OffsetRect(R,x,y);
        R := Grid.GetCellRect(i);
        if R.Top > Grid.ClientHeight then Break;

        //DoCellPaint(Dest, I, R);
        {if i = LHoverI then
          LCellStates := [csHover]
        else
          LCellStates := []; }
          
        ABuffer.Font := Grid.Font; //reset
        PaintCell(ABuffer, I,  R);
        //ABuffer.FrameRectS(R, clTrRed32);//debug
      end;
      
      Inc(i);
    end;
  end;
end;

procedure TbivTheme.PaintUI(ABuffer: TBitmap32; StageNum: Integer);
begin

end;

procedure TbivTheme.PaintUiLayers(ABuffer: TBitmap32; StageNum: Integer);
var
  I: Integer;
  LMask: Cardinal;
begin
  LMask := PaintStages[StageNum]^.Parameter;
  for I := 0 to UiLayers.Count - 1 do
    if (UiLayers.Items[I].LayerOptions and LMask) <> 0 then
      TLayerAccess(UiLayers.Items[I]).DoPaint(ABuffer);
end;

procedure TbivTheme.SetUiLayers(const AValue: TLayerCollection);
begin
  if Assigned(FUiLayers) then
    FUiLayers.Free;

  FUiLayers := AValue;
  
  with TLayerCollectionAccess(FUiLayers) do
  begin
    OnChange := Self.UiLayerChangeHandler;
    OnGetViewportShift := Self.UiLayerGetViewportShiftHandler;
  end;
end;

function TbivTheme.ThumbnailPlace(AWidth, AHight: Integer): TRect;
begin

end;

procedure TbivTheme.UiLayerChangeHandler(Sender: TObject);
begin
  Grid.Changed;  
end;

procedure TbivTheme.UiLayerGetViewportShiftHandler(Sender: TObject;
  out ShiftX, ShiftY: TFloat);
begin
  ShiftX := Grid.FViewportOffset.X;
  ShiftY := Grid.FViewportOffset.Y;
end;


procedure TbivCustomGrid.DoCellPaint(ABuffer: TBitmap32; AIndex: Integer;
  ARect: TRect);
begin
  //ancestor will do something
end;

function TbivCustomGrid.GetCellCount: Integer;
begin
  Result := FCellCount;
end;

procedure TbivCustomGrid.SetCellSelection(const Value: Integer);
begin
  if FCellSelection <> Value then
  begin
    FCellSelection := Value;
    Invalidate;
  end;
end;

procedure TbivTheme.SetGrid(const Value: TbivCustomGrid);
begin
  if FGrid <> Value then
  begin
    FGrid := Value;
    if Assigned(FUiLayers) then
      //FUiLayers.Collection := FGRid;
  end;
end;

{ TbivOptions }

constructor TbivOptions.Create(AGrid: TbivCustomGrid);
begin
  inherited Create;
  FGrid := AGrid;
end;

function TbivOptions.GetPaintboxOption: TPaintBoxOptions;
begin
  Result := [];
  if Assigned(FGrid) then
    Result := FGrid.GetLegacyOptions;
end;

procedure TbivOptions.SetListMode(const Value: Boolean);
begin
  FListMode := Value;
  if Assigned(FGrid) then
    FGrid.InvalidateLayout;
end;

procedure TbivOptions.SetMultiSelect(const Value: Boolean);
begin
  if FMultiSelect <> Value then
  begin
    FMultiSelect := Value;
    if Assigned(FGrid) then
      FGrid.Invalidate;
  end;
end;

procedure TbivOptions.SetPaintboxOption(const Value: TPaintBoxOptions);
begin
  if Assigned(FGrid) then
    FGrid.LegacyOptions := value;
end;

procedure TbivCustomGrid.SetOptions(const Value: TbivOptions);
begin
  FOptions.Assign(Value);
end;

function TbivCustomGrid.GetLegacyOptions: TPaintBoxOptions;
begin
  Result := inherited Options;
end;

procedure TbivCustomGrid.SetLegacyOptions(const Value: TPaintBoxOptions);
begin
  inherited Options := Value;
end;

function TbivCustomGrid.IsSelected(AIndex: Integer): Boolean;
begin
  Result := AIndex = CellSelection; //for multi-select mode, you might ask via event-handler
end;

procedure TbivCustomGrid.SetSelected(AIndex: Integer);
begin
  CellSelection := AIndex; //for multi-select mode, you might ask via event-handler
end;

initialization
  UScrollLock := TCriticalSection.Create;

finalization
  UScrollLock.Free;

end.
