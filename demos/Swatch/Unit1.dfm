object Form1: TForm1
  Left = 222
  Top = 144
  Width = 928
  Height = 480
  Caption = 'Form1'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object lst2: TigSwatchListView
    Left = 208
    Top = 56
    Width = 192
    Height = 192
    Bitmap.ResamplerClassName = 'TKernelResampler'
    Bitmap.Resampler.KernelClassName = 'TBoxKernel'
    Bitmap.Resampler.KernelMode = kmDynamic
    Bitmap.Resampler.TableSize = 32
    BitmapAlign = baCustom
    ParentShowHint = False
    Scale = 1.000000000000000000
    ScaleMode = smScale
    ScrollBars.ShowHandleGrip = True
    ScrollBars.Style = rbsDefault
    ScrollBars.Size = 17
    ShowHint = True
    OverSize = 0
    TabOrder = 0
    SwatchList = swatch1
    CellBorderStyle = borSwatch
  end
  object btn1: TButton
    Left = 112
    Top = 176
    Width = 75
    Height = 25
    Caption = 'btn1'
    TabOrder = 1
    OnClick = btn1Click
  end
  object swatch1: TigSwatchList
    Collection = <
      item
        DisplayName = 'Custom'
        Color = clBlue
        Data = {}
      end
      item
        DisplayName = 'Custom'
        Color = clYellow
        Data = {}
      end
      item
        DisplayName = 'Custom'
        Color = clWhite
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
