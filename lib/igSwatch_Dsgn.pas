unit igSwatch_Dsgn;

(* ***** BEGIN LICENSE BLOCK *****
 * Version: MPL 1.1 or LGPL 2.1 with linking exception
 *
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * Alternatively, the contents of this file may be used under the terms of the
 * Free Pascal modified version of the GNU Lesser General Public License
 * Version 2.1 (the "FPC modified LGPL License"), in which case the provisions
 * of this license are applicable instead of those above.
 * Please see the file LICENSE.txt for additional information concerning this
 * license.
 *
 * The Initial Developer of this unit are
 *   x2nie  < x2nie[at]yahoo[dot]com >
 *
 * Contributor(s):
 *
 * ***** END LICENSE BLOCK ***** *)

interface

{$I GR32.inc}

uses
{$IFDEF FPC}
  LCLIntf, LCLType, RtlConsts, Buttons, LazIDEIntf, PropEdits,
  ComponentEditors,
{$ELSE}
  Windows, ExtDlgs, ToolWin, Registry, ImgList, Consts, DesignIntf,
  DesignEditors, VCLEditors,
{$ENDIF}
  Forms, Controls, ComCtrls, ExtCtrls, StdCtrls, Graphics, Dialogs, Menus,
  SysUtils, Classes, Clipbrd, GR32,
  igSwatch, igCore_Items, igGrid, GR32_Image, bivGrid

  ;

type

  TigSwatchListEditorForm = class(TForm)
    ImageList: TImageList;
    ToolBar: TToolBar;
    btnLoad: TToolButton;
    btnSave: TToolButton;
    btnClear: TToolButton;
    btn1: TToolButton;
    btnCopy: TToolButton;
    btnPaste: TToolButton;
    PopupMenu: TPopupMenu;
    mnLoad: TMenuItem;
    mnSave: TMenuItem;
    mnClear: TMenuItem;
    mnSeparator: TMenuItem;
    mnCopy: TMenuItem;
    mnPaste: TMenuItem;
    mnSeparator2: TMenuItem;
    mnInvert: TMenuItem;
    pnl1: TPanel;
    btnOKButton: TButton;
    btnCancel: TButton;
    pnl2: TPanel;
    SwatchList: TigSwatchList;
    SwatchGrid: TigSwatchGrid;
    dlgOpen1: TOpenDialog;
    dlgSave1: TSaveDialog;
    Splitter1: TSplitter;
    procedure btnLoadClick(Sender: TObject);
    procedure btnClearClick(Sender: TObject);
    procedure ToolBarResize(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
  public
    SwatchList1: TigSwatchList;
    function Execute: Boolean;
  end;


  TigSwatchListEditor = class(TComponentEditor)
  public
    procedure ExecuteVerb(Index: Integer); override;
    function GetVerb(Index: Integer): string; override;
    function GetVerbCount: Integer; override;
  end;


implementation

uses
  bivTheme_Standard,
  igSwatch_rwACO, igSwatch_rwASE;
  
{$R *.dfm}


{ TigSwatchListComponentEditor }

procedure TigSwatchListEditor.ExecuteVerb(Index: Integer);
var
  LSwatcs,LBackupSwatchs : TigSwatchList;
  Form: TigSwatchListEditorForm;
begin
  LSwatcs := Component as TigSwatchList;
  if Index = 0 then
  begin
    //LBackupSwatchs := TigSwatchList.Create(nil);
    //LBackupSwatchs.Assign(LSwatcs); //backup
    Form := TigSwatchListEditorForm.Create(nil);
    try
      //Form.SwatchList := LSwatcs;
      //Form.SwatchGrid.SwatchList := LSwatcs;
      Form.SwatchList.Assign(LSwatcs);
      if Form.Execute then
      begin
        LSwatcs.Assign(Form.SwatchList);
        Designer.Modified;
      end
      else
      begin
        //LSwatcs.Assign(LBackupSwatchs);
        //Designer.Modified;
      end;
    finally
      Form.Free;
      //LBackupSwatchs.Free;
    end;
  end;
end;

function TigSwatchListEditor.GetVerb(Index: Integer): string;
begin
  if Index = 0 then Result := 'Items Editor...';
end;

function TigSwatchListEditor.GetVerbCount: Integer;
begin
  Result := 1;
end;

function TigSwatchListEditorForm.Execute: Boolean;
begin
  result := ShowModal = mrOk;
end;

procedure TigSwatchListEditorForm.btnLoadClick(Sender: TObject);
begin
  dlgOpen1.Filter := TigSwatchList.ReadersFilter;
  if dlgOpen1.Execute then
  begin
    SwatchList.BeginUpdate;
    SwatchList.LoadFromFile(dlgOpen1.FileName);
    SwatchList.EndUpdate;
  end;

end;

procedure TigSwatchListEditorForm.btnClearClick(Sender: TObject);
begin
  SwatchList.Clear;
end;

procedure TigSwatchListEditorForm.ToolBarResize(Sender: TObject);
begin
  if ToolBar.Height < 30 then
    ToolBar.Height :=30
  else
  begin
    ToolBar.ShowCaptions := true; 
  end;

end;

procedure TigSwatchListEditorForm.FormCreate(Sender: TObject);
begin
  self.SwatchGrid.Theme := TbivTheme_Standard.Create(SwatchGrid);
end;

end.
