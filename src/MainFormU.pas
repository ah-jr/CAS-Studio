/// /////////////////////////////////////////////////////////////////////////////
//
// CAS Studio
//
// Uses CasEngine to implement an audio editor.
//
// Creation: 07/08/2022 by Airton Junior
//
/// /////////////////////////////////////////////////////////////////////////////
unit MainFormU;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.Classes,
  System.SysUtils,
  System.UITypes,
  System.ImageList,
  System.Generics.Collections,
  Vcl.ComCtrls,
  Vcl.StdCtrls,
  Vcl.Dialogs,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.ImgList,
  Vcl.ExtCtrls,
  AsioList,
  Math,
  ShellApi,
  IOUtils,
  GDIPOBJ,
  CasTrackU,
  CasConstantsU,
  AcrylicFormU,
  AcrylicButtonU,
  AcrylicTrackU,
  AcrylicLabelU,
  AcrylicGhostPanelU,
  AcrylicControlU,
  AcrylicScrollBoxU,
  AcrylicKnobU,
  AcrylicFrameU,
  AcrylicTrackBarU,
  AudioManagerU,
  TypesU;

type
  TMainForm = class(TAcrylicForm, IAudioListener)
    odOpenFile            : TOpenDialog;
    cbDriver              : TComboBox;
    btnPrev               : TAcrylicButton;
    btnPlay               : TAcrylicButton;
    btnNext               : TAcrylicButton;
    btnOpenFile           : TAcrylicButton;
    btnDriverControlPanel : TAcrylicButton;
    btnStop               : TAcrylicButton;
    btnBlur               : TAcrylicButton;
    btnBarFunc            : TAcrylicButton;
    btnInfo               : TAcrylicButton;
    lblTime               : TAcrylicLabel;
    lblTitle              : TAcrylicLabel;
    lblVolume             : TAcrylicLabel;
    lblPitch              : TAcrylicLabel;
    lblLoading            : TAcrylicLabel;
    sbTracks              : TAcrylicScrollBox;
    knbLevel              : TAcrylicKnob;
    knbSpeed              : TAcrylicKnob;
    pnlBlurHint           : TPanel;
    tbProgress            : TAcrylicTrackBar;


    procedure FormCreate                 (Sender: TObject);
    procedure FormDestroy                (Sender: TObject);
    procedure FormKeyDown                (Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure cbDriverChange             (Sender: TObject);
    procedure btnDriverControlPanelClick (Sender: TObject);
    procedure btnStopClick               (Sender: TObject);
    procedure btnPlayClick               (Sender: TObject);
    procedure btnPrevClick               (Sender: TObject);
    procedure btnNextClick               (Sender: TObject);
    procedure btnBlurClick               (Sender: TObject);
    procedure btnPrevDblClick            (Sender: TObject);
    procedure btnCloseClick              (Sender: TObject);
    procedure btnAddClick                (Sender: TObject);
    procedure btnUpClick                 (Sender: TObject);
    procedure btnDownClick               (Sender: TObject);
    procedure btnOpenFileClick           (Sender: TObject);
    procedure btnBarFuncClick            (Sender: TObject);
    procedure btnInfoClick               (Sender: TObject);
    procedure trackClick                 (Sender: TObject);
    procedure trackWheelUp               (Sender: TObject; Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);
    procedure trackWheelDown             (Sender: TObject; Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);
    procedure tbProgressChange           (Sender: TObject);
    procedure knbLevelChange             (Sender: TObject);
    procedure knbSpeedChange             (Sender: TObject);

    procedure WMNCSize(var Message: TWMSize); message WM_SIZE;


  private
    m_dctFrames                  : TDictionary<Integer, TAcrylicFrame>;
    m_AudioManager               : TAudioManager;

    m_bBlockBufferPositionUpdate : Boolean;
    m_bPlaylistBar               : Boolean;
    m_bStartPlaying              : Boolean;
    m_nLoadedTrackCount          : Integer;

    m_DriverList                 : TAsioDriverList;
    m_lstTracks                  : TList<TAcrylicGhostPanel>;
    m_lstFiles                   : TStringList;

    procedure AddTrackInfo(a_CasTrack : TCasTrack);

    procedure InitializeVariables;
    procedure InitializeControls;
    procedure InitializeFrames;
    procedure LoadFiles;
    procedure ChangeEnabledObjects;
    procedure UpdateBufferPosition;
    procedure UpdateProgressBar;
    procedure RearrangeTracks;
    procedure SwapTracks(a_nTrack1, a_nTrack2 : Integer);

    procedure UpdateProgress(a_dProgress : Double);
    procedure AddTrack      (a_nTrackID  : Integer);
    procedure RemoveTrack   (a_nTrackID  : Integer);
    procedure UpdateGUI;
    procedure DriverChange;

end;

const
  c_nPanelHeight   = 75;
  c_nPanelOffset   = 3;
  c_nFirstPanelTop = 3;
  c_nPanelGap      = 10;
  c_nButtonWidth   = 25;
  c_nButtonHeight  = 25;
  c_nButtonRight1  = 30;
  c_nButtonRight2  = 58;
  c_nButtonTop1    = 1;
  c_nButtonTop2    = 29;
  c_nTrackOffset   = 61;
  c_nBntBlurRight  = 150;

var
  MainForm: TMainForm;

implementation

uses
  GDIPAPI,
  GDIPUTIL,
  Vcl.Imaging.pngimage,
  CasUtilsU,
  CasTypesU,
  Registry,
  AcrylicUtilsU,
  AcrylicTypesU,
  InfoFrameU,
  PlaylistFrameU;

{$R *.dfm}

//==============================================================================
procedure TMainForm.FormCreate(Sender: TObject);
begin
  Caption     := 'CAS Studio';
  Resizable   := False;
  BlurColor   := $000000;
  BackColor   := $1F1F1F;
  WithBorder  := True;
  BorderColor := $A064FFFF;
  BlurAmount  := 210;
  KeyPreview  := True;
  Resizable   := True;

  Left        := 30;
  Top         := 30;
  Width       := Screen.WorkAreaRect.Width  - 200;
  Height      := Screen.WorkAreaRect.Height - 200;

  MinWidth    := 500;
  MinHeight   := 700;

  Style       := [fsClose, fsMinimize, fsMaximize];

  InitializeVariables;
  InitializeControls;
  InitializeFrames;
  LoadFiles;

  ChangeEnabledObjects;

  Inherited;
end;

//==============================================================================
procedure TMainForm.InitializeControls;
var
  pngImage : TPngImage;
begin
  pngImage := TPngImage.Create;
  pngImage.LoadFromResourceName(HInstance, 'btnPlay');
  btnPlay.Png := pngImage;

  pngImage := TPngImage.Create;
  pngImage.LoadFromResourceName(HInstance, 'btnPrev');
  btnPrev.Png := pngImage;

  pngImage := TPngImage.Create;
  pngImage.LoadFromResourceName(HInstance, 'btnNext');
  btnNext.Png := pngImage;

  pngImage := TPngImage.Create;
  pngImage.LoadFromResourceName(HInstance, 'btnStop');
  btnStop.Png := pngImage;

  btnBlur.Enabled     := SupportBlur;
  btnBlur.WithBorder  := True;
  btnBlur.FontColor   := $FFFF8B64;
  btnBlur.BorderColor := $1FFF8B64;

  btnBarFunc.FontColor := c_clSeaBlue;
  btnBarFunc.Text      := 'P';

  lblLoading.FontColor := $FFFF8B64;
  lblLoading.Visible   := False;

  btnBlur.ShowHint     := True;
  btnBlur.Hint         := 'Blur is available in Windows 10';
  pnlBlurHint.ShowHint := True;
  pnlBlurHint.Hint     := btnBlur.Hint;

  btnPrev.TriggerDblClick := True;

  btnInfo.FontColor    := $FFFF8B64;
  btnInfo.BorderColor  := $1FFF8B64;
end;

//==============================================================================
procedure TMainForm.InitializeFrames;
var
  afFrame : TAcrylicFrame;
begin
  //////////////////////////////////////////////////////////////////////////////
  ///  InfoFrame
  afFrame        := TInfoFrame.Create(Self);
  afFrame.Parent := Self;
  afFrame.Left   := (ClientWidth  - afFrame.Width)  div 2;
  afFrame.Top    := (ClientHeight - afFrame.Height) div 2;
  m_dctFrames.AddOrSetValue(FID_Info, afFrame);

  //////////////////////////////////////////////////////////////////////////////
  ///  PlaylistFrame
  afFrame        := TPlaylistFrame.Create(sbTracks, m_AudioManager);
  afFrame.Parent := sbTracks;
  afFrame.Left   := 10;
  afFrame.Top    := 10;
  afFrame.Width  := 300;
  afFrame.Height := 300;
  afFrame.Visible := True;
  m_dctFrames.AddOrSetValue(FID_Playlist, afFrame);
end;

//==============================================================================
procedure TMainForm.LoadFiles;
begin
  if ParamCount > 0 then
  begin
    m_lstFiles.Clear;
    m_lstFiles.Add(ParamStr(1));
    m_bStartPlaying    := True;
    lblLoading.Visible := True;

    m_AudioManager.AsyncDecodeFile(m_lstFiles);
  end;
end;

//==============================================================================
procedure TMainForm.FormDestroy(Sender: TObject);
var
  pnlPanel : TAcrylicGhostPanel;
begin
  m_AudioManager.RemoveListener(Self);

  m_AudioManager.Free;
  m_dctFrames.Free;

  for pnlPanel in m_lstTracks do
    pnlPanel.Destroy;

  FreeAndNil(m_lstTracks);
  FreeAndNil(m_lstFiles);

  SetLength(m_DriverList, 0);
end;

//==============================================================================
procedure TMainForm.WMNCSize(var Message: TWMSize);
var
  nIndex : Integer;
begin
  inherited;

  pnlBlurHint.Left := ClientWidth - pnlBlurHint.Width - c_nBntBlurRight;
  btnInfo.Left     := pnlBlurHint.Left - btnInfo.Width - 5;

  sbTracks.Width  := ClientWidth  - 50;
  sbTracks.Height := ClientHeight - 170;

  if (m_lstTracks <> nil) then
  begin
    for nIndex := 0 to m_lstTracks.Count - 1 do
    begin
      (m_lstTracks.Items[nIndex] as TAcrylicGhostPanel).Width := sbTracks.ScrollPanel.Width - 2 * c_nPanelOffset;

      (m_lstTracks.Items[nIndex] as TAcrylicGhostPanel).Controls[0].Left := sbTracks.ScrollPanel.Width - 2 * c_nPanelOffset - c_nButtonRight2;
      (m_lstTracks.Items[nIndex] as TAcrylicGhostPanel).Controls[1].Left := sbTracks.ScrollPanel.Width - 2 * c_nPanelOffset - c_nButtonRight2;
      (m_lstTracks.Items[nIndex] as TAcrylicGhostPanel).Controls[2].Left := sbTracks.ScrollPanel.Width - 2 * c_nPanelOffset - c_nButtonRight1;
      (m_lstTracks.Items[nIndex] as TAcrylicGhostPanel).Controls[3].Left := sbTracks.ScrollPanel.Width - 2 * c_nPanelOffset - c_nButtonRight1;

      (m_lstTracks.Items[nIndex] as TAcrylicGhostPanel).Controls[4].Width := sbTracks.ScrollPanel.Width - 2 * c_nPanelOffset - c_nTrackOffset;
    end;
  end;
end;

//==============================================================================
procedure TMainForm.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_SPACE then
    btnPlayClick(nil);

  if GE_L(Key, $30, $3A) and ((Key - 49) <  m_lstTracks.Count) then
    m_AudioManager.GoToTrack(StrToInt(String((m_lstTracks.Items[Key - 49] as TAcrylicGhostPanel).Name).SubString(3)));
end;

//==============================================================================
procedure TMainForm.InitializeVariables;
var
  nDriverIdx : Integer;
begin
  m_dctFrames    := TDictionary<Integer, TAcrylicFrame>.Create;
  m_AudioManager := TAudioManager.Create;
  m_AudioManager.AddListener(Self);

  m_lstTracks   := TList<TAcrylicGhostPanel>.Create;
  m_lstFiles    := TStringList.Create;

  knbLevel.Level := 0.7;
  knbSpeed.Level := 0.5;

  m_nLoadedTrackCount := 0;

  m_bPlaylistBar               := True;
  m_bStartPlaying              := False;
  m_bBlockBufferPositionUpdate := False;

  SetLength(m_DriverList, 0);
  ListAsioDrivers(m_DriverList);
  cbDriver.Items.Add('DirectSound');

  for nDriverIdx := Low(m_DriverList) to High(m_DriverList) do
    cbDriver.Items.Add(String(m_DriverList[nDriverIdx].name));

  cbDriver.ItemIndex := 0;
  cbDriverChange(cbDriver);
end;

//==============================================================================
procedure TMainForm.ChangeEnabledObjects;
begin
  btnOpenFile.Enabled           := (m_AudioManager.GetReady);
  btnDriverControlPanel.Enabled := (m_AudioManager.GetReady) and
                                   (m_AudioManager.Engine.DriverType = dtASIO);

  btnPlay.Enabled               := (m_AudioManager.GetReady) and
                                   (m_nLoadedTrackCount > 0);

  btnStop.Enabled               := (m_nLoadedTrackCount > 0);
  btnPrev.Enabled               := (m_nLoadedTrackCount > 0);
  btnNext.Enabled               := (m_nLoadedTrackCount > 0);
  btnBarFunc.Enabled            := (m_nLoadedTrackCount > 0);
  tbProgress.Enabled            := (m_nLoadedTrackCount > 0);

  RefreshAcrylicControls(Self);
end;

//==============================================================================
procedure TMainForm.cbDriverChange(Sender: TObject);
var
  dtDriverType : TDriverType;
  pngImage     : TPngImage;
begin
  if cbDriver.ItemIndex = 0
    then dtDriverType := dtDirectSound
    else dtDriverType := dtASIO;

  m_AudioManager.ChangeDriver(dtDriverType, cbDriver.ItemIndex - 1);
  m_AudioManager.Engine.AsyncUpdate := dtDriverType = dtDirectSound;

  pngImage    := TPngImage.Create;
  pngImage.LoadFromResourceName(HInstance, 'btnPlay');
  btnPlay.Png := pngImage;

  ChangeEnabledObjects;
end;

//==============================================================================
procedure TMainForm.btnOpenFileClick(Sender: TObject);
begin
  if odOpenFile.Execute then
  begin
    try
      m_AudioManager.AsyncDecodeFile(odOpenFile.Files);

      lblLoading.Visible := True;
    finally
    end;
  end;
end;

//==============================================================================
procedure TMainForm.btnDriverControlPanelClick(Sender: TObject);
begin
  if m_AudioManager.GetReady then
    m_AudioManager.ControlPanel;
end;

//==============================================================================
procedure TMainForm.btnInfoClick(Sender: TObject);
var
  afFrame : TAcrylicFrame;
begin
  if m_dctFrames.TryGetValue(FID_Info, afFrame) then
    AfFrame.Visible := not AfFrame.Visible;
end;

//==============================================================================
procedure TMainForm.btnPlayClick(Sender: TObject);
var
  pngImage : TPngImage;
begin
  if m_AudioManager.GetPlaying then
  begin
    pngImage    := TPngImage.Create;
    pngImage.LoadFromResourceName(HInstance, 'btnPlay');
    btnPlay.Png := pngImage;

    m_AudioManager.Pause;
  end
  else
  begin
    pngImage    := TPngImage.Create;
    pngImage.LoadFromResourceName(HInstance, 'btnPause');
    btnPlay.Png := pngImage;

    m_AudioManager.Play;
  end;

  ChangeEnabledObjects;
end;

//==============================================================================
procedure TMainForm.btnStopClick(Sender: TObject);
var
  pngImage : TPngImage;
begin
  pngImage    := TPngImage.Create;
  pngImage.LoadFromResourceName(HInstance, 'btnPlay');
  btnPlay.Png := pngImage;

  m_AudioManager.Stop;
  UpdateProgressBar;
  ChangeEnabledObjects;
end;

//==============================================================================
procedure TMainForm.btnPrevClick(Sender: TObject);
begin
  m_AudioManager.Prev;
  UpdateProgressBar;
  ChangeEnabledObjects;
end;

//==============================================================================
procedure TMainForm.btnNextClick(Sender: TObject);
begin
  m_AudioManager.Next;
  UpdateProgressBar;
  ChangeEnabledObjects;
end;

//==============================================================================
procedure TMainForm.btnPrevDblClick(Sender: TObject);
begin
  m_AudioManager.Prev;
  m_AudioManager.Prev;
  UpdateProgressBar;
  ChangeEnabledObjects;
end;

//==============================================================================
procedure TMainForm.knbLevelChange(Sender: TObject);
begin
  m_AudioManager.SetLevel(knbLevel.Level);
end;

//==============================================================================
procedure TMainForm.knbSpeedChange(Sender: TObject);
begin
  m_AudioManager.Engine.Playlist.Speed := 2 * knbSpeed.Level;
end;

//==============================================================================
procedure TMainForm.tbProgressChange(Sender: TObject);
begin
  UpdateBufferPosition;
end;

//==============================================================================
procedure TMainForm.UpdateBufferPosition;
var
  CasTrack  : TCasTrack;
begin
  if not m_bBlockBufferPositionUpdate then
  begin
    if m_bPlaylistBar then
      m_AudioManager.SetPosition(Trunc(tbProgress.Level * m_AudioManager.GetLength))
    else
    begin
      if (m_AudioManager.GetActiveTracks.Count > 0) and
         (m_AudioManager.GetTrackById(m_AudioManager.GetActiveTracks.Items[0], CasTrack)) then
      begin
        m_AudioManager.SetPosition(CasTrack.Position + Trunc(tbProgress.Level * CasTrack.Size));
      end;
    end;
  end;
end;

//==============================================================================
procedure TMainForm.UpdateProgressBar;
var
  CasTrack  : TCasTrack;
  dProgress : Double;
  nPanelIdx : Integer;
begin
  m_bBlockBufferPositionUpdate := True;
  if m_bPlaylistBar then
  begin
    tbProgress.Level := m_AudioManager.GetProgress;
    lblTime.Text     := m_AudioManager.GetTime + '/' + m_AudioManager.GetDuration;
  end
  else
  begin
    if m_AudioManager.GetActiveTracks.Count > 0 then
    begin
      tbProgress.Level := m_AudioManager.GetTrackProgress(m_AudioManager.GetActiveTracks.Items[0]);
      lblTime.Text     := m_AudioManager.GetTime + '/' + m_AudioManager.GetDuration;
    end
    else
    begin
      tbProgress.Level := 0;
      lblTime.Text     := m_AudioManager.GetTime + '/' + m_AudioManager.GetDuration;
    end;
  end;
  m_bBlockBufferPositionUpdate := False;

  for nPanelIdx := 0 to m_lstTracks.Count - 1 do
  begin
    if m_AudioManager.GetTrackByID(StrToInt(String((m_lstTracks.Items[nPanelIdx] as TAcrylicGhostPanel).Name).SubString(3)), CasTrack) then
    begin
      dProgress := (m_AudioManager.GetPosition - CasTrack.Position) / CasTrack.Size;

      ((m_lstTracks.Items[nPanelIdx] as TAcrylicGhostPanel).Controls[4] as TAcrylicTrack).Position := dProgress;
      ((m_lstTracks.Items[nPanelIdx] as TAcrylicGhostPanel).Controls[4] as TAcrylicTrack).Refresh;
    end;
  end;
end;

//==============================================================================
procedure TMainForm.RearrangeTracks;
var
  nPanelIdx   : Integer;
  TotalLength : Integer;
  CasTrack    : TCasTrack;
begin
  TotalLength := 0;

  for nPanelIdx := 0 to m_lstTracks.Count - 1 do
  begin
    (m_lstTracks.Items[nPanelIdx] as TAcrylicGhostPanel).Top := nPanelIdx * (c_nPanelGap + c_nPanelHeight) + c_nFirstPanelTop;

    if m_AudioManager.GetTrackByID(StrToInt(String((m_lstTracks.Items[nPanelIdx] as TAcrylicGhostPanel).Name).SubString(3)), CasTrack) then
    begin
      CasTrack.Position := TotalLength;
      TotalLength := TotalLength + CasTrack.Size;

      ((m_lstTracks.Items[nPanelIdx] as TAcrylicGhostPanel).Controls[4] as TAcrylicTrack).Text := IntToStr(nPanelIdx + 1) + ') ' + CasTrack.Title;
    end;
  end;
end;

//==============================================================================
procedure TMainForm.SwapTracks(a_nTrack1, a_nTrack2 : Integer);
var
  pnlTrack1 : TAcrylicGhostPanel;
  pnlTrack2 : TAcrylicGhostPanel;
begin
  if (a_nTrack1 < m_lstTracks.Count) and
     (a_nTrack2 < m_lstTracks.Count) and
     (a_nTrack1 <> a_nTrack2)        and
     (a_nTrack1 >= 0)                and
     (a_nTrack2 >= 0) then
  begin
    pnlTrack1 := m_lstTracks.Items[a_nTrack1];
    pnlTrack2 := m_lstTracks.Items[a_nTrack2];

    m_lstTracks.Remove(pnlTrack1);
    m_lstTracks.Remove(pnlTrack2);

    if a_nTrack1 < a_nTrack2 then
    begin
      m_lstTracks.Insert(a_nTrack1, pnlTrack2);
      m_lstTracks.Insert(a_nTrack2, pnlTrack1);
    end
    else
    begin
      m_lstTracks.Insert(a_nTrack2, pnlTrack1);
      m_lstTracks.Insert(a_nTrack1, pnlTrack2);
    end;

    RearrangeTracks;
    RefreshAcrylicControls(Self);
  end;
end;

//==============================================================================
procedure TMainForm.btnBarFuncClick(Sender: TObject);
begin
  m_bPlaylistBar := not m_bPlaylistBar;

  if m_bPlaylistBar then
  begin
    tbProgress.TrackColor := c_clSeaBlue;
    btnBarFunc.FontColor  := c_clSeaBlue;
    btnBarFunc.Text       := 'P';
  end
  else
  begin
    tbProgress.TrackColor := c_clLavaOrange;
    btnBarFunc.FontColor  := c_clLavaOrange;
    btnBarFunc.Text       := 'T';
  end
end;

//==============================================================================
procedure TMainForm.btnBlurClick(Sender: TObject);
begin
  inherited;
  WithBlur := not WithBlur;
end;

procedure TMainForm.AddTrackInfo(a_CasTrack : TCasTrack);
var
  pnlTrack     : TAcrylicGhostPanel;
  btnUp        : TAcrylicButton;
  btnDown      : TAcrylicButton;
  btnAdd       : TAcrylicButton;
  btnClose     : TAcrylicButton;
  AcrylicTrack : TAcrylicTrack;
  pngImage     : TPngImage;
begin
  //////////////////////////////////////////////////////////////////////////////
  // Track Panel
  pnlTrack             := TAcrylicGhostPanel.Create(Self);
  pnlTrack.Parent      := Self;
  pnlTrack.BevelOuter  := bvNone;
  pnlTrack.Align       := alNone;
  pnlTrack.Caption     := '';
  pnlTrack.Name        := 'pnl' + IntToStr(a_CasTrack.ID);
  pnlTrack.Width       := sbTracks.ScrollPanel.Width - 2 * c_nPanelOffset;
  pnlTrack.Height      := c_nPanelHeight;
  pnlTrack.Left        := c_nPanelOffset;
  pnlTrack.Top         := m_nLoadedTrackCount * (c_nPanelGap + c_nPanelHeight) + c_nFirstPanelTop;

  sbTracks.AddControl(pnlTrack);
  m_lstTracks.Add(pnlTrack);

  //////////////////////////////////////////////////////////////////////////////
  // Button to move up
  btnUp                := TAcrylicButton.Create(pnlTrack);
  btnUp.Parent         := pnlTrack;
  btnUp.Align          := alNone;
  btnUp.Top            := c_nButtonTop1;
  btnUp.Left           := pnlTrack.Width - c_nButtonRight2;
  btnUp.Text           := '';
  btnUp.Name           := 'btnUp_' + IntToStr(a_CasTrack.ID);
  btnUp.OnClick        := btnUpClick;
  btnUp.Width          := c_nButtonWidth;
  btnUp.Height         := c_nButtonHeight;
  pngImage             := TPngImage.Create;
  pngImage.LoadFromResourceName(HInstance, 'btnUp');
  btnUp.Png            := pngImage;

  //////////////////////////////////////////////////////////////////////////////
  // Button to move down
  btnDown              := TAcrylicButton.Create(pnlTrack);
  btnDown.Parent       := pnlTrack;
  btnDown.Align        := alNone;
  btnDown.Top          := c_nButtonTop2;
  btnDown.Left         := pnlTrack.Width - c_nButtonRight2;
  btnDown.Text         := '';
  btnDown.Name         := 'btnDown_' + IntToStr(a_CasTrack.ID);
  btnDown.OnClick      := btnDownClick;
  btnDown.Width        := c_nButtonWidth;
  btnDown.Height       := c_nButtonHeight;
  pngImage             := TPngImage.Create;
  pngImage.LoadFromResourceName(HInstance, 'btnDown');
  btnDown.Png          := pngImage;

  //////////////////////////////////////////////////////////////////////////////
  // Button to clone track
  btnAdd               := TAcrylicButton.Create(pnlTrack);
  btnAdd.Parent        := pnlTrack;
  btnAdd.Align         := alNone;
  btnAdd.Top           := c_nButtonTop2;
  btnAdd.Left          := pnlTrack.Width - c_nButtonRight1;
  btnAdd.Text          := '';
  btnAdd.Name          := 'btnAdd_' + IntToStr(a_CasTrack.ID);
  btnAdd.OnClick       := btnAddClick;
  btnAdd.Width         := c_nButtonWidth;
  btnAdd.Height        := c_nButtonHeight;
  pngImage             := TPngImage.Create;
  pngImage.LoadFromResourceName(HInstance, 'btnAdd');
  btnAdd.Png           := pngImage;

  //////////////////////////////////////////////////////////////////////////////
  // Button to close track
  btnClose             := TAcrylicButton.Create(pnlTrack);
  btnClose.Parent      := pnlTrack;
  btnClose.Align       := alNone;
  btnClose.Top         := c_nButtonTop1;
  btnClose.Left        := pnlTrack.Width - c_nButtonRight1;
  btnClose.Text        := '';
  btnClose.Name        := 'btnClose_' + IntToStr(a_CasTrack.ID);
  btnClose.OnClick     := btnCloseClick;
  btnClose.Width       := c_nButtonWidth;
  btnClose.Height      := c_nButtonHeight;
  pngImage             := TPngImage.Create;
  pngImage.LoadFromResourceName(HInstance, 'btnClose');
  btnClose.Png         := pngImage;

  //////////////////////////////////////////////////////////////////////////////
  // Track title and image
  AcrylicTrack         := TAcrylicTrack.Create(pnlTrack);
  AcrylicTrack.Parent  := pnlTrack;
  AcrylicTrack.Align   := alNone;
  AcrylicTrack.Width   := pnlTrack.Width - c_nTrackOffset;
  AcrylicTrack.Height  := c_nPanelHeight;
  AcrylicTrack.OnClick := trackClick;
  AcrylicTrack.OnMouseWheelUp   := trackWheelUp;
  AcrylicTrack.OnMouseWheelDown := trackWheelDown;
  AcrylicTrack.Text    := IntToStr(m_nLoadedTrackCount + 1) + ') ' + a_CasTrack.Title;
  AcrylicTrack.Name    := 'trkTrack_' + IntToStr(a_CasTrack.ID);
  AcrylicTrack.SetData(@a_CasTrack.RawData.Right, a_CasTrack.Size);

  lblTime.Text := m_AudioManager.GetTime + '/' + m_AudioManager.GetDuration;
  Inc(m_nLoadedTrackCount);
end;

//==============================================================================
procedure TMainForm.btnCloseClick(Sender : TObject);
var
  CasTrack : TCasTrack;
begin
  if m_AudioManager.GetTrackByID(StrToInt(String((Sender as TAcrylicButton).Parent.Name).SubString(3)), CasTrack) then
  begin
    m_AudioManager.SetPosition(m_AudioManager.GetPosition - CasTrack.Size);
    m_AudioManager.DeleteTrack(CasTrack.ID);

    m_AudioManager.BroadcastRemoveTrack(CasTrack.ID);
  end;

  m_lstTracks.Remove((Sender as TAcrylicButton).Parent as TAcrylicGhostPanel);
  (Sender as TAcrylicButton).Parent.Destroy;
  Dec(m_nLoadedTrackCount);

  if m_nLoadedTrackCount = 0 then
    m_AudioManager.Stop;

  RearrangeTracks;
  UpdateProgressBar;
  ChangeEnabledObjects;
end;

//==============================================================================
procedure TMainForm.btnAddClick(Sender : TObject);
var
  OriginalTrack : TCasTrack;
  NewTrack      : TCasTrack;
begin
  if m_AudioManager.GetTrackByID(StrToInt(String((Sender as TAcrylicButton).Parent.Name).SubString(3)), OriginalTrack) then
  begin
    NewTrack       := OriginalTrack.Clone;
    NewTrack.ID    := m_AudioManager.GenerateID;
    m_AudioManager.AddTrack(NewTrack, 0);
    m_AudioManager.AddTrackToPlaylist(NewTrack.ID, m_AudioManager.GetLength);

    AddTrackInfo(NewTrack);

    m_AudioManager.BroadcastNewTrack(NewTrack.ID);

    UpdateProgressBar;
  end;
end;

//==============================================================================
procedure TMainForm.btnUpClick(Sender : TObject);
var
  nTrack : Integer;
begin
  nTrack := m_lstTracks.IndexOf((Sender as TAcrylicButton).Parent as TAcrylicGhostPanel);

  SwapTracks(nTrack, nTrack - 1);
end;

//==============================================================================
procedure TMainForm.btnDownClick(Sender : TObject);
var
  nTrack : Integer;
begin
  nTrack := m_lstTracks.IndexOf((Sender as TAcrylicButton).Parent as TAcrylicGhostPanel);

  SwapTracks(nTrack, nTrack + 1);
end;

//==============================================================================
procedure TMainForm.trackClick(Sender : TObject);
begin
  m_AudioManager.GoToTrack(StrToInt(String((Sender as TAcrylicTrack).Parent.Name).SubString(3)));
  UpdateProgressBar;
end;

//==============================================================================
procedure TMainForm.trackWheelUp(Sender: TObject; Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);
var
  ptMouse : TPoint;
  nTrack  : Integer;
  nDist   : Integer;
begin
  if ssShift in Shift then
  begin
    nTrack  := m_lstTracks.IndexOf((Sender as TAcrylicTrack).Parent as TAcrylicGhostPanel);
    nDist   := c_nPanelGap + c_nPanelHeight;

    SwapTracks(nTrack, nTrack - 1);

    GetCursorPos(ptMouse);
    ptMouse := ScreenToClient(ptMouse);

    if (ptMouse.Y - nDist) < (sbTracks.Top) then
    begin
      sbTracks.Scroll(nDist);
    end
    else if nTrack > 0 then
    begin
      ptMouse := Mouse.CursorPos;
      SetCursorPos(ptMouse.X, ptMouse.Y - nDist);
    end;
  end;
end;

//==============================================================================
procedure TMainForm.trackWheelDown(Sender: TObject; Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);
var
  ptMouse : TPoint;
  nTrack  : Integer;
  nDist   : Integer;
begin
  if ssShift in Shift then
  begin
    nTrack  := m_lstTracks.IndexOf((Sender as TAcrylicTrack).Parent as TAcrylicGhostPanel);
    nDist   := c_nPanelGap + c_nPanelHeight;

    SwapTracks(nTrack, nTrack + 1);

    GetCursorPos(ptMouse);
    ptMouse := ScreenToClient(ptMouse);

    if (ptMouse.Y + nDist) > (sbTracks.Top + sbTracks.Height) then
    begin
      sbTracks.Scroll(-nDist);
    end
    else if nTrack < m_lstTracks.Count - 1 then
    begin
      ptMouse := Mouse.CursorPos;
      SetCursorPos(ptMouse.X, ptMouse.Y + nDist);
    end;
  end;
end;

//==============================================================================
procedure TMainForm.UpdateProgress(a_dProgress : Double);
begin
  UpdateProgressBar;
end;

//==============================================================================
procedure TMainForm.AddTrack(a_nTrackID : Integer);
var
  CasTrack : TCasTrack;
begin
  if m_bStartPlaying then
  begin
    btnPlayClick(nil);
    m_bStartPlaying := False;
  end;

  lblLoading.Visible := False;

  if m_AudioManager.GetTrackById(a_nTrackID, CasTrack) then
    AddTrackInfo(CasTrack);
end;

//==============================================================================
procedure TMainForm.RemoveTrack(a_nTrackID  : Integer);
begin
  //
end;

//==============================================================================
procedure TMainForm.UpdateGUI;
begin
  ChangeEnabledObjects;
end;

//==============================================================================
procedure TMainForm.DriverChange;
begin
  cbDriverChange(cbDriver);
end;

end.
