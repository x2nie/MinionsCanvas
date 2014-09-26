unit GR32_ElasticLayers;

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
 * The Original Code is Elastic Layer for Graphics32
 *
 * The Initial Developer of the Original Code is
 *   Fathony Luthfillah - www.x2nie.com
 *   x2nie@yahoo.com
 *
 *
 * Portions created by the Initial Developer are Copyright (C) 2014
 * the Initial Developer. All Rights Reserved.
 *
 * The code was partially taken from GR32_Layers.pas
 *   www.graphics32.org
 *   http://graphics32.org/documentation/Docs/Units/GR32_Layers/_Body.htm
 *
 * The code was partially taken from GR32_ExtLayers.pas by
 *   Mike Lischke  www.delphi-gems.com  www.lischke-online.de 
 *   public@lischke-online.de
 *
 * Contributor(s):
 *
 *
 * ***** END LICENSE BLOCK ***** *)


interface

uses
  Windows, Classes, SysUtils, Controls, Forms, Graphics,
  GR32_Types, GR32, GR32_Image, GR32_Layers, GR32_Transforms, GR32_Polygons;

type

  // These states can be entered by the rubber band layer.
  {
    DIRECTION:            INDEX:            normal cursor:     rotated cursor:
                                                  ^                   ^
    NW    N   NE          0   4   1           \   ^   /             \   E
    W         E           7       5           <-W   E->          <-       ->
    SW    S   SE          3   6   2           /   v   \             W   \
                                                  v                   v
  }
  TTicDragState = (
    tdsResizeNW, tdsResizeN, tdsResizeNE,
    tdsResizeE, tdsResizeSE,
    tdsResizeS, tdsResizeSW, tdsResizeW,    
    tdsSheerN, tdsSheerE, tdsSheerS, tdsSheerW,
    tdsMoveLayer, tdsMovePivot,
    tdsRotate,
    tdsNone
  );
  TCursorDirection = (
    cdNotUsed,
    cdNorthWest,
    cdNorth,
    cdNorthEast,
    cdEast,
    cdSouthEast,
    cdSouth,
    cdSouthWest,
    cdWest
  );
  {
  TTicDragState = (
    tdsResizeNW, tdsResizeNE, tdsResizeSE, tdsResizeSW,
    tdsResizeN, tdsResizeE, tdsResizeS, tdsResizeW,
    tdsSheerN, tdsSheerE, tdsSheerS, tdsSheerW,
    tdsMoveLayer, tdsMovePivot,
    tdsRotate,
    tdsNone
  );
  }
  {
  TTicDragState = (
    tdsNone, tdsMoveLayer, tdsMovePivot,
    tdsResizeN, tdsResizeNE, tdsResizeE, tdsResizeSE,
    tdsResizeS, tdsResizeSW, tdsResizeW, tdsResizeNW,
    tdsSheerN, tdsSheerE, tdsSheerS, tdsSheerW,
    tdsRotate
  );
  }



  
  TExtRubberBandOptions = set of (
    rboAllowPivotMove,
    rboAllowCornerResize,
    rboAllowEdgeResize,
    rboAllowMove,
    rboAllowRotation,
    rboShowFrame,
    rboShowHandles
  );

const
  DefaultRubberbandOptions = [rboAllowCornerResize, rboAllowEdgeResize, rboAllowMove,
    rboAllowRotation, rboShowFrame, rboShowHandles];

type

  TTicTransformation = class;

  TTicLayer = class(TCustomLayer)
  private
    FScaled: Boolean;
    FCropped: Boolean;
    function GetTic(index: Integer): TFloatPoint;
    procedure SetTic(index: Integer; const Value: TFloatPoint);
    procedure SetScaled(const Value: Boolean);
    procedure SetCropped(const Value: Boolean);
    
    procedure SetEdges(const Value: TArrayOfFloatPoint);
    function GetSourceRect: TFloatRect;
    procedure SetSourceRect(const Value: TFloatRect);
    function GetEdges: TArrayOfFloatPoint;
  protected
    FTransformation : TTicTransformation {T3x3Transformation};  //Non ViewPort world
    FInViewPortTransformation : TTicTransformation ;            //used in Paint() and MouseMove
    //function Matrix : TFloatMatrix; //read only property
    //FTic : array[0..3] of TFloatPoint;
    //FQuadX: array [0..3] of TFloat;
    //FQuadY: array [0..3] of TFloat;
    //FEdges: TArrayOfFloatPoint;
    procedure DoSetEdges(const Value: TArrayOfFloatPoint); virtual;

  public
    constructor Create(ALayerCollection: TLayerCollection); override;
    destructor Destroy; override;
    
    function GetScaledRect(const R: TFloatRect): TFloatRect; virtual;
    function GetScaledEdges : TArrayOfFloatPoint; 
    procedure SetBounds(APosition: TFloatPoint; ASize: TFloatPoint); overload;
    procedure SetBounds(ABoundsRect: TFloatRect); overload;

    property Tic[index : Integer] : TFloatPoint read GetTic write SetTic; // expected index: 0 .. 3
    property Edges: TArrayOfFloatPoint read GetEdges write SetEdges;
    property Scaled: Boolean read FScaled write SetScaled;
    property SourceRect : TFloatRect read GetSourceRect write SetSourceRect;
    property Cropped: Boolean read FCropped write SetCropped;
        
  end;


  TTicBitmapLayer = class(TTicLayer)
  private
    FBitmap: TBitmap32;
    procedure BitmapChanged(Sender: TObject);
    procedure SetBitmap(const Value: TBitmap32);
  protected
    function DoHitTest(X, Y: Integer): Boolean; override;
    procedure Paint(Buffer: TBitmap32); override;
  public
    constructor Create(ALayerCollection: TLayerCollection); override;
    destructor Destroy; override;
    //procedure PaintTo(Buffer: TBitmap32; const R: TRect);
    property Bitmap: TBitmap32 read FBitmap write SetBitmap;
  end;

  TTicRubberBandLayer = class(TTicLayer)
  private
    FChildLayer: TTicLayer;
    // Drag/resize support
    FIsDragging: Boolean;
    FOldEdgest : TArrayOfFloatPoint;
    FDragState: TTicDragState;
    {FOldPosition: TFloatPoint;         // Keep the old values to restore in case of a cancellation.
    FOldScaling: TFloatPoint;
    FOldPivot: TFloatPoint;
    FOldSkew: TFloatPoint;
    FOldAbsAnchor, FOldAnchor : TFloatPoint;
    FOldAngle: Single;}
    FDragPos: TPoint;
    FThreshold: Integer;
    FPivotPoint: TFloatPoint;
    FOptions: TExtRubberBandOptions;
    FHandleSize: Integer;
    FHandleFrame: TColor;
    FHandleFill: TColor;

    procedure SetChildLayer(const Value: TTicLayer);
    procedure SetOptions(const Value: TExtRubberBandOptions);
    procedure SetHandleFill(const Value: TColor);
    procedure SetHandleFrame(const Value: TColor);
    procedure SetHandleSize(Value: Integer);
  protected
    //function DoHitTest(X, Y: Integer): Boolean; override;
    procedure DoSetEdges(const Value: TArrayOfFloatPoint); override;
    function GetHitCode(X, Y: Integer; Shift: TShiftState): TTicDragState;
    function GetCursorDirection(State: TTicDragState):TCursorDirection ;
    
    procedure Paint(Buffer: TBitmap32); override;
    procedure SetLayerOptions(Value: Cardinal); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;    
  public
    constructor Create(ALayerCollection: TLayerCollection); override;
    //destructor Destroy; override;
    property ChildLayer: TTicLayer read FChildLayer write SetChildLayer;
    property Options: TExtRubberBandOptions read FOptions write SetOptions default DefaultRubberbandOptions;
    property HandleSize: Integer read FHandleSize write SetHandleSize default 3;
    property HandleFill: TColor read FHandleFill write SetHandleFill default clWhite;
    property HandleFrame: TColor read FHandleFrame write SetHandleFrame default clBlack;
    
    property PivotPoint: TFloatPoint read FPivotPoint write FPivotPoint;
    property Threshold: Integer read FThreshold write FThreshold default 8;

  end;


  // A TProjectiveTransformation that doesnt store the values in itself
  TTicTransformation = class(T3x3Transformation)
  private
    FEdges: TArrayOfFloatPoint;
    procedure SetEdges(const Value: TArrayOfFloatPoint);
  protected
    //FOwner : TTicLayer;
    procedure AssignTo(Dest: TPersistent); override;

    procedure PrepareTransform; override;
    procedure ReverseTransformFixed(DstX, DstY: TFixed; out SrcX, SrcY: TFixed); override;
    procedure ReverseTransformFloat(DstX, DstY: TFloat; out SrcX, SrcY: TFloat); override;
    procedure TransformFixed(SrcX, SrcY: TFixed; out DstX, DstY: TFixed); override;
    procedure TransformFloat(SrcX, SrcY: TFloat; out DstX, DstY: TFloat); override;
  public
    //constructor Create(AOwner: TTicLayer); virtual;
    constructor Create; virtual;
    function GetTransformedBounds(const ASrcRect: TFloatRect): TFloatRect; override;
    function GetMiddleEdges: TArrayOfFloatPoint;
    //procedure Scale(Sx, Sy: TFloat); //overload;
    //procedure Scale(Value: TFloat); overload;
    //procedure Translate(Dx, Dy: TFloat);

    property Edges: TArrayOfFloatPoint read FEdges write SetEdges;
  end;

  
implementation

uses
  Math, GR32_Blend, GR32_LowLevel, GR32_Math, GR32_Bindings,
  GR32_Resamplers;

type
  TLayerCollectionAccess = class(TLayerCollection);
  TImage32Access = class(TCustomImage32);


function EdgesToFloatRect(AEdges: TArrayOfFloatPoint): TFloatRect ;
begin
    Result.Left   := Min(Min(AEdges[0].X, AEdges[1].X), Min(AEdges[2].X, AEdges[3].X));
    Result.Right  := Max(Max(AEdges[0].X, AEdges[1].X), Max(AEdges[2].X, AEdges[3].X));
    Result.Top    := Min(Min(AEdges[0].Y, AEdges[1].Y), Min(AEdges[2].Y, AEdges[3].Y));
    Result.Bottom := Max(Max(AEdges[0].Y, AEdges[1].Y), Max(AEdges[2].Y, AEdges[3].Y));
end;

function MoveEdges(AEdges : TArrayOfFloatPoint; Delta : TFloatPoint): TArrayOfFloatPoint;
var i : Integer;
begin
  SetLength(Result,4);
  //Result := AEdges;
  for i := 0 to 3 do
  begin
    Result[i].X  := AEdges[i].X + Delta.X;
    Result[i].Y  := AEdges[i].Y + Delta.Y;
  end;
end;

function MostLeftEdge(AEdges : TArrayOfFloatPoint): Integer;
var i : Integer;
begin
  Result := 0;
  for i := Length(AEdges)-1 downto 1 do
  begin
    if AEdges[i].X < AEdges[0].X then
      Result := i;
  end;
end;

{ TTicLayer }

constructor TTicLayer.Create(ALayerCollection: TLayerCollection);
begin
  inherited;
  LayerOptions := LOB_VISIBLE or LOB_MOUSE_EVENTS;  
  FTransformation := TTicTransformation.Create;
  FInViewPortTransformation := TTicTransformation.Create;
  
end;

destructor TTicLayer.Destroy;
begin
  FTransformation.Free;
  inherited;
end;

procedure TTicLayer.DoSetEdges(const Value: TArrayOfFloatPoint);
begin
  FTransformation.Edges := Value;
end;

function TTicLayer.GetScaledEdges: TArrayOfFloatPoint;
var
  ScaleX, ScaleY, ShiftX, ShiftY: TFloat;
  i : Integer;
begin
  //Result := Edges; ERROR HERE, IT SHARE THE ARRAY CONTENT.
  SetLength(Result,4);

  if Scaled and Assigned(LayerCollection) then
  begin
    LayerCollection.GetViewportShift(ShiftX, ShiftY);
    LayerCollection.GetViewportScale(ScaleX, ScaleY);

    for i := 0 to Length(Result)-1 do
    begin
      Result[i].X := Edges[i].X * ScaleX + ShiftX;
      Result[i].Y := Edges[i].Y * ScaleY + ShiftY;
    end;
  end;
end;

function TTicLayer.GetScaledRect(const R: TFloatRect): TFloatRect;
var
  ScaleX, ScaleY, ShiftX, ShiftY: TFloat;
begin
  if Scaled and Assigned(LayerCollection) then
  begin
    LayerCollection.GetViewportShift(ShiftX, ShiftY);
    LayerCollection.GetViewportScale(ScaleX, ScaleY);

    with Result do
    begin
      Left := R.Left * ScaleX + ShiftX;
      Top := R.Top * ScaleY + ShiftY;
      Right := R.Right * ScaleX + ShiftX;
      Bottom := R.Bottom * ScaleY + ShiftY;
    end;
  end
  else
    Result := R;
end;

function TTicLayer.GetEdges: TArrayOfFloatPoint;
begin
  Result := FTransformation.Edges;
end;

function TTicLayer.GetSourceRect: TFloatRect;
begin
  Result := FTransformation.SrcRect;
end;

function TTicLayer.GetTic(index: Integer): TFloatPoint;
begin
  //Result.X  := FQuadX[index];
  //Result.Y  := FQuadY[index];
  Result := Edges[index];
end;


procedure TTicLayer.SetBounds(APosition, ASize: TFloatPoint);
begin
  SetBounds(FloatRect(APosition, FloatPoint(APosition.X+ ASize.X, APosition.Y+ ASize.Y) ));
end;

procedure TTicLayer.SetBounds(ABoundsRect: TFloatRect);
begin
  BeginUpdate;
  try
    with ABoundsRect do
    begin
      Tic[0] := TopLeft;
      Tic[1] := FloatPoint(Right, Top);
      Tic[2] := BottomRight;
      Tic[3] := FloatPoint(Left, Bottom);
    end;
  finally
    EndUpdate;
  end;
end;

procedure TTicLayer.SetCropped(const Value: Boolean);
begin
  if Value <> FCropped then
  begin
    FCropped := Value;
    Changed;
  end;
end;

procedure TTicLayer.SetEdges(const Value: TArrayOfFloatPoint);
begin
  if Edges <> Value then
  begin
    Changing;
    DoSetEdges(Value);
    //FTransformation.TransformValid := False;
    Changed;
  end;
end;

procedure TTicLayer.SetScaled(const Value: Boolean);
begin
  if Value <> FScaled then
  begin
    Changing;
    FScaled := Value;
    Changed;
  end;
end;


procedure TTicLayer.SetSourceRect(const Value: TFloatRect);
begin
  Changing;
  FTransformation.SrcRect := Value;
  Changed;
end;

procedure TTicLayer.SetTic(index: Integer; const Value: TFloatPoint);
begin
  Changing;
  //FQuadX[index] := Value.X;
  //FQuadY[index] := Value.Y;
  Edges[index] := Value;
  //FTransformation.TransformValid := False;
  Changed;
end;


{ TTicTransformation }

{constructor TTicTransformation.Create(AOwner: TTicLayer);
begin
  Assert(AOwner <> nil, 'Must be TTicLayer');
  inherited Create;
  FOwner := AOwner;
end;}

procedure TTicTransformation.AssignTo(Dest: TPersistent);
begin
  if Dest is TTicTransformation then
  begin
    TTicTransformation(Dest).SrcRect := Self.SrcRect;
    TTicTransformation(Dest).Edges := Self.Edges;
  end
  else
  inherited;

end;

constructor TTicTransformation.Create;
begin
  inherited;
  SetLength(FEdges,4);
end;

function TTicTransformation.GetMiddleEdges: TArrayOfFloatPoint;
var i, next : Integer;
begin
  SetLength(Result,4);
  
  for i := 0 to 3 do
  begin
    next := i + 1;
    if next > 3 then next := 0;
    
    Result[i].X := Min(FEdges[i].X, FEdges[next].X ) + Abs(FEdges[i].X - FEdges[next].X) /2;  
    Result[i].Y := Min(FEdges[i].Y, FEdges[next].Y ) + Abs(FEdges[i].Y - FEdges[next].Y) /2;  
  end;

end;

function TTicTransformation.GetTransformedBounds(const ASrcRect: TFloatRect): TFloatRect;
{var
  V1, V2, V3, V4: TVector3f;}
begin
{  V1[0] := ASrcRect.Left;  V1[1] := ASrcRect.Top;    V1[2] := 1;
  V2[0] := ASrcRect.Right; V2[1] := V1[1];           V2[2] := 1;
  V3[0] := V1[0];          V3[1] := ASrcRect.Bottom; V3[2] := 1;
  V4[0] := V2[0];          V4[1] := V3[1];           V4[2] := 1;
  V1 := VectorTransform(Matrix, V1);
  V2 := VectorTransform(Matrix, V2);
  V3 := VectorTransform(Matrix, V3);
  V4 := VectorTransform(Matrix, V4);
  Result.Left   := Min(Min(V1[0], V2[0]), Min(V3[0], V4[0]));
  Result.Right  := Max(Max(V1[0], V2[0]), Max(V3[0], V4[0]));
  Result.Top    := Min(Min(V1[1], V2[1]), Min(V3[1], V4[1]));
  Result.Bottom := Max(Max(V1[1], V2[1]), Max(V3[1], V4[1]));}
  //with FOwner do
  begin
    Result.Left   := Min(Min(FEdges[0].X, FEdges[1].X), Min(FEdges[2].X, FEdges[3].X));
    Result.Right  := Max(Max(FEdges[0].X, FEdges[1].X), Max(FEdges[2].X, FEdges[3].X));
    Result.Top    := Min(Min(FEdges[0].Y, FEdges[1].Y), Min(FEdges[2].Y, FEdges[3].Y));
    Result.Bottom := Max(Max(FEdges[0].Y, FEdges[1].Y), Max(FEdges[2].Y, FEdges[3].Y));
  end;
end;

procedure TTicTransformation.PrepareTransform;
var
  dx1, dx2, px, dy1, dy2, py: TFloat;
  g, h, k: TFloat;
  R: TFloatMatrix;
  LQuadX,LQuadY : array[0..3] of TFloat;
  i : Integer;
begin
  for i := 0 to 3 do
  with {FOwner.}FEdges[i] do
  begin
    LQuadX[i] := X;
    LQuadY[i] := Y;
  end;



  px  := LQuadX[0] - LQuadX[1] + LQuadX[2] - LQuadX[3];
  py  := LQuadY[0] - LQuadY[1] + LQuadY[2] - LQuadY[3];

  if (px = 0) and (py = 0) then
  begin
    // affine mapping
    FMatrix[0, 0] := LQuadX[1] - LQuadX[0];
    FMatrix[1, 0] := LQuadX[2] - LQuadX[1];
    FMatrix[2, 0] := LQuadX[0];

    FMatrix[0, 1] := LQuadY[1] - LQuadY[0];
    FMatrix[1, 1] := LQuadY[2] - LQuadY[1];
    FMatrix[2, 1] := LQuadY[0];

    FMatrix[0, 2] := 0;
    FMatrix[1, 2] := 0;
    FMatrix[2, 2] := 1;
  end
  else
  begin
    // projective mapping
    dx1 := LQuadX[1] - LQuadX[2];
    dx2 := LQuadX[3] - LQuadX[2];
    dy1 := LQuadY[1] - LQuadY[2];
    dy2 := LQuadY[3] - LQuadY[2];
    k := dx1 * dy2 - dx2 * dy1;
    if k <> 0 then
    begin
      k := 1 / k;
      g := (px * dy2 - py * dx2) * k;
      h := (dx1 * py - dy1 * px) * k;

      FMatrix[0, 0] := LQuadX[1] - LQuadX[0] + g * LQuadX[1];
      FMatrix[1, 0] := LQuadX[3] - LQuadX[0] + h * LQuadX[3];
      FMatrix[2, 0] := LQuadX[0];

      FMatrix[0, 1] := LQuadY[1] - LQuadY[0] + g * LQuadY[1];
      FMatrix[1, 1] := LQuadY[3] - LQuadY[0] + h * LQuadY[3];
      FMatrix[2, 1] := LQuadY[0];

      FMatrix[0, 2] := g;
      FMatrix[1, 2] := h;
      FMatrix[2, 2] := 1;
    end
    else
    begin
      FillChar(FMatrix, SizeOf(FMatrix), 0);
    end;
  end;

  // denormalize texture space (u, v)
  R := IdentityMatrix;
  R[0, 0] := 1 / (SrcRect.Right - SrcRect.Left);
  R[1, 1] := 1 / (SrcRect.Bottom - SrcRect.Top);
  FMatrix := Mult(FMatrix, R);

  R := IdentityMatrix;
  R[2, 0] := -SrcRect.Left;
  R[2, 1] := -SrcRect.Top;
  FMatrix := Mult(FMatrix, R);

  inherited;
end;


procedure TTicTransformation.ReverseTransformFixed(DstX, DstY: TFixed;
  out SrcX, SrcY: TFixed);
var
  Z: TFixed;
  Zf: TFloat;
begin
  Z := FixedMul(FInverseFixedMatrix[0, 2], DstX) +
    FixedMul(FInverseFixedMatrix[1, 2], DstY) + FInverseFixedMatrix[2, 2];

  if Z = 0 then Exit;

  {$IFDEF UseInlining}
  SrcX := FixedMul(DstX, FInverseFixedMatrix[0, 0]) +
    FixedMul(DstY, FInverseFixedMatrix[1, 0]) + FInverseFixedMatrix[2, 0];
  SrcY := FixedMul(DstX, FInverseFixedMatrix[0,1]) +
    FixedMul(DstY, FInverseFixedMatrix[1, 1]) + FInverseFixedMatrix[2, 1];
  {$ELSE}
  inherited;
  {$ENDIF}

  if Z <> FixedOne then
  begin
    EMMS;
    Zf := FixedOne / Z;
    SrcX := Round(SrcX * Zf);
    SrcY := Round(SrcY * Zf);
  end;
end;


procedure TTicTransformation.ReverseTransformFloat(
  DstX, DstY: TFloat;
  out SrcX, SrcY: TFloat);
var
  Z: TFloat;
begin
  EMMS;
  Z := FInverseMatrix[0, 2] * DstX + FInverseMatrix[1, 2] * DstY +
    FInverseMatrix[2, 2];

  if Z = 0 then Exit;

  {$IFDEF UseInlining}
  SrcX := DstX * FInverseMatrix[0, 0] + DstY * FInverseMatrix[1, 0] +
    FInverseMatrix[2, 0];
  SrcY := DstX * FInverseMatrix[0, 1] + DstY * FInverseMatrix[1, 1] +
    FInverseMatrix[2, 1];
  {$ELSE}
  inherited;
  {$ENDIF}

  if Z <> 1 then
  begin
    Z := 1 / Z;
    SrcX := SrcX * Z;
    SrcY := SrcY * Z;
  end;
end;


{procedure TTicTransformation.Scale(Sx, Sy: TFloat);
var
  M: TFloatMatrix;
begin
  M := IdentityMatrix;
  M[0, 0] := Sx;
  M[1, 1] := Sy;
  FMatrix := Mult(M, Matrix);

  //Changed;
  inherited PrepareTransform;
end;}

procedure TTicTransformation.SetEdges(const Value: TArrayOfFloatPoint);
begin
  FEdges := Value;
  TransformValid := False;
end;

procedure TTicTransformation.TransformFixed(SrcX, SrcY: TFixed;
  out DstX, DstY: TFixed);
var
  Z: TFixed;
  Zf: TFloat;
begin
  Z := FixedMul(FFixedMatrix[0, 2], SrcX) +
    FixedMul(FFixedMatrix[1, 2], SrcY) + FFixedMatrix[2, 2];

  if Z = 0 then Exit;

  {$IFDEF UseInlining}
  DstX := FixedMul(SrcX, FFixedMatrix[0, 0]) +
    FixedMul(SrcY, FFixedMatrix[1, 0]) + FFixedMatrix[2, 0];
  DstY := FixedMul(SrcX, FFixedMatrix[0, 1]) +
    FixedMul(SrcY, FFixedMatrix[1, 1]) + FFixedMatrix[2, 1];
  {$ELSE}
  inherited;
  {$ENDIF}

  if Z <> FixedOne then
  begin
    EMMS;
    Zf := FixedOne / Z;
    DstX := Round(DstX * Zf);
    DstY := Round(DstY * Zf);
  end;
end;


procedure TTicTransformation.TransformFloat(SrcX, SrcY: TFloat;
  out DstX, DstY: TFloat);
var
  Z: TFloat;
begin
  EMMS;
  Z := FMatrix[0, 2] * SrcX + FMatrix[1, 2] * SrcY + FMatrix[2, 2];

  if Z = 0 then Exit;

  {$IFDEF UseInlining}
  DstX := SrcX * Matrix[0, 0] + SrcY * Matrix[1, 0] + Matrix[2, 0];
  DstY := SrcX * Matrix[0, 1] + SrcY * Matrix[1, 1] + Matrix[2, 1];
  {$ELSE}
  inherited;
  {$ENDIF}

  if Z <> 1 then
  begin
    Z := 1 / Z;
    DstX := DstX * Z;
    DstY := DstY * Z;
  end;
end;



{ TTicBitmapLayer }

procedure TTicBitmapLayer.BitmapChanged(Sender: TObject);
begin
  SourceRect := FloatRect(0, 0, Bitmap.Width - 1, Bitmap.Height - 1);
end;

constructor TTicBitmapLayer.Create(ALayerCollection: TLayerCollection);
begin
  inherited;
  FBitmap := TBitmap32.Create;
  FBitmap.OnChange := BitmapChanged;
end;

destructor TTicBitmapLayer.Destroy;
begin
  FBitmap.Free;
  inherited;
end;


function TTicBitmapLayer.DoHitTest(X, Y: Integer): Boolean;

var
  B: TPoint;
begin
  B := FTransformation.ReverseTransform(Point(X, Y));

  Result := PtInRect(Rect(0, 0, Bitmap.Width, Bitmap.Height), B);
  if Result and {AlphaHit and} (Bitmap.PixelS[B.X, B.Y] and $FF000000 = 0) then
    Result := False;
end;


procedure TTicBitmapLayer.Paint(Buffer: TBitmap32);
var ImageRect : TRect;
  DstRect, ClipRect, TempRect: TRect;
  //LTransformer : TTicTransformation;
  ShiftX, ShiftY, ScaleX, ScaleY: Single;  
begin
 if Bitmap.Empty then Exit;

  //LEdges := GetScaledEdges;

  //Buffer.FrameRectS(MakeRect(EdgesToFloatRect(LEdges)), clBlueViolet32);

  //LTransformer := TTicTransformation.Create;
  //LTransformer.Assign(Self.FTransformation);

  // Scale to viewport if activated.
  FInViewPortTransformation.Edges := GetScaledEdges;
  FInViewPortTransformation.SrcRect := FTransformation.SrcRect;

  DstRect := MakeRect(FInViewPortTransformation.GetTransformedBounds);
  //DstRect := MakeRect(EdgesToFloatRect(LTransformer.Edges));
  ClipRect := Buffer.ClipRect;
  IntersectRect(ClipRect, ClipRect, DstRect);
  if IsRectEmpty(ClipRect) then Exit;
  
  if Cropped and (LayerCollection.Owner is TCustomImage32) and
    not (TImage32Access(LayerCollection.Owner).PaintToMode) then
  begin
    ImageRect := TCustomImage32(LayerCollection.Owner).GetBitmapRect;
    IntersectRect(ClipRect, ClipRect, ImageRect);
    if IsRectEmpty(ClipRect) then Exit;
  end;

  //Transform(Buffer, FBitmap, FTransformation,ClipRect);
  Transform(Buffer, FBitmap, FInViewPortTransformation,ClipRect);

  //Buffer.Draw(MakeRect(FloatRect(Tic[0],Tic[2])), Bitmap.BoundsRect, Bitmap);
  //Buffer.Draw(MakeRect(LTransformer.GetTransformedBounds), Bitmap.BoundsRect, Bitmap);
  
 (*
 if Bitmap.Empty then Exit;

  LTransformer := TTicTransformation.Create;
  LTransformer.Assign(Self.FTransformation);

    // Scale to viewport if activated.
  if FScaled and Assigned(LayerCollection) then
  begin
    LTransformer.PrepareTransform;
    
    LayerCollection.GetViewportScale(ScaleX, ScaleY);
    LTransformer.Scale(ScaleX, ScaleY);
    
    LayerCollection.GetViewportShift(ShiftX, ShiftY);
    LTransformer.Translate(ShiftX, ShiftY);
  end;

  DstRect := MakeRect(LTransformer.GetTransformedBounds);
  ClipRect := Buffer.ClipRect;
  IntersectRect(ClipRect, ClipRect, DstRect);
  if IsRectEmpty(ClipRect) then Exit;
  
  if Cropped and (LayerCollection.Owner is TCustomImage32) and
    not (TImage32Access(LayerCollection.Owner).PaintToMode) then
  begin
    ImageRect := TCustomImage32(LayerCollection.Owner).GetBitmapRect;
    IntersectRect(ClipRect, ClipRect, ImageRect);
    //IntersectRect(ClipRect, ClipRect, MakeRect(LTransformer.GetTransformedBounds) );
  end;

  //Transform(Buffer, FBitmap, FTransformation,ClipRect);
  Transform(Buffer, FBitmap, LTransformer,ClipRect);

  //Buffer.Draw(MakeRect(FloatRect(Tic[0],Tic[2])), Bitmap.BoundsRect, Bitmap);
  //Buffer.Draw(MakeRect(LTransformer.GetTransformedBounds), Bitmap.BoundsRect, Bitmap);
 *)

end;

procedure TTicBitmapLayer.SetBitmap(const Value: TBitmap32);
begin
  Changing;
  FBitmap.Assign(Value);
  Changed;
end;

{ TTicRubberBandLayer }

constructor TTicRubberBandLayer.Create(ALayerCollection: TLayerCollection);
begin
  inherited;
  FThreshold := 8;
  FHandleFrame := clBlack;
  FHandleFill := clWhite;
  FOptions := DefaultRubberbandOptions;
  FHandleSize := 3;  
end;

procedure TTicRubberBandLayer.DoSetEdges(const Value: TArrayOfFloatPoint);
begin
  inherited;
  if Assigned(FChildLayer) then
    FChildLayer.Edges := Value;
end;

function TTicRubberBandLayer.GetCursorDirection(
  State: TTicDragState): TCursorDirection;

const
  SheerDirections: array[0..3] of TCursorDirection = (
    cdNorth, cdEast, cdSouth, cdWest
  );
    
var
    LRadians, dx,dy,ScaleX, ScaleY : TFloat;
    LE,PairLE, Angle : Integer;
    LEdges : TArrayOfFloatPoint;
    CursorShift : TCursorDirection;
begin
    if State in  [tdsSheerN..tdsSheerW] then
    begin
      Result := SheerDirections[Ord(State) - 11];
      Exit;
    end;

    LEdges := FInViewPortTransformation.Edges;
    LE := MostLeftEdge(LEdges);
    PairLE := LE + 1;
    if PairLE > 3 then
      PairLE := 0;
    LRadians := ArcTan2(LEdges[PairLE].Y - LEdges[LE].Y,
                        LEdges[PairLE].X - LEdges[LE].X);
    Angle := Round(RadToDeg(LRadians));
    // assumed angle = [0..90]
    //Angle := 0;//DEBUG
    case Angle of
      //0..15   : Inc(LE, 0);
      16..75  : Inc(LE, 1);
      76..90  : Inc(LE, 2);
    end;

    CursorShift := TCursorDirection(LE);

    Result := cdNotUsed;

    case State of
      tdsResizeNW..tdsResizeW:
        begin
          Result := TCursorDirection(1+ Ord(State) + LE);
        end;
      tdsRotate:
        begin
          // Transform coordinates into local space.
(*
          with FTransformation do
          begin
            PivotX := Round(Matrix[0, 0] * FPivotPoint.X + Matrix[1, 0] * FPivotPoint.Y + Matrix[2, 0]);
            PivotY := Round(Matrix[0, 1] * FPivotPoint.X + Matrix[1, 1] * FPivotPoint.Y + Matrix[2, 1]);
          end;

          dX := Round(X - PivotX);
          dY := Round(Y - PivotY);
          if dX = 0 then
          begin
            if dY < 0 then
              Result := cdNorth
            else
              Result := cdSouth;
          end
          else
            if dY = 0 then
            begin
              if dX > 0 then
                Result := cdEast
              else
                Result := cdWest;
            end
            else
            begin
              // Everything within AxisTolerance from an axis is considered as would the axis have been hit.
              // Check the axes (with tolerance) first before checking all other possible directions.
              Angle := Round(RadToDeg(ArcTan2(dY, dX)));
              if (-180 <= Angle) and (Angle < -180 + AxisTolerance) then
                Result := cdWest
              else
                if (-90 - AxisTolerance <= Angle) and (Angle < -90 + AxisTolerance) then
                  Result := cdNorth
                else
                  if (-AxisTolerance <= Angle) and (Angle < AxisTolerance) then
                    Result := cdEast
                  else
                    if (90 - AxisTolerance <= Angle) and (Angle < 90 + AxisTolerance) then
                      Result := cdSouth
                    else
                      if (180 - AxisTolerance <= Angle) and (Angle < 180) then
                        Result := cdWest
                      else // No axis aligned direction, check the others.
                        if (-180 + AxisTolerance <= Angle) and (Angle < -90 - AxisTolerance) then
                          Result := cdNorthWest
                        else
                          if (-90 + AxisTolerance <= Angle) and (Angle < -AxisTolerance) then
                            Result := cdNorthEast
                          else
                            if (AxisTolerance <= Angle) and (Angle < 90 - AxisTolerance) then
                              Result := cdSouthEast
                            else
                              if (90 + AxisTolerance <= Angle) and (Angle < 180 - AxisTolerance) then
                                Result := cdSouthWest
                              else
                                Result := cdNotUsed;
            end;
            *)
        end;
    end;
end;

function TTicRubberBandLayer.GetHitCode(X, Y: Integer;
  Shift: TShiftState): TTicDragState;
// Determines the possible drag state, which the layer could enter.

{
    DIRECTION:            INDEX:

    NW    N   NE          0   4   1
    W         E           7       5
    SW    S   SE          3   6   2

}

    function IsXYNear(AnEdge: TFloatPoint): Boolean ;
    var a,b,c:double;
    begin
      Result := False;

      a:=abs(AnEdge.X - X);
      b:=abs(AnEdge.Y - Y);
      {c:=sqr(a)+sqr(b);
      if C >= 0 then
        Result :=  sqrt(c) <= FThreshold;}
      Result := Max(a,b) <= FThreshold;
    end;

    function GetNearestEdges(AnEdges : TArrayOfFloatPoint): Integer;
    var
      i :Integer;
    begin
      Result := -1;
      
      for i := 0 to Length(AnEdges)-1 do
      begin
        if IsXYNear(AnEdges[i]) then
        begin
          Result := i;
          Break;
        end;
      end;

      {if IsXYNear(LEdge[0]) then
        Result := rdsResizeNW
      else
      if IsXYNear(LEdge[1]) then
        Result := rdsResizeNE
      else
      if IsXYNear(LEdge[2]) then
        Result := rdsResizeSE
      else
      if IsXYNear(LEdge[3]) then
        Result := rdsResizeSW;}
    end;

var
  dX, dY: Single;
  Local: TPoint;
  LocalThresholdX,
  LocalThresholdY: Integer;
  NearTop,
  NearRight,
  NearBottom,
  NearLeft: Boolean;
  ScaleX, ScaleY: Single;
  OriginRect : TFloatRect;
  i : Integer;
  LEdge : TArrayOfFloatPoint;
  MatchEdge : Integer;
begin
  Result := tdsNone;

  // Transform coordinates into local space.
  //Local := FTransformation.ReverseTransform(Point(X, Y));
  Local := FInViewPortTransformation.ReverseTransform(Point(X, Y));

  LocalThresholdX := Abs(Round(FThreshold {/ FScaling.X}));
  LocalThresholdY := Abs(Round(FThreshold {/ FScaling.Y}));
  if FScaled and Assigned(LayerCollection) then
  begin
    LayerCollection.GetViewportScale(ScaleX, ScaleY);
    LocalThresholdX := Round(LocalThresholdX / ScaleX);
    LocalThresholdY := Round(LocalThresholdY / ScaleY);
  end;

  // Check rotation Pivot first.
  dX := Round(Local.X - FPivotPoint.X);
  if Abs(dX) < LocalThresholdX then
    dX := 0;
  dY := Round(Local.Y - FPivotPoint.Y);
  if Abs(dY) < LocalThresholdY then
    dY := 0;

  // Special case: rotation Pivot is hit.
  if (dX = 0) and (dY = 0) {and (rboAllowPivotMove in FOptions)} then
    Result := tdsMovePivot
  else
  begin
    OriginRect := FTransformation.SrcRect;
    InflateRect(OriginRect, LocalThresholdX, LocalThresholdY);
    // Check if the mouse is within the bounds.
    //if (Local.X >= -LocalThresholdX) and (Local.X <= FSize.cx + LocalThresholdX) and
    //   (Local.Y >= -LocalThresholdY) and (Local.Y <= FSize.cy + LocalThresholdY) then
    if PtInRect( OriginRect, Local ) then
    begin
      Result := tdsMoveLayer;

      LEdge := FInViewPortTransformation.Edges;

      {NearLeft := Local.X <= LocalThresholdX;
      NearRight := FSize.cx - Local.X <= LocalThresholdX;
      NearTop := Abs(Local.Y) <= LocalThresholdY;
      NearBottom := Abs(FSize.cy - Local.Y) <= LocalThresholdY;}

      {NearLeft  := Abs(LEdge[0].X - X) <= FThreshold;
      NearRight := Abs(LEdge[1].X - X) <= FThreshold;
      NearTop   := Abs(LEdge[1].X - X) <= FThreshold;
      NearBottom := Abs(FSize.cy - Local.Y) <= LocalThresholdY;}

      {if rboAllowCornerResize in FOptions then
      begin
        // Check borders.
        if NearTop then
        begin
          if NearRight then
            Result := rdsResizeNE
          else
            if NearLeft then
              Result := rdsResizeNW;
        end
        else
          if NearBottom then
          begin
            if NearRight then
              Result := rdsResizeSE
            else
              if NearLeft then
                Result := rdsResizeSW;
          end;
      end;}

      {if IsXYNear(LEdge[0]) then
        Result := rdsResizeNW
      else
      if IsXYNear(LEdge[1]) then
        Result := rdsResizeNE
      else
      if IsXYNear(LEdge[2]) then
        Result := rdsResizeSE
      else
      if IsXYNear(LEdge[3]) then
        Result := rdsResizeSW;}

      MatchEdge := GetNearestEdges(LEdge);
      if MatchEdge > -1 then
        Result := TTicDragState( Ord(tdsResizeNW)+ MatchEdge *2 );


      
      {if (Result = rdsMoveLayer) and (rboAllowEdgeResize in FOptions) then
      begin
        // Check for border if no corner hit.
        if NearTop then
          Result := rdsResizeN
        else
          if NearBottom then
            Result := rdsResizeS
          else
            if NearRight then
              Result := rdsResizeE
            else
              if NearLeft then
                Result := rdsResizeW;
      end;}
      if (Result = tdsMoveLayer) {and (rboAllowEdgeResize in FOptions)} then
      begin
        // Check for border if no corner hit.
        LEdge := FInViewPortTransformation.GetMiddleEdges;
        
        {if IsXYNear(LEdge[0]) then
          Result := rdsResizeN
        else
        if IsXYNear(LEdge[1]) then
          Result := rdsResizeE
        else
        if IsXYNear(LEdge[2]) then
          Result := rdsResizeS
        else
        if IsXYNear(LEdge[3]) then
          Result := rdsResizeW;}

        MatchEdge := GetNearestEdges(LEdge);
        if MatchEdge > -1 then
          //Result := TTicDragState(4 + MatchEdge);
          Result := TTicDragState( Ord(tdsResizeN)+ MatchEdge *2 );

      end;

      // If the user holds down the control key then sheering becomes active (only for edges).
      if ssCtrl in Shift then
      begin
        case Result of
          tdsResizeN:
            Result := tdsSheerN;
          tdsResizeE:
            Result := tdsSheerE;
          tdsResizeS:
            Result := tdsSheerS;
          tdsResizeW:
            Result := tdsSheerW;
        end;
      end;
    end
    else
    begin
      // Mouse is not within the bounds. So if rotating is allowed we can return the rotation state.
      {if rboAllowRotation in FOptions then
        Result := rdsRotate;}
    end;
  end;

end;

procedure TTicRubberBandLayer.MouseDown(Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if FIsDragging then Exit;
  FDragPos := Point(X, Y);
  FOldEdgest := Edges;
  FIsDragging := True;
  inherited;
end;




procedure TTicRubberBandLayer.MouseMove(Shift: TShiftState; X, Y: Integer);

const
  MoveCursor: array [TCursorDirection] of TCursor = (
    crDefault,
    crGrMovePointNWSE,  // cdNorthWest
    crGrMovePointNS,    // cdNorth
    crGrMovePointNESW,  // cdNorthEast
    crGrMovePointWE,    // cdEast
    crGrMovePointNWSE,  // cdSouthEast
    crGrMovePointNS,    // cdSouth
    crGrMovePointNESW,  // cdSouthWest
    crGrMovePointWE     // cdWest
  );

  RotateCursor: array [TCursorDirection] of TCursor = (
    crDefault,
    crGrRotateNW,       // cdNorthWest
    crGrRotateN,        // cdNorth
    crGrRotateNE,       // cdNorthEast
    crGrRotateE,        // cdEast
    crGrRotateSE,       // cdSouthEast
    crGrRotateS,        // cdSouth
    crGrRotateSW,       // cdSouthWest
    crGrRotateW         // cdWest
  );

  SheerCursor: array [TCursorDirection] of TCursor = (
    crDefault,
    crDefault,          // cdNorthWest
    crGrArrowMoveWE,    // cdNorth
    crDefault,          // cdNorthEast
    crGrArrowMoveNS,    // cdEast
    crDefault,          // cdSouthEast
    crGrArrowMoveWE,    // cdSouth
    crDefault,          // cdSouthWest
    crGrArrowMoveNS     // cdWest
  );


var
  dx,dy,ScaleX, ScaleY : TFloat;

begin
  


  if not FIsDragging then
  begin
    FDragState := GetHitCode(X, Y, Shift);
    case FDragState of
      tdsNone:
        Cursor := crDefault;
      tdsRotate:
        Cursor := RotateCursor[GetCursorDirection(FDragState)];
      tdsMoveLayer:
        Cursor := crGrArrow;
      tdsMovePivot:
        Cursor := crGrMoveCenter;
      tdsSheerN..tdsSheerW:
        Cursor := SheerCursor[GetCursorDirection(FDragState)];
    else
      Cursor := MoveCursor[GetCursorDirection(FDragState)];
    end;
  end
  else
  //if FIsDragging then
  begin
    dx := X - FDragPos.X;
    dy := Y - FDragPos.Y;
    if Scaled then
    begin
      LayerCollection.GetViewportScale(ScaleX, ScaleY);
      dx := dx / ScaleX;
      dy := dy / ScaleY;
    end;  
    Edges := MoveEdges(FOldEdgest, FloatPoint(dx,dy) );
  end;
  inherited;

end;

procedure TTicRubberBandLayer.MouseUp(Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if FIsDragging then
  begin
    FIsDragging := False;
  end;
  inherited;

end;

procedure TTicRubberBandLayer.Paint(Buffer: TBitmap32);

var
  //Contour: TContour;
  LEdges : TArrayOfFloatPoint;

  //--------------- local functions -------------------------------------------

  {procedure CalculateContour(X, Y, W, H: Single);

  // Constructs four vertex points from the given coordinates and sizes and
  // transforms them into a contour structure, which corresponds to the
  // current transformations.

  var
    R: TFloatRect;

  begin
    R.TopLeft := FloatPoint(X, Y);
    R.BottomRight := FloatPoint(X + W, Y + H);

    with FTransformation do
    begin
      // Upper left
      Contour[0].X := Fixed(Matrix[0, 0] * R.Left + Matrix[1, 0] * R.Top + Matrix[2, 0]);
      Contour[0].Y := Fixed(Matrix[0, 1] * R.Left + Matrix[1, 1] * R.Top + Matrix[2, 1]);

      // Upper right
      Contour[1].X := Fixed(Matrix[0, 0] * R.Right + Matrix[1, 0] * R.Top + Matrix[2, 0]);
      Contour[1].Y := Fixed(Matrix[0, 1] * R.Right + Matrix[1, 1] * R.Top + Matrix[2, 1]);

      // Lower right
      Contour[2].X := Fixed(Matrix[0, 0] * R.Right + Matrix[1, 0] * R.Bottom + Matrix[2, 0]);
      Contour[2].Y := Fixed(Matrix[0, 1] * R.Right + Matrix[1, 1] * R.Bottom + Matrix[2, 1]);

      // Lower left
      Contour[3].X := Fixed(Matrix[0, 0] * R.Left + Matrix[1, 0] * R.Bottom + Matrix[2, 0]);
      Contour[3].Y := Fixed(Matrix[0, 1] * R.Left + Matrix[1, 1] * R.Bottom + Matrix[2, 1]);
    end;
  end; }

  //---------------------------------------------------------------------------

  procedure DrawContour;

  begin
    with Buffer do
    begin
      MoveToF(LEdges[0].X, LEdges[0].Y);
      LineToFSP(LEdges[1].X, LEdges[1].Y);
      LineToFSP(LEdges[2].X, LEdges[2].Y);
      LineToFSP(LEdges[3].X, LEdges[3].Y);
      LineToFSP(LEdges[0].X, LEdges[0].Y);
    end;
  end;

  //---------------------------------------------------------------------------

  procedure DrawHandle(XY: TFloatPoint);

  // Special version for handle vertex calculation. Handles are fixed sized and not rotated.

  var
    R : TRect;
    P : TPoint;
  begin
    with Point(XY) do
      R := MakeRect(X,Y,X,Y);

    InflateRect(R, FHandleSize, FHandleSize);

    Buffer.FillRectS(R, FHandleFill);
    Buffer.FrameRectS(R, FHandleFrame);
  end;
  //---------------------------------------------------------------------------

  procedure DrawHandles(AEdges: TArrayOfFloatPoint);

  // Special version for handle vertex calculation. Handles are fixed sized and not rotated.

  var
    i : Integer;
  begin
    for i := 0 to 3 do
    begin
      DrawHandle(AEdges[i]);
    end;
  end;

  //---------------------------------------------------------------------------

  procedure DrawPivot(X, Y: Single);

  // Special version for the pivot image. Also this image is neither rotated nor scaled.

  var
    XNew, YNew, ShiftX, ShiftY: Single;

  begin

    with FTransformation do
    begin
      XNew := Matrix[0, 0] * X + Matrix[1, 0] * Y + Matrix[2, 0];
      YNew := Matrix[0, 1] * X + Matrix[1, 1] * Y + Matrix[2, 1];
    end;

{    if FScaled and Assigned(LayerCollection) then
    begin
      LayerCollection.GetViewportScale(XNew, YNew);
      LayerCollection.GetViewportShift(ShiftX, ShiftY);
      XNew := XNew * X + ShiftX;
      YNew := YNew * Y + ShiftY;
    end
    else
    begin
      XNew := X;
      YNew := Y;
    end;}

    DrawIconEx(Buffer.Handle, Round(XNew - 8), Round(YNew - 8), Screen.Cursors[crGrCircleCross], 0, 0, 0, 0, DI_NORMAL);
  end;

  
  //--------------- end local functions ---------------------------------------

var
  Cx, Cy: Single;
var
  i : Integer;
  LTransformer : TTicTransformation;
  ShiftX, ShiftY, ScaleX, ScaleY: Single;
  //LEdges : TArrayOfFloatPoint;
begin
  // Scale to viewport if activated.
  LEdges := GetScaledEdges;
  FInViewPortTransformation.Edges := LEdges;
  FInViewPortTransformation.SrcRect := FTransformation.SrcRect;


  //CalculateContour(0, 0, FSize.cx, FSize.cy);

  //if AlphaComponent(FOuterColor) > 0 then
    //FillOuter(Buffer, Rect(0, 0, Buffer.Width, Buffer.Height), Contour);

  if rboShowFrame in FOptions then
  begin
    Buffer.SetStipple([clWhite32, clWhite32, clBlack32, clBlack32]);
    Buffer.StippleCounter := 0;
    Buffer.StippleStep := 1;
    DrawContour;
  end;

  if rboShowHandles in FOptions then
  begin
    DrawHandles(LEdges);

    LEdges := FInViewPortTransformation.GetMiddleEdges;
    DrawHandles(LEdges);
  end;
  
  if rboAllowPivotMove in FOptions then
    DrawPivot(FPivotPoint.X, FPivotPoint.Y);


  {Buffer.PenColor := clYellow32;
    Buffer.MoveToF(LEdges[0].X, LEdges[0].Y );
    for i := 1 to 3 do
    begin
      //Buffer.LineToFS(LEdges[i].X, LEdges[i].Y );
    end;}
  //Buffer.FrameRectS(MakeRect(EdgesToFloatRect(LEdges)), clBlueViolet32);

  {
  LTransformer := TTicTransformation.Create;
  LTransformer.Assign(Self.FTransformation);

    // Scale to viewport if activated.
  if FScaled and Assigned(LayerCollection) then
  begin
    LTransformer.PrepareTransform;
    
    LayerCollection.GetViewportScale(ScaleX, ScaleY);
    LTransformer.Scale(ScaleX, ScaleY);
    
    LayerCollection.GetViewportShift(ShiftX, ShiftY);
    LTransformer.Translate(ShiftX, ShiftY);
  end;

  Buffer.PenColor := clBlack32;
  with LTransformer do
  begin

    Buffer.FrameRectS(MakeRect(GetTransformedBounds), clBlueViolet32);
  end;
  }
end;

procedure TTicRubberBandLayer.SetChildLayer(const Value: TTicLayer);
begin
  if Assigned(FChildLayer) then
    RemoveNotification(FChildLayer);
    
  FChildLayer := Value;
  if Assigned(Value) then
  begin
    //Location := Value.Location;
    //SetBounds(FloatRect(Value.Tic[0], Value.Tic[2]));
    FTransformation.Assign(Value.FTransformation);
    Scaled := Value.Scaled;
    AddNotification(FChildLayer);
  end;
end;

{procedure TTicTransformation.Translate(Dx, Dy: TFloat);
var
  M: TFloatMatrix;
begin
  M := IdentityMatrix;
  M[2, 0] := Dx;
  M[2, 1] := Dy;
  FMatrix := Mult(M, Matrix);

  //Changed;
  inherited PrepareTransform;
end;}

procedure TTicRubberBandLayer.SetHandleFill(const Value: TColor);
begin
  if FHandleFill <> Value then
  begin
    FHandleFill := Value;
    TLayerCollectionAccess(LayerCollection).GDIUpdate;
  end;
end;

procedure TTicRubberBandLayer.SetHandleFrame(const Value: TColor);
begin
  if FHandleFrame <> Value then
  begin
    FHandleFrame := Value;
    TLayerCollectionAccess(LayerCollection).GDIUpdate;
  end;
end;

procedure TTicRubberBandLayer.SetHandleSize(Value: Integer);
begin
  if Value < 1 then
    Value := 1;
  if FHandleSize <> Value then
  begin
    FHandleSize := Value;
    TLayerCollectionAccess(LayerCollection).GDIUpdate;
  end;
end;

procedure TTicRubberBandLayer.SetLayerOptions(Value: Cardinal);
begin
  Value := Value and not LOB_NO_UPDATE; // workaround for changed behaviour
  inherited SetLayerOptions(Value);
end;

procedure TTicRubberBandLayer.SetOptions(
  const Value: TExtRubberBandOptions);
begin
  if FOptions <> Value then
  begin
    Changing;
    FOptions := Value;
    Changed; // Layer collection.
    //DoChange;
  end;
end;

end.
