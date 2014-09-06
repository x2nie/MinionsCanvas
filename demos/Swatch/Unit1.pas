unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, GR32_Image, igCore_Viewer, igGrid_ListView,
  igSwatch_ListView, igCore_Items, igGrid, igSwatch;

type
  TForm1 = class(TForm)
    swatch1: TigSwatchList;
    lst2: TigSwatchListView;  
    btn1: TButton;
    dlgOpen1: TOpenDialog;
    procedure btn1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation
uses
  igSwatch_rwACO;

{$R *.dfm}

procedure TForm1.btn1Click(Sender: TObject);
begin
  if dlgOpen1.Execute then
    swatch1.LoadFromFile(dlgOpen1.FileName);    
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  dlgOpen1.Filter :=
  TigSwatchList.ReadersFilter;
end;

end.
