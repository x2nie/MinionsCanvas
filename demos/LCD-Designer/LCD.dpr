program LCD;

uses
  Forms,
  MAIN in 'MAIN.PAS' {MainForm},
  CHILDWIN in 'CHILDWIN.PAS' {MDIChild},
  about in 'about.pas' {AboutBox},
  igGrid in '..\..\lib\igGrid.pas',
  igSwatch in '..\..\lib\igSwatch.pas',
  igLiquidCrystal in 'igLiquidCrystal.pas',
  igTool_LcdLine in 'igTool_LcdLine.pas';

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TAboutBox, AboutBox);
  Application.Run;
end.
