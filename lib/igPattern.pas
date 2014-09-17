unit igPattern;
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
  igGrid,  igCore_rw;

type

  TigPatternItem = class(TigGridItem)
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

  TigPatternList = class(TigGridList)
  private

    function GetItem(Index: Integer): TigPatternItem;
    procedure SetItem(Index: Integer; const Value: TigPatternItem);
  protected
    class function GetItemClass : TCollectionItemClass; override;
  public
    //constructor Create(AOwner:TComponent); override;
    function Add: TigPatternItem; reintroduce;
    class function GetFileReaders : TigFileFormatsList; override;
    class function GetFileWriters : TigFileFormatsList; override;

    procedure ItemPaint(ABuffer: TBitmap32; AIndex: Integer; ARect: TRect);  override; // called by grid needed by Theme

    property Items[Index: Integer]: TigPatternItem read GetItem write SetItem; default;
  end;

  {TigPatternCollection = class(TigGridCollection)
  public
    constructor Create(AOwner:TComponent); override;
  end;}

  TigPatternGrid = class(TigGrid)
  private
    function GetPatternList: TigPatternList;
    procedure SetPatternList(const Value: TigPatternList);
  published
    property PatternList : TigPatternList read GetPatternList write SetPatternList;  
  end;

procedure Register;
  
implementation

uses
  igCore_Items, //for registering class
  igPaintFuncs;

procedure Register;
begin
//  RegisterComponents('miniGlue', [TigPatternList, TigPatternGrid]);
end;

var
  UPatternReaders, UPatternWriters : TigFileFormatsList;

{ TigPatternItem }

constructor TigPatternItem.Create(Collection: TCollection);
begin
  inherited Create(Collection);
  FColor := clWhite;
end;

function TigPatternItem.CachedBitmap(const AWidth, AHeight: Integer): TBitmap32;
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

function TigPatternItem.GetHint: string;
var
  s : string;
begin
  s := '';

  if DisplayName <> '' then
    s := DisplayName + #13;
    
  Result := Format('%sred: %d, green: %d, blue: %d',[s,RedComponent(Color),
          GreenComponent(Color),BlueComponent(Color)]);
end;

procedure TigPatternItem.SetColor(const Value: TColor);
begin
  FColor := Value;
  Changed(False);
end;

function TigPatternItem.GetEmpty: Boolean;
begin
  Result := False; //nothing to countize. swatch always has surface
end;

procedure TigPatternItem.AssignTo(Dest: TPersistent);
begin
  inherited;
  {
    Ancestor must call inherited, to get benefit of inheritance of "Assign()"
  }
  if Dest is TigPatternItem then
  begin
    with TigPatternItem(Dest) do
    begin
      Color := self.Color;
    end;
  end;
end;

{ TigPatternCollection }


function TigPatternList.Add: TigPatternItem;
begin
  Result := TigPatternItem(inherited Add);
end;

class function TigPatternList.GetFileReaders: TigFileFormatsList;
begin
  if not Assigned(UPatternReaders) then
  begin
    UPatternReaders := TigFileFormatsList.Create;
  end;

  Result := UPatternReaders;
end;

class function TigPatternList.GetFileWriters: TigFileFormatsList;
begin
  if not Assigned(UPatternWriters) then
  begin
    UPatternWriters := TigFileFormatsList.Create;
  end;

  Result := UPatternWriters;
end;

function TigPatternList.GetItem(Index: Integer): TigPatternItem;
begin
  Result := TigPatternItem(inherited GetItem(Index));
end;

class function TigPatternList.GetItemClass: TCollectionItemClass;
begin
  result := TigPatternItem;
end;

procedure TigPatternList.ItemPaint(ABuffer: TBitmap32; AIndex: Integer;
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

procedure TigPatternList.SetItem(Index: Integer;
  const Value: TigPatternItem);
begin
  inherited SetItem(Index, Value);
end;

{ TigPatternCollection }

{constructor TigPatternCollection.Create(AOwner: TComponent);
begin
  inherited Create(AOwner,TigPatternItem);
end;}

{ TigPatternGrid }


function TigPatternGrid.GetPatternList: TigPatternList;
begin
  Result := ItemList as TigPatternList;
end;

procedure TigPatternGrid.SetPatternList(const Value: TigPatternList);
begin
  ItemList := Value;
end;

initialization
  RegisterCoreList(TigPatternList);
end.
