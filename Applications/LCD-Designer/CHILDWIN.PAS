unit CHILDWIN;

interface

uses Windows, Classes, Graphics, Forms, Controls, StdCtrls, SysUtils,
  GR32_Image,
  icBase, GR32_RangeBars, ExtCtrls;

type
  TMDIChild = class(TForm)
    img1: TicPaintBox;
    pnlZoom: TPanel;
    gbrZoom: TGaugeBar;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormActivate(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure gbrZoomMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
  private
    { Private declarations }
  public
    { Public declarations }
    //property DocumentName : string read DocumentName
    procedure LoadDocument(AFileName : string);
    //maybe the FileName or just caption
    procedure SetDocumentTitle(ATitle : string);
  end;

const
  NONAME = 'Untitled';
    
implementation

uses
  icLayers, jpeg,
  icLiquidCrystal;

{$R *.dfm}

procedure TMDIChild.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
end;

procedure TMDIChild.FormActivate(Sender: TObject);
begin
  img1.SetFocus(); //I dont know how to delete this line :(
end;

procedure TMDIChild.LoadDocument(AFileName: string);
var LLayerPanel : TicLiquidCrystal;
  i : Integer;
begin
  if not FileExists(AFileName) then
    Exit;

  for i := 0 to img1.Layers.Count -1 do
  begin
    if img1.Layers[i] is TicLiquidCrystal then
    begin
      LLayerPanel := img1.Layers[i] as TicLiquidCrystal;
      LLayerPanel.LoadFromFile(AFileName);

      img1.Bitmap.SetSizeFrom(LLayerPanel.LayerBitmap);
      //img1.Layers.CombineResult.SetSizeFrom(LLayerPanel.LayerBitmap);
      //img1.Layers.LayerPanels[0].LayerBitmap.SetSizeFrom(LLayerPanel.LayerBitmap);
      //img1.Layers.Update(nil); //rebuild all
      img1.Invalidate;

      Break;
    end;
  end;

end;

procedure TMDIChild.FormCreate(Sender: TObject);
var LLayerPanel : TicLiquidCrystal;
begin
    LLayerPanel := TicLiquidCrystal.Create(img1.Layers);

//      LLayerPanel.BeginUpdate;
      //with img1.Bitmap do       LLayerPanel.LayerBitmap.SetSize(Width,height);
      //LLayerPanel.LayerBitmap.Clear($FF000000 or Cardinal(Random($FFFFFF)));
      //LLayerPanel.UpdateLayerThumbnail;


//      LLayerPanel.EndUpdate;

      //LPanelIndex := GIntegrator.ActivePaintBox.LayerList.SelectedIndex + 1;
  img1.Bitmap.SetSizeFrom(LLayerPanel.LayerBitmap);
  img1.SelectedLayer := LLayerPanel;
  //img1.Layers.CombineResult.SetSizeFrom(LLayerPanel.LayerBitmap);
  //if img1.Layers.Count > 0 then
    //img1.Layers.LayerPanels[0].LayerBitmap.SetSizeFrom(LLayerPanel.LayerBitmap);
  //img1.Layers.Add(LLayerPanel);
end;

procedure TMDIChild.gbrZoomMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
const zoomLevel : array[0..9] of Single = (0.1, 0.25, 0.50, 0.75, 1.0, 2.0, 3.0, 4.0, 6.0, 8.0);   
begin
  img1.Scale := zoomLevel[ gbrZoom.Position];
end;

procedure TMDIChild.SetDocumentTitle(ATitle: string);
begin
 { if Copy(ATitle,1, Length(NONAME)) = NONAME then
  begin
    Caption := ATitle;
  end
  else
  begin
    if FileExists(ATitle) then
      LoadDocument(ATitle);

    Caption := ExtractFileName(ATitle);
  end;}
end;

end.
