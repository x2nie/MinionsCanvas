unit igCore_Items;
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
  igCore_rw, igCore_Viewer;


type
  TigCoreList = class; //later definition
  TigCoreListClass = class of TigCoreList;
  TigCoreIndex = type Integer; //used for display gradient in property editor
  IgmItemListSupport = interface
    //used by property editor in design time
    //implement it in various component
    ['{87ABF976-1F61-448F-8892-A9DBD3186F49}']
    //function GetItemList: TigCoreList;
    function GetItemListClass: TigCoreListClass;
  end;

  TigCoreItem = class(TCollectionItem)
  private

  protected
    FDisplayName     : string;
    procedure SetDisplayName(const Value: string); override;
    function GetDisplayName: string; override;
    function GetEmpty: Boolean; virtual; abstract;
    function GetItemList : TigCoreList;
    procedure DefineProperties(Filer: TFiler); override;
    function Equals(AItem: TigCoreItem): Boolean; virtual;

    //These are used for undo/redo and another native stream format.
    //Since TFiller cant load Pointer & Array of published properties.
    procedure ReadData(AStream: TStream); virtual; //LoadFromStream
    procedure WriteData(AStream: TStream); virtual; //SaveToStream
  public
    constructor Create(ACollection: TCollection); override;

    property Empty: Boolean read GetEmpty;
  published
    property DisplayName;// read GetDisplayName write SetDisplayName;
  end;
  //TgmCoreItemClass = class of TigCoreItem;

  TigCoreCollection = class(TOwnedCollection)
  private
    FOnChange: TNotifyEvent;
    //FFileName: TFilename;
  protected
    procedure Update(Item: TCollectionItem); override;
    

  public
    constructor Create(AOwner: TComponent); overload; virtual;
    constructor Create(AOwner: TComponent; GetItemClass: TCollectionItemClass);overload;virtual;
    function IsValidIndex(index : Integer):Boolean;virtual;


    //property FileReaders : TigFileFormatsList read GetFileReaders;


    //procedure LoadFromFile(const FileName: string); virtual;
    //procedure LoadFromStream(AStream: TStream); virtual;
    //procedure Move(CurIndex, NewIndex: Integer); virtual;
    //procedure SaveToFile(const FileName: string); virtual;
    //procedure SaveToStream(AStream: TStream); virtual;


    property OnChange             : TNotifyEvent    read FOnChange        write FOnChange;


  end;
  TigCoreCollectionClass = class of TigCoreCollection;


{ TChangeLink }

  TigCoreChangeLink = class(TObject)
  private
    FSender: TigCoreList;
    FOnChange: TNotifyEvent;
  public
    destructor Destroy; override;
    procedure Change; dynamic;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property Sender: TigCoreList read FSender write FSender;
  end;


  {TigCoreList}
  {VCL component, usefull in designtime}
  TigCoreList = class(TComponent,IStreamPersist)
  private
    FClients: TList;
    FOnChange: TNotifyEvent;
    FFileName: TFilename;
    FCurrentStreamFileName : TFileName; //for temporary
    function GetCount: Integer;

    procedure GridChangedHandler(Sender:TObject);
    function GeFirstItem: TigCoreItem;
    function GetLastItem: TigCoreItem;
    { Private declarations }
  protected
    { Protected declarations }
    FCollection: TigCoreCollection;
    procedure SetCollection(const Value: TigCoreCollection);
    procedure Change; dynamic;
    function GetItem(Index: TigCoreIndex): TigCoreItem;
    procedure SetItem(Index: TigCoreIndex; const Value: TigCoreItem);

    {"Simulating class properties in (Win32) Delphi"
    http://delphi.about.com/library/weekly/aa031505a.htm
    While (Win32) Delphi enables you to create class (static) methods
    (function or procedure), you cannot mark a property of a class to be a
    class (static) property. False. You can! Let's see how to simulate
    class properties using typed constants.}
    class function GetFileReaders : TigFileFormatsList; virtual;
    class function GetFileWriters : TigFileFormatsList; virtual;



    //class function CollectionClass : TigCoreCollectionClass;virtual;

    class function GetItemClass : TCollectionItemClass; virtual;
    //property Collection : TigCoreCollection read FCollection write SetCollection;

  public
    { Public declarations }
    function Add : TigCoreItem; virtual;
    procedure Clear; virtual;
    procedure BeginUpdate; virtual;
    procedure EndUpdate; virtual;

    function IsValidIndex(index : Integer):Boolean;

    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure RegisterChanges(Value: TigCoreChangeLink);
    procedure UnRegisterChanges(Value: TigCoreChangeLink);

    //OpenDialog\SaveDialog
    class function ReadersFilter: string;
    class function WritersFilter: string;


    class procedure RegisterConverterReader(const AExtension, ADescription: string;
      DescID: Integer; AReaderClass: TigConverterClass);
    class procedure RegisterConverterWriter(const AExtension, ADescription: string;
      DescID: Integer; AReaderClass: TigConverterClass);


    procedure LoadFromFile(const FileName: string); virtual;
    procedure LoadFromStream(AStream: TStream); virtual;
    procedure SaveToFile(const FileName: string); virtual;
    procedure SaveToStream(AStream: TStream); virtual;

    property FileName : TFilename read FFileName write FFileName;
    property Count: Integer read GetCount;
    property Items[Index: TigCoreIndex]: TigCoreItem read GetItem write SetItem;
    property Last : TigCoreItem read GetLastItem;
    property First : TigCoreItem read GeFirstItem;
  published
    { Published declarations }
    property Collection : TigCoreCollection read FCollection write SetCollection;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;


  TigSelectionItem = class(TObjectList)
  private
    function GetItem(Index: Integer): TigCoreItem;
    procedure SetItem(Index: Integer; const Value: TigCoreItem);

  public
    property Items[Index: Integer]: TigCoreItem read GetItem write SetItem; default;
  end;

//============== CHUNK CLASSES =========================

  TigChunk = record
    MagicWord   : array[0..3] of Char; //such as SHPE
    HeaderSize  : Word; //in bytes. also for indicating the version used for this chunk
    Count       : Word; //such ChildrenCount, PointsCount
    ContentSize : LongWord;//plan for future
  end;

var
  GCoreListList : TClassList;
  GCoreViewerList : TClassList;

procedure RegisterCoreList(ACoreListClass: TigCoreListClass);
procedure RegisterCoreViewer(ACoreViewerClass: TigCoreViewerClass);

implementation



var
  UCoreItemsReaders, UCoreItemsWriters : TigFileFormatsList;
  UCoreItemKernelList: TClassList;

procedure RegisterCoreList(ACoreListClass: TigCoreListClass);
begin
  if not Assigned(GCoreListList) then GCoreListList := TClassList.Create;
  GCoreListList.Add(ACoreListClass);
end;

procedure RegisterCoreViewer(ACoreViewerClass: TigCoreViewerClass);
begin
  if not Assigned(GCoreViewerList) then GCoreViewerList := TClassList.Create;
  GCoreViewerList.Add(ACoreViewerClass);
end;


{ TigCoresItem }


constructor TigCoreItem.Create(ACollection: TCollection);
begin
  inherited Create(ACollection);
  FDisplayName := 'Custom';
end;

procedure TigCoreItem.DefineProperties(Filer: TFiler);
  function DoWrite: Boolean;
  begin
    if Filer.Ancestor <> nil then
      Result := not (Filer.Ancestor is TigCoreItem) or
        not Equals(TigCoreItem(Filer.Ancestor))
    else
      Result := not Empty;
  end;

begin
  inherited;
  Filer.DefineBinaryProperty('Data', ReadData, WriteData, DoWrite);
end;

function TigCoreItem.Equals(AItem: TigCoreItem): Boolean;
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

procedure TigCoreItem.ReadData(AStream: TStream);
begin
  //LoadFromStream(Stream);
end;

procedure TigCoreItem.WriteData(AStream: TStream);
begin
  //SaveToStream(Stream);
end;

function TigCoreItem.GetDisplayName: string;
begin
  Result := FDisplayName;
end;


function TigCoreItem.GetItemList: TigCoreList;
begin
  Result := nil;
  if Assigned(Collection) then
    if Collection.Owner is TigCoreList then
      Result := Collection.Owner as TigCoreList;
end;

procedure TigCoreItem.SetDisplayName(const Value: string);
begin
  FDisplayName := Value;
end;

{ TigCoreCollection }

constructor TigCoreCollection.Create(AOwner: TComponent);
begin
  Create(AOwner,TigCoreItem);
end;

constructor TigCoreCollection.Create(AOwner: TComponent;
  GetItemClass: TCollectionItemClass);
begin
  inherited Create(AOwner,GetItemClass);
end;


function TigCoreCollection.IsValidIndex(index: Integer): Boolean;
begin
  Result := (index > -1) and (index < Count);
end;


procedure TigCoreCollection.Update(Item: TCollectionItem);
begin
  inherited;
  if Assigned(FOnChange) then
  begin
    FOnChange(Self);
  end;
end;


{ TigCoreChangeLink }

procedure TigCoreChangeLink.Change;
begin
  if Assigned(FOnChange) then FOnChange(Sender);
end;

destructor TigCoreChangeLink.Destroy;
begin
  if Sender <> nil then Sender.UnRegisterChanges(Self);
  inherited;
end;

{ TigCoreList }

procedure TigCoreList.Change;
var
  I: Integer;
begin
  if FClients <> nil then
    for I := 0 to FClients.Count - 1 do
      TigCoreChangeLink(FClients[I]).Change;
  if Assigned(FOnChange) then FOnChange(Self);

end;

{class function TigCoreList.CollectionClass: TigCoreCollectionClass;
begin
  Result := TigCoreCollection;//ascendant must override it
end;}

constructor TigCoreList.Create(AOwner: TComponent);
begin
  inherited;
  FClients := TList.Create;
  FCollection := TigCoreCollection.Create(Self, GetItemClass );
///disabled as need FPC  FCollection.FOnChange := GridChangedHandler;
end;

destructor TigCoreList.Destroy;
begin
  while FClients.Count > 0 do
    UnRegisterChanges(TigCoreChangeLink(FClients.Last));
  FClients.Free;
  FClients := nil;
  inherited;
end;

function TigCoreList.GetCount: Integer;
begin
  Result := Collection.Count;
end;



class function TigCoreList.GetFileReaders: TigFileFormatsList;
begin
 if not Assigned(UCoreItemsReaders) then
  begin
    UCoreItemsReaders := TigFileFormatsList.Create;
  end;

  Result := UCoreItemsReaders;
end;

class function TigCoreList.GetFileWriters: TigFileFormatsList;
begin
if not Assigned(UCoreItemsWriters) then
  begin
    UCoreItemsWriters := TigFileFormatsList.Create;
  end;

  Result := UCoreItemsWriters;
end;

procedure TigCoreList.GridChangedHandler(Sender: TObject);
begin
  Change;
end;

class function TigCoreList.GetItemClass: TCollectionItemClass;
begin
  Result := TigCoreItem;
end;

procedure TigCoreList.LoadFromFile(const FileName: string);
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

procedure TigCoreList.LoadFromStream(AStream: TStream);
{var
  //LFileHeader         : TigGradientFileHeader;
  LFirstStreamPosition: Int64;
  i                   : Integer;
  LReader             : TigConverter;
  LReaderClass        : TigConverterClass;
  LReaders            : TigFileFormatsList;
  LReaderAccepted     : Boolean;
  //SelfClass           : TigCoreCollectionClass;
}
var
  LFirstStreamPosition: Int64;
  i                   : Integer;
  LReader             : TigConverter;
  LReaderClass        : TigConverterClass;
  LReaders            : TigFileFormatsList;
  LReaderAccepted     : Boolean;
  //SelfClass           : TigCoreCollectionClass;

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

  function SatisfiedHungry(AReaderClass : TigConverterClass): Boolean;
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
  LMatchReaders : TigArrayOfConverterClass;
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

class function TigCoreList.ReadersFilter: string;
var
  LFilters: string;
begin
  GetFileReaders.BuildFilterStrings(TigConverter, Result, LFilters);
end;

procedure TigCoreList.RegisterChanges(Value: TigCoreChangeLink);
begin
  Value.Sender := Self;
  if FClients <> nil then FClients.Add(Value);
end;



class procedure TigCoreList.RegisterConverterReader(const AExtension,
  ADescription: string; DescID: Integer; AReaderClass: TigConverterClass);
begin
  self.GetFileReaders.Add(AExtension, ADescription, DescID,AReaderClass);
end;


class procedure TigCoreList.RegisterConverterWriter(const AExtension,
  ADescription: string; DescID: Integer; AReaderClass: TigConverterClass);
begin
  self.GetFileWriters.Add(AExtension, ADescription, DescID,AReaderClass);
end;

procedure TigCoreList.SaveToFile(const FileName: string);
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

procedure TigCoreList.SaveToStream(AStream: TStream);
var
  //LFileHeader         : TigGradientFileHeader;
  LFirstStreamPosition: Int64;
  i                   : Integer;
  LWriter             : TigConverter;
  LWriterClass        : TigConverterClass;
  LWriters            : TigFileFormatsList;
  LWriterAccepted     : Boolean;
  //SelfClass           : TigCoreCollectionClass;
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

procedure TigCoreList.SetCollection(const Value: TigCoreCollection);
begin
  FCollection.Assign(Value);
end;

procedure TigCoreList.UnRegisterChanges(Value: TigCoreChangeLink);
var
  I: Integer;
begin
  if FClients <> nil then
    for I := 0 to FClients.Count - 1 do
      if TigCoreChangeLink(FClients[I]) = Value then
      begin
        Value.Sender := nil;
        FClients.Delete(I);
        Break;
      end;
end;

class function TigCoreList.WritersFilter: string;
var
  LFilters: string;
begin
  GetFileWriters.BuildFilterStrings(TigConverter, Result, LFilters);
end;


function TigCoreList.Add: TigCoreItem;
begin
  Result := TigCoreItem(FCollection.Add);
end;

function TigCoreList.GetItem(Index: TigCoreIndex): TigCoreItem;
begin
  Result := nil;
  if (index >= 0) and (index < self.Count) then
    Result := FCollection.GetItem(Index) as TigCoreItem;
end;

procedure TigCoreList.SetItem(Index: TigCoreIndex;
  const Value: TigCoreItem);
begin
  FCollection.Items[Index].Assign(Value);
end;

procedure TigCoreList.BeginUpdate;
begin
  FCollection.BeginUpdate;
end;

procedure TigCoreList.EndUpdate;
begin
  FCollection.EndUpdate;
end;

procedure TigCoreList.Clear;
begin
  FCollection.Clear;
end;

function TigCoreList.IsValidIndex(index: Integer): Boolean;
begin
  Result := (index > -1) and (index < Count);
end;

function TigCoreList.GeFirstItem: TigCoreItem;
begin
  Result := Items[0]; //validation in self.getitem
end;

function TigCoreList.GetLastItem: TigCoreItem;
begin
  Result := Items[Count -1]; //validation in self.getitem
end;

{ TigSelectionItem }

function TigSelectionItem.GetItem(Index: Integer): TigCoreItem;
begin
//  Result := inherited Items[index] as TigCoreItem;
  Result := TigCoreItem(inherited Items[index]);
end;

procedure TigSelectionItem.SetItem(Index: Integer;
  const Value: TigCoreItem);
begin
  inherited Items[index] := Value;
end;

initialization

finalization
  if Assigned(GCoreListList) then
    GCoreListList.Free;
  if Assigned(GCoreViewerList) then
    GCoreViewerList.Free;

end.
