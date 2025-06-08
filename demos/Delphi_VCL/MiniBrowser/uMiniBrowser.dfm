object MiniBrowserFrm: TMiniBrowserFrm
  Left = 0
  Top = 0
  Caption = 'MiniBrowser'
  ClientHeight = 711
  ClientWidth = 1180
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Position = poScreenCenter
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  TextHeight = 13
  object Splitter1: TSplitter
    Left = 1175
    Top = 41
    Width = 5
    Height = 651
    Align = alRight
    Visible = False
    ExplicitLeft = 0
    ExplicitTop = 657
    ExplicitHeight = 909
  end
  object NavControlPnl: TPanel
    Left = 0
    Top = 0
    Width = 1180
    Height = 41
    Align = alTop
    BevelOuter = bvNone
    Enabled = False
    TabOrder = 1
    object NavButtonPnl: TPanel
      Left = 0
      Top = 0
      Width = 133
      Height = 41
      Align = alLeft
      BevelOuter = bvNone
      TabOrder = 0
      object BackBtn: TButton
        Left = 8
        Top = 8
        Width = 25
        Height = 25
        Caption = '3'
        Font.Charset = SYMBOL_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'Webdings'
        Font.Style = []
        ParentFont = False
        TabOrder = 0
        OnClick = BackBtnClick
      end
      object ForwardBtn: TButton
        Left = 39
        Top = 8
        Width = 25
        Height = 25
        Caption = '4'
        Font.Charset = SYMBOL_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'Webdings'
        Font.Style = []
        ParentFont = False
        TabOrder = 1
        OnClick = ForwardBtnClick
      end
      object ReloadBtn: TButton
        Left = 70
        Top = 8
        Width = 25
        Height = 25
        Caption = 'q'
        Font.Charset = SYMBOL_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'Webdings'
        Font.Style = []
        ParentFont = False
        TabOrder = 2
        OnClick = ReloadBtnClick
      end
      object StopBtn: TButton
        Left = 101
        Top = 8
        Width = 25
        Height = 25
        Caption = '='
        Font.Charset = SYMBOL_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'Webdings'
        Font.Style = []
        ParentFont = False
        TabOrder = 3
        OnClick = StopBtnClick
      end
    end
    object URLEditPnl: TPanel
      Left = 133
      Top = 0
      Width = 974
      Height = 41
      Align = alClient
      BevelOuter = bvNone
      Padding.Top = 9
      Padding.Bottom = 8
      TabOrder = 1
      object URLCbx: TComboBox
        Left = 0
        Top = 9
        Width = 974
        Height = 21
        Align = alClient
        ItemIndex = 0
        TabOrder = 0
        Text = 'https://www.google.com'
        Items.Strings = (
          'https://www.google.com'
          
            'https://www.whatismybrowser.com/detect/what-http-headers-is-my-b' +
            'rowser-sending'
          'https://www.w3schools.com/js/tryit.asp?filename=tryjs_win_close'
          'https://www.w3schools.com/js/tryit.asp?filename=tryjs_alert'
          'https://www.w3schools.com/js/tryit.asp?filename=tryjs_loc_assign'
          
            'https://www.w3schools.com/jsref/tryit.asp?filename=tryjsref_styl' +
            'e_backgroundcolor'
          
            'https://www.w3schools.com/Tags/tryit.asp?filename=tryhtml_iframe' +
            '_name'
          
            'https://www.w3schools.com/tags/tryit.asp?filename=tryhtml5_input' +
            '_type_file'
          
            'https://www.w3schools.com/jsref/tryit.asp?filename=tryjsref_stat' +
            'e_throw_error'
          'https://www.htmlquick.com/es/reference/tags/input-file.html'
          
            'https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input/' +
            'file'
          
            'https://developer.mozilla.org/en-US/docs/Web/API/HTMLInputElemen' +
            't/webkitdirectory'
          'https://www.w3schools.com/html/html5_video.asp'
          'http://html5test.com/'
          
            'https://webrtc.github.io/samples/src/content/devices/input-outpu' +
            't/'
          'https://test.webrtc.org/'
          'https://www.browserleaks.com/webrtc'
          'https://shaka-player-demo.appspot.com/demo/'
          'http://webglsamples.org/'
          'https://get.webgl.org/'
          'https://www.briskbard.com'
          'https://www.youtube.com'
          'https://html5demos.com/drag/'
          'https://frames-per-second.appspot.com/'
          
            'https://www.sede.fnmt.gob.es/certificados/persona-fisica/verific' +
            'ar-estado'
          'https://www.kirupa.com/html5/accessing_your_webcam_in_html5.htm'
          'https://www.xdumaine.com/enumerateDevices/test/'
          
            'https://dagrs.berkeley.edu/sites/default/files/2020-01/sample.pd' +
            'f'
          'https://codepen.io/udaymanvar/pen/MWaePBY'
          
            'https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes/acc' +
            'ept'
          
            'https://codesandbox.io/p/sandbox/image-blob-example-0igon?file=%' +
            '2Fsrc%2FApp.js'
          'chrome://version/'
          'chrome://net-internals/'
          'chrome://tracing/'
          'chrome://appcache-internals/'
          'chrome://blob-internals/'
          'chrome://view-http-cache/'
          'chrome://credits/'
          'chrome://histograms/'
          'chrome://media-internals/'
          'chrome://kill'
          'chrome://crash'
          'chrome://hang'
          'chrome://shorthang'
          'chrome://gpuclean'
          'chrome://gpucrash'
          'chrome://gpuhang'
          'chrome://extensions-support'
          'chrome://process-internals')
      end
    end
    object ConfigPnl: TPanel
      Left = 1107
      Top = 0
      Width = 73
      Height = 41
      Align = alRight
      BevelOuter = bvNone
      TabOrder = 2
      object ConfigBtn: TButton
        Left = 40
        Top = 8
        Width = 25
        Height = 25
        Caption = #8801
        Font.Charset = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -17
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 0
        OnClick = ConfigBtnClick
      end
      object GoBtn: TButton
        Left = 8
        Top = 8
        Width = 25
        Height = 25
        Caption = #9658
        Font.Charset = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -17
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 1
        OnClick = GoBtnClick
      end
    end
  end
  object CEFWindowParent1: TCEFWindowParent
    Left = 0
    Top = 41
    Width = 1175
    Height = 651
    Align = alClient
    TabStop = True
    TabOrder = 0
  end
  object DevTools: TCEFWindowParent
    Left = 1180
    Top = 41
    Width = 0
    Height = 651
    Align = alRight
    TabOrder = 2
    Visible = False
  end
  object StatusBar1: TStatusBar
    Left = 0
    Top = 692
    Width = 1180
    Height = 19
    Panels = <
      item
        Width = 100
      end
      item
        Width = 500
      end
      item
        Width = 100
      end
      item
        Width = 100
      end
      item
        Width = 50
      end>
  end
  object Chromium1: TChromium
    OnTextResultAvailable = Chromium1TextResultAvailable
    OnPdfPrintFinished = Chromium1PdfPrintFinished
    OnPrefsAvailable = Chromium1PrefsAvailable
    OnResolvedHostAvailable = Chromium1ResolvedHostAvailable
    OnNavigationVisitorResultAvailable = Chromium1NavigationVisitorResultAvailable
    OnDownloadImageFinished = Chromium1DownloadImageFinished
    OnCookiesFlushed = Chromium1CookiesFlushed
    OnZoomPctAvailable = Chromium1ZoomPctAvailable
    OnRenderCompMsg = Chromium1RenderCompMsg
    OnLoadEnd = Chromium1LoadEnd
    OnLoadError = Chromium1LoadError
    OnLoadingStateChange = Chromium1LoadingStateChange
    OnBeforeContextMenu = Chromium1BeforeContextMenu
    OnContextMenuCommand = Chromium1ContextMenuCommand
    OnPreKeyEvent = Chromium1PreKeyEvent
    OnKeyEvent = Chromium1KeyEvent
    OnAddressChange = Chromium1AddressChange
    OnTitleChange = Chromium1TitleChange
    OnFullScreenModeChange = Chromium1FullScreenModeChange
    OnStatusMessage = Chromium1StatusMessage
    OnConsoleMessage = Chromium1ConsoleMessage
    OnLoadingProgressChange = Chromium1LoadingProgressChange
    OnMediaAccessChange = Chromium1MediaAccessChange
    OnCanDownload = Chromium1CanDownload
    OnBeforeDownload = Chromium1BeforeDownload
    OnDownloadUpdated = Chromium1DownloadUpdated
    OnAfterCreated = Chromium1AfterCreated
    OnBeforeClose = Chromium1BeforeClose
    OnCertificateError = Chromium1CertificateError
    OnSelectClientCertificate = Chromium1SelectClientCertificate
    OnBeforeResourceLoad = Chromium1BeforeResourceLoad
    OnResourceResponse = Chromium1ResourceResponse
    OnFileDialog = Chromium1FileDialog
    OnDevToolsMethodResult = Chromium1DevToolsMethodResult
    OnChromeCommand = Chromium1ChromeCommand
    OnRequestMediaAccessPermission = Chromium1RequestMediaAccessPermission
    Left = 32
    Top = 224
  end
  object PopupMenu1: TPopupMenu
    OnPopup = PopupMenu1Popup
    Left = 32
    Top = 168
    object DevTools1: TMenuItem
      Caption = 'DevTools'
      OnClick = DevTools1Click
    end
    object N4: TMenuItem
      Caption = '-'
    end
    object Openfile1: TMenuItem
      Caption = 'Open file with a FILE URL...'
      OnClick = Openfile1Click
    end
    object OpenfilewithaDAT1: TMenuItem
      Caption = 'Open file with a DATA URL...'
      OnClick = OpenfilewithaDAT1Click
    end
    object SaveasMHTML1: TMenuItem
      Caption = 'Save as MHTML...'
      OnClick = SaveasMHTML1Click
    end
    object N2: TMenuItem
      Caption = '-'
    end
    object Print1: TMenuItem
      Caption = 'Print'
      OnClick = Print1Click
    end
    object PrintinPDF1: TMenuItem
      Caption = 'Print to PDF file...'
      OnClick = PrintinPDF1Click
    end
    object N3: TMenuItem
      Caption = '-'
    end
    object Zoom1: TMenuItem
      Caption = 'Zoom'
      object Inczoom1: TMenuItem
        Caption = 'Inc zoom'
        OnClick = Inczoom1Click
      end
      object Deczoom1: TMenuItem
        Caption = 'Dec zoom'
        OnClick = Deczoom1Click
      end
      object Resetzoom1: TMenuItem
        Caption = 'Reset zoom'
        OnClick = Resetzoom1Click
      end
    end
    object N1: TMenuItem
      Caption = '-'
    end
    object Preferences1: TMenuItem
      Caption = 'Preferences...'
      OnClick = Preferences1Click
    end
    object Resolvehost1: TMenuItem
      Caption = 'Resolve host...'
      OnClick = Resolvehost1Click
    end
    object Downloadimage1: TMenuItem
      Caption = 'Download image...'
      OnClick = Downloadimage1Click
    end
    object Downloadfile1: TMenuItem
      Caption = 'Download file...'
      OnClick = Downloadfile1Click
    end
    object Simulatekeyboardpresses1: TMenuItem
      Caption = 'Simulate keyboard presses'
      OnClick = Simulatekeyboardpresses1Click
    end
    object Acceptlanguage1: TMenuItem
      Caption = 'Accept language...'
      OnClick = Acceptlanguage1Click
    end
    object Flushcookies1: TMenuItem
      Caption = 'Flush cookies'
      OnClick = Flushcookies1Click
    end
    object FindText1: TMenuItem
      Caption = 'Find text...'
      OnClick = FindText1Click
    end
    object Clearcache1: TMenuItem
      Caption = 'Clear cache'
      OnClick = Clearcache1Click
    end
    object ClearallstorageforcurrentURL1: TMenuItem
      Caption = 'Clear all storage for current URL'
      OnClick = ClearallstorageforcurrentURL1Click
    end
    object akescreenshot1: TMenuItem
      Caption = 'Take screenshot'
      OnClick = akescreenshot1Click
    end
    object Useragent1: TMenuItem
      Caption = 'User agent...'
      OnClick = Useragent1Click
    end
    object Allowdownloads1: TMenuItem
      Caption = 'Allow downloads'
      OnClick = Allowdownloads1Click
    end
    object Toggleaudio1: TMenuItem
      Caption = 'Toggle audio'
      OnClick = Toggleaudio1Click
    end
    object N5: TMenuItem
      Caption = '-'
    end
    object Memoryinfo1: TMenuItem
      Caption = 'Memory info...'
      OnClick = Memoryinfo1Click
    end
    object CEFinfo1: TMenuItem
      Caption = 'CEF info...'
      OnClick = CEFinfo1Click
    end
  end
  object SaveDialog1: TSaveDialog
    Left = 32
    Top = 112
  end
  object ApplicationEvents1: TApplicationEvents
    OnMessage = ApplicationEvents1Message
    Left = 32
    Top = 56
  end
  object OpenDialog1: TOpenDialog
    Filter = 
      'HTML files|*.htm;*.html|Text files|*.txt|PDF files|*.pdf|Image f' +
      'iles|*.jpg;*.jpeg;*.png;*.bmp;*.gif'
    Left = 32
    Top = 280
  end
  object Timer1: TTimer
    Enabled = False
    Interval = 300
    OnTimer = Timer1Timer
    Left = 32
    Top = 344
  end
end
