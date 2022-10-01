////////////////////////////////////////////////////////////////////////////////
//
// CAS Studio
//
// Uses CasEngine to implement an audio editor.
//
// Creation: 07/08/2022 by Airton Junior
//
////////////////////////////////////////////////////////////////////////////////

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
  AcrylicFormU,
  AcrylicButtonU,
  AcrylicTrackU,
  AcrylicLabelU,
  AcrylicControlU,
  AcrylicKnobU,
  AcrylicFrameU,
  AcrylicTrackBarU,
  AcrylicGhostPanelU,
  AcrylicPopUpU,
  AudioManagerU,
  TypesU, Vcl.NumberBox;

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
    btnExport             : TAcrylicButton;
    lblTime               : TAcrylicLabel;
    lblTitle              : TAcrylicLabel;
    lblVolume             : TAcrylicLabel;
    lblPitch              : TAcrylicLabel;
    lblLoading            : TAcrylicLabel;
    knbLevel              : TAcrylicKnob;
    knbSpeed              : TAcrylicKnob;
    pnlBlurHint           : TPanel;
    tbProgress            : TAcrylicTrackBar;
    pnlDesktop            : TAcrylicGhostPanel;
    Panel1: TPanel;
    NumberBox1: TNumberBox;

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
    procedure btnOpenFileClick           (Sender: TObject);
    procedure btnBarFuncClick            (Sender: TObject);
    procedure btnInfoClick               (Sender: TObject);
    procedure tbProgressChange           (Sender: TObject);
    procedure knbLevelChange             (Sender: TObject);
    procedure knbSpeedChange             (Sender: TObject);

    procedure WMNCSize(var Message: TWMSize); message WM_SIZE;
    procedure btnExportClick(Sender: TObject);
    procedure Panel1Click(Sender: TObject);

    procedure MessageEvent(var Msg: TMsg; var Handled: Boolean);
    procedure NumberBox1ChangeValue(Sender: TObject);

  private
    m_dctFrames       : TDictionary<Integer, TAcrylicFrame>;
    m_AudioManager    : TAudioManager;
    m_PopUp           : TAcrylicPopUp;

    m_bBlockPosUpdate : Boolean;
    m_bPlaylistBar    : Boolean;
    m_bStartPlaying   : Boolean;

    m_DriverList      : TAsioDriverList;
    m_lstFiles        : TStringList;

    procedure InitializeVariables;
    procedure InitializeControls;
    procedure InitializeFrames;
    procedure LoadFiles;
    procedure ChangeEnabledObjects;
    procedure UpdateBufferPosition;
    procedure UpdateProgressBar;

    function GetDesktopX(a_dProp : Double) : Integer;
    function GetDesktopY(a_dProp : Double) : Integer;

    procedure UpdateBPM     (a_dOldBPM, a_dNewBPM : Double);
    procedure UpdateProgress(a_dProgress : Double);
    procedure AddTrack      (a_nTrackID  : Integer);
    procedure RemoveTrack   (a_nTrackID  : Integer);
    procedure UpdateGUI;
    procedure DriverChange;

end;

const
  c_nBntBlurRight  = 150;

var
  MainForm: TMainForm;

implementation

uses
  Vcl.Imaging.pngimage,
  GDIPAPI,
  GDIPUTIL,
  CasUtilsU,
  CasTypesU,
  CasTrackU,
  CasConstantsU,
  Registry,
  AcrylicUtilsU,
  AcrylicTypesU,
  InfoFrameU,
  PlaylistFrameU,
  MixerFrameU,
  RackFrameU;

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
  Width       := Trunc(Screen.WorkAreaRect.Width * 1/2);
  Height      := Trunc(Screen.WorkAreaRect.Height * 2/3);
  MinWidth    := 500;
  MinHeight   := 700;
  Style       := [fsClose, fsMinimize, fsMaximize];

  InitializeVariables;
  InitializeControls;
  InitializeFrames;
  LoadFiles;

  ChangeEnabledObjects;


  Application.OnMessage := MessageEvent;

  Inherited;
end;

//==============================================================================
procedure TMainForm.MessageEvent(var Msg: TMsg; var Handled: Boolean);
begin
  if (Msg.message = WM_LBUTTONDOWN) or
     (Msg.message = WM_NCLBUTTONDOWN) then
  begin
    m_PopUp.Hide;
  end;
end;

procedure TMainForm.NumberBox1ChangeValue(Sender: TObject);
var
  strBPM : String;
begin
  strBPM := (Sender as TNumberBox).Text;
  m_AudioManager.BPM := StrToFloat(strBPM);
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

  NumberBox1.Text := m_AudioManager.BPM.ToString;

  m_PopUp := TAcrylicPopup.Create(Self);
  m_PopUp.Parent := Self;
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
  ///  RackFrame
  afFrame        := TRackFrame.Create(pnlDesktop, m_AudioManager);
  afFrame.Parent := pnlDesktop;
  afFrame.Left   := GetDesktopX(c_dRackLeft);
  afFrame.Top    := GetDesktopY(c_dRackTop);
  afFrame.Width  := GetDesktopX(c_dRackWidth);
  afFrame.Height := GetDesktopY(c_dRackHeight);
  afFrame.Visible := True;
  m_dctFrames.AddOrSetValue(FID_Rack, afFrame);

  //////////////////////////////////////////////////////////////////////////////
  ///  PlaylistFrame
  afFrame        := TPlaylistFrame.Create(pnlDesktop, m_AudioManager);
  afFrame.Parent := pnlDesktop;
  afFrame.Left   := GetDesktopX(c_dPlaylistLeft);
  afFrame.Top    := GetDesktopY(c_dPlaylistTop);
  afFrame.Width  := GetDesktopX(c_dPlaylistWidth);
  afFrame.Height := GetDesktopY(c_dPlaylistHeight);
  afFrame.Visible := True;
  m_dctFrames.AddOrSetValue(FID_Playlist, afFrame);

  //////////////////////////////////////////////////////////////////////////////
  ///  MixerFrame
  afFrame        := TMixerFrame.Create(pnlDesktop, m_AudioManager);
  afFrame.Parent := pnlDesktop;
  afFrame.Left   := GetDesktopX(c_dMixerLeft);
  afFrame.Top    := GetDesktopY(c_dMixerTop);
  afFrame.Width  := GetDesktopX(c_dMixerWidth);
  afFrame.Height := GetDesktopY(c_dMixerHeight);
  afFrame.Visible := True;
  m_dctFrames.AddOrSetValue(FID_Mixer, afFrame);
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

procedure TMainForm.Panel1Click(Sender: TObject);
var
  P: TPoint;
  test : TPopUpItem;
begin
  test.Text := 'test';
  test.Action := nil;
  m_PopUp.AddItem(test);

  GetCursorPos(P);
  P := ScreenToClient(P);

  m_PopUp.PopUp(P.X, P.Y);
end;

//==============================================================================
procedure TMainForm.FormDestroy(Sender: TObject);
begin
  m_AudioManager.RemoveListener(Self);

  FreeAndNil(m_AudioManager);
  FreeAndNil(m_dctFrames);
  FreeAndNil(m_lstFiles);

  SetLength(m_DriverList, 0);
end;

//==============================================================================
procedure TMainForm.WMNCSize(var Message: TWMSize);
begin
  inherited;

  pnlBlurHint.Left := ClientWidth - pnlBlurHint.Width - c_nBntBlurRight;
  btnInfo.Left     := pnlBlurHint.Left - btnInfo.Width - 5;

  pnlDesktop.Width  := ClientWidth  - 50;
  pnlDesktop.Height := ClientHeight - 170;
end;

//==============================================================================
procedure TMainForm.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_SPACE then
    btnPlayClick(nil);

//  if GE_L(Key, $30, $3A) and ((Key - 49) <  m_lstTracks.Count) then
//    m_AudioManager.GoToTrack(StrToInt(String((m_lstTracks.Items[Key - 49] as TAcrylicGhostPanel).Name).SubString(3)));
end;

//==============================================================================
procedure TMainForm.InitializeVariables;
var
  nDriverIdx : Integer;
begin
  m_dctFrames    := TDictionary<Integer, TAcrylicFrame>.Create;
  m_AudioManager := TAudioManager.Create;
  m_AudioManager.AddListener(Self);
  m_lstFiles     := TStringList.Create;

  knbLevel.Level := 0.7;
  knbSpeed.Level := 0.5;

  m_bPlaylistBar    := True;
  m_bStartPlaying   := False;
  m_bBlockPosUpdate := False;

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
                                   (m_AudioManager.GetTrackCount > 0);

  btnStop.Enabled               := (m_AudioManager.GetTrackCount > 0);
  btnPrev.Enabled               := (m_AudioManager.GetTrackCount > 0);
  btnNext.Enabled               := (m_AudioManager.GetTrackCount > 0);
  btnBarFunc.Enabled            := (m_AudioManager.GetTrackCount > 0);
  tbProgress.Enabled            := (m_AudioManager.GetTrackCount > 0);

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
  if not m_bBlockPosUpdate then
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
begin
  m_bBlockPosUpdate := True;
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
  m_bBlockPosUpdate := False;
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

//==============================================================================
function TMainForm.GetDesktopX(a_dProp : Double) : Integer;
begin
  Result := Trunc(a_dProp * pnlDesktop.Width);
end;

//==============================================================================
function TMainForm.GetDesktopY(a_dProp : Double) : Integer;
begin
  Result := Trunc(a_dProp * pnlDesktop.Height);
end;

//==============================================================================
procedure TMainForm.UpdateBPM(a_dOldBPM, a_dNewBPM : Double);
begin

end;

//==============================================================================
procedure TMainForm.UpdateProgress(a_dProgress : Double);
begin
  UpdateProgressBar;
end;

//==============================================================================
procedure TMainForm.btnExportClick(Sender: TObject);
var
  asSpecs : TAudioSpecs;
begin
  with asSpecs do
  begin
    BitDepth   := 24;
    SampleRate := 44100;
    Format     := afMp3;
  end;

  m_AudioManager.AudioExport(asSpecs, 'audio');
end;

procedure TMainForm.AddTrack(a_nTrackID : Integer);
begin
  if m_bStartPlaying then
  begin
    btnPlayClick(nil);
    m_bStartPlaying := False;
  end;

  lblLoading.Visible := False;
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
