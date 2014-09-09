object Form1: TForm1
  Left = 343
  Top = 108
  Width = 918
  Height = 480
  Caption = 'Form1'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  ShowHint = True
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object btn1: TButton
    Left = 24
    Top = 224
    Width = 75
    Height = 25
    Caption = 'btn1'
    TabOrder = 1
    OnClick = btn1Click
  end
  object swgrid1: TigSwatchGrid
    Left = 0
    Top = 0
    Width = 910
    Height = 193
    Align = alTop
    Options.PaintBox32 = [pboWantArrowKeys, pboAutoFocus]
    Options.MultiSelect = True
    Options.ListMode = True
    SwatchList = swatch1
  end
  object btnClear: TButton
    Left = 32
    Top = 280
    Width = 75
    Height = 25
    Caption = 'Clear'
    TabOrder = 3
    OnClick = btnClearClick
  end
  object swgrid2: TigSwatchGrid
    Left = 400
    Top = 216
    Width = 225
    Height = 209
    Options.PaintBox32 = [pboWantArrowKeys, pboAutoFocus]
    Options.MultiSelect = False
    Options.ListMode = False
    SwatchList = swatch1
  end
  object swatch1: TigSwatchList
    Collection = <
      item
        DisplayName = 'Custom1'
        Color = clFuchsia
        Data = {}
      end
      item
        DisplayName = 'Custom2'
        Color = clYellow
        Data = {}
      end
      item
        DisplayName = 'Custom3'
        Color = clWhite
        Data = {}
      end
      item
        DisplayName = 'Custom'
        Color = clLime
        Data = {}
      end>
    Left = 128
    Top = 48
  end
  object dlgOpen1: TOpenDialog
    Left = 96
    Top = 104
  end
end
