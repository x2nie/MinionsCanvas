unit igGrid;
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
  igCore_Items, igCore_rw;

type
  TigGridFlow = (ZWidth2Bottom,
                 NHeight2Right,
                 OSquaredGrow,
                 XStretchInnerGrow);
                 
  TigGridChangeLink = class(TigCoreChangeLink);//backward compatibility
  TigGridList = class; //later definition
  TigGridIndex = type Integer; //used for display gradient in property editor

  TigGridItem = class(TigCoreItem)
  private

  protected
    FCachedBitmap      : TBitmap32;
    FCachedBitmapValid : Boolean;

  public
    function CachedBitmap(const AWidth, AHeight: Integer): TBitmap32;virtual;
    function GetHint:string; virtual;
  published
  end;


  TigGridCollection = class(TigCoreCollection)
  private
    //FOnChange              : TNotifyEvent;
  protected

  public
    constructor Create(AOwner: TComponent); override;
    function Draw(const AIndex: Integer; const ACanvas: TCanvas;
      const ARect: TRect): Boolean;

    //property OnChange : TNotifyEvent read FOnChange write FOnChange;
    
  end;
  TigGridCollectionClass = class of TigGridCollection;


  
  {TigGridList}
  TigGridList = class(TigCoreList)
  end;


  
  TigGridListClass = class of TigGridList;

  IGridBasedListSupport = interface
    //used by property editor in design time
    //implement it in various component
    ['{6CC76557-5CA1-4B58-8D90-CDE901548414}']
    function GetGridBasedList: TigGridList;

  end;  

implementation

uses
{ miniGlue }
  igPaintFuncs;


{ TigGridItem }


function TigGridItem.CachedBitmap(
  const AWidth, AHeight: Integer): TBitmap32;
begin
  Result := nil; //descendant must override;

  if Assigned(FCachedBitmap) then
    Result := FCachedBitmap;
end;

function TigGridItem.GetHint: string;
begin
  Result := DisplayName;
end;

{ TigGridCollection }

constructor TigGridCollection.Create(AOwner: TComponent);
begin
  Create(AOwner, TigGridItem);
end;

function TigGridCollection.Draw(const AIndex: Integer;
  const ACanvas: TCanvas; const ARect: TRect): Boolean;
var
  LBmp : TBitmap32;
  LRect: TRect;
  LItem: TigGridItem;
begin
  Result := False;

  if not IsValidIndex(AIndex) then
    raise Exception.Create('GridBasedCollection.Draw() -- Error: invalid index.');

  if not Assigned(ACanvas) then
  begin
    raise Exception.Create('GridBasedCollection.Draw() -- Error: Canvas is nil.');
  end;

  if GR32.IsRectEmpty(ARect) then
  begin
    raise Exception.Create('GridBasedCollection.Draw() -- Error: Rect is empty.');
  end;

  with ARect do
  begin
    LRect := MakeRect(0, 0, Right - Left, Bottom - Top);
  end;

  LItem := TigGridItem(Items[AIndex]);

  LBmp := TBitmap32.Create;
  try
    LBmp.SetSize(LRect.Right + 1, LRect.Bottom + 1);
    DrawCheckerboardPattern(LBmp, LBmp.BoundsRect);

    LBmp.Draw(0, 0, LItem.CachedBitmap(LRect.Right + 1, LRect.Bottom + 1));
    LBmp.DrawTo(ACanvas.Handle, ARect.Left, ARect.Top);
  finally
    LBmp.Free;
  end;
end;


(*procedure TigGridCollection.LoadFromStream(const AStream: TStream);
var
  LFirstStreamPosition: Int64;
  i                   : Integer;
  LReader             : TigConverter;
  LReaderClass        : TigConverterClass;
  LReaders            : TigFileFormatsList;
  LReaderAccepted     : Boolean;
  //SelfClass           : TigGridCollectionClass;

  {procedure AllYouCanEat(); //this is the name of a menu in restourants
  begin
    //FCurrentStreamFileName
    LReader := LReaderClass.Create;
        try
          LReader.LoadFromStream(Stream,Self);
        finally
          LReader.Free;
        end;
  end;}

  function SatisfiedHungry(AReaderClass : TigConverterClass): Boolean;
  begin
    //Result := False;
    //  AReaderClass := LReaders.Readers(i);

    //do test
    Result := AReaderClass.WantThis(AStream);

    //set to beginning stream
    AStream.Seek(LFirstStreamPosition,soFromBeginning);

    //do real dinner!
    if Result then
    begin
      LReader := AReaderClass.Create;
      try
         LReader.LoadFromStream(AStream, Self);
      finally
        LReader.Free;
      end;
    end
  end;

begin
  BeginUpdate;
  try
    //In case current stream position is not zero, we remember the position.
    LFirstStreamPosition := AStream.Position;
    LReaders             := GetFileReaders;

    //LEVEL 1, find the extention
    if FCurrentStreamFileName <> '' then
    begin
      LReaderClass := LReaders.FindExt(ExtractFileExt(FCurrentStreamFileName));

      if Assigned(LReaderClass) then
      begin
        if SatisfiedHungry(LReaderClass) then
          Exit;
      end;
    end;


    //LEVEL 2 ASK THEM ALL
    // Because many reader has same MagicWord as their signature,
    // we want to ask all of them,
    // when anyone is accepting, we break.
    // if UGradientReaders.Find(IntToHex(MagicWord,8),i) then
    //  (UGradientReaders.Objects[i] as TigCustomGradientReader).LoadFromStream(Stream,Self);
    for i := 0 to (LReaders.Count - 1) do
    begin
      LReaderClass := LReaders.Readers(i);

      if SatisfiedHungry(LReaderClass) then
        Break;
      {
      //do test
      LReaderAccepted := LReaderClass.WantThis(Stream);

      //set to beginning stream
      Stream.Seek(LFirstStreamPosition,soFromBeginning);

      //do real dinner!
      if LReaderAccepted then
      begin
        AllYouCanEat;
        Break;
      end}
    end;

  finally
    EndUpdate;
    Changed;
  end;
end;
*)


end.

