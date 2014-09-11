unit igSwatch_rwGPL;

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
 *   x2nie - Fathony Luthfillah  <x2nie@yahoo.com>
 *
 * Contributor(s):
 *
 * Credit :
 *  http://www.selapa.net/swatches/colors/fileformats.php
 *
 * ***** END LICENSE BLOCK ***** *)
 
interface

uses
{ Standard }
  Classes, SysUtils,
{ GraphicsMagic }
  igCore_rw, igSwatch ;

type
  TigSwatch_GPLConverter = class(TigConverter)
  public
    procedure LoadFromStream(AStream: TStream; ACollection: TCollection); override;
    procedure LoadItemFromString(AItem: TigSwatchItem; S: string);
    procedure SaveToStream(AStream: TStream; ACollection: TCollection); override;
    class function WantThis(AStream: TStream): Boolean; override;
  end;

implementation

uses
  Graphics, GR32;

{ TigSwaConverter }

procedure TigSwatch_GPLConverter.LoadFromStream(AStream: TStream;
  ACollection: TCollection);
var
  LStrList    : TStrings;
  z,i         : Integer;
  s           : string;
  LCollection : TigSwatchCollection;
begin
  LCollection := TigSwatchCollection(ACollection);
  LStrList := TStringList.Create;
  LStrList.LoadFromStream(AStream);
  try
    {
    GIMP Palette
    Name: Tango Icon Theme
    Columns: 3
    #
    252 233  79	Butter 1
    237 212   0	Butter 2
    196 160   0	Butter 3
    138 226  52	Chameleon 1
    ...
    }
    i := 0;
    repeat
      s := LStrList[i];
      if lowercase( Copy(s,1,4) ) = 'name' then
      begin
        s := trim( Copy(s, Pos(':',s)+1, Length(s)));
        if LCollection.Owner is TigSwatchList then
          TigSwatchList(LCollection.Owner).Description := s;
      end;
      inc(i);
    until s[1] = '#';

    {
    GIMP Palette
    Name: Topographic
    #
    #   "Topographic" color map - M. Davis
    #
      0   0   0	#000000
    }
    while LStrList[i][1] = '#' do
    begin
      Inc(i);
    end;

    if LStrList.Count > 0 then
    begin
      while i < LStrList.Count do
      begin
        s := LStrList[i];
        if Trim(s) <> '' then //safety when meet the empty line
          LoadItemFromString(ACollection.Add as TigSwatchItem,s);
        inc(i);
      end;
    end;
  finally
    LStrList.Free;
  end;

end;

procedure TigSwatch_GPLConverter.LoadItemFromString(AItem: TigSwatchItem; S: string);
var
  r,g,b : Byte;
  s2    : string;
begin
  {
  GIMP Palette
  Name: Tango Icon Theme
  Columns: 3
  #
  252 233  79	Butter 1
  237 212   0	Butter 2
  196 160   0	Butter 3
  138 226  52	Chameleon 1
  ...
  }
  r   := StrToInt(Trim(Copy(s,1,4)));
  g   := StrToInt(Trim(Copy(s,5,4)));
  b   := StrToInt(Trim(Copy(s,9,4)));
  s2  := Trim(Copy(s,13,255));

  AItem.Color       := (b shl 16) or (g shl 8) or r;
  AItem.DisplayName := s2;
end;

procedure TigSwatch_GPLConverter.SaveToStream(AStream: TStream;
  ACollection: TCollection);
var
  LStrList    : TStrings;
  i           : Integer;
  Color       : TColor;
  r, g, b     : Byte;
  s           : string;
//  LCollection : TigSwatchCollection;
  LItem       : TigSwatchItem;
begin
  if ACollection.Count <= 0 then
  begin
    Exit;
  end;

  //LCollection := TigSwatchCollection(ACollection);
  LStrList := TStringList.Create;
  try
      LStrList.Add(Format('%-6d %s',[ACollection.Count, TigSwatchList(ACollection.Owner).Description]));

      //z := StrToInt(Trim(Copy(LStrList[0],1,4)));
      for i := 0 to ACollection.Count -1 do
      begin
        //LoadItemFromString(LCollection.Add,LStrList[i]);
        LItem := ACollection.items[i] as TigSwatchItem;
        Color := LItem.Color;

        LStrList.Add(Format('%6d%6d%6d%s',[RedComponent(Color),
          GreenComponent(Color),BlueComponent(Color),LItem.DisplayName]))
      end;

    LStrList.SaveToStream(AStream);
  finally
    LStrList.Free;
  end;
end;

class function TigSwatch_GPLConverter.WantThis(AStream: TStream): Boolean;
begin
  Result := True;
end;

initialization
  TigSwatchList.RegisterConverterReader('GPL','Gimp/Inkscape/CinePaint/Krita Palette',0, TigSwatch_GPLConverter);
  //TigSwatchList.RegisterConverterWriter('SWA','GraphicsMagic Color Swatch',0, TigSwatch_GPLConverter);

end.
