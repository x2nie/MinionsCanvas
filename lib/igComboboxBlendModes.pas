unit igComboboxBlendModes;

interface

uses
  SysUtils, Classes, Controls, StdCtrls,
  igBase, igLayers;

type
  TigComboBoxBlendMode = class(TComboBox)
  private
    FAgent: TigAgent;
    { Private declarations }
  protected
    { Protected declarations }
    procedure Change; override;
    property Agent: TigAgent read FAgent; //read only. for internal access
  public
    { Public declarations }
    constructor Create(AOwner: TComponent); override;
    procedure AfterConstruction; override;
  published
    { Published declarations }
  end;


implementation

uses
  GR32_Add_BlendModes;


{ TigComboBoxBlendMode }

procedure TigComboBoxBlendMode.AfterConstruction;
begin
  inherited;
  if not (csDesigning in self.ComponentState) then
  begin
    FAgent := TigAgent.Create(Self); //autodestroy
    GetBlendModeList(Self.Items); //fill items
  end;
//ItemIndex := 0;
end;

procedure TigComboBoxBlendMode.Change;
var TempNotifyEvent : TNotifyEvent;
  LLayer : TigLayer;
begin
  //we need OnChange triggered at the last chance.
  TempNotifyEvent := OnChange;
  try
    OnChange := nil;
    inherited; //without OnChange triggered
    if GIntegrator.ActivePaintBox <> nil then
    begin
      ///GIntegrator.ActivePaintBox.LayerList.SelectedPanel.LayerBlendMode := TBlendMode32(ItemIndex);
      LLayer := GIntegrator.ActivePaintBox.SelectedLayer;
      if LLayer is TigBitmapLayer then
        TigBitmapLayer(LLayer).LayerBlendMode := TBlendMode32(ItemIndex);
    end;

    if Assigned(TempNotifyEvent) then
      TempNotifyEvent(Self);
  finally
    OnChange := TempNotifyEvent;
  end;


end;

constructor TigComboBoxBlendMode.Create(AOwner: TComponent);
begin
  inherited;


end;

end.
