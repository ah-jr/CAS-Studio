unit PlaylistManagerU;

interface

uses
  System.Types,
  AudioManagerU,
  VisualTypesU,
  TypesU;

type
  TPlaylistManager = class
  private
    m_AudioManager : TAudioManager;

    m_vtTransform : TVisualTransform;
    m_nSize       : Integer;
    m_dProgress   : Double;
    m_recPlaylist : TRect;


  public
    constructor Create(a_AudioManager : TAudioManager);
    destructor  Destroy; override;

    function  XToBeat            (a_dX          : Double)  : Double;
    function  XToSample          (a_dX          : Double)  : Integer;
    function  BeatToX            (a_dBeat       : Double)  : Double;
    function  SampleToX          (a_nSample     : Integer) : Double;
    function  GetVisualSize      (a_nSampleSize : Integer) : Double;
    function  GetSampleSize      (a_nVisualSize : Double)  : Integer;
    function  GetTrackVisualSize (a_nTrackID    : Integer) : Integer;
    function  GetBeatCount    : Double;
    function  GetProgressX    : Double;
    function  GetPlaylistRect : TRect;

    function  GetTrackData(a_nTrackID   : Integer;
                           var a_pLeft  : PIntArray;
                           var a_pRight : PIntArray;
                           var a_nSize  : Integer) : Boolean;

    procedure SetPlaylistRect (a_recPlaylist : TRect);
    procedure SetTrackPosition(a_nTrackID : Integer; a_nPos : Integer);

    property Transform : TVisualTransform read  m_vtTransform write m_vtTransform;
    property Size      : Integer          read  m_nSize       write m_nSize;
    property Progress  : Double           read  m_dProgress   write m_dProgress;
    property BeatCount : Double           read  GetBeatCount;

  end;

implementation

uses
  UtilsU;

//==============================================================================
constructor TPlaylistManager.Create(a_AudioManager : TAudioManager);
begin
  m_AudioManager := a_AudioManager;
  m_recPlaylist  := TRect.Create(-1,-1,-1,-1);
end;

//==============================================================================
destructor  TPlaylistManager.Destroy;
begin
  //
end;

//==============================================================================
function TPlaylistManager.GetBeatCount : Double;
var
  nSampleRate : Integer;
  dBPM        : Double;
  nSize       : Integer;
begin
  nSampleRate := Trunc(m_AudioManager.Engine.SampleRate);
  dBPM        := m_AudioManager.BPM;
  nSize       := m_AudioManager.Engine.Length;
  Result      := MsToBeats(dBPM, SampleCountToMs(nSize, nSampleRate));
end;

//==============================================================================
function TPlaylistManager.GetProgressX : Double;
var
  dProgress : Double;
  dX        : Double;
begin
  dProgress := m_AudioManager.Engine.Progress;
  dX        := dProgress*GetBeatCount*c_nBarWidth;

  Result := (dX - m_vtTransform.Offset) * m_vtTransform.Scale.X;
end;

//==============================================================================
function TPlaylistManager.XToBeat(a_dX : Double) : Double;
begin
  Result := (a_dX/m_vtTransform.Scale.X + m_vtTransform.Offset) / c_nBarWidth;
end;

//==============================================================================
function TPlaylistManager.BeatToX(a_dBeat : Double) : Double;
begin
  Result := (a_dBeat * c_nBarWidth - m_vtTransform.Offset) * m_vtTransform.Scale.X;
end;

//==============================================================================
function TPlaylistManager.XToSample(a_dX : Double) : Integer;
var
  nSampleRate : Integer;
  dBPM        : Double;
begin
  nSampleRate := Trunc(m_AudioManager.Engine.SampleRate);
  dBPM        := m_AudioManager.BPM;

  Result := MsToSampleCount(BeatsToMs(dBPM, XToBeat(a_dX)), nSampleRate);
end;

//==============================================================================
function TPlaylistManager.SampleToX(a_nSample : Integer) : Double;
var
  nSampleRate : Integer;
  dBPM        : Double;
begin
  nSampleRate := Trunc(m_AudioManager.Engine.SampleRate);
  dBPM        := m_AudioManager.BPM;

  Result := BeatToX(MsToBeats(dBPM, SampleCountToMs(a_nSample, nSampleRate)));
end;

//==============================================================================
function TPlaylistManager.GetVisualSize(a_nSampleSize : Integer) : Double;
var
  nSampleRate : Integer;
  dBPM        : Double;
  dBeats      : Double;
begin
  nSampleRate    := Trunc(m_AudioManager.Engine.SampleRate);
  dBPM           := m_AudioManager.BPM;
  dBeats         := MsToBeats(dBPM, SampleCountToMs(a_nSampleSize, nSampleRate));

  Result := dBeats * c_nBarWidth * m_vtTransform.Scale.X;
end;

//==============================================================================
function TPlaylistManager.GetSampleSize(a_nVisualSize : Double) : Integer;
var
  nSampleRate : Integer;
  dBPM        : Double;
  dMs         : Double;
begin
  nSampleRate    := Trunc(m_AudioManager.Engine.SampleRate);
  dBPM           := m_AudioManager.BPM;
  dMs            := BeatsToMs(dBPM, a_nVisualSize / (c_nBarWidth * m_vtTransform.Scale.X));

  Result := MsToSampleCount(dMs, nSampleRate);
end;

//==============================================================================
function TPlaylistManager.GetTrackVisualSize(a_nTrackID : Integer) : Integer;
var
  nSampleRate : Integer;
  dBPM        : Double;
  dBeats      : Double;
  nSize       : Integer;
begin
  nSampleRate    := Trunc(m_AudioManager.Engine.SampleRate);
  dBPM           := m_AudioManager.BPM;
  nSize          := m_AudioManager.GetTrackSize(a_nTrackID);
  dBeats         := MsToBeats(dBPM, SampleCountToMs(nSize, nSampleRate));

  Result := Trunc(dBeats * c_nBarWidth * m_vtTransform.Scale.X);
end;

//==============================================================================
procedure TPlaylistManager.SetTrackPosition(a_nTrackID : Integer; a_nPos : Integer);
begin
  m_AudioManager.SetTrackPosition(a_nTrackID, a_nPos);
end;

//==============================================================================
function TPlaylistManager.GetTrackData(a_nTrackID   : Integer;
                                       var a_pLeft  : PIntArray;
                                       var a_pRight : PIntArray;
                                       var a_nSize  : Integer) : Boolean;
begin
  Result := m_AudioManager.GetTrackData(a_nTrackID, a_pLeft, a_pRight, a_nSize);
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
end.
