unit PlaylistManagerU;

interface

uses
  AudioManagerU,
  VisualTypesU;

type
  TPlaylistManager = class
  private
    m_AudioManager : TAudioManager;

    m_vtTransform : TVisualTransform;
    m_nSize       : Integer;
    m_dProgress   : Double;

  public
    constructor Create(a_AudioManager : TAudioManager);
    destructor Destroy; override;

    function  PositionToBeat(a_nX : Integer) : Double;
    function  PositionToSample(a_nX : Integer) : Integer;
    function  GetVisualSize(a_nSampleSize : Integer) : Integer;
    function  GetTrackVisualSize(a_nTrackID : Integer) : Integer;
    function  GetBeatCount : Double;

    procedure SetTrackPosition(a_nTrackID : Integer; a_nX : Integer);

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
end;

//==============================================================================
destructor  TPlaylistManager.Destroy;
begin
  //
end;

//==============================================================================
function TPlaylistManager.GetBeatCount : Double;
begin
  Result := MsToBeats(m_AudioManager.BPM, SampleCountToMs(m_AudioManager.Engine.Length, m_AudioManager.Engine.SampleRate));
end;

//==============================================================================
function TPlaylistManager.PositionToBeat(a_nX : Integer) : Double;
begin
  Result := (a_nX / c_nBarWidth);
end;

//==============================================================================
function TPlaylistManager.PositionToSample(a_nX : Integer) : Integer;
var
  nSampleRate : Integer;
  dBPM        : Double;
begin
  nSampleRate := Trunc(m_AudioManager.Engine.SampleRate);
  dBPM        := m_AudioManager.BPM;

  Result := MsToSampleCount(BeatsToMs(dBPM, a_nX / c_nBarWidth), nSampleRate);
end;

//==============================================================================
function TPlaylistManager.GetVisualSize(a_nSampleSize : Integer) : Integer;
var
  nSampleRate : Integer;
  dBPM        : Double;
  dBeats      : Double;
begin
  nSampleRate    := Trunc(m_AudioManager.Engine.SampleRate);
  dBPM           := m_AudioManager.BPM;
  dBeats         := MsToBeats(dBPM, SampleCountToMs(a_nSampleSize, nSampleRate));

  Result := Trunc(dBeats * c_nBarWidth);
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

  Result := Trunc(dBeats * c_nBarWidth);
end;

//==============================================================================
procedure TPlaylistManager.SetTrackPosition(a_nTrackID : Integer; a_nX : Integer);
var
  nPosition : Integer;
begin
  nPosition := PositionToSample(a_nX);
  m_AudioManager.SetTrackPosition(a_nTrackID, nPosition);
end;

end.
