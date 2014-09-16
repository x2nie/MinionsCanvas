unit igSwatch;
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

  TigSwatchItem = class(TigGridItem)
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

  TigSwatchList = class(TigGridList)
  private

    function GetItem(Index: Integer): TigSwatchItem;
    procedure SetItem(Index: Integer; const Value: TigSwatchItem);
  protected
    class function GetItemClass : TCollectionItemClass; override;
  public
    //constructor Create(AOwner:TComponent); override;
    function Add: TigSwatchItem;
    class function GetFileReaders : TigFileFormatsList; override;
    class function GetFileWriters : TigFileFormatsList; override;

    procedure ItemPaint(ABuffer: TBitmap32; AIndex: Integer; ARect: TRect);  override; // called by grid needed by Theme

    property Items[Index: Integer]: TigSwatchItem read GetItem write SetItem; default;
  end;

  TigSwatchCollection = class(TigGridCollection)
  public
    constructor Create(AOwner:TComponent); override;
  end;

  TigSwatchGrid = class(TigGrid)
  private
    function GetSwatchList: TigSwatchList;
    procedure SetSwatchList(const Value: TigSwatchList);
  published
    property SwatchList : TigSwatchList read GetSwatchList write SetSwatchList;  
  end;

procedure Register;
  
implementation

uses
  igCore_Items, //for registering class
  igPaintFuncs;

procedure Register;
begin
//  RegisterComponents('miniGlue', [TigSwatchList, TigSwatchGrid]);
end;

var
  USwatchReaders, USwatchWriters : TigFileFormatsList;

{ TigSwatchItem }

constructor TigSwatchItem.Create(Collection: TCollection);
begin
  inherited Create(Collection);
  FColor := clWhite;
end;

function TigSwatchItem.CachedBitmap(const AWidth, AHeight: Integer): TBitmap32;
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

function TigSwatchItem.GetHint: string;
var
  s : string;
begin
  s := '';

  if DisplayName <> '' then
    s := DisplayName + #13;
    
  Result := Format('%sred: %d, green: %d, blue: %d',[s,RedComponent(Color),
          GreenComponent(Color),BlueComponent(Color)]);
end;

procedure TigSwatchItem.SetColor(const Value: TColor);
begin
  FColor := Value;
  Changed(False);
end;

function TigSwatchItem.GetEmpty: Boolean;
begin
  Result := False; //nothing to countize. swatch always has surface
end;

procedure TigSwatchItem.AssignTo(Dest: TPersistent);
begin
  inherited;
  {
    Ancestor must call inherited, to get benefit of inheritance of "Assign()"
  }
  if Dest is TigSwatchItem then
  begin
    with TigSwatchItem(Dest) do
    begin
      Color := self.Color;
    end;
  end;
end;

{ TigSwatchCollection }


function TigSwatchList.Add: TigSwatchItem;
begin
  Result := TigSwatchItem(inherited Add);
end;

class function TigSwatchList.GetFileReaders: TigFileFormatsList;
begin
  if not Assigned(USwatchReaders) then
  begin
    USwatchReaders := TigFileFormatsList.Create;
  end;

  Result := USwatchReaders;
end;

class function TigSwatchList.GetFileWriters: TigFileFormatsList;
begin
  if not Assigned(USwatchWriters) then
  begin
    USwatchWriters := TigFileFormatsList.Create;
  end;

  Result := USwatchWriters;
end;

function TigSwatchList.GetItem(Index: Integer): TigSwatchItem;
begin
  Result := TigSwatchItem(inherited GetItem(Index));
end;

class function TigSwatchList.GetItemClass: TCollectionItemClass;
begin
  result := TigSwatchItem;
end;

procedure TigSwatchList.ItemPaint(ABuffer: TBitmap32; AIndex: Integer;
  ARect: TRect);
begin
  if IsValidIndex(AIndex) then
  begin
    //ABuffer.Textout(ARect.Left,ARect.Top, SwatchList[AIndex].DisplayName);
    if Items[AIndex].Color = clNone then
      DrawCheckerboardPattern(ABuffer, ARect, True )
    else
      ABuffer.FillRectS(ARect, Color32( Items[AIndex].Color) );
    ABuffer.FrameRectS(ARect, clTrGray32 );
  end;
end;

procedure TigSwatchList.SetItem(Index: Integer;
  const Value: TigSwatchItem);
begin
  inherited SetItem(Index, Value);
end;

{ TigSwatchCollection }

constructor TigSwatchCollection.Create(AOwner: TComponent);
begin
  inherited Create(AOwner,TigSwatchItem);
end;

{ TigSwatchGrid }


function TigSwatchGrid.GetSwatchList: TigSwatchList;
begin
  Result := ItemList as TigSwatchList;
end;

procedure TigSwatchGrid.SetSwatchList(const Value: TigSwatchList);
begin
  ItemList := Value;
end;

initialization
  RegisterCoreList(TigSwatchList);
end.
