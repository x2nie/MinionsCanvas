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
  igCore_Items, igGrid,
  igSwatch, igSwatch_Dsgn,
  igGradient;

procedure Register();
begin
  registerComponents('miniGlue',[TigPaintBox, TigAgent, TigLayersListBox, TigComboBoxBlendMode,
    TigGridBox,TigSwatchList, TigSwatchGrid,
    TigGradientList]);
  RegisterComponentEditor(TigSwatchList, TigSwatchListEditor);
  RegisterPropertyEditor(TypeInfo(TigCoreCollection), TigSwatchList, 'Collection', TigGridCollectionProperty);

end;

end.
