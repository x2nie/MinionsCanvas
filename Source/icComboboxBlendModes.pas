unit icComboboxBlendModes;

interface

uses
  SysUtils, Classes, Controls, StdCtrls,
  icBase, icLayers;

type
  TicComboBoxBlendMode = class(TComboBox)
  private
    FAgent: TicAgent;
    { Private declarations }
  protected
    { Protected declarations }
    procedure Change; override;
    property Agent: TicAgent read FAgent; //read only. for internal access
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


{ TicComboBoxBlendMode }

procedure TicComboBoxBlendMode.AfterConstruction;
begin
  inherited;
  if not (csDesigning in self.ComponentState) then
  begin
    FAgent := TicAgent.Create(Self); //autodestroy
    GetBlendModeList(Self.Items); //fill items
  end;
//ItemIndex := 0;
end;

procedure TicComboBoxBlendMode.Change;
var TempNotifyEvent : TNotifyEvent;
  LLayer : TicLayer;
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
      if LLayer is TicBitmapLayer then
        TicBitmapLayer(LLayer).LayerBlendMode := TBlendMode32(ItemIndex);
    end;

    if Assigned(TempNotifyEvent) then
      TempNotifyEvent(Self);
  finally
    OnChange := TempNotifyEvent;
  end;


end;

constructor TicComboBoxBlendMode.Create(AOwner: TComponent);
begin
  inherited;


end;

end.
