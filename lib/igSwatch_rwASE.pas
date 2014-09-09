unit igSwatch_rwASE;

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
 * x2nie - Fathony Luthfillah  <x2nie@yahoo.com>
 *
 * Contributor(s):
 *
 * Lab to RGB color conversion is using RGBCIEUtils.pas under mbColorLib library
 * developed by Marko Binic' marko_binic [at] yahoo [dot] com
 * or mbinic [at] gmail [dot] com.
 * forums : http://mxs.bergsoft.net/forums
 *
 *
 * ***** END LICENSE BLOCK ***** *)

interface
uses Classes,SysUtils, Graphics,
  igCore_rw, igSwatch, igSwatch_rwACO ;

type
  //TigAcoColorLoader = function (Stream8 : TStream): TColor of object;

  TigAseConverter = class(TigConverter)
  private
    FAcoColorLoaders : array [0..10] of TigAcoColorLoader;
    function FAcoRGBLoader(Stream8 : TStream): TColor;
    function FAcoHSBLoader(Stream8 : TStream): TColor;
    function FAcoCMYKLoader(Stream8 : TStream): TColor;
    function FAcoLabLoader(Stream8 : TStream): TColor;
    function FAcoGrayscaleLoader(Stream8 : TStream): TColor;
    function FAcoDummyLoader(Stream8 : TStream): TColor;

    procedure LoadItemFromASE1(Item :TigSwatchItem; Stream : TStream);
    procedure LoadItemFromACO2(Item :TigSwatchItem; Stream : TStream);
  public
    constructor Create; override;
    procedure LoadFromStream(AStream: TStream; ACollection: TCollection); override;
    //procedure LoadItemFromString(Item :TigSwatchItem; S : string);
    //procedure LoadItemFromStream(Stream: TStream; AItem: TCollectionItem); virtual; abstract;
    //procedure SaveToStream(Stream: TStream; ACollection: TCollection); override;
    //procedure SaveItemToStream(Stream: TStream; AItem: TCollectionItem); virtual; abstract;
    class function WantThis(AStream: TStream): Boolean; override;
    //constructor Create; virtual;
  end;

implementation

uses
  GR32, be_stream,
  RGBCIEUtils,
  GR32_LowLevel;

type
  TigAcoItemLoader = procedure (Item :TigSwatchItem; Stream : TStream) of object;
  TigAcoHeader = record
    Version : Word;
    Count   : Word;
  end;

{ TigConverter }
 
constructor TigAseConverter.Create;
begin
  inherited;
  FAcoColorLoaders[0] := self.FAcoRGBLoader;
  FAcoColorLoaders[1] := self.FAcoHSBLoader;
  FAcoColorLoaders[2] := self.FAcoCMYKLoader;
  FAcoColorLoaders[3] := self.FAcoDummyLoader; //Pantone matching system
  FAcoColorLoaders[4] := self.FAcoDummyLoader; //Focoltone colour system
  FAcoColorLoaders[5] := self.FAcoDummyLoader; //Trumatch color
  FAcoColorLoaders[6] := self.FAcoDummyLoader; //Toyo 88 colorfinder 1050
  FAcoColorLoaders[7] := self.FAcoLabLoader;
  FAcoColorLoaders[8] := self.FAcoGrayscaleLoader;
  FAcoColorLoaders[9] := self.FAcoDummyLoader; //unknown
  FAcoColorLoaders[10]:= self.FAcoDummyLoader; //HKS colors
end;

function TigAseConverter.FAcoCMYKLoader(Stream8: TStream): TColor;
var
  C,M,Y,K : Word;
begin
  C := Round(BE_ReadSingle);
  M := Round(BE_ReadSingle);
  Y := Round(BE_ReadSingle);
  K := Round(BE_ReadSingle);
  Stream8.Seek(2,soFromCurrent);
  
  Result := (K shr 8) shl 16 + (M shr 8) shl 8 + (C shr 8);
end;

function TigAseConverter.FAcoDummyLoader(Stream8: TStream): TColor;
begin
  Result := clNone; //dummy
end;

function TigAseConverter.FAcoGrayscaleLoader(Stream8: TStream): TColor;
var
  Gray : Word;
  g : byte;
begin
  Gray := BE_ReadWord; // gray value, from 0...10000.
  Stream8.Seek(6,soFromCurrent);

  g := Round(Gray / 10000 * 255);
  Result := g shl 16 + g shl 8 + g;
end;

function TigAseConverter.FAcoHSBLoader(Stream8: TStream): TColor;
    function Hue_2_RGB( v1, v2, vH : double ):Double;             //Function Hue_2_RGB
    begin
      if ( vH < 0 ) then vH := vH + 1;
      if ( vH > 1 ) then vH := vH - 1;
      if ( ( 6 * vH ) < 1 )
        then result := ( v1 + ( v2 - v1 ) * 6 * vH )
      else if ( ( 2 * vH ) < 1 )
        then Result := v2
      else if ( ( 3 * vH ) < 2 )
        then result := ( v1 + ( v2 - v1 ) * ( ( 2 / 3 ) - vH ) * 6 )
      else result := v1;
    end;

var
  //H,S,L : Word;
  H,S,L,var_1,var_2: Double;
  R,G,B : Integer;
begin
  H := BE_ReadWord /360; // hue
  S := BE_ReadWord /100; // saturation
  L := BE_ReadWord /100; // brigthness
  Stream8.Seek(2,soFromCurrent);
  //Result := (L div 255) shl 16 + (S div 255) shl 8 + (H div 255);
  if ( S = 0 ) then                       //HSL from 0 to 1
  begin
     R := Round(L * 255);                      //RGB results from 0 to 255
     G := Round(L * 255);
     B := Round(L * 255);
  end
  else
  begin
     if ( L < 0.5 ) then
      var_2 := L * ( 1 + S )
     else
      var_2 := ( L + S ) - ( S * L );

     var_1 := 2 * L - var_2;

     R := Round(255 * Hue_2_RGB( var_1, var_2, H + ( 1 / 3 ) ) );
     G := Round(255 * Hue_2_RGB( var_1, var_2, H ) );
     B := Round(255 * Hue_2_RGB( var_1, var_2, H - ( 1 / 3 ) )  );
  end;
  clamp(R);
  clamp(G);
  clamp(B);
  //Result :=  B shl 16 + G shl 8 + R;
  Result := B shl 16 + G shl 8 + R;  
end;

function TigAseConverter.FAcoLabLoader(Stream8: TStream): TColor;
var
  L : Word;
  A,B : SmallInt;
begin
  L := BE_ReadWord;     // lightness
  A := BE_ReadSmallInt; // a chrominance
  B := BE_ReadSmallInt; // b chrominance
  {Lightness is a 16-bit value from 0...10000.
  Chrominance components are each 16-bit values from -12800...12700.
  Gray values are represented by chrominance components of 0.
  Pure white = 10000,0,0.}
  Stream8.Seek(2,soFromCurrent);
  Result := LabToRGB(L /100, A /100, B /100);
end;

function TigAseConverter.FAcoRGBLoader(Stream8: TStream): TColor;
var
  R,G,B : Byte;
begin
  R := Round(BE_ReadSingle * 255);
  G := Round(BE_ReadSingle * 255);
  B := Round(BE_ReadSingle * 255);
  Stream8.Seek(2,soFromCurrent);

  Result := (B) shl 16 + (G ) shl 8 + (R);
end;

procedure TigAseConverter.LoadFromStream(AStream: TStream;
  ACollection: TCollection);
var
  LCount, i   : Integer;
  LVersion    : TigVersionRec;
  LCollection         : TigSwatchCollection;
  LAseLoader          : TigAcoItemLoader;
begin
  LCollection       := TigSwatchCollection(ACollection);
  be_stream.GStream := AStream;
  BE_ReadDWord; //skip magic word
  AStream.Read(LVersion, SizeOf(TigVersionRec));
  LCount            := BE_ReadDWord;

  case SwapEndian(LVersion.BEMajor) of
    1 : LAseLoader := self.LoadItemFromASE1;
    //2 : LAseLoader := self.LoadItemFromACO2;
  else
    LAseLoader := nil;
  end;

  if Assigned(LAseLoader) and  (LCount > 0) then
  begin
    LCollection.BeginUpdate;
    try
      for i := 0 to LCount -1 do
        LAseLoader( TigSwatchItem(LCollection.Add), AStream );
    finally
      ACollection.EndUpdate;
    end;
  end;
end;

procedure TigAseConverter.LoadItemFromASE1(Item: TigSwatchItem;
  Stream: TStream);
var LBlockType, nChars, i : Word;
  LColorSpace : TigVersionRec;
  LBlockLength : Cardinal;
  WS : WideString;
  p : PWideChar;
  LASEColorParser : TigAcoColorLoader;
begin
  LBlockType := BE_ReadWord;
  LBlockLength := BE_ReadDWord;

  //currently, we only interest on color entry.
  while (LBlockType <> $0001) and (Stream.Position < Stream.Size ) do
  begin
    Stream.Seek(LBlockLength, soCurrent);
    LBlockType := BE_ReadWord;
    LBlockLength := BE_ReadDWord;
  end;

  if Stream.Position = Stream.Size then
    Exit;


  nChars := BE_ReadWord;
  SetLength(WS, nChars);
  if nChars > 0 then
    for i := 1 to nChars do
    begin
      WS[i] := WideChar(BE_ReadWord);
    end;
  if WS[nChars] = #0 then
    SetLength(WS, nChars - 1);

  Item.DisplayName := WS;

  //get color model
  Stream.Read(LColorSpace, SizeOf(TigVersionRec));
  if      LColorSpace.Chars = 'CMYK' then LASEColorParser := FAcoCMYKLoader
  else if LColorSpace.Chars = 'RGB ' then LASEColorParser := FAcoRGBLoader
  else LASEColorParser := self.FAcoDummyLoader;
  
  Item.Color := LASEColorParser( Stream );
end;

procedure TigAseConverter.LoadItemFromACO2(Item: TigSwatchItem;
  Stream: TStream);
begin
  LoadItemFromASE1(Item,Stream);
  Item.DisplayName := BE_ReadWideString;
end;

class function TigAseConverter.WantThis(AStream: TStream): Boolean;
var
  LVersion,
  Magic : TigVersionRec;
begin
  be_stream.GStream := AStream;
  AStream.Read(Magic, SizeOf(TigVersionRec));
  AStream.Read(LVersion, SizeOf(TigVersionRec));

  //LVersion := BE_ReadWord;
  Result := (Magic.Chars = 'ASEF') and (SwapEndian(LVersion.BEMajor) = 1) ; //only accept ver1 for now 
end;

initialization
  TigSwatchList.RegisterConverterReader('ASE','Adobe Swatch Exchange',0, TigAseConverter);
  //TigSwatchCollection.RegisterConverterWriter('SWA');
end.
