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
 *
 * Ma Xiaoguang and Ma Xiaoming < gmbros@hotmail.com >
 * x2nie - Fathony Luthfillah  <x2nie@yahoo.com>
 *
 * Contributor(s):
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
  GR32, GR32_LowLevel,
{ miniGlue }
  igCore_Items, igGrid,  igCore_rw;

//-- .grd files ----------------------------------------------------------------

const
  GRADIENT_FILE_ID      = $474D4347; // i.e. GMCG - GraphicsMagic Color Gradient
  GRADIENT_FILE_VERSION = 1;         // the file version we could process so far

type
  TigGradientItem = class; // far definition
  TigGradientStopCollection = class; // far def

  { TigGradientStopItem }

  TigGradientStopItem = class(TCollectionItem)
  private
    FValue        : TColor;
    FLocationScale: Double;
    FMidPoint     : Double;
    FOnlyAlphaUsed: Boolean;
    FSavedColor   : TColor;
    
    procedure SetLocationScale(const AValue: Double);
    procedure SetMidPoint(const AValue: Double);
    procedure SetValue(const AValue: TColor);
    procedure SetOnlyAlphaUsed(const AValue: Boolean);

    function GetNextLocationScale: Double;
    function GetCollection: TigGradientStopCollection;
    function GetOnlyAlphaUsed: Boolean;
    function GetValidValue: TColor;
    function GetNextColor32: TColor32;
    function GetByteValue: Byte;
    function IfMidPointNotIsHalf: Boolean;

  protected
    procedure AssignTo(ADest: TPersistent); override;
    
  public
    constructor Create(ACollection: TCollection); override;

    function MidPointLocation: Integer;

    property Collection       : TigGradientStopCollection read GetCollection;
    property NextLocationScale: Double                    read GetNextLocationScale;
    property EndColor         : TColor32                  read GetNextColor32;
    property OnlyAlphaUsed    : Boolean                   read GetOnlyAlphaUsed write SetOnlyAlphaUsed;
    property ValidValue       : TColor                    read GetValidValue; // Mature Color, such as clDefault >>out=clBlack
    property ByteValue        : Byte                      read GetByteValue;  // only used by Alpha, RGB should not use it.
    property SavedColor       : TColor                    read FSavedColor write FSavedColor; // temporary save, used for tristate between clDefault,clBackground
  published
    property Value        : TColor read FValue         write SetValue; // moveto TColor, safety for special value, as clDefault, clBackground
    property LocationScale: Double read FLocationScale write SetLocationScale;
    property MidPoint     : Double read FMidPoint      write SetMidPoint stored IfMidPointNotIsHalf;
  end;

  { TigGradientStopCollection }
  
  TigGradientStopCollection = class(TOwnedCollection)
  private
    FOnChange        : TNotifyEvent;
    FOnlyAlphaUsed   : Boolean;
    FOutputColorArray: TArrayOfColor32;

    procedure SetItem(AIndex: Integer; const AValue: TigGradientStopItem);

    function GetItem(Index: Integer): TigGradientStopItem;
    function GetOutputColorArray: TArrayOfColor32;

  protected
    procedure Update(AItem: TCollectionItem); override;
    function  GradientLength: Integer;

    property OutputColors: TArrayOfColor32 read GetOutputColorArray;
  public
    constructor Create(AOwner: TigGradientItem);
    destructor Destroy; override;

    procedure Sort;
    procedure Delete(const AIndex: Integer);
    procedure DistributeAverage;

    function Owner: TigGradientItem;
    function Add: TigGradientStopItem;

    function Insert(const AIndex: Integer): TigGradientStopItem; overload;
    function Insert(ALocationScale: Double; AValue: TColor): Integer; overload;
    function Insert32(ALocationScale: Double; AValue: TColor32): Integer;
    function ChangeLocationScale(const AColorIndex: Integer; const AScale: Double): Integer;

    property OnlyAlphaUsed        : Boolean             read FOnlyAlphaUsed write FOnlyAlphaUsed;
    property OnChange             : TNotifyEvent        read FOnChange      write FOnChange;
    property Items[Index: Integer]: TigGradientStopItem read GetItem        write SetItem; default;

  published
  end;

  { TigGradientItem }

  // A TigGradientItem contains two TigGradientStopCollection, one for RGB
  // gradients and the another for Alpha gradients.
  //
  // Note that, an instance of TigGradientStopCollection contains several
  // objects that type of TigGradientStopItem. Each TigGradientStopItem object
  // stores Value as TColor, not TColor32, because sometimes we actually need
  // special TColor, as Photoshop done. Such as clDefault = Foreground Color ;
  // and clBackground = Background Color .
  TigGradientItem = class(TigGridItem)
  private
    FAlphaGradient   : TigGradientStopCollection;
    FRGBGradient     : TigGradientStopCollection;
    FOutputColorArray: TArrayOfColor32;
    FGradientLength  : Integer;
    FBackgroundColor : TColor;
    FForegroundColor : TColor;
    FColorSpace      : string;
    FTag             : Integer;
    FOnChange        : TNotifyEvent;
    FCachedBitmap    : TBitmap32;

    procedure SetGradientLength(const ALength: Integer);
    procedure SetAlphaGradient(const AValue: TigGradientStopCollection);
    procedure SetRGBGradient(const AValue: TigGradientStopCollection);

    function GetAbsolutEndColor: TColor32;
    function GetAbsolutStartColor: TColor32;
    function GetBackgroundColor: TColor;
    function GetForegroundColor: TColor;
    function IsGroundcolorStored: Boolean;

  protected
    FSpectrumValid : Boolean;

    procedure AssignTo(ADest: TPersistent); override;
    function GetEmpty: Boolean; override;
    
    procedure SpectrumChanged(ASender: TObject);
  public
    constructor Create(ACollection: TCollection); override;
    destructor Destroy; override;

    procedure Clear; dynamic;
    function IsEmpty: Boolean; dynamic;

    procedure RefreshColorArray;
    procedure DrawColorGradients(const ABmp: TBitmap32; const AReversed: Boolean = False);

    // high speed drawing: use cachedBitmap, validate chachedBitmap if not yet valid
    procedure DrawCachedBitmap(const AWidth, AHeight: Integer;
      const ADestBmp: TBitmap32; const ADestPoint:TPoint);
      
    function CachedBitmap(const AWidth, AHeight: Integer): TBitmap32; override;
    
    function IsSpecialColorUsed: Boolean;

    property ColorSpace        : string           read FColorSpace     write FColorSpace; // in case other than "RGBC"
    property AbsolutStartColor : TColor32         read GetAbsolutStartColor;
    property AbsolutEndColor   : TColor32         read GetAbsolutEndColor;
    property OutputColors      : TArrayOfColor32  read FOutputColorArray;
    property Tag               : Integer          read FTag            write FTag; // multipurpos temporary property.
    property GradientLength    : Integer          read FGradientLength write SetGradientLength;

    // may overided by collection
    property ForegroundColor   : TColor           read GetForegroundColor write FForegroundColor stored IsGroundcolorStored;
    property BackgroundColor   : TColor           read GetBackgroundColor write FBackgroundColor stored IsGroundcolorStored;
  published
    property DisplayName;
    property AlphaGradient : TigGradientStopCollection read FAlphaGradient   write SetAlphaGradient;
    property RGBGradient   : TigGradientStopCollection read FRGBGradient     write SetRGBGradient;
    property OnChange      : TNotifyEvent              read FOnChange write FOnChange; // used by gradient editor
  end;

  { TigGradientCollection }

  {TigGradientCollection = class(TigGridCollection)
  private
    FStreamVersion  : Double;
    FForegroundColor: TColor;
    FBackgroundColor: TColor;

    function GetItem(Index: Integer): TigGradientItem;

    procedure SetItem(AIndex: Integer; const AValue: TigGradientItem);
    procedure SetForegroundColor(const AColor: TColor);
    procedure SetBackgroundColor(const AColor: TColor);

  protected
    //procedure Changed;reintroduce;
    //procedure Update(Item: TCollectionItem); override;
  public
    constructor Create(AOwner:TComponent); override;

    procedure Assign(ASource: TPersistent); override;

    function IsValidIndex(const AIndex: Integer):Boolean;
    function Add: TigGradientItem;
    
    function Draw(const AGradientIndex: Integer;
      const ACanvas: TCanvas; const ARect: TRect): Boolean;

    property Items[Index: Integer]: TigGradientItem read GetItem          write SetItem; default;
    property StreamVersion        : Double          read FStreamVersion   write FStreamVersion;
    property ForegroundColor      : TColor          read FForegroundColor write SetForegroundColor;
    property BackgroundColor      : TColor          read FBackgroundColor write SetBackgroundColor;

  published
  end;}

  TigGradientIndex = type TigCoreIndex; //used for display gradient in property editor
  //TigGradientItem = class;

  //TigGradientList = class(TigCoreList)
  TigGradientList = class(TigGridList)
  private
    FBackgroundColor: TColor;
    FForegroundColor: TColor;
    procedure SetItem(AIndex: TigGradientIndex; const AValue: TigGradientItem);
    //procedure SetGradients(const AValue: TigGradientCollection);
    procedure SetForegroundColor(const AValue: TColor);
    procedure SetBackgroundColor(const AValue: TColor);
    
    function GetItem(AIndex: TigGradientIndex): TigGradientItem;
    //function GetGradients: TigGradientCollection;
    //function GetForegroundColor: TColor;
    //function GetBackgroundColor: TColor;
//    class function CollectionClass: TigCoreCollectionClass;
    ///function GetGradients: TigGradientCollection;
    ///procedure SetGradients(const AValue: TigGradientCollection);
  protected
    //class function CollectionClass : TigCoreCollectionClass; override;
    class function GetItemClass : TCollectionItemClass; override;

  public
    property Items[Index: TigGradientIndex]: TigGradientItem read GetItem write SetItem; default;
    class function GetFileReaders : TigFileFormatsList; override;
    class function GetFileWriters : TigFileFormatsList; override;

    procedure ItemPaint(ABuffer: TBitmap32; AIndex: Integer; ARect: TRect);  override; // called by grid needed by Theme
    
  published
    //property Gradients : TigGradientCollection read GetGradients write SetGradients;

    //property ForegroundColor : TColor read GetForegroundColor write SetForegroundColor;
    //property BackgroundColor : TColor read GetBackgroundColor write SetBackgroundColor;
    property ForegroundColor      : TColor          read FForegroundColor write SetForegroundColor;
    property BackgroundColor      : TColor          read FBackgroundColor write SetBackgroundColor;
  end;
implementation

uses
{ Standard }
  //SysUtils,
  Math,
{ Graphics32}
  GR32_Blend, GR32_ColorGradients,
  GR32_Polygons, GR32_VectorUtils,
{ GraphicsMagic }
  igPaintFuncs
{
  gmGradient_rwVer1,
  gmGradient_rwPhotoshop,
//  gmGradient_rwUnversioned,

  //gmGradient_rwPegtopNew,
  gmGradient_Render,
  gmMiscFuncs};

var
  UGradientReaders, UGradientWriters: TigFileFormatsList;

{ TigGradientStopItem }

constructor TigGradientStopItem.Create(ACollection: TCollection);
begin
  inherited;
  FSavedColor    := clNone;
  FValue         := clWhite;
  FMidPoint      := 0.5;
  FLocationScale := 0;
end;

function TigGradientStopItem.GetByteValue: Byte;
begin
  Result := FValue and $000000FF;
end;

function TigGradientStopItem.GetCollection: TigGradientStopCollection;
begin
  Result := inherited Collection as TigGradientStopCollection;
end;

function TigGradientStopItem.GetNextColor32: TColor32;
var
  LStop: TigGradientStopItem;
begin
  if Self.Index = (Collection.Count -1) then
  begin
    Result := Color32(Self.ValidValue);
  end
  else
  begin
    LStop  := Collection.Items[Index +1];
    Result := Color32(LStop.ValidValue);
  end;
end;

function TigGradientStopItem.GetNextLocationScale: Double;
var
  LStop: TigGradientStopItem;
begin
  if Self.Index = (Collection.Count -1) then
  begin
    Result := 1.0;
  end
  else
  begin
    LStop  := Collection.Items[Index +1];
    Result := LStop.LocationScale;
  end;
end;

function TigGradientStopItem.GetOnlyAlphaUsed: Boolean;
begin
  Result := FOnlyAlphaUsed;
  
  if Assigned(Collection) then
  begin
    Result := Collection.FOnlyAlphaUsed;
  end;
end;

function TigGradientStopItem.GetValidValue: TColor;
begin
  Result := FValue;

  if Result = clDefault then
  begin
    Result := TigGradientItem(Collection.Owner).ForegroundColor;
  end
  else
  if Result = clBackground then
  begin
    Result := TigGradientItem(Collection.Owner).BackgroundColor;
  end;
end;

// Resturns the actual horizontal location of the mid point at the length of
// the total steps
function TigGradientStopItem.MidPointLocation: Integer;
begin
  Result := Round( (LocationScale * Collection.GradientLength ) +
                   ((GetNextLocationScale - LocationScale) *
                    Collection.GradientLength * MidPoint) );
end;

procedure TigGradientStopItem.SetLocationScale(const AValue: Double);
begin
  FLocationScale := AValue;
  Changed(False);
end;

procedure TigGradientStopItem.SetMidPoint(const AValue: Double);
begin
  FMidPoint := AValue;
  Changed(False);
end;

procedure TigGradientStopItem.SetOnlyAlphaUsed(const AValue: Boolean);
begin
  FOnlyAlphaUsed := AValue;
  //but it will overrides while has Collection
end;

procedure TigGradientStopItem.SetValue(const AValue: TColor);
var
  LValue: TColor;
  B     : Byte;
begin
  LValue := AValue;
  
  if OnlyAlphaUsed then
  begin
    B      := AValue and $FF;
    LValue := B + (B shl 8) + (B shl 16);
    //FillChar(LValue, 4, B);
  end;

  if FValue <> LValue then
  begin
    FValue := LValue;
    Changed(False);
  end;
end;

function TigGradientStopItem.IfMidPointNotIsHalf: Boolean;
begin
  Result := MidPoint <> 0.5;
end;

procedure TigGradientStopItem.AssignTo(ADest: TPersistent);
var
  LDest: TigGradientStopItem;
begin
  if ADest = Self then
  begin
    Exit;
  end;

  if ADest is TigGradientStopItem then
  begin
    LDest                := ADest as TigGradientStopItem;
    LDest.FValue         := Self.FValue;
    LDest.FLocationScale := Self.FLocationScale;
    LDest.FMidPoint      := Self.FMidPoint;
  end
  else
  begin
    inherited; // assign error
  end;
end;

{ TigGradientStopCollection }

constructor TigGradientStopCollection.Create(AOwner: TigGradientItem);
begin
  inherited Create(AOwner, TigGradientStopItem);
end;

destructor TigGradientStopCollection.Destroy;
begin
  Clear;
  inherited Destroy;
end;

function TigGradientStopCollection.Add: TigGradientStopItem;
begin
  Result := TigGradientStopItem(inherited Add);
end;

procedure TigGradientStopCollection.Delete(const AIndex: Integer);
begin
  inherited Delete(AIndex);
  Changed;
end;

function TigGradientStopCollection.GetItem(
  Index: Integer): TigGradientStopItem;
begin
  if (Index < 0) or (Index >= Count) then
    Result := nil
  else
    Result := TigGradientStopItem(inherited GetItem(Index));
end;

function TigGradientStopCollection.Insert(
  const AIndex: Integer): TigGradientStopItem;
begin
  Result := TigGradientStopItem(inherited Insert(AIndex));
end;

function TigGradientStopCollection.Insert(ALocationScale: Double;
  AValue: TColor): Integer;
var
  LGradientStop: TigGradientStopItem;
begin
  LGradientStop               := Self.Add;
  LGradientStop.LocationScale := ALocationScale;
  LGradientStop.Value         := AValue;

  Sort;
  Result := LGradientStop.Index;
end;

function TigGradientStopCollection.GradientLength: Integer;
begin
  Result := Owner.GradientLength;
end;

procedure TigGradientStopCollection.SetItem(AIndex: Integer;
  const AValue: TigGradientStopItem);
begin
  inherited SetItem(AIndex, AValue);
end;

procedure TigGradientStopCollection.Update(AItem: TCollectionItem);
begin
  inherited Update(AItem);
  
  if Assigned(FOnChange) then
  begin
    FOnChange(Self);
  end;
end;

function TigGradientStopCollection.GetOutputColorArray: TArrayOfColor32;
var
  LIndex    : Integer; // current position color32 of FOutputColorArray
  LLastColor: TColor32;

    // draw gradient to FOutputColorArray, using LIndex as start position
    procedure DrawGradientColorArray(const AStartColor, AEndColor: TColor32;
      const AGradientLength: Integer);
    var
      i, LGradientLength: Integer;
      r, g, b           : Byte;
      sr, sg, sb        : Byte;
      er, eg, eb        : Byte;
      ir, ig, ib        : Single;
      LRedInc           : Single;
      LGreenInc         : Single;
      LBlueInc          : Single;
      LStepScale        : Single;
    begin
      if (AGradientLength > 0) and (LIndex < Owner.GradientLength) then
      begin
        sr := AStartColor shr 16 and $FF;
        sg := AStartColor shr  8 and $FF;
        sb := AStartColor        and $FF;

        er := AEndColor shr 16 and $FF;
        eg := AEndColor shr  8 and $FF;
        eb := AEndColor        and $FF;

        LStepScale := 1 / AGradientLength;
        LRedInc    := (er - sr) * LStepScale;
        LGreenInc  := (eg - sg) * LStepScale;
        LBlueInc   := (eb - sb) * LStepScale;

        FOutputColorArray[LIndex] := AStartColor;
        LLastColor                := AStartColor;

        ir := sr;
        ig := sg;
        ib := sb;
        
        LGradientLength := 0;

        for i := (LIndex + 1) to (LIndex + AGradientLength - 1) do
        begin
          if i >= Owner.GradientLength then
          begin
            Continue;
          end;

          Inc(LGradientLength);

          ir := ir + LRedInc;
          ig := ig + LGreenInc;
          ib := ib + LBlueInc;

          r := Round(ir);
          g := Round(ig);
          b := Round(ib);

          r := Clamp(r);
          g := Clamp(g);
          b := Clamp(b);

          LLastColor          := $FF000000 or (r shl 16) or (g shl 8) or b;
          FOutputColorArray[i]:= LLastColor;
        end;

        Inc(LIndex, LGradientLength);
      end;
    end; 

    // because of ROUND()ing,  we make sure that every stop in it's own
    // occupy position
    procedure BugFixScaled(AStop:TigGradientStopItem);
    var
      LValidIndex : Integer;
    begin
      LValidIndex := Min(Owner.GradientLength, Round(AStop.LocationScale * Owner.GradientLength));

      while LIndex < LValidIndex do
      begin
        FOutputColorArray[LIndex] := LLastColor;
        Inc(LIndex);
      end;
    end;

    procedure FillGradientColorArray(const AStop: TigGradientStopItem);
    var
      LCopyCount: Integer;
      LMidLength: Integer;
      LMidColor : TColor32;
      LNextColor: TColor32;
    begin
      // In some PS grd, their many fist stop is same [0.0, 0.0, 0.0, 0.0...0.344, ...]
      if AStop.NextLocationScale = AStop.LocationScale then
      begin
        Exit;
      end;

      // process the part that before the first color...
      if (AStop.Index = 0) and (AStop.LocationScale > 0.0) then
      begin
        LCopyCount := Round(AStop.LocationScale * Owner.GradientLength);
        LLastColor := Color32(AStop.ValidValue);

        FillLongword(FOutputColorArray[LIndex], LCopyCount, LLastColor);
        Inc(LIndex, LCopyCount);
      end;

      // is it the last?
      if AStop.Index >= (Self.Count - 1) then
      begin
        // process the part that after the last color
        if ( AStop.LocationScale < 1.0 ) and
           ( LIndex < GradientLength ) then
        begin
          FillLongword( FOutputColorArray[LIndex], GradientLength - LIndex,
                        Color32(AStop.ValidValue) );
        end;
      end
      else
      begin
        BugFixScaled(AStop);
        
        LNextColor := Color32(Self.Items[AStop.Index + 1].ValidValue);
        LMidColor  := CombineReg( Color32(AStop.ValidValue), LNextColor, 128 );
        EMMS;

        LMidLength := Round( (AStop.GetNextLocationScale - AStop.LocationScale) *
          Self.GradientLength * AStop.MidPoint );

        // get first part of gradient colors ...
        DrawGradientColorArray( Color32(AStop.ValidValue), LMidColor, LMidLength );

        // get second part of gradient colors ...
        LMidLength := Round(AStop.GetNextLocationScale *
          Self.GradientLength ) - LIndex ; // -1 for correct length: 0..width-1 = colorsArrayLength -1;

        DrawGradientColorArray(LMidColor, LNextColor, LMidLength);
      end;
    end;
    
var
  i: Integer;
begin
  SetLength(FOutputColorArray, Owner.GradientLength);
  
  if Self.Count <= 1 then
  begin
    FillChar(FOutputColorArray, Owner.GradientLength, 0);
  end;

  LIndex := 0;

  for i := 0 to (Count - 1) do
  begin
    FillGradientColorArray(Self.Items[i]);
  end;
  
  Result := FOutputColorArray;
end;

function TigGradientStopCollection.Owner: TigGradientItem;
begin
  Result := GetOwner() as TigGradientItem;
end;

// return the new index of the color
function TigGradientStopCollection.ChangeLocationScale(
  const AColorIndex: Integer; const AScale: Double): Integer;
var
  LGradientStop: TigGradientStopItem;
begin
  BeginUpdate;

  LGradientStop := Items[AColorIndex];
  LGradientStop.LocationScale := AScale;

  Sort;
  Result := LGradientStop.Index;
  
  EndUpdate;
end;

function TigGradientStopCollection.Insert32(ALocationScale: Double;
  AValue: TColor32): Integer;
begin
  Result := Insert( ALocationScale, WinColor(AValue) );
end;

//=============sort===================
{type
  TigGradientCompare = function (Item1, Item2: TigGradientStopItem): Integer;}

function SCompare(Item1, Item2: TigGradientStopItem): Integer;
begin
  if Item1.LocationScale > Item2.LocationScale then
    Result := 1
  else
  if Item1.LocationScale = Item2.LocationScale then
    Result := 0
  else
    Result := -1;
end;

procedure QuickSort(SortList: TigGradientStopCollection; L, R: Integer{;  SCompare: TigGradientCompare});
var
  I, J  : Integer;
  P     : Pointer;
  iT, iJ: TigGradientStopItem;
begin
  repeat
    I := L;
    J := R;
    P := SortList[(L + R) shr 1];
    
    repeat
      while SCompare(SortList[I], P) < 0 do
      begin
        Inc(I);
      end;
      
      while SCompare(SortList[J], P) > 0 do
      begin
        Dec(J);
      end;
      
      if I <= J then
      begin
        // exchange I & J
        {T := SortList[I];
        SortList[I] := SortList[J];  //J.index = i
        SortList[J] := T;}           //I.Index = j
        iT := SortList[I];
        iJ := SortList[J];
        iJ.Index := I;
        iT.Index := J;

        Inc(I);
        Dec(J);
      end;
      
    until I > J;
    
    if L < J then
    begin
      QuickSort(SortList, L, J{, SCompare});
    end;
    
    L := I;
  until I >= R;
end;

procedure TigGradientStopCollection.Sort;
begin
  BeginUpdate;
  QuickSort(Self, 0, Count - 1);
  EndUpdate;
end;

// make location be distributed averagely
procedure TigGradientStopCollection.DistributeAverage;
var
  i     : Integer;
  LScale: Double;
  LStop : TigGradientStopItem;
begin
  LScale := 1 / (Count - 1);

  BeginUpdate;

  for i := 0 to (Count - 1) do
  begin
    LStop := Items[i];
    LStop.LocationScale := i * LScale;

    LStop.MidPoint := 0.5;
  end;
  
  EndUpdate;
end;

{ TigGradientItem }

constructor TigGradientItem.Create(ACollection: TCollection);
var
  a, c: TigGradientStopItem;
begin
  inherited Create(ACollection);

  FAlphaGradient               := TigGradientStopCollection.Create(Self);
  FAlphaGradient.OnlyAlphaUsed := True;
  FAlphaGradient.OnChange      := SpectrumChanged;
  FAlphaGradient.Add;

  a               := FAlphaGradient.Add;
  a.LocationScale := 1.0;

  FRGBGradient    := TigGradientStopCollection.Create(Self);
  c               := FRGBGradient.Add;
  c.LocationScale := 0;
  c.FValue        := clDefault;
  
  c                     := FRGBGradient.Add;
  c.LocationScale       := 1.0;
  c.FValue              := clBackground;
  FRGBGradient.OnChange := SpectrumChanged;

  SetLength(FOutputColorArray, 0);
  
  FGradientLength  := 0;
  FForegroundColor := clBlack;
  FBackgroundColor := clWhite;
end; 

destructor TigGradientItem.Destroy;
begin
  if Length(FOutputColorArray) > 0 then
  begin
    SetLength(FOutputColorArray, 0);
    FOutputColorArray := nil;
  end;

  FAlphaGradient.Clear;
  FAlphaGradient.Free;
  FRGBGradient.Clear;
  FRGBGradient.Free;

  if Assigned(FCachedBitmap) then
    FCachedBitmap.Free;

  inherited Destroy;
end;

procedure TigGradientItem.SetGradientLength(const ALength: Integer);
begin
  if ALength > 0 then
  begin
    FGradientLength := ALength;
  end;
end;

procedure AlphaForceColor(A: TColor32; var C:TColor32);
var
  CX: TColor32Entry absolute C;
  AX: TColor32Entry absolute A;
begin
  CX.A := AX.B;
end;

procedure TigGradientItem.RefreshColorArray;
var
  i: Integer;
  A: TArrayOfColor32;
begin
  A := nil;
  
  if FGradientLength > 0 then
  begin
    FOutputColorArray := FRGBGradient.OutputColors;
    A                 := FAlphaGradient.OutputColors;

    // copy gradient colors to output color array
    for i := 0 to (FGradientLength - 1) do
    begin
      AlphaForceColor(A[i], FOutputColorArray[i] );
    end;
    
    EMMS;
  end;
end;

procedure TigGradientItem.DrawColorGradients(const ABmp: TBitmap32;
  const AReversed: Boolean = False);
var
  x, y          : Integer;
  LBmpColorArray: PColor32Array;
begin
// If a project take on range checking, access to any pixels on an image
// by PColor32Array will cause the compiler reports range checking error.
// We know that this is just a potential error. We know what we want to do,
// we know the following code will not cause such problem, so we just need
// to take off range checking at here temporarily.

{$RANGECHECKS OFF}

  if ( not Assigned(ABmp)) or
     ( ABmp.Height <= 0 ) then
  begin
    Exit;
  end;

  if ABmp.Width < FGradientLength then
  begin
    ABmp.Width := FGradientLength;
  end;

  for y := 0 to (ABmp.Height - 1) do
  begin
    LBmpColorArray := ABmp.ScanLine[y];

    for x := 0 to (ABmp.Width - 1) do
    begin
      if AReversed then
      begin
        LBmpColorArray[x] := FOutputColorArray[ABmp.Width - 1 - x];
      end
      else
      begin
        LBmpColorArray[x] := FOutputColorArray[x];
      end;
    end;
  end;

{$RANGECHECKS ON}
end;

procedure TigGradientItem.AssignTo(ADest: TPersistent);
var
  LDest : TigGradientItem;
begin
  if ADest = Self then
  begin
    Exit;
  end;

  inherited; //possibly assign error

  if ADest is TigGradientItem then
  begin
    LDest                  := ADest as TigGradientItem;
    //LDest.FDisplayName     := Self.DisplayName;
    LDest.FForegroundColor := Self.FForegroundColor;
    LDest.FBackgroundColor := Self.FBackgroundColor;

    LDest.AlphaGradient.Assign(Self.AlphaGradient);
    LDest.RGBGradient.Assign(self.RGBGradient);
    LDest.RefreshColorArray;

    if Assigned(LDest.FOnChange) then
    begin
      LDest.FOnChange(LDest);
    end
  end;
end;

function TigGradientItem.GetAbsolutEndColor: TColor32;
begin
  if Length(FOutputColorArray) > 0 then
    Result := FOutputColorArray[ High(FOutputColorArray) ]
  else
    Result := Color32(RGBGradient[RGBGradient.Count - 1].ValidValue);
end;

function TigGradientItem.GetAbsolutStartColor: TColor32;
begin
  if Length(FOutputColorArray) > 0 then
    Result := FOutputColorArray[0]
  else
    Result := Color32(RGBGradient[0].ValidValue);
end;

function TigGradientItem.IsSpecialColorUsed: Boolean;
var
  i: Integer;
begin
  Result := False;
  
  for i := 0 to (RGBGradient.Count - 1) do
  begin
    //remember that is Value and FValue is different
    if (RGBGradient[i].FValue = clNone) or
       (RGBGradient[i].FValue = clDefault) or
       (RGBGradient[i].FValue = clBackground ) then
    begin
      Result := True;
      Break; //enough one to set to true
    end;
  end;
end;

procedure TigGradientItem.SetAlphaGradient(
  const AValue: TigGradientStopCollection);
begin
  FAlphaGradient.Assign(AValue);
end;

procedure TigGradientItem.SetRGBGradient(
  const AValue: TigGradientStopCollection);
begin
  FRGBGradient.Assign(AValue);
end;

procedure TigGradientItem.Clear;
begin
  RGBGradient.Clear;
  AlphaGradient.Clear;
end;

function TigGradientItem.IsEmpty: Boolean;
begin
  Result := (RGBGradient.Count = 0) and (AlphaGradient.Count = 0);
end;

function TigGradientItem.GetBackgroundColor: TColor;
begin
  Result := FBackgroundColor;

  if GetItemList <> nil then
    Result := TigGradientList(GetItemList).BackgroundColor;
end;

function TigGradientItem.GetForegroundColor: TColor;
begin
  Result := FForegroundColor;

  if GetItemList <> nil then
    Result := TigGradientList(GetItemList).ForegroundColor;
end;

function TigGradientItem.IsGroundcolorStored: Boolean;
begin
  //if has not collection, then save
  Result := not Assigned(Collection);
end;

procedure TigGradientItem.SpectrumChanged(ASender: TObject);
begin
  FSpectrumValid := False;

  if Assigned(FOnChange) then
    FOnChange(Self);

  Changed(False);
end;

procedure TigGradientItem.DrawCachedBitmap(const AWidth, AHeight: Integer;
  const ADestBmp: TBitmap32; const ADestPoint: TPoint);
var
  LEdge,i               : Integer;
  R                     : TFloatRect;
  LStartPoint, LEndPoint: TPoint;
  LGradient: TColor32Gradient;
  LGradientLUT: TColor32LookupTable;
  LinearGradFiller: TCustomLinearGradientPolygonFiller;
  PolygonTop: TArrayOfFloatPoint;
begin
  if not Assigned(FCachedBitmap) then
  begin
    FCachedBitmap          := TBitmap32.Create;
    FCachedBitmap.DrawMode := dmBlend;
  end;

  if (not FSpectrumValid) or
     (FCachedBitmap.Width <> AWidth) or
     (FCachedBitmap.Height <> AHeight) then
  begin
    FCachedBitmap.SetSize(AWidth, AHeight);

    LEdge       := Round(Sqrt(AWidth * AHeight) * 0.05);
    LStartPoint := Point(LEdge, LEdge); //because zero based, start from 0

    LEndPoint   := Point(FCachedBitmap.Width - LEdge-1,
                         FCachedBitmap.Height - LEdge-1);

    ///DrawLinearGradient(FCachedBitmap, LStartPoint, LEndPoint, Self, False);
    LGradient:= TColor32Gradient.Create;
    for i := 0 to Self.FRGBGradient.Count-1 do
    begin
      LGradient.AddColorStop(FRGBGradient[i].FLocationScale, Color32(FRGBGradient[i].ValidValue));
    end;
    LGradientLUT:= TColor32LookupTable.Create;
    LGradient.FillColorLookUpTable(LGradientLUT); //or array of color32
    LinearGradFiller := TLinearGradientPolygonFiller.Create(LGradientLUT);
    try
      //R := FloatRect(ADestPoint.X, ADestPoint.Y, ADestPoint.X + AWidth, ADestPoint.Y + AHeight )
      R := FloatRect(0,0, AWidth, AHeight );
      PolygonTop := Rectangle(R);
      LinearGradFiller.StartPoint := R.TopLeft;
      LinearGradFiller.EndPoint := R.BottomRight;
      //LinearGradFiller.WrapMode := TWrapMode(RgpWrapMode.ItemIndex);

      PolygonFS(FCachedBitmap, PolygonTop, LinearGradFiller);
      //PolyLineFS(ImgView32.Bitmap, PolygonTop, clBlack32, True, 1);
    finally
      LinearGradFiller.Free;
      LGradientLUT.Free;
    end;

    //FCachedBitmap.Clear(Color32(FRGBGradient.Items[0].ValidValue));
  end;

  with ADestPoint do
    ADestBmp.Draw(X, Y, FCachedBitmap);
end;

function TigGradientItem.CachedBitmap(
  const AWidth, AHeight: Integer): TBitmap32;
var
  LEdge                  : Integer;
  LStartPoint, LEndPoint : TPoint;
  LGradientBmp           : TBitmap32;
begin
  if not Assigned(FCachedBitmap) then
  begin
    FCachedBitmap          := TBitmap32.Create;
    FCachedBitmap.DrawMode := dmBlend;
  end;

  if (not FSpectrumValid) or
     (FCachedBitmap.Width <> AWidth) or
     (FCachedBitmap.Height <> AHeight) then
  begin
    FCachedBitmap.SetSize(AWidth, AHeight);
    DrawCheckerboardPattern(FCachedBitmap, FCachedBitmap.BoundsRect);

    LEdge       := Round( Sqrt(AWidth * AHeight) * 0.05 );
    LStartPoint := Point(LEdge, LEdge); //because zero based, start from 0

    LEndPoint   := Point(FCachedBitmap.Width - LEdge-1,
                         FCachedBitmap.Height - LEdge-1);

    //DrawLinearGradient(FCachedBitmap, LStartPoint, LEndPoint, Self, False);

    // added by Ma Xiaoming and Ma Xiaoguang to replace the above line code
    LGradientBmp := TBitmap32.Create;
    try
      LGradientBmp.DrawMode := dmBlend;
      LGradientBmp.SetSizeFrom(FCachedBitmap);
      ///DrawLinearGradient(LGradientBmp, LStartPoint, LEndPoint, Self, False);
      ///FCachedBitmap.Draw(0, 0, LGradientBmp);
      FCachedBitmap.Clear(clRosyBrown32);
    finally
      LGradientBmp.Free;
    end;
  end;
  
  Result := FCachedBitmap;
end;

{ TigGradientCollection }

(*constructor TigGradientCollection.Create(AOwner: TComponent);
begin
  inherited Create(AOwner, TigGradientItem);
  
  FForegroundColor := clBlack;
  FBackgroundColor := clWhite;
end;

//here is the trick!
function TigGradientCollection.Add: TigGradientItem;
begin
  Result                 := TigGradientItem(inherited Add);
  Result.ForegroundColor := Self.ForegroundColor;
  Result.BackgroundColor := Self.BackgroundColor;
end;

function TigGradientCollection.Draw(const AGradientIndex: Integer;
  const ACanvas: TCanvas; const ARect: TRect): Boolean;
var
  LGradientBmp: TBitmap32;
  LRect       : TRect;
begin
  Result := False;

  if not Assigned(ACanvas) then
  begin
    raise Exception.Create('TigGradientCollection.Draw() -- Error: Canvas is nil.');
  end;

  if GR32.IsRectEmpty(ARect) then
  begin
    raise Exception.Create('Rect is Empty');
  end;

  with ARect do
  begin
    LRect := MakeRect(0, 0, Right - Left, Bottom - Top);
  end;
  
  LGradientBmp := TBitmap32.Create;
  try
    LGradientBmp.SetSize(LRect.Right + 1, LRect.Bottom + 1);
    DrawCheckerboard(LGradientBmp, LGradientBmp.BoundsRect);

    DrawLinearGradient(LGradientBmp, LRect.TopLeft, LRect.BottomRight,
                       Items[agradientIndex], False);

    LGradientBmp.DrawTo(ACanvas.Handle, ARect.Left, ARect.Top);
  finally
    LGradientBmp.Free;
  end;
end; 

function TigGradientCollection.GetItem(Index: Integer): TigGradientItem;
begin
  Result := TigGradientItem(inherited GetItem(Index));
end;

procedure TigGradientCollection.SetItem(AIndex: Integer;
  const AValue: TigGradientItem);
begin
  inherited SetItem(AIndex, AValue);
end;

procedure TigGradientCollection.SetForegroundColor(const AColor: TColor);
var
  i            : Integer;
  LGradientItem: TigGradientItem;
begin
  if FForegroundColor <> AColor then
  begin
    FForegroundColor := AColor;

    if Self.Count > 0 then
    begin
      for i := 0 to (Self.Count - 1) do
      begin
        LGradientItem := Items[i];
        LGradientItem.FForegroundColor := Self.FForegroundColor;
      end;
    end;
  end;
end;

procedure TigGradientCollection.SetBackgroundColor(const AColor: TColor);
var
  i            : Integer;
  LGradientItem: TigGradientItem;
begin
  if FBackgroundColor <> AColor then
  begin
    FBackgroundColor := AColor;

    if Self.Count > 0 then
    begin
      for i := 0 to (Self.Count - 1) do
      begin
        LGradientItem := Items[i];
        LGradientItem.FBackgroundColor := Self.FBackgroundColor;
      end;
    end;
  end;
end;

function TigGradientCollection.IsValidIndex(const AIndex: Integer): Boolean;
begin
  Result := (AIndex > -1) and (AIndex < Count);
end;

procedure TigGradientCollection.Assign(ASource: TPersistent);
begin
  if ASource is TigGradientCollection then
  begin
    FForegroundColor := TigGradientCollection(ASource).ForegroundColor;
    FBackgroundColor := TigGradientCollection(ASource).BackgroundColor;
  end;
  
  inherited; //may error, so put at end
end;
*)



{ TigGradientList }

{class function TigGradientList.CollectionClass: TigCoreCollectionClass;
begin
  Result := TigGradientCollection;
end;

function TigGradientList.GetBackgroundColor: TColor;
begin
  Result := Gradients.BackgroundColor;
end;

function TigGradientList.GetForegroundColor: TColor;
begin
  Result := Gradients.ForegroundColor;
end;

function TigGradientList.GetGradients: TigGradientCollection;
begin
  Result := TigGradientCollection(Self.Collection);
end;}

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

function TigGradientList.GetItem(
  AIndex: TigGradientIndex): TigGradientItem;
begin
  Result := TigGradientItem(Collection.Items[AIndex])
end;

class function TigGradientList.GetItemClass: TCollectionItemClass;
begin
  Result := TigGradientItem;
end;

procedure TigGradientList.ItemPaint(ABuffer: TBitmap32; AIndex: Integer;
  ARect: TRect);
begin
  if IsValidIndex(AIndex) then
  begin
    Self.Items[AIndex].DrawCachedBitmap( ARect.Right- ARect.Left, ARect.Bottom- ARect.Top, ABuffer, ARect.TopLeft);
    {if Items[AIndex].Color = clNone then
      DrawCheckerboardPattern(ABuffer, ARect, True )
    else
      ABuffer.FillRectS(ARect, Color32( Items[AIndex].Color) );
    ABuffer.FrameRectS(ARect, clTrGray32 );}
  end;

end;

procedure TigGradientList.SetBackgroundColor(const AValue: TColor);
var
  i            : Integer;
  LGradientItem: TigGradientItem;
begin
  if FBackgroundColor <> AValue then
  begin
    FBackgroundColor := AValue;

    if Self.Count > 0 then
    begin
      for i := 0 to (Self.Count - 1) do
      begin
        LGradientItem := Items[i];
        LGradientItem.FBackgroundColor := Self.FBackgroundColor;
      end;
    end;
    Self.Changed;
  end;
end;

procedure TigGradientList.SetForegroundColor(const AValue: TColor);
var
  i            : Integer;
  LGradientItem: TigGradientItem;
begin
  if FForegroundColor <> AValue then
  begin
    FForegroundColor := AValue;

    if Self.Count > 0 then
    begin
      for i := 0 to (Self.Count - 1) do
      begin
        LGradientItem := Items[i];
        LGradientItem.FForegroundColor := Self.FForegroundColor;
      end;
    end;
    Self.Changed;
  end;
end;

{procedure TigGradientList.SetGradients(
  const AValue: TigGradientCollection);
begin
  Collection.Assign(AValue);
end;}

procedure TigGradientList.SetItem(AIndex: TigGradientIndex;
  const AValue: TigGradientItem);
begin
  Collection.Items[AIndex].Assign(AValue);
end;

function TigGradientItem.GetEmpty: Boolean;
begin
  Result := IsEmpty;
end;

initialization
  RegisterCoreList(TigGradientList);
end.

