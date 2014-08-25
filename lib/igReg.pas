unit igReg;

interface
uses
  Classes;

procedure Register;

implementation
uses
  igBase, igLayersListBox, igComboboxBlendModes;

procedure Register();
begin
  registerComponents('miniGlue',[TigPaintBox, TigAgent, TigLayersListBox, TigComboBoxBlendMode]);
end;

end.
