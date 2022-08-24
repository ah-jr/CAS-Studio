unit AudioManagerU;

interface

uses
  System.Generics.Collections,
  CasEngineU,
  TypesU;

type
  TAudioManager = class

  private
    m_lstListeners : TList<IAudioListener>;
    m_CasEngine    : TCasEngine;

    m_dBpm         : Double;

    function GetBeatCount : Double;

  public
    constructor Create(CasEngine : TCasEngine);
    destructor  Destroy; override;

    procedure AddListener(a_alListener : IAudioListener);
    procedure RemoveListener(a_alListener : IAudioListener);

    procedure BroadcastProgress(a_dProgress : Double);
    procedure BroadcastNewTrack(a_nTrackID : Integer);
    procedure SetTrackPosition(a_nTrackID : Integer; a_nPosition : Integer);

    property Engine    : TCasEngine read m_CasEngine write m_CasEngine;
    property BPM       : Double     read m_dBpm      write m_dBpm;
    property BeatCount : Double     read GetBeatCount;

  end;

  procedure CreateAudioManager(CasEngine : TCasEngine);

var
  g_AudioManager : TAudioManager = nil;

implementation

uses
  CasTrackU,
  UtilsU;

//==============================================================================
constructor TAudioManager.Create(CasEngine : TCasEngine);
begin
  m_CasEngine    := CasEngine;
  m_lstListeners := TList<IAudioListener>.Create;

  m_dBpm := 130;
end;

//==============================================================================
destructor TAudioManager.Destroy;
begin
  inherited;
  m_lstListeners.Free;
end;

//==============================================================================
function TAudioManager.GetBeatCount : Double;
begin
  Result := MsToBeats(BPM, SampleCountToMs(m_CasEngine.Length, m_CasEngine.SampleRate));
end;

//==============================================================================
procedure TAudioManager.AddListener(a_alListener : IAudioListener);
begin
  m_lstListeners.Add(a_alListener);
end;

//==============================================================================
procedure TAudioManager.RemoveListener(a_alListener : IAudioListener);
begin
  m_lstListeners.Remove(a_alListener);
end;

//==============================================================================
procedure TAudioManager.BroadcastProgress(a_dProgress : Double);
var
  nIndex : Integer;
begin
  for nIndex := 0 to m_lstListeners.Count - 1 do
  begin
    m_lstListeners.Items[nIndex].UpdateProgress(a_dProgress);
  end;
end;

//==============================================================================
procedure TAudioManager.BroadcastNewTrack(a_nTrackID : Integer);
var
  nIndex : Integer;
begin
  for nIndex := 0 to m_lstListeners.Count - 1 do
  begin
    m_lstListeners.Items[nIndex].AddTrack(a_nTrackID);
  end;
end;

//==============================================================================
procedure TAudioManager.SetTrackPosition(a_nTrackID : Integer; a_nPosition : Integer);
var
  CasTrack : TCasTrack;
begin
  if m_CasEngine.Database.GetTrackById(a_nTrackID, CasTrack) then
    CasTrack.Position := a_nPosition;
end;

//==============================================================================
procedure CreateAudioManager(CasEngine : TCasEngine);
begin
  g_AudioManager := TAudioManager.Create(CasEngine);
end;

end.

