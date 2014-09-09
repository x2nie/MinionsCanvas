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
 * Credits:
 *   HintShow is taken from ColorPickerButton.pas written by
 *      Dipl. Ing. Mike Lischke (public@lischke-online.de) (c) 1999
 *   bivGrid is taken from BIV bronco Image Viewer
 *      developed by x2nie +
 *      Ma Xiaoguang and Ma Xiaoming < gmbros [at] hotmail [dot] com>
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
{$IFDEF FPC}
  LCLIntf, LCLType, LMessages, Types,
{$ELSE}
  Windows, Messages,
{$ENDIF}
{ Standard }
  Classes, SysUtils, Graphics,
  Controls {CM_HINTSHOW}, Forms {TCMHintShow} , 
{ Graphics32 }
  GR32, GR32_LowLevel,
{ miniGlue }
  igCore_Items, igCore_rw,
{ BroncoImageViewer }
  bivGrid
  ;

type
  TigGridFlow = (ZWidth2Bottom,
                 NHeight2Right,
                 OSquaredGrow,
                 XStretchInnerGrow);
                 
  TigGridChangeLink = class(TigCoreChangeLink);//backward compatibility
  TigGridList = class; //later definition
  TigGridIndex = type Integer; //used for display gradient in property editor



  TigGridItem = class(TigCoreItem)
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

  
  TigGrid = class(TbivCustomGrid)
  private
    FChangeLink : TigGridChangeLink;
    FMyItemList : TigGridList;    //destroyable
    procedure CMHintShow(var Message: TMessage); message CM_HINTSHOW;
    
    function GetGridBasedList: TigGridList;
    procedure SetItemList(const Value: TigGridList);
  protected
    FItemList   : TigGridList;      //don't destroy. maybe external
    procedure ItemListChangedHandler(Sender: TObject);
    procedure DoCellPaint(ABuffer: TBitmap32; AIndex: Integer; ARect: TRect);  override; // called by Theme
    function  GetCellCount: Integer; override;
    procedure SetCellCount(const Value: Integer); override;

    property ItemList        : TigGridList   read GetGridBasedList write SetItemList;
  public
    constructor Create(AOwner: TComponent); override;
    function IsSelected(AIndex: Integer): Boolean; override;   //useful for rendering multiselect
    procedure SetSelected(AIndex: Integer); override; //useful in multi-select mode

  published
    property Align;
    property Options;
  end; 

  
  TigGridTheme = class(TbivTheme)
  protected
    procedure DoCellPaint(ABuffer: TBitmap32; AIndex: Integer; ARect: TRect);  override; //left align thumbnail on ListMode=True
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


{ TigGrid }

procedure TigGrid.CMHintShow(var Message:TMessage);
// determine hint message (tooltip) and out-of-hint rect

var
  LHoverIndex : Integer;
  LItem       : TigGridItem;
begin
  with TCMHintShow(Message) do
  begin
    if not ShowHint then
    begin
      Message.Result := 1;
    end
    else
    begin
      with HintInfo^ do
      begin
        // show that we want a hint
        Result := 0;
        

        LHoverIndex := Self.GetItemAtXY(CursorPos.X, CursorPos.Y);
          if Assigned(FItemList) and FItemList.IsValidIndex(LHoverIndex) then
          begin
            LItem       := FItemList.Items[LHoverIndex] as TigGridItem;
            HintStr     := LItem.GetHint;
            HideTimeout := 5000;
          end;
        
        // make the hint follow the mouse
        CursorRect := Rect(CursorPos.X, CursorPos.Y, CursorPos.X, CursorPos.Y);
      end;
    end;
  end;
end;

constructor TigGrid.Create(AOwner: TComponent);
begin
  inherited;
  FChangeLink          := TigGridChangeLink.Create;
  FChangeLink.OnChange := ItemListChangedHandler;
  FMargin := Point(0,0);
  CellWidth := 24;
  CellHeight:= 24;
end;

procedure TigGrid.DoCellPaint(ABuffer: TBitmap32; AIndex: Integer;
  ARect: TRect);
begin
  //demo:
  if Assigned(FItemList) and FItemList.IsValidIndex(AIndex) then
  begin
      ABuffer.Textout(ARect.Left,ARect.Top, FItemList.Items[AIndex].DisplayName);
      ABuffer.FrameRectS(ARect, clGray32);
  end;
  //ancestor may display item's surface

end;

function TigGrid.GetCellCount: Integer;
begin
  Result := 0;
  if Assigned(FItemList) then
    Result := FItemList.Count;
end;

function TigGrid.GetGridBasedList: TigGridList;
begin
  Result := FItemList;
end;

function TigGrid.IsSelected(AIndex: Integer): Boolean;
begin
  Result := False;
  if ItemList.IsValidIndex(AIndex) then
  begin
    Result := ItemList.Selections.IndexOf(ItemList[AIndex]) > -1;
  end;
end;

procedure TigGrid.ItemListChangedHandler(Sender: TObject);
begin
  if Assigned(Sender) and (Sender = FItemList) then
  begin
      {if FItemList.Count <> Self.Layers.Count then
      begin
        Self.Clear;
      end;
    InvalidateSize;}
    Invalidate;
  end;
end;

procedure TigGrid.SetCellCount(const Value: Integer);
begin
  //inherited; //do nothing. it should be a read only property.
end;

procedure TigGrid.SetItemList(const Value: TigGridList);
begin
  //detach if any previouse
  if FItemList <> nil then
  begin
    FItemList.UnRegisterChanges(FChangeLink);
    FItemList.RemoveFreeNotification(Self);
  end;

  //assigning
  FItemList := Value;

  //attach if any incoming
  if FItemList <> nil then
  begin
    FItemList.RegisterChanges(FChangeLink);
    FItemList.FreeNotification(Self);
  end;
  
  //InvalidateSize;
  //LayoutValid := False;
  Invalidate;
end;

procedure TigGrid.SetSelected(AIndex: Integer);
begin
  if ItemList.IsValidIndex(AIndex) then
  begin
    if not Options.MultiSelect then
      ItemList.Selections.Clear;
    ItemList.Selections.Add(ItemList[AIndex]);
    ItemList.Changed;
  end;

end;

{ TigGridTheme }

procedure TigGridTheme.DoCellPaint(ABuffer: TBitmap32; AIndex: Integer;
  ARect: TRect);
begin
  inherited;

end;

end.

