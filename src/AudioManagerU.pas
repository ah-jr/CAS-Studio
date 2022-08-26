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
    procedure BroadcastRemoveTrack(a_nTrackID : Integer);
    procedure SetTrackPosition(a_nTrackID : Integer; a_nPosition : Integer);

    function  GetTrackSize(a_nTrackID   : Integer) : Integer;
    function  GetTrackData(a_nTrackID   : Integer;
                           var a_pLeft  : PIntArray;
                           var a_pRight : PIntArray;
                           var a_nSize  : Integer) : Boolean;

    property Engine    : TCasEngine read m_CasEngine write m_CasEngine;
    property BPM       : Double     read m_dBpm      write m_dBpm;
    property BeatCount : Double     read GetBeatCount;

  end;

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
procedure TAudioManager.BroadcastRemoveTrack(a_nTrackID : Integer);
var
  nIndex : Integer;
begin
  for nIndex := 0 to m_lstListeners.Count - 1 do
  begin
    m_lstListeners.Items[nIndex].RemoveTrack(a_nTrackID);
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
function TAudioManager.GetTrackSize(a_nTrackID : Integer) : Integer;
var
  CasTrack : TCasTrack;
begin
  Result := 0;
  if m_CasEngine.Database.GetTrackById(a_nTrackID, CasTrack) then
    Result := CasTrack.Size;
end;

//==============================================================================
function TAudioManager.GetTrackData(a_nTrackID   : Integer;
                                    var a_pLeft  : PIntArray;
                                    var a_pRight : PIntArray;
                                    var a_nSize  : Integer) : Boolean;
var
  CasTrack : TCasTrack;
begin
  Result := m_CasEngine.DataBase.GetTrackByID(a_nTrackID, CasTrack);

  if Result then
  begin
    a_pLeft  := @CasTrack.RawData.Left;
    a_pRight := @CasTrack.RawData.Right;
    a_nSize := Length(CasTrack.RawData.Left);
  end;
end;


end.

