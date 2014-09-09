unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, GR32_Image, igCore_Viewer, igGrid_ListView,
  igSwatch_ListView, igCore_Items, igGrid, igSwatch, bivGrid;

type
  TForm1 = class(TForm)
    swatch1: TigSwatchList;
    btn1: TButton;
    dlgOpen1: TOpenDialog;
    swgrid1: TigSwatchGrid;
    btnClear: TButton;
    swgrid2: TigSwatchGrid;
    procedure btn1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnClearClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation
uses
  igSwatch_rwACO, igSwatch_rwASE;

{$R *.dfm}

type
  TigGridAccess = class(TigGrid);
procedure TForm1.btn1Click(Sender: TObject);
begin
  if dlgOpen1.Execute then
    swatch1.LoadFromFile(dlgOpen1.FileName);
end;

procedure TForm1.FormCreate(Sender: TObject);
var g : TigGrid;
begin
  dlgOpen1.Filter := TigSwatchList.ReadersFilter;
  {g := TigGrid.Create(self);
  g.Parent := self;
  TigGridAccess(g).ItemList := swatch1;}
end;

procedure TForm1.btnClearClick(Sender: TObject);
begin
  swatch1.Clear;
end;

end.
