inherited UpdateLocaleForm: TUpdateLocaleForm
  HelpContext = 160
  Caption = 'Update Locale'
  ClientHeight = 105
  ExplicitHeight = 144
  PixelsPerInch = 96
  TextHeight = 13
  object LocalePanel: TPanel
    AlignWithMargins = True
    Left = 5
    Top = 0
    Width = 442
    Height = 33
    Margins.Left = 5
    Margins.Top = 0
    Margins.Right = 0
    Margins.Bottom = 0
    Align = alTop
    Alignment = taLeftJustify
    BevelOuter = bvNone
    Caption = 'LocalePanel'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -21
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 0
  end
  object FileNamePanel: TPanel
    AlignWithMargins = True
    Left = 5
    Top = 33
    Width = 442
    Height = 21
    Margins.Left = 5
    Margins.Top = 0
    Margins.Right = 0
    Margins.Bottom = 0
    Align = alTop
    Alignment = taLeftJustify
    BevelOuter = bvNone
    Caption = 'FileNamePanel'
    TabOrder = 1
  end
  object StatusPanel: TPanel
    AlignWithMargins = True
    Left = 5
    Top = 84
    Width = 442
    Height = 21
    Margins.Left = 5
    Margins.Top = 0
    Margins.Right = 0
    Margins.Bottom = 0
    Align = alBottom
    Alignment = taLeftJustify
    BevelOuter = bvNone
    Caption = 'StatusPanel'
    TabOrder = 2
  end
  object bbUpdate: TButton
    Left = 5
    Top = 57
    Width = 75
    Height = 25
    Action = UpdateAction
    TabOrder = 3
  end
  object cbUpdateAttributes: TCheckBox
    Left = 91
    Top = 61
    Width = 283
    Height = 17
    Caption = 'Update localizable attributes into yaml files'
    Checked = True
    State = cbChecked
    TabOrder = 4
  end
  object ActionList: TActionList
    Left = 304
    Top = 32
    object UpdateAction: TAction
      Caption = 'Update'
      OnExecute = UpdateActionExecute
      OnUpdate = UpdateActionUpdate
    end
  end
end
