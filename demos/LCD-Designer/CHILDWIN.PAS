unit CHILDWIN;

interface

uses Windows, Classes, Graphics, Forms, Controls, StdCtrls, GR32_Image,
  igBase;

type
  TMDIChild = class(TForm)
    img1: TigPaintBox;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormActivate(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    //property DocumentName : string read DocumentName
    procedure LoadDocument(AFileName : string);
  end;

implementation

uses
  igLayers, jpeg,
  igLiquidCrystal;

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
var P : TPicture;
begin
  p := TPicture.Create;
  p.LoadFromFile(AFileName);
  with TigNormalLayerPanel(img1.LayerList.LayerPanels[0]) do
  begin

    //LayerBitmap.LoadFromFile(AFileName);
    LayerBitmap.Assign(p);
    img1.Bitmap.SetSizeFrom(LayerBitmap);
    img1.LayerList.CombineResult.SetSizeFrom(img1.Bitmap);
    Changed;
  end;
end;

procedure TMDIChild.FormCreate(Sender: TObject);
var LLayerPanel : TigLiquidCrystal;
begin
    LLayerPanel := TigLiquidCrystal.Create(nil);
      LLayerPanel.BeginUpdate;
      //with img1.Bitmap do       LLayerPanel.LayerBitmap.SetSize(Width,height);
      //LLayerPanel.LayerBitmap.Clear($FF000000 or Cardinal(Random($FFFFFF)));
      //LLayerPanel.UpdateLayerThumbnail;
      LLayerPanel.EndUpdate;

      //LPanelIndex := GIntegrator.ActivePaintBox.LayerList.SelectedIndex + 1;
  img1.Bitmap.SetSizeFrom(LLayerPanel.LayerBitmap);
  img1.LayerList.CombineResult.SetSizeFrom(LLayerPanel.LayerBitmap);
  img1.LayerList.LayerPanels[0].LayerBitmap.SetSizeFrom(LLayerPanel.LayerBitmap);
  img1.LayerList.Add(LLayerPanel);
end;

end.
