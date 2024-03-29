unit PlaylistManagerU;

interface

uses
  System.Types,
  AudioManagerU,
  VisualTypesU,
  CasTrackU,
  CasClipU,
  TypesU;

type
  TToolType= (ttMove,
              ttCut);

  TPlaylistManager = class
  private
    m_AudioManager   : TAudioManager;

    m_vtTransform    : TVisualTransform;
    m_nSize          : Integer;
    m_recPlaylist    : TRect;
    m_ttSelectedTool : TToolType;

  public
    constructor Create(a_AudioManager : TAudioManager);
    destructor  Destroy; override;

    function  XToOffset            (a_dX          : Double)  : Double;
    function  XToBeat              (a_dX          : Double)  : Double;
    function  XToSample            (a_dX          : Double)  : Double;
    function  OffsetToX            (a_dOffset     : Double)  : Double;
    function  BeatToX              (a_dBeat       : Double)  : Double;
    function  SampleToX            (a_dSample     : Double)  : Double;
    function  GetVisualSize        (a_dSampleSize : Double)  : Double;
    function  GetSampleSize        (a_dVisualSize : Double)  : Double;
    function  GetClipVisualWidth   (a_nClipID     : Integer) : Double;
    function  GetClipVisualHeight : Double;
    function  GetBeatCount      : Double;
    function  GetProgressX      : Double;
    function  GetProgressOffset : Double;
    function  GetProgress       : Double;
    function  GetPlaylistRect   : TRect;

    function  GetTrackByClipID(a_nClipID : Integer; var a_CasTrack : TCasTrack) : Boolean;

    procedure SetProgress     (a_dProgress : Double);
    procedure SetPlaylistRect (a_recPlaylist : TRect);
    procedure SetClipPos      (a_nClipID : Integer; a_nPos : Integer);
    procedure CutClip         (a_nClipID : Integer; a_nPos : Integer; a_nHeight : Integer);

    function  GetClipPos    (a_nClipId : Integer) : Integer;
    function  GetClipSize   (a_nClipId : Integer) : Integer;
    function  GetClipOffset (a_nClipId : Integer) : Integer;
    function  GetClipTrackID(a_nClipId : Integer) : Integer;

    property SelectedTool : TToolType        read  m_ttSelectedTool write m_ttSelectedTool;
    property Transform    : TVisualTransform read  m_vtTransform    write m_vtTransform;
    property Size         : Integer          read  m_nSize          write m_nSize;
    property Progress     : Double           read  GetProgress      write SetProgress;
    property BeatCount    : Double           read  GetBeatCount;

  end;

implementation

uses
  UtilsU;

//==============================================================================
constructor TPlaylistManager.Create(a_AudioManager : TAudioManager);
begin
  m_AudioManager := a_AudioManager;
  m_recPlaylist  := TRect.Create(-1,-1,-1,-1);

  m_ttSelectedTool := ttMove;
end;

//==============================================================================
destructor  TPlaylistManager.Destroy;
begin
  //
end;

//==============================================================================
function TPlaylistManager.GetBeatCount : Double;
var
  dSampleRate : Double;
  dBPM        : Double;
  nSize       : Integer;
begin
  dSampleRate := m_AudioManager.Engine.SampleRate;
  dBPM        := m_AudioManager.BPM;
  nSize       := m_AudioManager.Engine.Length;
  Result      := MsToBeats(dBPM, SampleCountToMs(nSize, dSampleRate));
end;

//==============================================================================
function TPlaylistManager.GetProgressX : Double;
begin
  Result := OffsetToX(GetProgressOffset);
end;

//==============================================================================
function TPlaylistManager.GetProgress : Double;
begin
  Result := m_AudioManager.Engine.Progress;
end;

//==============================================================================
function TPlaylistManager.GetProgressOffset : Double;
begin
  Result := m_AudioManager.Engine.Progress * GetBeatCount * c_nBarWidth;
end;

//==============================================================================
procedure TPlaylistManager.SetProgress(a_dProgress : Double);
var
  dDist : Double;
begin
  // Sync playlist position with progress
  dDist := (GetPlaylistRect.Width / 4) / Transform.Scale.X;
  Transform.SetOffsetX(GetProgressOffset - dDist);
end;

//==============================================================================
function TPlaylistManager.XToOffset(a_dX : Double) : Double;
begin
  Result := (a_dX/m_vtTransform.Scale.X + m_vtTransform.Offset.X);
end;

//==============================================================================
function TPlaylistManager.OffsetToX(a_dOffset : Double) : Double;
begin
  Result := (a_dOffset - m_vtTransform.Offset.X) * m_vtTransform.Scale.X;
end;

//==============================================================================
function TPlaylistManager.XToBeat(a_dX : Double) : Double;
begin
  Result := XToOffset(a_dX) / c_nBarWidth;
end;

//==============================================================================
function TPlaylistManager.BeatToX(a_dBeat : Double) : Double;
begin
  Result := OffsetToX(a_dBeat * c_nBarWidth);
end;

//==============================================================================
function TPlaylistManager.XToSample(a_dX : Double) : Double;
var
  dSampleRate : Double;
  dBPM        : Double;
begin
  dSampleRate := m_AudioManager.Engine.SampleRate;
  dBPM        := m_AudioManager.BPM;

  Result := MsToSampleCount(BeatsToMs(dBPM, XToBeat(a_dX)), dSampleRate);
end;

//==============================================================================
function TPlaylistManager.SampleToX(a_dSample : Double) : Double;
var
  dSampleRate : Double;
  dBPM        : Double;
begin
  dSampleRate := m_AudioManager.Engine.SampleRate;
  dBPM        := m_AudioManager.BPM;

  Result := BeatToX(MsToBeats(dBPM, SampleCountToMs(a_dSample, dSampleRate)));
end;

//==============================================================================
function TPlaylistManager.GetVisualSize(a_dSampleSize : Double) : Double;
var
  dSampleRate : Double;
  dBPM        : Double;
  dBeats      : Double;
begin
  dSampleRate := m_AudioManager.Engine.SampleRate;
  dBPM        := m_AudioManager.BPM;
  dBeats      := MsToBeats(dBPM, SampleCountToMs(a_dSampleSize, dSampleRate));

  Result := dBeats * c_nBarWidth * m_vtTransform.Scale.X;
end;

//==============================================================================
function TPlaylistManager.GetSampleSize(a_dVisualSize : Double) : Double;
var
  dSampleRate : Double;
  dBPM        : Double;
  dMs         : Double;
begin
  dSampleRate := m_AudioManager.Engine.SampleRate;
  dBPM        := m_AudioManager.BPM;
  dMs         := BeatsToMs(dBPM, a_dVisualSize / (c_nBarWidth * m_vtTransform.Scale.X));

  Result := MsToSampleCount(dMs, dSampleRate);
end;

//==============================================================================
function TPlaylistManager.GetClipVisualWidth(a_nClipID : Integer) : Double;
var
  dSampleRate : Double;
  dBPM        : Double;
  dBeats      : Double;
  nSize       : Integer;
begin
  dSampleRate := m_AudioManager.Engine.SampleRate;
  dBPM        := m_AudioManager.BPM;
  nSize       := m_AudioManager.GetClipSize(a_nClipID);
  dBeats      := MsToBeats(dBPM, SampleCountToMs(nSize, dSampleRate));

  Result := (dBeats * c_nBarWidth * m_vtTransform.Scale.X);
end;

//==============================================================================
function TPlaylistManager.GetClipVisualHeight : Double;
begin
  Result := c_nLineHeight * m_vtTransform.Scale.Y;
end;

//==============================================================================
procedure TPlaylistManager.SetClipPos(a_nClipID : Integer; a_nPos : Integer);
begin
  m_AudioManager.SetClipPos(a_nClipID, a_nPos);
end;

//==============================================================================
procedure TPlaylistManager.CutClip(a_nClipID : Integer; a_nPos : Integer; a_nHeight : Integer);
begin
  m_AudioManager.CutClip(a_nClipID, a_nPos, a_nHeight);
end;

//==============================================================================
function TPlaylistManager.GetTrackByClipID(a_nClipID : Integer; var a_CasTrack : TCasTrack) : Boolean;
var
  Clip : TCasClip;
begin
  Result := False;

  if m_AudioManager.Engine.Playlist.GetClip(a_nClipID, Clip) then
  begin
    Result := m_AudioManager.Engine.Database.GetTrackById(Clip.TrackID, a_CasTrack);
  end;
end;

//==============================================================================
function TPlaylistManager.GetPlaylistRect : TRect;
begin
  Result.Left   := m_recPlaylist.Left;
  Result.Top    := m_recPlaylist.Top;
  Result.Width  := m_recPlaylist.Width;
  Result.Height := m_recPlaylist.Height;
end;

//==============================================================================
procedure TPlaylistManager.SetPlaylistRect(a_recPlaylist : TRect);
begin
  m_recPlaylist.Left   := a_recPlaylist.Left;
  m_recPlaylist.Top    := a_recPlaylist.Top;
  m_recPlaylist.Width  := a_recPlaylist.Width;
  m_recPlaylist.Height := a_recPlaylist.Height;
end;

//==============================================================================
function TPlaylistManager.GetClipPos(a_nClipId: Integer) : Integer;
begin
  Result := m_AudioManager.GetClipPos(a_nClipId);
end;

//==============================================================================
function TPlaylistManager.GetClipSize(a_nClipId: Integer) : Integer;
begin
  Result := m_AudioManager.GetClipSize(a_nClipId);
end;

//==============================================================================
function TPlaylistManager.GetClipOffset(a_nClipId: Integer) : Integer;
begin
  Result := m_AudioManager.GetClipOffset(a_nClipId);
end;

//==============================================================================
function TPlaylistManager.GetClipTrackID(a_nClipId: Integer) : Integer;
begin
  Result := m_AudioManager.GetClipTrackID(a_nClipId);
end;

//==============================================================================
end.
