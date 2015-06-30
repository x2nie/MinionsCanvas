program LCD;

uses
  Forms,
  MAIN in 'MAIN.PAS' {MainForm},
  CHILDWIN in 'CHILDWIN.PAS' {MDIChild},
  about in 'about.pas' {AboutBox},
  icGrid in '..\..\Source\icGrid.pas',
  icSwatch in '..\..\Source\icSwatch.pas',
  icLiquidCrystal in 'icLiquidCrystal.pas',
  icTool_LcdFloodfill in 'icTool_LcdFloodfill.pas';

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TAboutBox, AboutBox);
  Application.Run;
end.
