unit PlaylistInfoU;

interface

uses
  AudioManagerU,
  VisualTypesU;

type
  TPlaylistInfo = class
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

    procedure SetTrackPosition(a_nTrackID : Integer; a_nX : Integer);

    property Transform : TVisualTransform read  m_vtTransform write m_vtTransform;
    property Size      : Integer          read  m_nSize       write m_nSize;
    property Progress  : Double           read  m_dProgress   write m_dProgress;

  end;

implementation

uses
  UtilsU;

//==============================================================================
constructor TPlaylistInfo.Create(a_AudioManager : TAudioManager);
begin
  m_AudioManager := a_AudioManager;
end;

//==============================================================================
destructor  TPlaylistInfo.Destroy;
begin
  //
end;

//==============================================================================
function TPlaylistInfo.PositionToBeat(a_nX : Integer) : Double;
begin
  Result := (a_nX / c_nBarWidth);
end;

//==============================================================================
function TPlaylistInfo.PositionToSample(a_nX : Integer) : Integer;
var
  nSampleRate : Integer;
  dBPM        : Double;
begin
  nSampleRate := Trunc(m_AudioManager.Engine.SampleRate);
  dBPM        := m_AudioManager.BPM;

  Result := MsToSampleCount(BeatsToMs(dBPM, a_nX / c_nBarWidth), nSampleRate);
end;

//==============================================================================
function TPlaylistInfo.GetVisualSize(a_nSampleSize : Integer) : Integer;
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
procedure TPlaylistInfo.SetTrackPosition(a_nTrackID : Integer; a_nX : Integer);
var
  nPosition : Integer;
begin
  nPosition := PositionToSample(a_nX);
  m_AudioManager.SetTrackPosition(a_nTrackID, nPosition);
end;

end.
