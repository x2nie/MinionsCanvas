unit igSwatch_Dsgn;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, DesignIntf, DesignEditors, DesignWindows, GR32_Image, bivGrid,
  igGrid, igSwatch, ExtCtrls, ComCtrls, ToolWin, ImgList, StdActns,
  ActnList, Buttons;

type
  TigGridCollectionEditor = class(TDesignWindow)
    ImageList: TImageList;
    ToolBar: TToolBar;
    btnLoad: TToolButton;
    btnSave: TToolButton;
    btnClear: TToolButton;
    btnCopy: TToolButton;
    btnPaste: TToolButton;
    Splitter1: TSplitter;
    SwatchGrid: TigSwatchGrid;
    ActionList1: TActionList;
    ToolButton1: TToolButton;
    FileOpen1: TFileOpen;
    FileSaveAs1: TFileSaveAs;
    EditSelectAll1: TEditSelectAll;
    EditDelete1: TEditDelete;
    SpeedButton1: TSpeedButton;
    StatusBar1: TStatusBar;
    btnNew: TToolButton;
    actNew: TAction;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnClearClick(Sender: TObject);
    procedure SwatchGridChange(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FileOpen1BeforeExecute(Sender: TObject);
    procedure FileOpen1Accept(Sender: TObject);
    procedure EditSelectAll1Execute(Sender: TObject);
    procedure HasSelection(Sender: TObject);
    procedure EditDelete1Execute(Sender: TObject);
    procedure actNewExecute(Sender: TObject);
    procedure HasAtLeastOneItem(Sender: TObject);
  private
    FCollectionPropertyName: string;
    FSwatchList: TigSwatchList;
    procedure SetCollectionPropertyName(const Value: string);
    procedure SetSwatchList(const Value: TigSwatchList);
  protected
    procedure Activated; override;
  public
    Collection: TCollection;
    //Component: TComponent;
    property SwatchList: TigSwatchList read FSwatchList write SetSwatchList;
    procedure UpdateListbox;
    procedure SelectionChanged(const ADesigner: IDesigner; const ASelection: IDesignerSelections); override;
    procedure ItemDeleted(const ADesigner: IDesigner; Item: TPersistent); override;
    procedure DesignerClosed(const ADesigner: IDesigner; AGoingDormant: Boolean); override;


    property CollectionPropertyName: string read FCollectionPropertyName
      write SetCollectionPropertyName;
  end;

  TigGridCollectionEditorClass = class of TigGridCollectionEditor;



  TigGridCollectionProperty = class(TClassProperty)
  public
    procedure Edit; override;
    function GetAttributes: TPropertyAttributes; override;
  end;

  

  TigSwatchListEditor = class(TComponentEditor)
  public
    procedure ExecuteVerb(Index: Integer); override;
    function GetVerb(Index: Integer): string; override;
    function GetVerbCount: Integer; override;
  end;

procedure ShowCollectionEditor(ADesigner: IDesigner; AComponent: TComponent;
  ACollection: TCollection; const PropertyName: string);
function ShowCollectionEditorClass(ADesigner: IDesigner;
  CollectionEditorClass: TigGridCollectionEditorClass; AComponent: TComponent;
  ACollection: TCollection; const PropertyName: string): TigGridCollectionEditor;

var
  igGridCollectionEditor: TigGridCollectionEditor;

implementation

{$R *.dfm}
uses
  Registry, TypInfo, DesignConst, ComponentDesigner,
  igSwatch_rwACO, igSwatch_rwASE, igSwatch_rwGPL;

type
  TAccessCollection = class(TCollection); // used for protected method access
  TPersistentCracker = class(TPersistent);

var
  CollectionEditorsList: TList = nil;

function ShowCollectionEditorClass(ADesigner: IDesigner;
  CollectionEditorClass: TigGridCollectionEditorClass; AComponent: TComponent;
  ACollection: TCollection; const PropertyName: string): TigGridCollectionEditor;
var
  I: Integer;
begin
  if CollectionEditorsList = nil then
    CollectionEditorsList := TList.Create;
  for I := 0 to CollectionEditorsList.Count-1 do
  begin
    Result := TigGridCollectionEditor(CollectionEditorsList[I]);
    with Result do
      if (Designer = ADesigner) and (SwatchList = AComponent)
        and (Collection = ACollection)
        and (CompareText(CollectionPropertyName, PropertyName) = 0) then
      begin
        Show;
        BringToFront;
        Exit;
      end;
  end;
  Result := CollectionEditorClass.Create(Application);
  with Result do
  try
    //Options := ColOptions;
    Designer := ADesigner;
    Collection := ACollection;
    //FCollectionClassName := ACollection.ClassName;
    SwatchList := TigSwatchList(AComponent);

    CollectionPropertyName := PropertyName;
    UpdateListbox;
    Show;
  except
    Free;
  end;
end;

procedure ShowCollectionEditor(ADesigner: IDesigner; AComponent: TComponent;
  ACollection: TCollection; const PropertyName: string);
begin
  ShowCollectionEditorClass(ADesigner, TigGridCollectionEditor, AComponent,
    ACollection, PropertyName);
end;

{ TCollectionProperty }

procedure TigGridCollectionProperty.Edit;
var
  Obj: TPersistent;
begin
  Obj := GetComponent(0);
  while (Obj <> nil) and not (Obj is TComponent) do
    Obj := TPersistentCracker(Obj).GetOwner;
  ShowCollectionEditorClass(Designer, TigGridCollectionEditor,
    TComponent(Obj), TCollection(GetOrdValue), GetName);

end;

function TigGridCollectionProperty.GetAttributes: TPropertyAttributes;
begin
  Result := [paDialog, paReadOnly, paVCL, paAutoUpdate];
end;

{ TigGridCollectionEditor }

procedure TigGridCollectionEditor.SetCollectionPropertyName(
  const Value: string);
begin
  if Value <> FCollectionPropertyName then
  begin
    FCollectionPropertyName := Value;
    Caption := Format(sColEditCaption, [SwatchList.Name, DotSep, Value]);
  end;
end;

procedure TigGridCollectionEditor.UpdateListbox;
/// <summary>
/// update the form to reflect the changes made in the component being edit
/// </summary>
begin
  //
end;

procedure TigGridCollectionEditor.FormCreate(Sender: TObject);
begin
  CollectionEditorsList.Add(Self);
end;

procedure TigGridCollectionEditor.FormDestroy(Sender: TObject);
begin
  if CollectionEditorsList <> nil then
    CollectionEditorsList.Remove(Self);
end;

procedure TigGridCollectionEditor.btnClearClick(Sender: TObject);
begin
  SwatchList.Clear;
end;

procedure TigGridCollectionEditor.SelectionChanged(
  const ADesigner: IDesigner; const ASelection: IDesignerSelections);
var i : integer;
  LOwnItem : Boolean;
begin
  if TAccessCollection(Collection).UpdateCount > 0 then
    Exit;
  LOwnItem := False;
  //test first
    for i := 0 to ASelection.Count-1 do
    begin
      if (ASelection[i] is TigSwatchItem)
      and (TigSwatchItem(ASelection[i]).Collection = Self.Collection)then
      begin
        LOwnItem := True;
        Break;
      end;
    end;
  if not LOwnItem then Exit;

  SwatchList.BeginUpdate;
  try
    SwatchList.Selections.Clear;
    for i := 0 to ASelection.Count-1 do
    begin
      if ASelection[i] is TigSwatchItem then
      begin
        SwatchList.Selections.Add(ASelection[i]);
      end;
    end;
  finally
    SwatchList.EndUpdate;
    SwatchGrid.Invalidate;
  end;

end;

procedure TigGridCollectionEditor.SwatchGridChange(Sender: TObject);
var
  I: Integer;
  List: IDesignerSelections;
begin
  if SwatchList.Selections.Count > 0 then
  begin
    List := CreateSelectionList;
    for I := 0 to SwatchList.Selections.Count - 1 do
      begin
        List.Add(SwatchList.Selections.Items[I]);
      end;
    Designer.SetSelections(List);
  end
  else
    Designer.SelectComponent(Collection);
end;

procedure TigGridCollectionEditor.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  Action := caFree;
  Self.SwatchGrid.OnChange := nil;
end;

{ TigSwatchListComponentEditor }

procedure TigSwatchListEditor.ExecuteVerb(Index: Integer);
var
  LSwatcs,LBackupSwatchs : TigSwatchList;
begin
  if Index = 0 then
  begin
    LSwatcs := Component as TigSwatchList;

    ShowCollectionEditorClass(Designer, TigGridCollectionEditor,
      LSwatcs, LSwatcs.Collection, LSwatcs.Name);
  end;
end;

function TigSwatchListEditor.GetVerb(Index: Integer): string;
begin
  if Index = 0 then Result := 'Items Editor...';
end;

function TigSwatchListEditor.GetVerbCount: Integer;
begin
  Result := 1;
end;

procedure TigGridCollectionEditor.Activated;
begin
  SwatchGridChange(Self);
end;

procedure DeInit;
var i : Integer;
begin
  if Assigned(CollectionEditorsList) then
  begin
    for i := CollectionEditorsList.Count-1 downto 0 do
    begin
       with TigGridCollectionEditor(CollectionEditorsList[i]) do
       begin
         Close;
         Free;
       end;
    end;
    CollectionEditorsList.Free;
    CollectionEditorsList := nil;
  end;
end;


procedure TigGridCollectionEditor.FileOpen1BeforeExecute(Sender: TObject);
begin
  FileOpen1.Dialog.Filter := TigSwatchList.ReadersFilter;
end;

procedure TigGridCollectionEditor.FileOpen1Accept(Sender: TObject);
var i :Integer;
begin
    SwatchList.BeginUpdate;
    try
      for i := 0 to FileOpen1.Dialog.Files.Count -1 do
      begin
        SwatchList.LoadFromFile(FileOpen1.Dialog.Files[i]);
      end;
    finally
      SwatchList.EndUpdate;
      //Designer.Modified;
      self.SwatchGridChange(Self);
    end;
end;

procedure TigGridCollectionEditor.EditSelectAll1Execute(Sender: TObject);
begin
  SwatchList.SelectAll;
  SwatchGridChange(Self);
end;

procedure TigGridCollectionEditor.HasSelection(Sender: TObject);
begin
  TAction(Sender).Enabled := self.SwatchList.Selections.Count > 0;
end;

procedure TigGridCollectionEditor.EditDelete1Execute(Sender: TObject);
var i :Integer;
  LItem : TCollectionItem;
begin
  SwatchList.BeginUpdate;
  try
    {//Self.SetSelection(nil);
    Designer.SelectComponent(Collection);
    for i := SwatchList.Selections.Count-1 to 0 do
    begin
      LItem := SwatchList.Selections[i];
      SwatchList.Selections.Extract(LItem);
      //LItem.Free;
    end;}
    Designer.DeleteSelection(True);
    SwatchList.ClearSelection;
  finally
    SwatchList.EndUpdate;
  end;

end;

procedure TigGridCollectionEditor.actNewExecute(Sender: TObject);
begin
  SwatchList.BeginUpdate;
  SwatchList.Selections.Clear;
  SwatchList.Selections.Add( Collection.Add);
  SwatchList.EndUpdate;
  SwatchGridChange(Self);
end;

procedure TigGridCollectionEditor.HasAtLeastOneItem(Sender: TObject);
begin
  TAction(Sender).Enabled := Collection.Count > 0;
end;

procedure TigGridCollectionEditor.ItemDeleted(const ADesigner: IDesigner;
  Item: TPersistent);
begin
  if SwatchList.Selections.IndexOf(Item) > 0 then
    SwatchList.Selections.Remove(Item);

end;

procedure TigGridCollectionEditor.SetSwatchList(
  const Value: TigSwatchList);
begin
  if FSwatchList <> Value then
  begin
    FSwatchList := Value;
    SwatchGrid.SwatchList := FSwatchList;
  end;
end;

procedure TigGridCollectionEditor.DesignerClosed(
  const ADesigner: IDesigner; AGoingDormant: Boolean);
begin
  if Designer = ADesigner then
    Close;

end;

initialization

finalization
   DeInit;
end.
