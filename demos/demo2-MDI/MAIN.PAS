unit MAIN;

interface

uses Windows, SysUtils, Classes, Graphics, Forms, Controls, Menus,
  StdCtrls, Dialogs, Buttons, Messages, ExtCtrls, ComCtrls, StdActns,
  ActnList, ToolWin, ImgList, GR32_Image, igLayerPanelManager,
  igLayersListBox, GR32_RangeBars, igBase;

type
  TMainForm = class(TForm)
    MainMenu1: TMainMenu;
    File1: TMenuItem;
    FileNewItem: TMenuItem;
    FileOpenItem: TMenuItem;
    FileCloseItem: TMenuItem;
    Window1: TMenuItem;
    Help1: TMenuItem;
    N1: TMenuItem;
    FileExitItem: TMenuItem;
    WindowCascadeItem: TMenuItem;
    WindowTileItem: TMenuItem;
    WindowArrangeItem: TMenuItem;
    HelpAboutItem: TMenuItem;
    OpenDialog: TOpenDialog;
    FileSaveItem: TMenuItem;
    FileSaveAsItem: TMenuItem;
    Edit1: TMenuItem;
    CutItem: TMenuItem;
    CopyItem: TMenuItem;
    PasteItem: TMenuItem;
    WindowMinimizeItem: TMenuItem;
    StatusBar: TStatusBar;
    ActionList1: TActionList;
    EditCut1: TEditCut;
    EditCopy1: TEditCopy;
    EditPaste1: TEditPaste;
    FileNew1: TAction;
    FileSave1: TAction;
    FileExit1: TAction;
    FileOpen1: TAction;
    FileSaveAs1: TAction;
    WindowCascade1: TWindowCascade;
    WindowTileHorizontal1: TWindowTileHorizontal;
    WindowArrangeAll1: TWindowArrange;
    WindowMinimizeAll1: TWindowMinimizeAll;
    HelpAbout1: TAction;
    FileClose1: TWindowClose;
    WindowTileVertical1: TWindowTileVertical;
    WindowTileItem2: TMenuItem;
    ToolBar2: TToolBar;
    ToolButton1: TToolButton;
    ToolButton2: TToolButton;
    ToolButton3: TToolButton;
    ToolButton4: TToolButton;
    ToolButton5: TToolButton;
    ToolButton6: TToolButton;
    ToolButton9: TToolButton;
    ToolButton7: TToolButton;
    ToolButton8: TToolButton;
    ToolButton10: TToolButton;
    ToolButton11: TToolButton;
    ImageList1: TImageList;
    pnlLayer: TPanel;
    tlbrLayers: TToolBar;
    tlbnSeparator1: TToolButton;
    tlbtnNewFillAdjustmentLayer: TToolButton;
    tlbrAddMask: TToolButton;
    btnLayer_New: TToolButton;
    btnLayer_Delete: TToolButton;
    actTool_Brush: TAction;
    actTool_Pencil: TAction;
    ToolButton13: TToolButton;
    btnTool_Brush: TToolButton;
    btnTool_Pencil: TToolButton;
    actLayer_New: TAction;
    actLayer_Delete: TAction;
    tlbrBlendModes: TToolBar;
    tlbnSeparator2: TToolButton;
    cmbbxBlendModes: TComboBox;
    tlbrLayerOpacity: TToolBar;
    ToolButton12: TToolButton;
    ggbrLayerOpacity: TGaugeBar;
    edtLayerOpacity: TEdit;
    lblLayerOpacity: TLabel;
    actUndo: TAction;
    actRedo: TAction;
    btn1: TToolButton;
    btnUndo: TToolButton;
    btnRedo: TToolButton;
    spl1: TSplitter;
    pmUndo: TPopupMenu;
    pmRedo: TPopupMenu;
    btn2: TToolButton;
    btn3: TToolButton;
    lyrs1: TigLayersListBox;
    igLayersListBox1: TigLayersListBox;
    igAgent1: TigAgent;
    lbName: TLabel;
    procedure FileNew1Execute(Sender: TObject);
    procedure FileOpen1Execute(Sender: TObject);
    procedure HelpAbout1Execute(Sender: TObject);
    procedure FileExit1Execute(Sender: TObject);
    procedure btnLayer_NewClick(Sender: TObject);
    procedure actTool_BrushExecute(Sender: TObject);
    procedure actTool_PencilExecute(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure EnabledWhenMDIavailabled(Sender: TObject);
    procedure actLayer_DeleteExecute(Sender: TObject);
    procedure actUndoExecute(Sender: TObject);
    procedure actRedoExecute(Sender: TObject);
    procedure actUndoUpdate(Sender: TObject);
    procedure actRedoUpdate(Sender: TObject);
    procedure pmUndoPopup(Sender: TObject);
    procedure pmRedoPopup(Sender: TObject);
    procedure btn3Click(Sender: TObject);
    procedure igAgent1SelectionChange(Sender: TObject);
    procedure cmbbxBlendModesChange(Sender: TObject);
    procedure ggbrLayerOpacityUserChange(Sender: TObject);
  private
    { Private declarations }
    procedure CreateMDIChild(const Name: string);
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses CHILDWIN, about,
  GR32_Add_BlendModes,
  igComboboxBlendModes, igLayers,
  igTool_BrushSimple,
  igTool_PencilSimple;

type TigCustomLayerPanelAccess = class(TigCustomLayerPanel);
  
procedure TMainForm.CreateMDIChild(const Name: string);
var
  Child: TMDIChild;
begin
  { create a new MDI child window }
  Child := TMDIChild.Create(Application);
  Child.Caption := Name;
  if FileExists(Name) then Child.LoadDocument(Name);
end;

procedure TMainForm.FileNew1Execute(Sender: TObject);
begin
  CreateMDIChild('NONAME' + IntToStr(MDIChildCount + 1));
end;

procedure TMainForm.FileOpen1Execute(Sender: TObject);
begin
  if OpenDialog.Execute then
    CreateMDIChild(OpenDialog.FileName);
end;

procedure TMainForm.HelpAbout1Execute(Sender: TObject);
begin

  AboutBox.ShowModal;
end;

procedure TMainForm.FileExit1Execute(Sender: TObject);
begin
  Close;
end;

procedure TMainForm.btnLayer_NewClick(Sender: TObject);
var
  LLayerPanel : TigCustomLayerPanel;
  LPanelIndex : Integer;
var cmd : TigCmdLayer_New;
begin
  if not Assigned(GIntegrator.ActivePaintBox) then
    Exit;

  Screen.Cursor := crHourGlass;
  try
    //with gActiveChildForm do
    begin
      Randomize;

      //LLayerPanel := CreateNormalLayer( $FF000000 or Cardinal(Random($FFFFFF)), False );
      //LLayerPanel := TigNormalLayerPanel.Create(GIntegrator.ActivePaintBox.LayerList); //error access violation
      LLayerPanel := TigNormalLayerPanel.Create(nil);
      LLayerPanel.BeginUpdate;
      with GIntegrator.ActivePaintBox.Bitmap do
      LLayerPanel.LayerBitmap.SetSize(Width,height);
      LLayerPanel.LayerBitmap.Clear($FF000000 or Cardinal(Random($FFFFFF)));
      //LLayerPanel.UpdateLayerThumbnail;
      LLayerPanel.EndUpdate;

      LPanelIndex := GIntegrator.ActivePaintBox.LayerList.SelectedIndex + 1;

      GIntegrator.ActivePaintBox.LayerList.Insert(LPanelIndex, LLayerPanel);

      cmd := TigCmdLayer_New.Create(GIntegrator.ActivePaintBox.UndoRedo);
      cmd.ChangedLayer(LLayerPanel);
      GIntegrator.ActivePaintBox.UndoRedo.AddUndo(cmd,'New Layer');

    end;
  finally
    Screen.Cursor := crDefault;
  end;

end;

procedure TMainForm.actTool_BrushExecute(Sender: TObject);
begin
  //set a drawing tool for mouse operation's response.
  actTool_Brush.Checked := GIntegrator.ActivateTool(TigToolBrushSimple);
end;

procedure TMainForm.actTool_PencilExecute(Sender: TObject);
begin
  actTool_Pencil.Checked := GIntegrator.ActivateTool(TigToolPencilSimple);
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  //actTool_Pencil.Execute(); failed
  GetBlendModeList(cmbbxBlendModes.Items);
  self.actTool_PencilExecute(self);
  self.actTool_BrushExecute(self);
end;

procedure TMainForm.EnabledWhenMDIavailabled(Sender: TObject);
begin
  TAction(Sender).Enabled := MDIChildCount > 0;
end;

procedure TMainForm.actLayer_DeleteExecute(Sender: TObject);
begin
  if not Assigned(GIntegrator.ActivePaintBox) then
    Exit;
  GIntegrator.ActivePaintBox.LayerList.DeleteSelectedLayerPanel;
end;

procedure TMainForm.actUndoExecute(Sender: TObject);
begin
  if not Assigned(GIntegrator.ActivePaintBox) then Exit;
  GIntegrator.ActivePaintBox.UndoRedo.Undo;
end;

procedure TMainForm.actRedoExecute(Sender: TObject);
begin
  if not Assigned(GIntegrator.ActivePaintBox) then Exit;
  GIntegrator.ActivePaintBox.UndoRedo.Redo;
end;

procedure TMainForm.actUndoUpdate(Sender: TObject);
var c : string;
begin
  if not Assigned(GIntegrator.ActivePaintBox) then
    c := 'no active paintbox'
  else
    with GIntegrator.ActivePaintBox.UndoRedo do
      c := Format('@ %d   (%d of %d undos)',[ ItemIndex, ItemIndex +1, Count]);

  //if self.Caption <> c then //avoid flicker
    //self.Caption := c;


  actUndo.Enabled := Assigned(GIntegrator.ActivePaintBox) and
    GIntegrator.ActivePaintBox.UndoRedo.IsUndoAllowed;
end;

procedure TMainForm.actRedoUpdate(Sender: TObject);
begin
  actRedo.Enabled := Assigned(GIntegrator.ActivePaintBox) and
    GIntegrator.ActivePaintBox.UndoRedo.IsRedoAllowed;
end;

procedure TMainForm.pmUndoPopup(Sender: TObject);
var i : Integer;
  m : TMenuItem;
begin
  pmUndo.Items.Clear;
  if not Assigned(GIntegrator.ActivePaintBox) then Exit;
  with GIntegrator.ActivePaintBox.UndoRedo do
  begin
    for i := ItemIndex downto 0 do
    begin
      m := TMenuItem.Create(pmUndo);
      m.Caption := Strings[i];
      pmundo.Items.Add(m);
    end;
  end;
end;

procedure TMainForm.pmRedoPopup(Sender: TObject);
var i : Integer;
  m : TMenuItem;
begin
  pmRedo.Items.Clear;
  if not Assigned(GIntegrator.ActivePaintBox) then Exit;
  with GIntegrator.ActivePaintBox.UndoRedo do
  begin
    for i := ItemIndex +1 to Count -1 do
    begin
      m := TMenuItem.Create(pmRedo);
      m.Caption := Strings[i];
      pmRedo.Items.Add(m);
    end;
  end;
end;

procedure TMainForm.btn3Click(Sender: TObject);
begin
  if not Assigned(GIntegrator.ActivePaintBox) then Exit;
  GIntegrator.ActivePaintBox.LayerList.SelectLayerPanel(0);

end;

procedure TMainForm.igAgent1SelectionChange(Sender: TObject);
var LLayer : TigLayerPanel;
begin
  if assigned(GIntegrator.ActivePaintBox) then
  begin
    LLayer := GIntegrator.ActivePaintBox.LayerList.SelectedPanel;
    if assigned(LLayer) then
    begin
      lbName.Caption := llayer.DisplayName;
      if LLayer is TigCustomLayerPanel then
      begin
        cmbbxBlendModes.ItemIndex :=  ord(TigCustomLayerPanelAccess(LLayer).LayerBlendMode);
        ggbrLayerOpacity.Position :=  TigCustomLayerPanelAccess(LLayer).LayerOpacity;
      end;
    end;
  end;
end;

procedure TMainForm.cmbbxBlendModesChange(Sender: TObject);
var LLayer : TigLayerPanel;
begin
  if assigned(GIntegrator.ActivePaintBox) then
  begin
    LLayer := GIntegrator.ActivePaintBox.LayerList.SelectedPanel;
    if assigned(LLayer) then
    begin
      if LLayer is TigCustomLayerPanel then
      begin
        TigCustomLayerPanelAccess(LLayer).LayerBlendMode := TBlendMode32(cmbbxBlendModes.ItemIndex);
      end;
    end;
  end;

end;

procedure TMainForm.ggbrLayerOpacityUserChange(Sender: TObject);
var LLayer : TigLayerPanel;
begin
  if assigned(GIntegrator.ActivePaintBox) then
  begin
    LLayer := GIntegrator.ActivePaintBox.LayerList.SelectedPanel;
    if assigned(LLayer) then
    begin
      if LLayer is TigCustomLayerPanel then
      begin
        TigCustomLayerPanelAccess(LLayer).LayerOpacity := ggbrLayerOpacity.Position;
      end;
    end;
  end;
end;

end.
