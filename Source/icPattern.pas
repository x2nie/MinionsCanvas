unit icPattern;
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
  GR32, GR32_LowLevel,
{ miniGlue }
  icGrid,  icCore_rw;

type

  TicPatternItem = class(TicGridItem)
  private
    FColor: TColor;

    procedure SetColor(const Value: TColor);
  protected
    function GetEmpty: Boolean; override;
    procedure AssignTo(Dest: TPersistent); override;
    
  public
    constructor Create(Collection: TCollection); override;
    function CachedBitmap(const AWidth, AHeight: Integer): TBitmap32; override;
    function GetHint: string; override;
  published
    property Color : TColor read FColor write SetColor;
    property DisplayName;
  end;

  TicPatternList = class(TicGridList)
  private

    function GetItem(Index: Integer): TicPatternItem;
    procedure SetItem(Index: Integer; const Value: TicPatternItem);
  protected
    class function GetItemClass : TCollectionItemClass; override;
  public
    //constructor Create(AOwner:TComponent); override;
    function Add: TicPatternItem; reintroduce;
    class function GetFileReaders : TicFileFormatsList; override;
    class function GetFileWriters : TicFileFormatsList; override;

    procedure ItemPaint(ABuffer: TBitmap32; AIndex: Integer; ARect: TRect);  override; // called by grid needed by Theme

    property Items[Index: Integer]: TicPatternItem read GetItem write SetItem; default;
  end;

  {TicPatternCollection = class(TicGridCollection)
  public
    constructor Create(AOwner:TComponent); override;
  end;}

  TicPatternGrid = class(TicGrid)
  private
    function GetPatternList: TicPatternList;
    procedure SetPatternList(const Value: TicPatternList);
  published
    property PatternList : TicPatternList read GetPatternList write SetPatternList;  
  end;

procedure Register;
  
implementation

uses
  icCore_Items, //for registering class
  icPaintFuncs;

procedure Register;
begin
//  RegisterComponents('miniGlue', [TicPatternList, TicPatternGrid]);
end;

var
  UPatternReaders, UPatternWriters : TicFileFormatsList;

{ TicPatternItem }

constructor TicPatternItem.Create(Collection: TCollection);
begin
  inherited Create(Collection);
  FColor := clWhite;
end;

function TicPatternItem.CachedBitmap(const AWidth, AHeight: Integer): TBitmap32;
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
    FCachedBitmap.Clear(Color32(Self.Color));
  end;

  Result := FCachedBitmap;
end;

function TicPatternItem.GetHint: string;
var
  s : string;
begin
  s := '';

  if DisplayName <> '' then
    s := DisplayName + #13;
    
  Result := Format('%sred: %d, green: %d, blue: %d',[s,RedComponent(Color),
          GreenComponent(Color),BlueComponent(Color)]);
end;

procedure TicPatternItem.SetColor(const Value: TColor);
begin
  FColor := Value;
  Changed(False);
end;

function TicPatternItem.GetEmpty: Boolean;
begin
  Result := False; //nothing to countize. swatch always has surface
end;

procedure TicPatternItem.AssignTo(Dest: TPersistent);
begin
  inherited;
  {
    Ancestor must call inherited, to get benefit of inheritance of "Assign()"
  }
  if Dest is TicPatternItem then
  begin
    with TicPatternItem(Dest) do
    begin
      Color := self.Color;
    end;
  end;
end;

{ TicPatternCollection }


function TicPatternList.Add: TicPatternItem;
begin
  Result := TicPatternItem(inherited Add);
end;

class function TicPatternList.GetFileReaders: TicFileFormatsList;
begin
  if not Assigned(UPatternReaders) then
  begin
    UPatternReaders := TicFileFormatsList.Create;
  end;

  Result := UPatternReaders;
end;

class function TicPatternList.GetFileWriters: TicFileFormatsList;
begin
  if not Assigned(UPatternWriters) then
  begin
    UPatternWriters := TicFileFormatsList.Create;
  end;

  Result := UPatternWriters;
end;

function TicPatternList.GetItem(Index: Integer): TicPatternItem;
begin
  Result := TicPatternItem(inherited GetItem(Index));
end;

class function TicPatternList.GetItemClass: TCollectionItemClass;
begin
  result := TicPatternItem;
end;

procedure TicPatternList.ItemPaint(ABuffer: TBitmap32; AIndex: Integer;
  ARect: TRect);
begin
  if IsValidIndex(AIndex) then
  begin
    //ABuffer.Textout(ARect.Left,ARect.Top, PatternList[AIndex].DisplayName);
    if Items[AIndex].Color = clNone then
      DrawCheckerboardPattern(ABuffer, ARect, True )
    else
      ABuffer.FillRectS(ARect, Color32( Items[AIndex].Color) );
    ABuffer.FrameRectS(ARect, clTrGray32 );
  end;
end;

procedure TicPatternList.SetItem(Index: Integer;
  const Value: TicPatternItem);
begin
  inherited SetItem(Index, Value);
end;

{ TicPatternCollection }

{constructor TicPatternCollection.Create(AOwner: TComponent);
begin
  inherited Create(AOwner,TicPatternItem);
end;}

{ TicPatternGrid }


function TicPatternGrid.GetPatternList: TicPatternList;
begin
  Result := ItemList as TicPatternList;
end;

procedure TicPatternGrid.SetPatternList(const Value: TicPatternList);
begin
  ItemList := Value;
end;

initialization
  RegisterCoreList(TicPatternList);
end.
