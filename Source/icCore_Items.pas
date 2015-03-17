unit icCore_Items;
{unit gmGridBased}

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
 *  x2nie - Fathony Luthfillah  <x2nie@yahoo.com>
 *
 * Contributor(s):
 *
 * ***** END LICENSE BLOCK ***** *)



interface

uses
  {$IFDEF FPC}
    LCLIntf, LCLType, LMessages, Types,
  {$ELSE}
    //Windows, Messages,
  {$ENDIF}
{ Standard }
  {Types,} Classes, SysUtils, Graphics, Contnrs,
{ Graphics32 }
  GR32, GR32_LowLevel, GR32_Containers,
  icCore_rw, icCore_Viewer;


type
  TicCoreList = class; //later definition
  TicCoreListClass = class of TicCoreList;
  TicCoreIndex = type Integer; //used for display gradient in property editor
  
  IgmItemListSupport = interface
    //used by property editor in design time
    //implement it in various component
    ['{87ABF976-1F61-448F-8892-A9DBD3186F49}']
    //function GetItemList: TicCoreList;
    function GetItemListClass: TicCoreListClass;
  end;


{ TicCoreItem }

  TicCoreItem = class(TCollectionItem)
  private

  protected
    FDisplayName     : string;
    procedure SetDisplayName(const Value: string); override;
    function GetDisplayName: string; override;
    function GetEmpty: Boolean; virtual; abstract;
    function GetItemList : TicCoreList;
    procedure DefineProperties(Filer: TFiler); override;
    function Equals(AItem: TicCoreItem): Boolean; virtual;

    procedure AssignTo(Dest: TPersistent); override;

    //These are used for undo/redo and another native stream format.
    //Since TFiller cant load such Pointer & Array of published properties.
    procedure ReadData(AStream: TStream); virtual; //LoadFromStream
    procedure WriteData(AStream: TStream); virtual; //SaveToStream
  public
    constructor Create(ACollection: TCollection); override;

    property Empty: Boolean read GetEmpty;
  published
    property DisplayName;// read GetDisplayName write SetDisplayName;
  end;
  //TgmCoreItemClass = class of TicCoreItem;


{ TicCoreCollection } 

  TicCoreCollection = class(TOwnedCollection)
  private
    FOnChange: TNotifyEvent;
    //FFileName: TFilename;
  protected
    procedure Update(Item: TCollectionItem); override;
  public
    constructor Create(AOwner: TComponent); overload; virtual;
    constructor Create(AOwner: TComponent; GetItemClass: TCollectionItemClass);overload;virtual;
    function IsValidIndex(index : Integer):Boolean;virtual;
    property OnChange             : TNotifyEvent    read FOnChange        write FOnChange;
  end;
  TicCoreCollectionClass = class of TicCoreCollection;


{ TChangeLink }

  TicCoreChangeLink = class(TObject)
  private
    FSender: TicCoreList;
    FOnChange: TNotifyEvent;
  public
    destructor Destroy; override;
    procedure Change; dynamic;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property Sender: TicCoreList read FSender write FSender;
  end;


{ TicSelectionItem }

  // useful for multi-select mode
  TicSelectionItem = class(TObjectList)
  private
    function GetItem(Index: Integer): TicCoreItem;
    procedure SetItem(Index: Integer; const Value: TicCoreItem);

  public
    property Items[Index: Integer]: TicCoreItem read GetItem write SetItem; default;
  end;


{ TicCoreList }

  {VCL component, usefull in designtime}
  TicCoreList = class(TComponent,IStreamPersist)
  private
    FClients: TList;
    FOnChange: TNotifyEvent;
    FFileName: TFilename;
    FCurrentStreamFileName : TFileName;
    FSelections: TicSelectionItem; //for temporary
    function GetCount: Integer;

    procedure GridChangedHandler(Sender:TObject);
    function GeFirstItem: TicCoreItem;
    function GetLastItem: TicCoreItem;
    { Private declarations }
  protected
    { Protected declarations }
    FCollection: TicCoreCollection;
    procedure AssignTo(Dest: TPersistent); override;
    
    procedure SetCollection(const Value: TicCoreCollection);
    procedure Changed; dynamic;
    function GetItem(Index: TicCoreIndex): TicCoreItem;
    procedure SetItem(Index: TicCoreIndex; const Value: TicCoreItem);

    {"Simulating class properties in (Win32) Delphi"
    http://delphi.about.com/library/weekly/aa031505a.htm
    While (Win32) Delphi enables you to create class (static) methods
    (function or procedure), you cannot mark a property of a class to be a
    class (static) property. False. You can! Let's see how to simulate
    class properties using typed constants.}
    class function GetFileReaders : TicFileFormatsList; virtual;
    class function GetFileWriters : TicFileFormatsList; virtual;



    //class function CollectionClass : TicCoreCollectionClass;virtual;

    class function GetItemClass : TCollectionItemClass; virtual;
    //property Collection : TicCoreCollection read FCollection write SetCollection;

  public
    { Public declarations }
    function Add : TicCoreItem; virtual;
    procedure Clear; virtual;
    procedure BeginUpdate; virtual;
    procedure EndUpdate; virtual;

    function IsValidIndex(index : Integer):Boolean;

    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    {collaborative viewer/modification}
    procedure RegisterChanges(Value: TicCoreChangeLink);
    procedure UnRegisterChanges(Value: TicCoreChangeLink);

    //OpenDialog\SaveDialog
    class function ReadersFilter: string;
    class function WritersFilter: string;


    class procedure RegisterConverterReader(const AExtension, ADescription: string;
      DescID: Integer; AReaderClass: TicConverterClass);
    class procedure RegisterConverterWriter(const AExtension, ADescription: string;
      DescID: Integer; AReaderClass: TicConverterClass);


    procedure LoadFromFile(const FileName: string); virtual;
    procedure LoadFromStream(AStream: TStream); virtual;
    procedure SaveToFile(const FileName: string); virtual;
    procedure SaveToStream(AStream: TStream); virtual;

    property FileName : TFilename read FFileName write FFileName;
    property Count: Integer read GetCount;
    property Items[Index: TicCoreIndex]: TicCoreItem read GetItem write SetItem; default;
    property Last : TicCoreItem read GetLastItem;
    property First : TicCoreItem read GeFirstItem;
  public
    { selection }
    procedure ClearSelection;
    procedure SelectAll;
    function IsSelected(AItem: TicCoreItem):Boolean;
    property Selections: TicSelectionItem read FSelections;
    //property ItemIndex : TicCoreIndex read FItemIndex write FItemIndex; //for display in property editor as combobox
  published
    { Published declarations }
    property Collection : TicCoreCollection read FCollection write SetCollection;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;


//============== CHUNK CLASSES =========================

  TicChunk = record
    MagicWord   : array[0..3] of Char; //such as SHPE
    HeaderSize  : Word; //in bytes. also for indicating the version used for this chunk
    Count       : Word; //such ChildrenCount, PointsCount
    ContentSize : LongWord;//plan for future
  end;

var
  GCoreListList : TClassList;
  GCoreViewerList : TClassList;

procedure RegisterCoreList(ACoreListClass: TicCoreListClass);
procedure RegisterCoreViewer(ACoreViewerClass: TicCoreViewerClass);

implementation

uses
  icBase;


var
  UCoreItemsReaders, UCoreItemsWriters : TicFileFormatsList;
  UCoreItemKernelList: TClassList;

procedure RegisterCoreList(ACoreListClass: TicCoreListClass);
begin
  if not Assigned(GCoreListList) then GCoreListList := TClassList.Create;
  GCoreListList.Add(ACoreListClass);
end;

procedure RegisterCoreViewer(ACoreViewerClass: TicCoreViewerClass);
begin
  if not Assigned(GCoreViewerList) then GCoreViewerList := TClassList.Create;
  GCoreViewerList.Add(ACoreViewerClass);
end;


{ TicCoresItem }


constructor TicCoreItem.Create(ACollection: TCollection);
begin
  inherited Create(ACollection);
  FDisplayName := 'Custom';
end;

procedure TicCoreItem.DefineProperties(Filer: TFiler);
  function DoWrite: Boolean;
  begin
    if Filer.Ancestor <> nil then
      Result := not (Filer.Ancestor is TicCoreItem) or
        not Equals(TicCoreItem(Filer.Ancestor))
    else
      Result := not Empty;
  end;

begin
  inherited;
  Filer.DefineBinaryProperty('Data', ReadData, WriteData, DoWrite);
end;

function TicCoreItem.Equals(AItem: TicCoreItem): Boolean;
var
  MyImage, GraphicsImage: TMemoryStream;
begin
  Result := (AItem <> nil) and (ClassType = AItem.ClassType);
  if Empty or AItem.Empty then
  begin
    Result := Empty and AItem.Empty;
    Exit;
  end;
  if Result then
  begin
    MyImage := TMemoryStream.Create;
    try
      WriteData(MyImage);
      GraphicsImage := TMemoryStream.Create;
      try
        AItem.WriteData(GraphicsImage);
        Result := (MyImage.Size = GraphicsImage.Size) and
          CompareMem(MyImage.Memory, GraphicsImage.Memory, MyImage.Size);
      finally
        GraphicsImage.Free;
      end;
    finally
      MyImage.Free;
    end;
  end;
end;

procedure TicCoreItem.ReadData(AStream: TStream);
begin
  //LoadFromStream(Stream);
end;

procedure TicCoreItem.WriteData(AStream: TStream);
begin
  //SaveToStream(Stream);
end;

function TicCoreItem.GetDisplayName: string;
begin
  Result := FDisplayName;
end;


function TicCoreItem.GetItemList: TicCoreList;
begin
  Result := nil;
  if Assigned(Collection) then
    if Collection.Owner is TicCoreList then
      Result := Collection.Owner as TicCoreList;
end;

procedure TicCoreItem.SetDisplayName(const Value: string);
begin
  FDisplayName := Value;
  //inherited; has no affect
  Self.Changed(False);
    //GIntegrator.SelectionChanged;
end;

{ TicCoreCollection }

constructor TicCoreCollection.Create(AOwner: TComponent);
begin
  Create(AOwner,TicCoreItem);
end;

constructor TicCoreCollection.Create(AOwner: TComponent;
  GetItemClass: TCollectionItemClass);
begin
  inherited Create(AOwner,GetItemClass);
end;


function TicCoreCollection.IsValidIndex(index: Integer): Boolean;
begin
  Result := (index > -1) and (index < Count);
end;


procedure TicCoreCollection.Update(Item: TCollectionItem);
begin
  inherited;
  if Assigned(FOnChange) then
  begin
    FOnChange(Self);
  end;
end;


{ TicCoreChangeLink }

procedure TicCoreChangeLink.Change;
begin
  if Assigned(FOnChange) then FOnChange(Sender);
end;

destructor TicCoreChangeLink.Destroy;
begin
  if Sender <> nil then Sender.UnRegisterChanges(Self);
  inherited;
end;

{ TicCoreList }

procedure TicCoreList.Changed;
var
  I: Integer;
begin
  if FClients <> nil then
    for I := 0 to FClients.Count - 1 do
      TicCoreChangeLink(FClients[I]).Change;
  if Assigned(FOnChange) then FOnChange(Self);

end;

{class function TicCoreList.CollectionClass: TicCoreCollectionClass;
begin
  Result := TicCoreCollection;//ascendant must override it
end;}

constructor TicCoreList.Create(AOwner: TComponent);
begin
  inherited;
  FClients := TList.Create;
  FCollection := TicCoreCollection.Create(Self, GetItemClass );
  FSelections := TicSelectionItem.Create(False); 
  {$IFNDEF FPC}
  ///disabled as need FPC
  FCollection.FOnChange := GridChangedHandler;
  {$ENDIF}
end;

destructor TicCoreList.Destroy;
begin
  while FClients.Count > 0 do
    UnRegisterChanges(TicCoreChangeLink(FClients.Last));
  FClients.Free;
  FClients := nil;
  FSelections.Free;
  inherited;
end;

function TicCoreList.GetCount: Integer;
begin
  Result := Collection.Count;
end;



class function TicCoreList.GetFileReaders: TicFileFormatsList;
begin
 if not Assigned(UCoreItemsReaders) then
  begin
    UCoreItemsReaders := TicFileFormatsList.Create;
  end;

  Result := UCoreItemsReaders;
end;

class function TicCoreList.GetFileWriters: TicFileFormatsList;
begin
if not Assigned(UCoreItemsWriters) then
  begin
    UCoreItemsWriters := TicFileFormatsList.Create;
  end;

  Result := UCoreItemsWriters;
end;

procedure TicCoreList.GridChangedHandler(Sender: TObject);
begin
  Changed;
end;

class function TicCoreList.GetItemClass: TCollectionItemClass;
begin
  Result := TicCoreItem;
end;

procedure TicCoreList.LoadFromFile(const FileName: string);
var
  Stream: TStream;
begin
  self.FileName := FileName;
  Stream := TFileStream.Create( ExpandFileName(FileName), fmOpenRead or fmShareDenyWrite);
  //Stream.Seek(0,soFromBeginning);
  try
    LoadFromStream(Stream);
  finally
    Stream.Free;
  end;
end;

procedure TicCoreList.LoadFromStream(AStream: TStream);
{var
  //LFileHeader         : TicGradientFileHeader;
  LFirstStreamPosition: Int64;
  i                   : Integer;
  LReader             : TicConverter;
  LReaderClass        : TicConverterClass;
  LReaders            : TicFileFormatsList;
  LReaderAccepted     : Boolean;
  //SelfClass           : TicCoreCollectionClass;
}
var
  LFirstStreamPosition: Int64;
  i                   : Integer;
  LReader             : TicConverter;
  LReaderClass        : TicConverterClass;
  LReaders            : TicFileFormatsList;
  LReaderAccepted     : Boolean;
  //SelfClass           : TicCoreCollectionClass;

  {procedure AllYouCanEat(); //this is the name of a menu in restaurants
  begin
    //FCurrentStreamFileName
    LReader := LReaderClass.Create;
        try
          LReader.LoadFromStream(Stream,Self);
        finally
          LReader.Free;
        end;
  end;}

  function SatisfiedHungry(AReaderClass : TicConverterClass): Boolean;
  begin
    //Result := False;

    //do test
    Result := AReaderClass.WantThis(AStream);

    //set to beginning stream
    AStream.Seek(LFirstStreamPosition,soFromBeginning);

    //do real dinner!
    if Result then
    begin
      LReader := AReaderClass.Create;
      try
         LReader.LoadFromStream(AStream, Self.FCollection);
      finally
        LReader.Free;
      end;
    end
  end;
var
  LMatchReaders : TicArrayOfConverterClass;
begin
  FCollection.BeginUpdate;
  try
    //In case current stream position is not zero, we remember the position.
    LFirstStreamPosition := AStream.Position;

    LReaders             := GetFileReaders;

    //LEVEL 1, find the extention
    if FCurrentStreamFileName <> '' then
    begin

      LMatchReaders := LReaders.ReadersByExt(ExtractFileExt(FCurrentStreamFileName));

      for i := 0 to Length(LMatchReaders) -1  do
      begin
        if SatisfiedHungry(LMatchReaders[i]) then
          Exit; //dont worry, the "finally" will be always executed.
      end;
    end;


    //LEVEL 2 ASK THEM ALL
    // Because many reader has same MagicWord as their signature,
    // we want to ask all of them,
    // when anyone is accepting, we break.
    // if UGradientReaders.Find(IntToHex(MagicWord,8),i) then
    //  (UGradientReaders.Objects[i] as TicCustomGradientReader).LoadFromStream(Stream,Self);
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
    FCollection.EndUpdate;
    FCollection.Changed;
  end;

(*begin
  BeginUpdate;
  try
    //In case current stream position is not zero, we remember the position.
    LFirstStreamPosition := Stream.Position;


    // Because many reader has same MagicWord as their signature,
    // we make a beauty contest: the way to choose a queen quickly.
    // when we anyone dealed to eat the rest of stream, this ceremony closed. :)
    // So, be carefull when make order list of "uses" unit of "stitch_rwXXX," !


    LReaders := GetFileReaders;
    for i := 0 to (LReaders.Count -1) do
    begin
      //Okay, there a beautifull guest coming.
      LReaderClass := LReaders.Readers(i);

      //We let them to taste the appetise:
      //Ask if she want to really eat the maincourse ?
      LReaderAccepted := LReaderClass.WantThis(Stream);

      //However, we back to the kitchen first, to prepare
      Stream.Seek(LFirstStreamPosition,soFromBeginning);

      //Here we go!
      //If she made an order menu, we are servicing her for the real dinner
      if LReaderAccepted then
      begin
        LReader := LReaderClass.Create;
        try
          LReader.LoadFromStream(Stream,Self);
        finally
          LReader.Free;
        end;

        //Okay, we've serviced one queen. we quit!
        Break;
      end

      //Oh? we haven't yet meet a queen? ask next other guest to be our queen if any.
    end;
  finally
    EndUpdate;
    Changed;
  end;
*)

end;

class function TicCoreList.ReadersFilter: string;
var
  LFilters: string;
begin
  GetFileReaders.BuildFilterStrings(TicConverter, Result, LFilters);
end;

procedure TicCoreList.RegisterChanges(Value: TicCoreChangeLink);
begin
  Value.Sender := Self;
  if FClients <> nil then FClients.Add(Value);
end;



class procedure TicCoreList.RegisterConverterReader(const AExtension,
  ADescription: string; DescID: Integer; AReaderClass: TicConverterClass);
begin
  self.GetFileReaders.Add(AExtension, ADescription, DescID,AReaderClass);
end;


class procedure TicCoreList.RegisterConverterWriter(const AExtension,
  ADescription: string; DescID: Integer; AReaderClass: TicConverterClass);
begin
  self.GetFileWriters.Add(AExtension, ADescription, DescID,AReaderClass);
end;

procedure TicCoreList.SaveToFile(const FileName: string);
var
  LStream: TStream;
begin
  FCurrentStreamFileName := ExpandFileName(FileName); //some reader/writer always accept; sadly sometime they wrong. we anticipate this accident

  LStream := TFileStream.Create(FCurrentStreamFileName, fmCreate);
  try
    SaveToStream(LStream);
  finally
    LStream.Free;
  end;
end;

procedure TicCoreList.SaveToStream(AStream: TStream);
var
  //LFileHeader         : TicGradientFileHeader;
  LFirstStreamPosition: Int64;
  i                   : Integer;
  LWriter             : TicConverter;
  LWriterClass        : TicConverterClass;
  LWriters            : TicFileFormatsList;
  LWriterAccepted     : Boolean;
  //SelfClass           : TicCoreCollectionClass;
begin
  //BeginUpdate;
  try
    //In case current stream position is not zero, we remember the position.
    LFirstStreamPosition := AStream.Position;


    // Because many reader has same MagicWord as their signature,
    // we make a beauty contest: the way to choose a queen quickly.
    // when we anyone dealed to eat the rest of stream, this ceremony closed. :)
    // So, be carefull when make order list of "uses" unit of "stitch_rwXXX," !


    LWriters := GetFileWriters;

    //LEVEL 1, find the extention
    if FCurrentStreamFileName <> '' then
    begin
      LWriterClass  := LWriters.FindExt(ExtractFileExt(FCurrentStreamFileName));
      if Assigned(LWriterClass) then
      begin
        LWriter := LWriterClass.Create;
        try
          LWriter.SaveToStream(AStream,Self.FCollection);
        finally
          LWriter.Free;
        end;
      end;
    end;
    { TODO -ox2nie -cmedium : 
Until now, we cant make sure wether first selected TWriter is as same as user prever to used.
Perhap we must integrated te Writers with the TSaveDialog }

  finally
    //EndUpdate;
    //Changed;    
  end;
end;

procedure TicCoreList.SetCollection(const Value: TicCoreCollection);
begin
  FCollection.Assign(Value);
end;

procedure TicCoreList.UnRegisterChanges(Value: TicCoreChangeLink);
var
  I: Integer;
begin
  if FClients <> nil then
    for I := 0 to FClients.Count - 1 do
      if TicCoreChangeLink(FClients[I]) = Value then
      begin
        Value.Sender := nil;
        FClients.Delete(I);
        Break;
      end;
end;

class function TicCoreList.WritersFilter: string;
var
  LFilters: string;
begin
  GetFileWriters.BuildFilterStrings(TicConverter, Result, LFilters);
end;


function TicCoreList.Add: TicCoreItem;
begin
  Result := TicCoreItem(FCollection.Add);
end;

function TicCoreList.GetItem(Index: TicCoreIndex): TicCoreItem;
begin
  Result := nil;
  if (index >= 0) and (index < self.Count) then
    Result := FCollection.GetItem(Index) as TicCoreItem;
end;

procedure TicCoreList.SetItem(Index: TicCoreIndex;
  const Value: TicCoreItem);
begin
  FCollection.Items[Index].Assign(Value);
end;

procedure TicCoreList.BeginUpdate;
begin
  FCollection.BeginUpdate;
end;

procedure TicCoreList.EndUpdate;
begin
  FCollection.EndUpdate;
end;

procedure TicCoreList.Clear;
begin
  FSelections.Clear;
  FCollection.Clear;
end;

function TicCoreList.IsValidIndex(index: Integer): Boolean;
begin
  Result := (index > -1) and (index < Count);
end;

function TicCoreList.GeFirstItem: TicCoreItem;
begin
  Result := Items[0]; //validation in self.getitem
end;

function TicCoreList.GetLastItem: TicCoreItem;
begin
  Result := Items[Count -1]; //validation in self.getitem
end;

procedure TicCoreList.ClearSelection;
begin
  FSelections.Clear;
end;

function TicCoreList.IsSelected(AItem: TicCoreItem): Boolean;
begin
  Result := Self.FSelections.IndexOf(AItem) > -1;
end;

procedure TicCoreList.AssignTo(Dest: TPersistent);
begin
{
  inherited;
  For now, since the AssignTo inherited method is directly came from TPersistent
  it will error to call.

  But, Ancestor must call inherited, to get benefit of inheritance of "Assign()"
  }
  if Dest is TicCoreList then
  begin
    with TicCoreList(Dest) do
    begin
      Collection.BeginUpdate;
      Collection.Assign(self.Collection);
      Collection.EndUpdate;
    end;
  end;

end;

procedure TicCoreList.SelectAll;
var i :Integer;
begin
  for i := 0 to Collection.Count-1 do
  begin
    with self.Selections do
    begin
      if IndexOf(Collection.Items[i]) < 0 then
        Add(Collection.Items[i]);
    end;
  end;
end;

{ TicSelectionItem }

function TicSelectionItem.GetItem(Index: Integer): TicCoreItem;
begin
//  Result := inherited Items[index] as TicCoreItem;
  Result := TicCoreItem(inherited Items[index]);
end;

procedure TicSelectionItem.SetItem(Index: Integer;
  const Value: TicCoreItem);
begin
  inherited Items[index] := Value;
end;

procedure TicCoreItem.AssignTo(Dest: TPersistent);
begin
  {
  inherited;
  For now, since the AssignTo inherited method is directly came from TPersistent
  it will error to call.

  But, Ancestor must call inherited, to get benefit of inheritance of "Assign()"
  }
  if Dest is TicCoreItem then
  begin
    with TicCoreItem(Dest) do
    begin
      DisplayName := Self.DisplayName;
    end;
  end;

end;

initialization

finalization
  if Assigned(GCoreListList) then
    GCoreListList.Free;
  if Assigned(GCoreViewerList) then
    GCoreViewerList.Free;

end.
