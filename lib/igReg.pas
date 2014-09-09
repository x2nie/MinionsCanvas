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
  igSwatch, igSwatch_Dsgn;

procedure Register();
begin
  registerComponents('miniGlue',[TigPaintBox, TigAgent, TigLayersListBox, TigComboBoxBlendMode,
    TigSwatchList, TigSwatchGrid]);
  RegisterComponentEditor(TigSwatchList, TigSwatchListEditor);

end;

end.
