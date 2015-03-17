unit icReg;

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
  icBase, icLayersListBox, icComboboxBlendModes,
  icCore_Items, icGrid,  icGrid_Dsgn,
  icSwatch, //igSwatch_Dsgn,
  icGradient;

procedure Register();
begin
  registerComponents('miniGlue',[TicPaintBox, TicAgent, TicLayersListBox, TicComboBoxBlendMode,
    TicGridBox,TicSwatchList, TicSwatchGrid,
    TicGradientList]);
  //RegisterComponentEditor(TicSwatchList, TicSwatchListEditor);
  RegisterComponentEditor(TicGridList, TicCellItemListEditor);
  //RegisterPropertyEditor(TypeInfo(TicCoreCollection), TicSwatchList, 'Collection', TicGridCollectionProperty);

end;

end.
