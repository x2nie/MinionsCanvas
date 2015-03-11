object MDIChild: TMDIChild
  Left = 352
  Top = 124
  Width = 469
  Height = 533
  ActiveControl = img1
  Caption = 'MDI Child'
  Color = clBtnFace
  ParentFont = True
  FormStyle = fsMDIChild
  OldCreateOrder = False
  Position = poDefault
  Visible = True
  WindowState = wsMaximized
  OnActivate = FormActivate
  OnClose = FormClose
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object img1: TigPaintBox
    Left = 0
    Top = 0
    Width = 461
    Height = 482
    Align = alClient
    Bitmap.ResamplerClassName = 'TDraftResampler'
    BitmapAlign = baCenter
    RepaintMode = rmOptimizer
    Scale = 1.000000000000000000
    ScaleMode = smScale
    TabOrder = 0
  end
  object pnlZoom: TPanel
    Left = 0
    Top = 482
    Width = 461
    Height = 17
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    object gbrZoom: TGaugeBar
      Left = 48
      Top = 0
      Width = 193
      Height = 16
      Backgnd = bgPattern
      Max = 9
      ShowHandleGrip = True
      Style = rbsMac
      Position = 4
      OnMouseUp = gbrZoomMouseUp
    end
  end
end
