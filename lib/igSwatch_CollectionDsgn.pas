unit igSwatch_CollectionDsgn;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, DesignIntf, DesignEditors, DesignWindows, GR32_Image, bivGrid,
  igGrid, igSwatch, ExtCtrls, ComCtrls, ToolWin, ImgList;

type
  TigGridCollectionEditor = class(TDesignWindow)
    ImageList: TImageList;
    ToolBar: TToolBar;
    btnLoad: TToolButton;
    btnSave: TToolButton;
    btnClear: TToolButton;
    btn1: TToolButton;
    btnCopy: TToolButton;
    btnPaste: TToolButton;
    Splitter1: TSplitter;
    SwatchGrid: TigSwatchGrid;
    dlgOpen1: TOpenDialog;
    dlgSave1: TSaveDialog;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnLoadClick(Sender: TObject);
    procedure btnClearClick(Sender: TObject);
    procedure SwatchGridChange(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    FCollectionPropertyName: string;
    procedure SetCollectionPropertyName(const Value: string);
    { Private declarations }
  public
    Collection: TCollection;
    //Component: TComponent;
    SwatchList: TigSwatchList;
    procedure UpdateListbox;
    procedure SelectionChanged(const ADesigner: IDesigner; const ASelection: IDesignerSelections); override;


    property CollectionPropertyName: string read FCollectionPropertyName
      write SetCollectionPropertyName;
  end;

  TigGridCollectionEditorClass = class of TigGridCollectionEditor;

  TigGridCollectionProperty = class(TClassProperty)
  public
    procedure Edit; override;
    function GetAttributes: TPropertyAttributes; override;
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
uses Registry, TypInfo, DesignConst, ComponentDesigner;

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
    SwatchGrid.SwatchList := SwatchList;
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

procedure TigGridCollectionEditor.btnLoadClick(Sender: TObject);
begin
  dlgOpen1.Filter := TigSwatchList.ReadersFilter;
  if dlgOpen1.Execute then
  begin
    SwatchList.BeginUpdate;
    try
      SwatchList.LoadFromFile(dlgOpen1.FileName);
    finally
      SwatchList.EndUpdate;
      Designer.Modified;
    end;
  end;

end;

procedure TigGridCollectionEditor.btnClearClick(Sender: TObject);
begin
  SwatchList.Clear;
end;

procedure DeInit;
begin
  if Assigned(CollectionEditorsList) then
  begin
    CollectionEditorsList.Free;
    CollectionEditorsList := nil;
  end;
end;

procedure TigGridCollectionEditor.SelectionChanged(
  const ADesigner: IDesigner; const ASelection: IDesignerSelections);
var i : integer;
begin
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

initialization

finalization
   DeInit;
end.
