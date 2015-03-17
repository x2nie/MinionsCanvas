object Form1: TForm1
  Left = 117
  Top = 222
  Width = 645
  Height = 365
  Caption = 'Hello-World'
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
  object lbl1: TLabel
    Left = 8
    Top = 8
    Width = 191
    Height = 13
    Caption = 'Drag mouse  to start paint in bellow box :'
  end
  object imgWorkArea: TicPaintBox
    Left = 8
    Top = 24
    Width = 300
    Height = 300
    Bitmap.ResamplerClassName = 'TNearestResampler'
    BitmapAlign = baTopLeft
    Scale = 1.000000000000000000
    ScaleMode = smNormal
    TabOrder = 0
  end
  object Memo1: TMemo
    Left = 328
    Top = 48
    Width = 289
    Height = 233
    Cursor = crArrow
    BevelInner = bvNone
    BevelOuter = bvNone
    BorderStyle = bsNone
    Color = clBtnFace
    Lines.Strings = (
      'Wellcome to MinionsCanvas ( iSee )'
      '-= hello world demo =-'
      ''
      'This application show you about How easy to use '
      'MinionsCanvas components.'
      '1. Just drop a TicPaintBox from Delphi'#39's '
      'Component Palette into your TForm.'
      '2. Set a drawingtool to the integrator '
      '&.. Done! anything else will be set up '
      'automagically.'
      ''
      'If you need more, just drop more MinionsCanvas component '
      '(LayerListBox, etc.) to the form.'
      ''
      'You can do more, by inheriting the TicTool or TicLayer,'
      'and integrate them in your application as plugins.'
      ''
      'see next demo for sample usage.')
    TabOrder = 1
  end
end
