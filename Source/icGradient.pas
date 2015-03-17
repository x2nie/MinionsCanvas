unit icGradient;
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
 * Update Date: 
 *
 * The Initial Developer of this unit are
 *   x2nie  < x2nie[at]yahoo[dot]com >
 *
 * Contributor(s):
 *
 *
 * ***** END LICENSE BLOCK ***** *)

interface

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

uses
{ Standard }
  Types, Classes, SysUtils, Graphics,
{ Graphics32 }
  GR32, GR32_LowLevel, GR32_ColorGradients,
{ miniGlue }
  icGrid,  icCore_rw;

type

  TicGradientStop = class(TCollectionItem)
  private

    function GetColor: TColor;
    procedure SetColor(const Value: TColor);
    function IsOffsetStored: Boolean;
    function GetByte: Byte;
    procedure SetByte(const Value: Byte);
    function GetPercent: Single;
    procedure SetPercent(const Value: Single);
    function GetColor32: TColor32;
    procedure SetColor32(const Value: TColor32);
    procedure SetOffset(const Value: Double);
    function IsMidPointStored: Boolean;
    procedure SetMidPoint(const Value: TFloat);
  protected
    FOffset: Double;
    FMidPoint: TFloat;
    FValue : Cardinal; //should be TColor
    procedure AssignTo(ADest: TPersistent); override;
  public
    constructor Create(ACollection: TCollection); override;
  published
    property AsByte : Byte read GetByte write SetByte stored False;
    property AsPercent : Single read GetPercent write SetPercent stored False;
    property AsColor32 : TColor32 read GetColor32 write SetColor32 stored False;
    property AsCardinal: Cardinal read FValue;
    property AsColor : TColor read GetColor write SetColor; //must be the last for correction in save
    property Offset: Double read FOffset write SetOffset stored IsOffsetStored; //expected range between 0.0 and 1.0
    property MidPoint: TFloat read FMidPoint write SetMidPoint stored IsMidPointStored; //expected range between 0.0 and 1.0
  end;


  TicGradientStopCollection = class(TOwnedCollection)
  private
    FOnChange: TNotifyEvent;
    function GetItem(Index: Integer): TicGradientStop;
    procedure SetItem(Index: Integer; const Value: TicGradientStop);
  protected
    procedure Update(Item: TCollectionItem); override;
  public
    constructor Create(AOwner : TPersistent);
    function Add: TicGradientStop;
    function First: TicGradientStop;
    function Last: TicGradientStop;

    procedure FillColorLookUpTable(var ColorLUT: array of TColor32); overload;
    procedure FillColorLookUpTable(ColorLUT: PColor32Array; ACount: Integer); overload;
    procedure FillColorLookUpTable(ColorLUT: TColor32LookupTable); overload;
        
    property Items[Index: Integer]: TicGradientStop read GetItem write SetItem; default;
    property OnChange : TNotifyEvent read FOnChange write FOnChange;
  end;


  
  TicGradientItem = class(TicGridItem)
  private
    FRGBGradient: TicGradientStopCollection;
    FAlphaGradient: TicGradientStopCollection;
    FColorLUT: TColor32LookupTable;
    FColorSpace: string;
    procedure StopGradientChanged(Sender : TObject);
    procedure SetAlphaGradient(const Value: TicGradientStopCollection);
    procedure SetRGBGradient(const Value: TicGradientStopCollection);

  protected
    //FSurfaceValid : Boolean;
    function GetEmpty: Boolean; override;
    procedure AssignTo(Dest: TPersistent); override;

  public
    constructor Create(Collection: TCollection); override;
    procedure FillColorLookUpTable(var ColorLUT: array of TColor32); overload;
    procedure FillColorLookUpTable(ColorLUT: PColor32Array; ACount: Integer); overload;
    procedure FillColorLookUpTable(ColorLUT: TColor32LookupTable); overload;
    function ColorLUT: TColor32LookupTable; //included Fill with valid colors
    
    function CachedBitmap(const AWidth, AHeight: Integer): TBitmap32; override;
    function GetHint: string; override;
  published
    property RGBGradient : TicGradientStopCollection read FRGBGradient write SetRGBGradient;
    property AlphaGradient : TicGradientStopCollection read FAlphaGradient write SetAlphaGradient;
    property DisplayName;
    property ColorSpace : string read FColorSpace write FColorSpace;
  end;

  TicGradientList = class(TicGridList)
  private
    
    function GetItem(Index: Integer): TicGradientItem;
    procedure SetItem(Index: Integer; const Value: TicGradientItem);
  protected
    class function GetItemClass : TCollectionItemClass; override;
  public
    //constructor Create(AOwner:TComponent); override;
    function Add: TicGradientItem; reintroduce;
    class function GetFileReaders : TicFileFormatsList; override;
    class function GetFileWriters : TicFileFormatsList; override;

    procedure ItemPaint(ABuffer: TBitmap32; AIndex: Integer; ARect: TRect);  override; // called by grid needed by Theme

    property Items[Index: Integer]: TicGradientItem read GetItem write SetItem; default;

  end;

  {TicGradientCollection = class(TicGridCollection)
  public
    constructor Create(AOwner:TComponent); override;
  end;}

  TicGradientGrid = class(TicGrid)
  private
    function GetGradientList: TicGradientList;
    procedure SetGradientList(const Value: TicGradientList);
  published
    property GradientList : TicGradientList read GetGradientList write SetGradientList;  
  end;

procedure Register;
  
implementation

uses
  GR32_Blend, GR32_Polygons, GR32_VectorUtils,
  icCore_Items, //for registering class
  icPaintFuncs;

procedure Register;
begin
//  RegisterComponents('miniGlue', [TicGradientList, TicGradientGrid]);
end;

var
  UGradientReaders, UGradientWriters : TicFileFormatsList;

{ TicGradientItem }

constructor TicGradientItem.Create(Collection: TCollection);
begin
  inherited Create(Collection);
  FRGBGradient  := TicGradientStopCollection.Create(Self);
  FRGBGradient.OnChange := StopGradientChanged;
  with FRGBGradient.Add do
  begin
    AsColor := clDefault;
    Offset  := 0;
  end;
  with FRGBGradient.Add do
  begin
    AsColor := clBackground;
    Offset  := 1;
  end;

  FAlphaGradient:= TicGradientStopCollection.Create(Self);
  FAlphaGradient.OnChange := StopGradientChanged;
  with FAlphaGradient.Add do
  begin
    AsByte := $FF;
    Offset := 0;
  end;
  with FAlphaGradient.Add do
  begin
    AsByte := $FF;
    Offset := 1;
  end;
end;

function TicGradientItem.CachedBitmap(const AWidth, AHeight: Integer): TBitmap32;
var
  LinearGradFiller: TCustomLinearGradientPolygonFiller;
  PolygonTop: TArrayOfFloatPoint;
  R : TFloatRect;
  LEdge : Integer;
begin
  if not Assigned(FCachedBitmap) then
  begin
    FCachedBitmap := TBitmap32.Create;
    FCachedBitmap.DrawMode := dmBlend;
  end;

  if (not FCachedBitmapValid) or
     (FCachedBitmap.Width <> AWidth) or
     (FCachedBitmap.Height <> AHeight)
  then
  begin
    FCachedBitmap.SetSize(AWidth, AHeight);
    LinearGradFiller := TLinearGradientPolygonFiller.Create(ColorLUT);
    try
      //R := FloatRect(ADestPoint.X, ADestPoint.Y, ADestPoint.X + AWidth, ADestPoint.Y + AHeight )
      R := FloatRect(0,0, AWidth-1, AHeight-1 );
      PolygonTop := Rectangle(R);

      LEdge       := Round(Sqrt(AWidth * AHeight) * 0.2);
      InflateRect(R, -LEdge, -LEdge);
      LinearGradFiller.StartPoint := R.TopLeft;
      LinearGradFiller.EndPoint := R.BottomRight;
      LinearGradFiller.WrapMode := wmClamp;

      PolygonFS(FCachedBitmap, PolygonTop, LinearGradFiller);
      //FCachedBitmap.SaveToFile('D:\v\GR32\miniglue\trunk\units\'+DisplayName+'.bmp');
      //PolyLineFS(ImgView32.Bitmap, PolygonTop, clBlack32, True, 1);
    finally
      LinearGradFiller.Free;
    end;
    FCachedBitmapValid := True;
  end;

  Result := FCachedBitmap;
end;

function TicGradientItem.GetHint: string;
var
  s : string;
begin
  s := '';

  if DisplayName <> '' then
    s := DisplayName + #13;
    
//  Result := Format('%sred: %d, green: %d, blue: %d',[s,RedComponent(Color),
//          GreenComponent(Color),BlueComponent(Color)]);
end;


function TicGradientItem.GetEmpty: Boolean;
begin
  Result := (RGBGradient.Count = 0) and (AlphaGradient.Count = 0);
end;

procedure TicGradientItem.AssignTo(Dest: TPersistent);
begin
  inherited;
  {
    Ancestor must call inherited, to get benefit of inheritance of "Assign()"
  }
  if Dest is TicGradientItem then
  begin
    with TicGradientItem(Dest) do
    begin
      RGBGradient   := self.RGBGradient;
      AlphaGradient := self.AlphaGradient;
    end;
  end;
end;

{ TicGradientCollection }


function TicGradientList.Add: TicGradientItem;
begin
  Result := TicGradientItem(inherited Add);
end;

class function TicGradientList.GetFileReaders: TicFileFormatsList;
begin
  if not Assigned(UGradientReaders) then
  begin
    UGradientReaders := TicFileFormatsList.Create;
  end;

  Result := UGradientReaders;
end;

class function TicGradientList.GetFileWriters: TicFileFormatsList;
begin
  if not Assigned(UGradientWriters) then
  begin
    UGradientWriters := TicFileFormatsList.Create;
  end;

  Result := UGradientWriters;
end;

function TicGradientList.GetItem(Index: Integer): TicGradientItem;
begin
  Result := TicGradientItem(inherited GetItem(Index));
end;

class function TicGradientList.GetItemClass: TCollectionItemClass;
begin
  result := TicGradientItem;
end;

procedure TicGradientList.ItemPaint(ABuffer: TBitmap32; AIndex: Integer;
  ARect: TRect);
var
  LBmp : TBitmap32;
begin
  if IsValidIndex(AIndex) then
  begin
    DrawCheckerboardPattern(ABuffer, ARect, True );
    
    if Items[AIndex].FRGBGradient.Count > 0 then
    begin
      //let the item prepare her face if necessary, otherwise she will return the cache
      LBmp := Items[AIndex].CachedBitmap(ARect.Right- ARect.Left, ARect.Bottom- ARect.Top);
      ABuffer.Draw(ARect, LBmp.BoundsRect, LBmp  );
    end;
    ABuffer.FrameRectS(ARect, clTrGray32 );
  end;
end;

procedure TicGradientList.SetItem(Index: Integer;
  const Value: TicGradientItem);
begin
  inherited SetItem(Index, Value);
end;

{ TicGradientCollection }

{constructor TicGradientCollection.Create(AOwner: TComponent);
begin
  inherited Create(AOwner,TicGradientItem);
end;}

procedure TicGradientItem.SetAlphaGradient(
  const Value: TicGradientStopCollection);
begin
  FAlphaGradient.Assign(Value);
end;

procedure TicGradientItem.SetRGBGradient(
  const Value: TicGradientStopCollection);
begin
  FRGBGradient.Assign(Value);
end;

procedure TicGradientItem.StopGradientChanged(Sender: TObject);
begin
  FCachedBitmapValid := False;
  Changed(False);
end;

function TicGradientItem.ColorLUT: TColor32LookupTable;
begin
  if not Assigned(FColorLUT) then
  begin
    FColorLUT:= TColor32LookupTable.Create;
  end;

  if not FCachedBitmapValid then
  begin
    //TODO: update the ordery if required
    FillColorLookUpTable(FColorLUT);
    FCachedBitmapValid := True;
  end;

  Result := FColorLUT;
end;

procedure TicGradientItem.FillColorLookUpTable(
  ColorLUT: TColor32LookupTable);
begin
  FillColorLookUpTable(ColorLUT.Color32Ptr, ColorLUT.Size);
end;

procedure TicGradientItem.FillColorLookUpTable(
  var ColorLUT: array of TColor32);
begin
{$WARNINGS OFF}
  FillColorLookUpTable(@ColorLUT[0], Length(ColorLUT));
{$WARNINGS ON}
end;

procedure TicGradientItem.FillColorLookUpTable(ColorLUT: PColor32Array;
  ACount: Integer);
var
  //LRGB,
  LAlpha : TColor32LookupTable;
  AlphaLUT: PColor32Array;
  i,L : Integer;
begin
  L := 4;
  while (1 shl L) < ACount do
    Inc(L);
  LAlpha := TColor32LookupTable.Create(L);
  
  try
    FRGBGradient.FillColorLookUpTable(ColorLUT,ACount);
    FAlphaGradient.FillColorLookUpTable(LAlpha);

    for i := 0 to ACount-1 do
    begin
      //ColorLUT^[i] :=  (ColorLUT^[i] and $00FFFFFF) or ((LAlpha.Color32[i] and $FF) shl 24);
      TColor32Entry(ColorLUT^[i]).A := LAlpha.Color32[i] and $FF;
    end;
  finally
    LAlpha.Free;
  end;
end;

{ TicGradientGrid }


function TicGradientGrid.GetGradientList: TicGradientList;
begin
  Result := ItemList as TicGradientList;
end;

procedure TicGradientGrid.SetGradientList(const Value: TicGradientList);
begin
  ItemList := Value;
end;

{ TicGradientStop }

procedure TicGradientStop.AssignTo(ADest: TPersistent);
begin
  if ADest is TicGradientStop then
  begin
    with TicGradientStop(ADest) do
    begin
      AsColor := Self.AsColor;
      Offset  := Self.Offset;
      MidPoint:= Self.MidPoint;
    end;
    Exit;
  end;

  inherited;
end;

constructor TicGradientStop.Create(ACollection: TCollection);
begin
  inherited;
  FMidPoint := 0.5;
  
  FOffset := 0;
end;

function TicGradientStop.GetByte: Byte;
begin
  Result := FValue and $FF;
end;

function TicGradientStop.GetColor: TColor;
begin
  Result := TColor(FValue); //boxing from unsigned into signed
end;

function TicGradientStop.GetColor32: TColor32;
begin
  result := Color32(AsColor);
  {Result := FValue;
  case AsColor of  clDefault,clNone,clBackground:
    result := Color32(AsColor);
  end;}
end;

function TicGradientStop.GetPercent: Single;
begin
  Result := Self.AsByte / 2.55;
end;

function TicGradientStop.IsMidPointStored: Boolean;
begin
  Result := FMidPoint <> 0.5;
end;

function TicGradientStop.IsOffsetStored: Boolean;
begin
  Result := FOffset <> 0;
end;

procedure TicGradientStop.SetByte(const Value: Byte);
begin
  FValue := Value or Value shl 8 or Value shl 16;// or Value shl 24;
  Changed(False);
end;

procedure TicGradientStop.SetColor(const Value: TColor);
begin
  FValue := Cardinal(Value); //boxing from signed into unsigned
  Changed(False);
end;

procedure TicGradientStop.SetColor32(const Value: TColor32);
begin
  FValue := WinColor(Value);
  Changed(False);
end;

procedure TicGradientStop.SetMidPoint(const Value: TFloat);
begin
  FMidPoint := Value;
  Changed(False);
end;

procedure TicGradientStop.SetOffset(const Value: Double);
begin
  FOffset := Value;
  Changed(False);
end;

procedure TicGradientStop.SetPercent(const Value: Single);
begin
  AsByte := Round(Value * 2.55);
  Changed(False);
end;

{ TicGradientStopCollection }

function TicGradientStopCollection.Add: TicGradientStop;
begin
  Result := TicGradientStop(inherited Add);
end;

constructor TicGradientStopCollection.Create(AOwner: TPersistent);
begin
  inherited Create(AOwner, TicGradientStop);
end;

procedure TicGradientStopCollection.FillColorLookUpTable(
  var ColorLUT: array of TColor32);
begin
{$WARNINGS OFF}
  FillColorLookUpTable(@ColorLUT[0], Length(ColorLUT));
{$WARNINGS ON}
end;

procedure TicGradientStopCollection.FillColorLookUpTable(
  ColorLUT: PColor32Array; ACount: Integer);
var
  LutIndex, StopIndex, GradCount: Integer;
  RecalculateScale: Boolean;
  Fraction, LocalFraction, Delta, Scale: TFloat;
begin
  GradCount := Self.Count;

  //check trivial case
  if (GradCount < 2) or (ACount < 2) then
  begin
    for LutIndex := 0 to ACount - 1 do
      ColorLUT^[LutIndex] := 0; //it shouldn't happen since there was auto-create items
    Exit;
  end;

  // set first (start) and last (end) color
  ColorLUT^[0] := First.AsColor32;// StartColor;
  ColorLUT^[ACount - 1] := Last.AsColor32; //EndColor;
  Delta := 1 / ACount;
  Fraction := Delta;

  LutIndex := 1;
  while Fraction <= Items[0].Offset do
  begin
    ColorLUT^[LutIndex] := ColorLUT^[0];
    Fraction := Fraction + Delta;
    Inc(LutIndex);
  end;

  Scale := 1;
  StopIndex := 1;
  RecalculateScale := True;
  for LutIndex := LutIndex to ACount - 2 do
  begin
    // eventually search next stop
    while (Fraction > Items[StopIndex].Offset) do
    begin
      Inc(StopIndex);
      if (StopIndex >= GradCount) then
        Break;
      RecalculateScale := True;
    end;

    // eventually fill remaining LUT
    if StopIndex = GradCount then
    begin
      for StopIndex := LutIndex to ACount - 2 do
        ColorLUT^[StopIndex] := ColorLUT^[ACount-1];
      Break;
    end;

    // eventually recalculate scale
    if RecalculateScale then
      Scale := 1 / (Items[StopIndex].Offset -
        Items[StopIndex - 1].Offset);

    // calculate current color
    LocalFraction := (Fraction - Items[StopIndex - 1].Offset) * Scale;
    if LocalFraction <= 0 then
      ColorLUT^[LutIndex] := Items[StopIndex - 1].AsColor32
    else if LocalFraction >= 1 then
      ColorLUT^[LutIndex] := Items[StopIndex].AsColor32
    else
    begin
      ColorLUT^[LutIndex] := CombineReg(Items[StopIndex].AsColor32,
        Items[StopIndex - 1].AsColor32, Round($FF * LocalFraction));
      EMMS;
    end;
    Fraction := Fraction + Delta;
  end;

end;

procedure TicGradientStopCollection.FillColorLookUpTable(
  ColorLUT: TColor32LookupTable);
begin
  FillColorLookUpTable(ColorLUT.Color32Ptr, ColorLUT.Size);
end;

function TicGradientStopCollection.First: TicGradientStop;
begin
  Result := nil;
  if Count > 0 then
    Result := Items[0];
end;

function TicGradientStopCollection.GetItem(
  Index: Integer): TicGradientStop;
begin
  Result := TicGradientStop(inherited GetItem(Index));
end;

function TicGradientStopCollection.Last: TicGradientStop;
begin
  Result := nil;
  if Count > 0 then
    Result := Items[Count-1];
end;

procedure TicGradientStopCollection.SetItem(Index: Integer;
  const Value: TicGradientStop);
begin
  inherited SetItem(Index, Value);
end;

procedure TicGradientStopCollection.Update(Item: TCollectionItem);
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

initialization
  RegisterCoreList(TicGradientList);
end.
