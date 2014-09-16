unit igGradient;
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
  igGrid,  igCore_rw;

type

  TigGradientStop = class(TCollectionItem)
  private
    FMidPoint: TFloat;
    function GetColor: TColor;
    procedure SetColor(const Value: TColor);
    function IsOffsetStored: Boolean;
    function GetByte: Byte;
    procedure SetByte(const Value: Byte);
    function GetPercent: Single;
    procedure SetPercent(const Value: Single);
    function GetColor32: TColor32;
    procedure SetColor32(const Value: TColor32);
    procedure SetOffset(const Value: TFloat);
    function IsMidPointStored: Boolean;
    procedure SetMidPoint(const Value: TFloat);
  protected
    FOffset: TFloat;
    FValue : Cardinal; //should be TColor
    procedure AssignTo(ADest: TPersistent); override;
  public
    constructor Create(ACollection: TCollection); override;
  published
    property AsByte : Byte read GetByte write SetByte stored False;
    property AsPercent : Single read GetPercent write SetPercent stored False;
    property AsColor32 : TColor32 read GetColor32 write SetColor32 stored False;
    property AsColor : TColor read GetColor write SetColor; //must be the last for correction in save
    property Offset: TFloat read FOffset write SetOffset stored IsOffsetStored; //expected range between 0.0 and 1.0
    property MidPoint: TFloat read FMidPoint write SetMidPoint stored IsMidPointStored; //expected range between 0.0 and 1.0
  end;


  TigGradientStopCollection = class(TOwnedCollection)
  private
    FOnChange: TNotifyEvent;
    function GetItem(Index: Integer): TigGradientStop;
    procedure SetItem(Index: Integer; const Value: TigGradientStop);
  protected
    procedure Update(Item: TCollectionItem); override;
  public
    constructor Create(AOwner : TPersistent);
    function Add: TigGradientStop;
    function First: TigGradientStop;
    function Last: TigGradientStop;

    property Items[Index: Integer]: TigGradientStop read GetItem write SetItem; default;
    property OnChange : TNotifyEvent read FOnChange write FOnChange;
  end;


  
  TigGradientItem = class(TigGridItem)
  private
    FRGBGradient: TigGradientStopCollection;
    FAlphaGradient: TigGradientStopCollection;
    FColorLUT: TColor32LookupTable;
    procedure StopGradientChanged(Sender : TObject);
    procedure SetAlphaGradient(const Value: TigGradientStopCollection);
    procedure SetRGBGradient(const Value: TigGradientStopCollection);

  protected
    //FSurfaceValid : Boolean;
    function GetEmpty: Boolean; override;
    procedure AssignTo(Dest: TPersistent); override;

  public
    constructor Create(Collection: TCollection); override;
    procedure FillColorLookUpTable(var ColorLUT: array of TColor32); overload;
    procedure FillColorLookUpTable(ColorLUT: PColor32Array; Count: Integer); overload;
    procedure FillColorLookUpTable(ColorLUT: TColor32LookupTable); overload;
    function ColorLUT: TColor32LookupTable; //included Fill with valid colors
    
    function CachedBitmap(const AWidth, AHeight: Integer): TBitmap32; override;
    function GetHint: string; override;
  published
    property RGBGradient : TigGradientStopCollection read FRGBGradient write SetRGBGradient;
    property AlphaGradient : TigGradientStopCollection read FAlphaGradient write SetAlphaGradient;
    property DisplayName;
  end;

  TigGradientList = class(TigGridList)
  private
    
    function GetItem(Index: Integer): TigGradientItem;
    procedure SetItem(Index: Integer; const Value: TigGradientItem);
  protected
    class function GetItemClass : TCollectionItemClass; override;
  public
    //constructor Create(AOwner:TComponent); override;
    function Add: TigGradientItem;
    class function GetFileReaders : TigFileFormatsList; override;
    class function GetFileWriters : TigFileFormatsList; override;

    procedure ItemPaint(ABuffer: TBitmap32; AIndex: Integer; ARect: TRect);  override; // called by grid needed by Theme

    property Items[Index: Integer]: TigGradientItem read GetItem write SetItem; default;

  end;

  {TigGradientCollection = class(TigGridCollection)
  public
    constructor Create(AOwner:TComponent); override;
  end;}

  TigGradientGrid = class(TigGrid)
  private
    function GetGradientList: TigGradientList;
    procedure SetGradientList(const Value: TigGradientList);
  published
    property GradientList : TigGradientList read GetGradientList write SetGradientList;  
  end;

procedure Register;
  
implementation

uses
  GR32_Blend, GR32_Polygons, GR32_VectorUtils,
  igCore_Items, //for registering class
  igPaintFuncs;

procedure Register;
begin
//  RegisterComponents('miniGlue', [TigGradientList, TigGradientGrid]);
end;

var
  UGradientReaders, UGradientWriters : TigFileFormatsList;

{ TigGradientItem }

constructor TigGradientItem.Create(Collection: TCollection);
begin
  inherited Create(Collection);
  FRGBGradient  := TigGradientStopCollection.Create(Self);
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

  FAlphaGradient:= TigGradientStopCollection.Create(Self);
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

function TigGradientItem.CachedBitmap(const AWidth, AHeight: Integer): TBitmap32;
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

      LEdge       := Round(Sqrt(AWidth * AHeight) * 0.05);
      InflateRect(R, -LEdge, -LEdge);
      LinearGradFiller.StartPoint := R.TopLeft;
      LinearGradFiller.EndPoint := R.BottomRight;
      //LinearGradFiller.WrapMode := TWrapMode(RgpWrapMode.ItemIndex);

      PolygonFS(FCachedBitmap, PolygonTop, LinearGradFiller);
      FCachedBitmap.SaveToFile('D:\v\GR32\miniglue\trunk\units\'+DisplayName+'.bmp');
      //PolyLineFS(ImgView32.Bitmap, PolygonTop, clBlack32, True, 1);
    finally
      LinearGradFiller.Free;
    end;
    FCachedBitmapValid := True;
  end;

  Result := FCachedBitmap;
end;

function TigGradientItem.GetHint: string;
var
  s : string;
begin
  s := '';

  if DisplayName <> '' then
    s := DisplayName + #13;
    
//  Result := Format('%sred: %d, green: %d, blue: %d',[s,RedComponent(Color),
//          GreenComponent(Color),BlueComponent(Color)]);
end;


function TigGradientItem.GetEmpty: Boolean;
begin
  Result := (RGBGradient.Count = 0) and (AlphaGradient.Count = 0);
end;

procedure TigGradientItem.AssignTo(Dest: TPersistent);
begin
  inherited;
  {
    Ancestor must call inherited, to get benefit of inheritance of "Assign()"
  }
  if Dest is TigGradientItem then
  begin
    with TigGradientItem(Dest) do
    begin
      RGBGradient   := self.RGBGradient;
      AlphaGradient := self.AlphaGradient;
    end;
  end;
end;

{ TigGradientCollection }


function TigGradientList.Add: TigGradientItem;
begin
  Result := TigGradientItem(inherited Add);
end;

class function TigGradientList.GetFileReaders: TigFileFormatsList;
begin
  if not Assigned(UGradientReaders) then
  begin
    UGradientReaders := TigFileFormatsList.Create;
  end;

  Result := UGradientReaders;
end;

class function TigGradientList.GetFileWriters: TigFileFormatsList;
begin
  if not Assigned(UGradientWriters) then
  begin
    UGradientWriters := TigFileFormatsList.Create;
  end;

  Result := UGradientWriters;
end;

function TigGradientList.GetItem(Index: Integer): TigGradientItem;
begin
  Result := TigGradientItem(inherited GetItem(Index));
end;

class function TigGradientList.GetItemClass: TCollectionItemClass;
begin
  result := TigGradientItem;
end;

procedure TigGradientList.ItemPaint(ABuffer: TBitmap32; AIndex: Integer;
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

procedure TigGradientList.SetItem(Index: Integer;
  const Value: TigGradientItem);
begin
  inherited SetItem(Index, Value);
end;

{ TigGradientCollection }

{constructor TigGradientCollection.Create(AOwner: TComponent);
begin
  inherited Create(AOwner,TigGradientItem);
end;}

procedure TigGradientItem.SetAlphaGradient(
  const Value: TigGradientStopCollection);
begin
  FAlphaGradient.Assign(Value);
end;

procedure TigGradientItem.SetRGBGradient(
  const Value: TigGradientStopCollection);
begin
  FRGBGradient.Assign(Value);
end;

procedure TigGradientItem.StopGradientChanged(Sender: TObject);
begin
  FCachedBitmapValid := False;
  Changed(False);
end;

function TigGradientItem.ColorLUT: TColor32LookupTable;
begin
  if not Assigned(FColorLUT) then
  begin
    FColorLUT:= TColor32LookupTable.Create;
  end;

  if not FCachedBitmapValid then
  begin
    FillColorLookUpTable(FColorLUT);
    FCachedBitmapValid := True;
  end;

  Result := FColorLUT;
end;

procedure TigGradientItem.FillColorLookUpTable(
  ColorLUT: TColor32LookupTable);
begin
  FillColorLookUpTable(ColorLUT.Color32Ptr, ColorLUT.Size);
end;

procedure TigGradientItem.FillColorLookUpTable(
  var ColorLUT: array of TColor32);
begin
{$WARNINGS OFF}
  FillColorLookUpTable(@ColorLUT[0], Length(ColorLUT));
{$WARNINGS ON}
end;

procedure TigGradientItem.FillColorLookUpTable(ColorLUT: PColor32Array;
  Count: Integer);
var
  LutIndex, StopIndex, GradCount: Integer;
  RecalculateScale: Boolean;
  Fraction, LocalFraction, Delta, Scale: TFloat;
begin
  GradCount := FRGBGradient.Count;

  //check trivial case
  if (GradCount < 2) or (Count < 2) then
  begin
    for LutIndex := 0 to Count - 1 do
      ColorLUT^[LutIndex] := 0; //it shouldn't happen since there was auto-create items
    Exit;
  end;

  // set first (start) and last (end) color
  ColorLUT^[0] := FRGBGradient.First.AsColor32;// StartColor;
  ColorLUT^[Count - 1] := FRGBGradient.Last.AsColor32; //EndColor;
  Delta := 1 / Count;
  Fraction := Delta;

  LutIndex := 1;
  while Fraction <= FRGBGradient[0].Offset do
  begin
    ColorLUT^[LutIndex] := ColorLUT^[0];
    Fraction := Fraction + Delta;
    Inc(LutIndex);
  end;

  Scale := 1;
  StopIndex := 1;
  RecalculateScale := True;
  for LutIndex := LutIndex to Count - 2 do
  begin
    // eventually search next stop
    while (Fraction > FRGBGradient[StopIndex].Offset) do
    begin
      Inc(StopIndex);
      if (StopIndex >= GradCount) then
        Break;
      RecalculateScale := True;
    end;

    // eventually fill remaining LUT
    if StopIndex = GradCount then
    begin
      for StopIndex := LutIndex to Count - 2 do
        ColorLUT^[StopIndex] := ColorLUT^[Count];
      Break;
    end;

    // eventually recalculate scale
    if RecalculateScale then
      Scale := 1 / (FRGBGradient[StopIndex].Offset -
        FRGBGradient[StopIndex - 1].Offset);

    // calculate current color
    LocalFraction := (Fraction - FRGBGradient[StopIndex - 1].Offset) * Scale;
    if LocalFraction <= 0 then
      ColorLUT^[LutIndex] := FRGBGradient[StopIndex - 1].AsColor32
    else if LocalFraction >= 1 then
      ColorLUT^[LutIndex] := FRGBGradient[StopIndex].AsColor32
    else
    begin
      ColorLUT^[LutIndex] := CombineReg(FRGBGradient[StopIndex].AsColor32,
        FRGBGradient[StopIndex - 1].AsColor32, Round($FF * LocalFraction));
      EMMS;
    end;
    Fraction := Fraction + Delta;
  end;
end;

{ TigGradientGrid }


function TigGradientGrid.GetGradientList: TigGradientList;
begin
  Result := ItemList as TigGradientList;
end;

procedure TigGradientGrid.SetGradientList(const Value: TigGradientList);
begin
  ItemList := Value;
end;

{ TigGradientStop }

procedure TigGradientStop.AssignTo(ADest: TPersistent);
begin
  if ADest is TigGradientStop then
  begin
    with TigGradientStop(ADest) do
    begin
      AsColor := Self.AsColor;
    end;
    Exit;
  end;

  inherited;
end;

constructor TigGradientStop.Create(ACollection: TCollection);
begin
  inherited;
  FMidPoint := 0.5;
  
  FOffset := 0.5;
end;

function TigGradientStop.GetByte: Byte;
begin
  Result := FValue and $FF;
end;

function TigGradientStop.GetColor: TColor;
begin
  Result := TColor(FValue); //boxing from unsigned into signed
end;

function TigGradientStop.GetColor32: TColor32;
begin
  result := Color32(AsColor)
end;

function TigGradientStop.GetPercent: Single;
begin
  Result := Self.AsByte / 2.55;
end;

function TigGradientStop.IsMidPointStored: Boolean;
begin
  Result := FMidPoint <> 0.5;
end;

function TigGradientStop.IsOffsetStored: Boolean;
begin
  Result := FOffset <> 0.5;
end;

procedure TigGradientStop.SetByte(const Value: Byte);
begin
  FValue := Value + Value shl 8 + Value shl 16 + Value shl 24;
  Changed(False);
end;

procedure TigGradientStop.SetColor(const Value: TColor);
begin
  FValue := Cardinal(Value); //boxing from signed into unsigned
  Changed(False);
end;

procedure TigGradientStop.SetColor32(const Value: TColor32);
begin
  FValue := WinColor(Value);
  Changed(False);
end;

procedure TigGradientStop.SetMidPoint(const Value: TFloat);
begin
  FMidPoint := Value;
  Changed(False);
end;

procedure TigGradientStop.SetOffset(const Value: TFloat);
begin
  FOffset := Value;
  Changed(False);
end;

procedure TigGradientStop.SetPercent(const Value: Single);
begin
  AsByte := Round(Value * 2.55);
  Changed(False);
end;

{ TigGradientStopCollection }

function TigGradientStopCollection.Add: TigGradientStop;
begin
  Result := TigGradientStop(inherited Add);
end;

constructor TigGradientStopCollection.Create(AOwner: TPersistent);
begin
  inherited Create(AOwner, TigGradientStop);
end;

function TigGradientStopCollection.First: TigGradientStop;
begin
  Result := nil;
  if Count > 0 then
    Result := Items[0];
end;

function TigGradientStopCollection.GetItem(
  Index: Integer): TigGradientStop;
begin
  Result := TigGradientStop(inherited GetItem(Index));
end;

function TigGradientStopCollection.Last: TigGradientStop;
begin
  Result := nil;
  if Count > 0 then
    Result := Items[Count-1];
end;

procedure TigGradientStopCollection.SetItem(Index: Integer;
  const Value: TigGradientStop);
begin
  inherited SetItem(Index, Value);
end;

procedure TigGradientStopCollection.Update(Item: TCollectionItem);
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

initialization
  RegisterCoreList(TigGradientList);
end.
