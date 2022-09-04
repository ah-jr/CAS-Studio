object MainForm: TMainForm
  Left = 0
  Top = 0
  BorderStyle = bsNone
  Caption = 'TPlayerGUI'
  ClientHeight = 294
  ClientWidth = 842
  Color = clBtnFace
  TransparentColorValue = clFuchsia
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnKeyDown = FormKeyDown
  PixelsPerInch = 96
  TextHeight = 13
  object cbDriver: TComboBox
    Left = 26
    Top = 50
    Width = 108
    Height = 21
    Style = csDropDownList
    TabOrder = 0
    OnChange = cbDriverChange
  end
  object btnPrev: TAcrylicButton
    Left = 144
    Top = 48
    Width = 65
    Height = 53
    Text = ''
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    Alignment = aCenter
    Color = x640F0F0F
    FontColor = claWhite
    BackColor = 2039583
    BorderColor = x34777777
    WithBorder = True
    WithBackground = True
    Ghost = False
    OnClick = btnPrevClick
    OnDblClick = btnPrevDblClick
  end
  object btnPlay: TAcrylicButton
    Left = 213
    Top = 48
    Width = 63
    Height = 53
    Text = ''
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    Alignment = aCenter
    Color = x640F0F0F
    FontColor = claWhite
    BackColor = 2039583
    BorderColor = x34777777
    WithBorder = True
    WithBackground = True
    Ghost = False
    OnClick = btnPlayClick
  end
  object btnNext: TAcrylicButton
    Left = 280
    Top = 48
    Width = 63
    Height = 53
    Text = ''
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    Alignment = aCenter
    Color = x640F0F0F
    FontColor = claWhite
    BackColor = 2039583
    BorderColor = x34777777
    WithBorder = True
    WithBackground = True
    Ghost = False
    OnClick = btnNextClick
  end
  object btnOpenFile: TAcrylicButton
    Left = 26
    Top = 77
    Width = 108
    Height = 24
    Text = 'Open File'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    Alignment = aCenter
    Color = x640F0F0F
    FontColor = claWhite
    BackColor = 2039583
    BorderColor = x34777777
    WithBorder = True
    WithBackground = True
    Ghost = False
    OnClick = btnOpenFileClick
  end
  object btnDriverControlPanel: TAcrylicButton
    Left = 26
    Top = 107
    Width = 108
    Height = 24
    Text = 'Driver Settings'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    Alignment = aCenter
    Color = x640F0F0F
    FontColor = claWhite
    BackColor = 2039583
    BorderColor = x34777777
    WithBorder = True
    WithBackground = True
    Ghost = False
    OnClick = btnDriverControlPanelClick
  end
  object lblTitle: TAcrylicLabel
    Left = 26
    Top = 8
    Width = 126
    Height = 17
    Text = 'CAS Studio'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Tahoma'
    Font.Style = []
    Alignment = aLeft
    Color = x640F0F0F
    FontColor = claWhite
    BackColor = 2039583
    BorderColor = x640F0F0F
    WithBorder = False
    WithBackground = False
    Ghost = True
  end
  object btnStop: TAcrylicButton
    Left = 347
    Top = 48
    Width = 63
    Height = 53
    Text = ''
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    Alignment = aCenter
    Color = x640F0F0F
    FontColor = claWhite
    BackColor = 2039583
    BorderColor = x34777777
    WithBorder = True
    WithBackground = True
    Ghost = False
    OnClick = btnStopClick
  end
  object lblTime: TAcrylicLabel
    Left = 347
    Top = 110
    Width = 63
    Height = 20
    Text = '0:00/0:00'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    Alignment = aCenter
    Color = x640F0F0F
    FontColor = claWhite
    BackColor = 2039583
    BorderColor = x34777777
    WithBorder = True
    WithBackground = True
    Ghost = False
  end
  object pnlBlurHint: TPanel
    Left = 700
    Top = 6
    Width = 50
    Height = 21
    Hint = '545'
    BevelOuter = bvNone
    ParentShowHint = False
    ShowHint = True
    TabOrder = 9
    object btnBlur: TAcrylicButton
      Left = 0
      Top = 0
      Width = 50
      Height = 21
      Text = 'BLUR'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      Alignment = aCenter
      Color = x640F0F0F
      FontColor = claWhite
      BackColor = 2039583
      BorderColor = x64070707
      WithBorder = True
      WithBackground = True
      Ghost = False
      OnClick = btnBlurClick
    end
  end
  object knbLevel: TAcrylicKnob
    Left = 426
    Top = 56
    Width = 30
    Height = 30
    Text = ''
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    Alignment = aCenter
    Color = x640F0F0F
    FontColor = claWhite
    BackColor = 2039583
    BorderColor = x64070707
    WithBorder = False
    WithBackground = False
    Ghost = False
    KnobColor = xFFFF8B64
    Level = 0.500000000000000000
    OnChange = knbLevelChange
  end
  object knbSpeed: TAcrylicKnob
    Left = 426
    Top = 103
    Width = 30
    Height = 30
    Text = ''
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    Alignment = aCenter
    Color = x640F0F0F
    FontColor = claWhite
    BackColor = 2039583
    BorderColor = x64070707
    WithBorder = False
    WithBackground = False
    Ghost = False
    KnobColor = xFFFF8B64
    Level = 0.500000000000000000
    OnChange = knbSpeedChange
  end
  object lblVolume: TAcrylicLabel
    Left = 420
    Top = 40
    Width = 42
    Height = 16
    Text = 'Volume'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    Alignment = aCenter
    Color = x640F0F0F
    FontColor = claWhite
    BackColor = 2039583
    BorderColor = x64070707
    WithBorder = False
    WithBackground = False
    Ghost = False
  end
  object lblPitch: TAcrylicLabel
    Left = 420
    Top = 87
    Width = 42
    Height = 16
    Text = 'Pitch'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    Alignment = aCenter
    Color = x640F0F0F
    FontColor = claWhite
    BackColor = 2039583
    BorderColor = x64070707
    WithBorder = False
    WithBackground = False
    Ghost = False
  end
  object lblLoading: TAcrylicLabel
    Left = 158
    Top = 8
    Width = 99
    Height = 17
    Text = 'Loading files...'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Tahoma'
    Font.Style = []
    Alignment = aLeft
    Color = x640F0F0F
    FontColor = claWhite
    BackColor = 2039583
    BorderColor = x640F0F0F
    WithBorder = False
    WithBackground = False
    Ghost = True
  end
  object tbProgress: TAcrylicTrackBar
    Left = 144
    Top = 110
    Width = 173
    Height = 20
    Text = ''
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    Alignment = aCenter
    Color = x640F0F0F
    FontColor = claWhite
    BackColor = 2039583
    BorderColor = x64070707
    WithBorder = False
    WithBackground = False
    Ghost = False
    TrackColor = xFF64FFFF
    OnChange = tbProgressChange
  end
  object btnBarFunc: TAcrylicButton
    Left = 323
    Top = 110
    Width = 20
    Height = 20
    Text = 'T'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    Alignment = aCenter
    Color = x640F0F0F
    FontColor = claWhite
    BackColor = 2039583
    BorderColor = x34777777
    WithBorder = True
    WithBackground = True
    Ghost = False
    OnClick = btnBarFuncClick
  end
  object btnInfo: TAcrylicButton
    Left = 263
    Top = 6
    Width = 21
    Height = 21
    Text = '?'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    Alignment = aCenter
    Color = x640F0F0F
    FontColor = claWhite
    BackColor = 2039583
    BorderColor = claChocolate
    WithBorder = True
    WithBackground = True
    Ghost = False
    OnClick = btnInfoClick
  end
  object pnlDesktop: TAcrylicGhostPanel
    Left = 26
    Top = 145
    Width = 436
    Height = 128
    Caption = 'pnlDesktop'
    Color = x001F1F1F
    TabOrder = 18
    Ghost = True
    Colored = False
    Backcolor = 2039583
    Bordercolor = claNull
    WithBorder = False
  end
  object btnExport: TAcrylicButton
    Left = 290
    Top = 8
    Width = 108
    Height = 25
    Text = 'Export'#13#10
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    Alignment = aCenter
    Color = x640F0F0F
    FontColor = claWhite
    BackColor = 2039583
    BorderColor = x34777777
    WithBorder = True
    WithBackground = True
    Ghost = False
    OnClick = btnExportClick
  end
  object odOpenFile: TOpenDialog
    Options = [ofHideReadOnly, ofAllowMultiSelect, ofEnableSizing]
    Left = 64
    Top = 88
  end
end
