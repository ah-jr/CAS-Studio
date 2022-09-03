unit RackFrameU;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Variants,
  System.Classes,
  System.Generics.Collections,
  System.UITypes,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.StdCtrls,
  Vcl.ExtCtrls,
  TypesU,
  AcrylicFrameU,
  AudioManagerU,
  AcrylicGhostPanelU,
  AcrylicScrollBoxU,
  CasTrackU;


  type
  TRackFrame = class(TAcrylicFrame, IAudioListener)
    procedure btnCloseClick              (Sender: TObject);
    procedure btnAddClick                (Sender: TObject);
    procedure btnUpClick                 (Sender: TObject);
    procedure btnDownClick               (Sender: TObject);

    procedure trackClick                 (Sender: TObject);
    procedure trackWheelUp               (Sender: TObject; Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);
    procedure trackWheelDown             (Sender: TObject; Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);

    procedure WMNCSize(var Message: TWMSize); message WM_SIZE;

  private
    m_AudioManager : TAudioManager;
    m_lstTracks    : TList<TAcrylicGhostPanel>;
    m_sbTracks     : TAcrylicScrollBox;

    procedure AddTrackInfo(a_CasTrack : TCasTrack);
    procedure RearrangeTracks;
    procedure SwapTracks(a_nTrack1, a_nTrack2 : Integer);

    procedure UpdateProgress(a_dProgress : Double);
    procedure AddTrack      (a_nTrackID  : Integer);
    procedure RemoveTrack   (a_nTrackID  : Integer);
    procedure UpdateGUI;
    procedure DriverChange;


  public
    constructor Create(AOwner : TComponent; a_AudioManager : TAudioManager); reintroduce; overload;
    destructor  Destroy; override;

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

implementation

uses
  Vcl.Imaging.pngimage,
  AcrylicTrackU,
  AcrylicUtilsU,
  AcrylicButtonU;

//==============================================================================
constructor TRackFrame.Create(AOwner : TComponent; a_AudioManager : TAudioManager);
begin
  Inherited Create(AOwner);

  Name := 'RackFrame';

  m_AudioManager := a_AudioManager;

  Resisable               := True;
  Width                   := 280;
  Height                  := 350;
  Title                   := 'Track Rack';

  m_lstTracks := TList<TAcrylicGhostPanel>.Create;
  m_sbTracks  := TAcrylicScrollBox.Create(Self);
  m_sbTracks.Parent := Body;
  m_sbTracks.Align  := alClient;

  m_AudioManager.AddListener(Self);
end;

//==============================================================================
destructor  TRackFrame.Destroy;
var
  pnlPanel : TAcrylicGhostPanel;
begin
  for pnlPanel in m_lstTracks do
    pnlPanel.Destroy;

  FreeAndNil(m_lstTracks);
  m_AudioManager.RemoveListener(Self);

  Inherited;
end;

//==============================================================================
procedure TRackFrame.AddTrackInfo(a_CasTrack : TCasTrack);
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
  pnlTrack.Width       := m_sbTracks.ScrollPanel.Width - 2 * c_nPanelOffset;
  pnlTrack.Height      := c_nPanelHeight;
  pnlTrack.Left        := c_nPanelOffset;
  pnlTrack.Top         := (m_AudioManager.GetTrackCount - 1) * (c_nPanelGap + c_nPanelHeight) + c_nFirstPanelTop;

  m_sbTracks.AddControl(pnlTrack);
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
  AcrylicTrack.Text    := IntToStr(m_AudioManager.GetTrackCount) + ') ' + a_CasTrack.Title;
  AcrylicTrack.Name    := 'trkTrack_' + IntToStr(a_CasTrack.ID);
  AcrylicTrack.SetData(@a_CasTrack.RawData.Right, a_CasTrack.Size);

  m_AudioManager.BroadcastProgress;
end;

//==============================================================================
procedure TRackFrame.RearrangeTracks;
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
procedure TRackFrame.SwapTracks(a_nTrack1, a_nTrack2 : Integer);
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
procedure TRackFrame.WMNCSize(var Message: TWMSize);
var
  nIndex : Integer;
begin
  inherited;

  m_sbTracks.Width  := ClientWidth  - 50;
  m_sbTracks.Height := ClientHeight - 170;

  if (m_lstTracks <> nil) then
  begin
    for nIndex := 0 to m_lstTracks.Count - 1 do
    begin
      (m_lstTracks.Items[nIndex] as TAcrylicGhostPanel).Width := m_sbTracks.ScrollPanel.Width - 2 * c_nPanelOffset;

      (m_lstTracks.Items[nIndex] as TAcrylicGhostPanel).Controls[0].Left := m_sbTracks.ScrollPanel.Width - 2 * c_nPanelOffset - c_nButtonRight2;
      (m_lstTracks.Items[nIndex] as TAcrylicGhostPanel).Controls[1].Left := m_sbTracks.ScrollPanel.Width - 2 * c_nPanelOffset - c_nButtonRight2;
      (m_lstTracks.Items[nIndex] as TAcrylicGhostPanel).Controls[2].Left := m_sbTracks.ScrollPanel.Width - 2 * c_nPanelOffset - c_nButtonRight1;
      (m_lstTracks.Items[nIndex] as TAcrylicGhostPanel).Controls[3].Left := m_sbTracks.ScrollPanel.Width - 2 * c_nPanelOffset - c_nButtonRight1;

      (m_lstTracks.Items[nIndex] as TAcrylicGhostPanel).Controls[4].Width := m_sbTracks.ScrollPanel.Width - 2 * c_nPanelOffset - c_nTrackOffset;
    end;
  end;
end;

//==============================================================================
procedure TRackFrame.btnCloseClick(Sender : TObject);
var
  CasTrack : TCasTrack;
begin
  if m_AudioManager.GetTrackByID(StrToInt(String((Sender as TAcrylicButton).Parent.Name).SubString(3)), CasTrack) then
  begin
    m_AudioManager.SetPosition(m_AudioManager.GetPosition - CasTrack.Size);
    m_AudioManager.DeleteTrack(CasTrack.ID);
    m_AudioManager.BroadcastRemoveTrack(CasTrack.ID);

    if m_AudioManager.GetTrackCount = 0 then
      m_AudioManager.Stop;

    RearrangeTracks;
    m_AudioManager.BroadcastProgress;
    m_AudioManager.BroadcastUpdateGUI;
  end;
end;

//==============================================================================
procedure TRackFrame.btnAddClick(Sender : TObject);
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
    m_AudioManager.BroadcastNewTrack(NewTrack.ID);
    m_AudioManager.BroadcastProgress;
  end;
end;

//==============================================================================
procedure TRackFrame.btnUpClick(Sender : TObject);
var
  nTrack : Integer;
begin
  nTrack := m_lstTracks.IndexOf((Sender as TAcrylicButton).Parent as TAcrylicGhostPanel);

  SwapTracks(nTrack, nTrack - 1);
end;

//==============================================================================
procedure TRackFrame.btnDownClick(Sender : TObject);
var
  nTrack : Integer;
begin
  nTrack := m_lstTracks.IndexOf((Sender as TAcrylicButton).Parent as TAcrylicGhostPanel);

  SwapTracks(nTrack, nTrack + 1);
end;

//==============================================================================
procedure TRackFrame.trackClick(Sender : TObject);
begin
  m_AudioManager.GoToTrack(StrToInt(String((Sender as TAcrylicTrack).Parent.Name).SubString(3)));
  m_AudioManager.BroadcastProgress;
end;

//==============================================================================
procedure TRackFrame.trackWheelUp(Sender: TObject; Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);
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

    if (ptMouse.Y - nDist) < (m_sbTracks.Top) then
    begin
      m_sbTracks.Scroll(nDist);
    end
    else if nTrack > 0 then
    begin
      ptMouse := Mouse.CursorPos;
      SetCursorPos(ptMouse.X, ptMouse.Y - nDist);
    end;
  end;
end;

//==============================================================================
procedure TRackFrame.trackWheelDown(Sender: TObject; Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);
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

    if (ptMouse.Y + nDist) > (m_sbTracks.Top + m_sbTracks.Height) then
    begin
      m_sbTracks.Scroll(-nDist);
    end
    else if nTrack < m_lstTracks.Count - 1 then
    begin
      ptMouse := Mouse.CursorPos;
      SetCursorPos(ptMouse.X, ptMouse.Y + nDist);
    end;
  end;
end;

//==============================================================================
procedure TRackFrame.UpdateProgress(a_dProgress : Double);
var
  CasTrack  : TCasTrack;
  dProgress : Double;
  nPanelIdx : Integer;
begin
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
procedure TRackFrame.AddTrack(a_nTrackID : Integer);
var
  CasTrack : TCasTrack;
begin
  if m_AudioManager.GetTrackById(a_nTrackID, CasTrack) then
    AddTrackInfo(CasTrack);
end;

//==============================================================================
procedure TRackFrame.RemoveTrack(a_nTrackID  : Integer);
var
  pnlTrack : TAcrylicGhostPanel;
begin
  pnlTrack := FindComponent('pnl' + IntToStr(a_nTrackID)) as TAcrylicGhostPanel;

  m_lstTracks.Remove(pnlTrack);
  pnlTrack.Destroy;
end;

//==============================================================================
procedure TRackFrame.UpdateGUI;
begin
  //
end;

//==============================================================================
procedure TRackFrame.DriverChange;
begin
  //
end;

end.
