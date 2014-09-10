unit igReg;

interface
uses
  Classes, TypInfo,
{$IFDEF FPC}
  LCLIntf, LResources, LazIDEIntf, PropEdits, ComponentEditors
{$ELSE}
  DesignIntf
{$ENDIF};

procedure Register;

implementation
uses
  igBase, igLayersListBox, igComboboxBlendModes,
  igCore_Items,
  igSwatch, igSwatch_Dsgn, igSwatch_CollectionDsgn;

procedure Register();
begin
  registerComponents('miniGlue',[TigPaintBox, TigAgent, TigLayersListBox, TigComboBoxBlendMode,
    TigSwatchList, TigSwatchGrid]);
  RegisterComponentEditor(TigSwatchList, TigSwatchListEditor);
  RegisterPropertyEditor(TypeInfo(TigCoreCollection), TigSwatchList, 'Collection', TigGridCollectionProperty);

end;

end.
