unit igGrid_Dsgn;

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
    gridGrid: TigGridBox;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnClearClick(Sender: TObject);
    procedure GridChange(Sender: TObject);
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
    FSwatchList: TigGridList;
    procedure SetCollectionPropertyName(const Value: string);
    procedure SetSwatchList(const Value: TigGridList);
  protected
    procedure Activated; override;
  public
    Collection: TCollection;
    //Component: TComponent;
    property GridCellList: TigGridList read FSwatchList write SetSwatchList;
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

  

  TigCellItemListEditor = class(TComponentEditor)
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
  igSwatch_rwACO, igSwatch_rwASE, igSwatch_rwGPL,
  igGradient_rwPhotoshopGRD;

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
      if (Designer = ADesigner) and (GridCellList = AComponent)
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
    GridCellList := TigGridList(AComponent);

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
    Caption := Format(sColEditCaption, [GridCellList.Name, DotSep, Value]);
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
  GridCellList.Clear;
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

  GridCellList.BeginUpdate;
  try
    GridCellList.Selections.Clear;
    for i := 0 to ASelection.Count-1 do
    begin
      if ASelection[i] is TigSwatchItem then
      begin
        GridCellList.Selections.Add(ASelection[i]);
      end;
    end;
  finally
    GridCellList.EndUpdate;
    gridGrid.Invalidate;
  end;

end;

procedure TigGridCollectionEditor.GridChange(Sender: TObject);
var
  I: Integer;
  List: IDesignerSelections;
begin
  if GridCellList.Selections.Count > 0 then
  begin
    List := CreateSelectionList;
    for I := 0 to GridCellList.Selections.Count - 1 do
      begin
        List.Add(GridCellList.Selections.Items[I]);
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
  Self.gridGrid.OnChange := nil;
end;

{ TigSwatchListComponentEditor }

procedure TigCellItemListEditor.ExecuteVerb(Index: Integer);
var
  LSwatcs,LBackupSwatchs : TigGridList;
begin
  if Index = 0 then
  begin
    LSwatcs := Component as TigGridList;

    ShowCollectionEditorClass(Designer, TigGridCollectionEditor,
      LSwatcs, LSwatcs.Collection, 'Collection');
  end;
end;

function TigCellItemListEditor.GetVerb(Index: Integer): string;
begin
  if Index = 0 then Result := 'Items Editor...';
end;

function TigCellItemListEditor.GetVerbCount: Integer;
begin
  Result := 1;
end;

procedure TigGridCollectionEditor.Activated;
begin
  GridChange(Self);
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
  //FileOpen1.Dialog.Filter := TigSwatchList.ReadersFilter;
  FileOpen1.Dialog.Filter := GridCellList.ReadersFilter;
end;

procedure TigGridCollectionEditor.FileOpen1Accept(Sender: TObject);
var i :Integer;
begin
    GridCellList.BeginUpdate;
    try
      for i := 0 to FileOpen1.Dialog.Files.Count -1 do
      begin
        GridCellList.LoadFromFile(FileOpen1.Dialog.Files[i]);
      end;
    finally
      GridCellList.EndUpdate;
      //Designer.Modified;
      GridChange(Self);
    end;
end;

procedure TigGridCollectionEditor.EditSelectAll1Execute(Sender: TObject);
begin
  GridCellList.SelectAll;
  GridChange(Self);
end;

procedure TigGridCollectionEditor.HasSelection(Sender: TObject);
begin
  TAction(Sender).Enabled := self.GridCellList.Selections.Count > 0;
end;

procedure TigGridCollectionEditor.EditDelete1Execute(Sender: TObject);
var i :Integer;
  LItem : TCollectionItem;
begin
  GridCellList.BeginUpdate;
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
    GridCellList.ClearSelection;
  finally
    GridCellList.EndUpdate;
  end;

end;

procedure TigGridCollectionEditor.actNewExecute(Sender: TObject);
begin
  GridCellList.BeginUpdate;
  GridCellList.Selections.Clear;
  GridCellList.Selections.Add( Collection.Add);
  GridCellList.EndUpdate;
  GridChange(Self);
end;

procedure TigGridCollectionEditor.HasAtLeastOneItem(Sender: TObject);
begin
  TAction(Sender).Enabled := Collection.Count > 0;
end;

procedure TigGridCollectionEditor.ItemDeleted(const ADesigner: IDesigner;
  Item: TPersistent);
begin
  if GridCellList.Selections.IndexOf(Item) > 0 then
    GridCellList.Selections.Remove(Item);

end;

procedure TigGridCollectionEditor.SetSwatchList(
  const Value: TigGridList);
begin
  if FSwatchList <> Value then
  begin
    FSwatchList := Value;
    gridGrid.ItemList := FSwatchList;
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
