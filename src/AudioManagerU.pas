unit AudioManagerU;

interface

uses
  System.Generics.Collections,
  System.Classes,
  Windows,
  Messages,
  CasEngineU,
  CasDecoderU,
  CasEncoderU,
  CasTrackU,
  CasMixerU,
  CasTypesU,
  CasConstantsU,
  TypesU;

type
  TAudioManager = class

  private
    m_hwndHandle   : HWND;
    m_lstListeners : TList<IAudioListener>;
    m_CasEngine    : TCasEngine;
    m_CasDecoder   : TCasDecoder;
    m_CasEncoder   : TCasEncoder;

    m_dBpm         : Double;

    function GetBeatCount : Double;

    procedure DecodeReady(var MsgRec: TMessage);
    procedure InitializeVariables;
    procedure ProcessMessage(var MsgRec: TMessage);

  public
    constructor Create;
    destructor  Destroy; override;

    procedure AsyncDecodeFile(a_lstFiles : TStrings);
    procedure AudioExport(a_asOut : TAudioSpecs; a_strFileName : String);

    procedure AddListener(a_alListener : IAudioListener);
    procedure RemoveListener(a_alListener : IAudioListener);

    procedure BroadcastProgress;
    procedure BroadcastNewClip    (a_nClipID  : Integer; a_nIndex : Integer = -1);
    procedure BroadcastNewTrack   (a_nTrackID : Integer);
    procedure BroadcastRemoveTrack(a_nTrackID : Integer);
    procedure BroadcastUpdateGUI;
    procedure BroadcastDriverChange;
    procedure BroadcastBPMChange(a_dOldBPM : Double);

    procedure CutClip(a_nClipID : Integer;  a_nPos : Integer; a_nHeight : Integer);

    procedure SetMixerLevel(a_nMixerID : Integer; a_dLevel : Double);
    procedure SetClipPos(a_nClipID : Integer; a_nFirst: Integer; a_nLast: Integer = -1; a_nOffset: Integer = -1);
    procedure SetNewBPM(a_dBPM : Double);

    function  GetMixerLevel (a_nMixerID  : Integer) : Double;
    function  GetClipOffset (a_nClipId    : Integer) : Integer;
    function  GetClipSize   (a_nClipID    : Integer) : Integer;
    function  GetClipPos    (a_nClipId    : Integer) : Integer;
    function  GetClipTrackID(a_nClipID    : Integer) : Integer;
    function  GetTrackSize  (a_nTrackID   : Integer) : Integer;

    function  GetTrackDataByTrackID(a_nTrackID   : Integer;
                                    var a_pLeft  : PIntArray;
                                    var a_pRight : PIntArray;
                                    var a_nSize  : Integer) : Boolean;
    function  GetTrackDataByClipID  (a_nClipID   : Integer;
                                    var a_pLeft  : PIntArray;
                                    var a_pRight : PIntArray;
                                    var a_nSize  : Integer) : Boolean;


    function GetTrackById(a_nID: Integer; var a_Castrack : TCasTrack) : Boolean;

    property Engine    : TCasEngine read m_CasEngine;
    property BPM       : Double     read m_dBpm      write SetNewBPM;
    property BeatCount : Double     read GetBeatCount;

  end;

implementation

uses
  System.SysUtils,
  UtilsU,
  CasClipU;

//==============================================================================
constructor TAudioManager.Create;
begin
  InitializeVariables;
end;

//==============================================================================
destructor TAudioManager.Destroy;
begin
  DestroyWindow(m_hwndHandle);
  m_lstListeners.Free;
  m_CasEngine.Free;
  m_CasDecoder.Free;

  inherited;
end;

//==============================================================================
procedure TAudioManager.InitializeVariables;
begin
  m_hwndHandle   := AllocateHWnd(ProcessMessage);
  m_CasEngine    := TCasEngine.Create(m_hwndHandle);
  m_CasDecoder   := TCasDecoder.Create;
  m_CasEncoder   := TCasEncoder.Create;
  m_lstListeners := TList<IAudioListener>.Create;

  m_dBpm := c_dDefBPM;
end;

//==============================================================================
procedure TAudioManager.DecodeReady(var MsgRec: TMessage);
var
  tiTrack  : TTrackInfo;
  nCount   : Integer; //REMOVE THIS IN THE FUTURE
  nTrackID : Integer;
  nClipID  : Integer;
begin
  nCount := 1;

  for tiTrack in m_CasDecoder.Tracks do
  begin
    nTrackID := m_CasEngine.AddTrack(tiTrack.Title, tiTrack.Data, nCount);
    nClipID := m_CasEngine.PlayList.AddClip(nTrackID, m_CasEngine.GetLength);

    BroadcastNewTrack(nTrackID);

    if nClipID > 0 then
      BroadcastNewClip(nClipID);

    Inc(nCount);
  end;

  m_CasDecoder.Tracks.Clear;

  BroadcastUpdateGui;
end;

//==============================================================================
procedure TAudioManager.ProcessMessage(var MsgRec: TMessage);
begin
  case MsgRec.Msg of
    CM_NotifyDecode : DecodeReady(MsgRec);
    CM_NotifyOwner  :
    begin
      case TNotificationType(MsgRec.Wparam) of
        ntBuffersDestroyed,
        ntBuffersCreated,
        ntDriverClosed     : BroadcastUpdateGui;
        ntRequestedReset   : BroadcastDriverChange;
        ntBuffersUpdated   : BroadcastProgress;
      end;
    end;
  end;
end;

//==============================================================================
procedure TAudioManager.AsyncDecodeFile(a_lstFiles : TStrings);
begin
  m_CasDecoder.AsyncDecodeFile(m_hwndHandle, a_lstFiles, m_CasEngine.SampleRate);
end;

//==============================================================================
procedure TAudioManager.AudioExport(a_asOut : TAudioSpecs; a_strFileName : String);
begin
  m_CasEncoder.AudioExport(m_CasEngine, a_asOut, a_strFileName);
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
procedure TAudioManager.BroadcastProgress;
var
  nIndex : Integer;
begin
  for nIndex := 0 to m_lstListeners.Count - 1 do
  begin
    m_lstListeners.Items[nIndex].UpdateProgress(Engine.Progress);
  end;
end;

//==============================================================================
procedure TAudioManager.BroadcastNewClip(a_nClipID : Integer; a_nIndex : Integer);
var
  nIndex : Integer;
begin
  for nIndex := 0 to m_lstListeners.Count - 1 do
  begin
    m_lstListeners.Items[nIndex].AddClip(a_nClipID, a_nIndex);
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
procedure TAudioManager.BroadcastUpdateGui;
var
  nIndex : Integer;
begin
  for nIndex := 0 to m_lstListeners.Count - 1 do
  begin
    m_lstListeners.Items[nIndex].UpdateGui;
  end;
end;

//==============================================================================
procedure TAudioManager.BroadcastDriverChange;
var
  nIndex : Integer;
begin
  for nIndex := 0 to m_lstListeners.Count - 1 do
  begin
    m_lstListeners.Items[nIndex].DriverChange;
  end;
end;

//==============================================================================
procedure TAudioManager.BroadcastBPMChange(a_dOldBPM : Double);
var
  nIndex : Integer;
begin
  for nIndex := 0 to m_lstListeners.Count - 1 do
  begin
    m_lstListeners.Items[nIndex].UpdateBPM(a_dOldBPM, m_dBPM);
  end;
end;

//==============================================================================
procedure TAudioManager.CutClip(a_nClipID : Integer; a_nPos : Integer; a_nHeight : Integer);
var
  Clip     : TCasClip;
  NewClip  : TCasClip;
  nNewClip : Integer;
begin
  if m_CasEngine.Playlist.GetClip(a_nClipID, Clip) then
  begin
    nNewClip := m_CasEngine.Playlist.AddClip(Clip.TrackID, Clip.StartPos, Clip.Offset, Clip.Size);
    m_CasEngine.Playlist.GetClip(nNewClip, NewClip);

    Clip.SetRightBound(a_nPos);
    NewClip.SetLeftBound(a_nPos);

    BroadcastNewClip(nNewClip, a_nHeight);
  end;
end;

//==============================================================================
procedure TAudioManager.SetNewBPM(a_dBPM : Double);
var
  dOldBPM : Double;
begin
  dOldBPM := m_dBpm;
  m_dBpm  := a_dBPM;
  BroadcastBPMChange(dOldBPM);
end;

//==============================================================================
procedure TAudioManager.SetMixerLevel(a_nMixerID : Integer; a_dLevel : Double);
var
  CasMixer : TCasMixer;
begin
  if m_CasEngine.Database.GetMixerById(a_nMixerID, CasMixer) then
    CasMixer.Level := a_dLevel;
end;

//==============================================================================
procedure TAudioManager.SetClipPos(a_nClipID : Integer; a_nFirst: Integer; a_nLast : Integer; a_nOffset: Integer);
begin
  m_CasEngine.Playlist.SetClipPos(a_nClipID, a_nFirst, a_nLast, a_nOffset);
end;

//==============================================================================
function  TAudioManager.GetMixerLevel(a_nMixerID : Integer) : Double;
var
  CasMixer : TCasMixer;
begin
  Result := 0;

  if m_CasEngine.Database.GetMixerById(a_nMixerID, CasMixer) then
    Result := CasMixer.Level;
end;

//==============================================================================
function TAudioManager.GetClipOffset(a_nClipID : Integer) : Integer;
var
  Clip : TCasClip;
begin
  if m_CasEngine.Playlist.GetClip(a_nClipID, Clip) then
  begin
    Result := Clip.Offset;
  end;
end;

//==============================================================================
function TAudioManager.GetClipSize(a_nClipID : Integer) : Integer;
begin
  Result := m_CasEngine.Playlist.GetClipSize(a_nClipID);
end;

//==============================================================================
function TAudioManager.GetClipPos(a_nClipID : Integer) : Integer;
var
  Clip : TCasClip;
begin
  if m_CasEngine.Playlist.GetClip(a_nClipID, Clip) then
  begin
    Result := Clip.StartPos;
  end;
end;

//==============================================================================
function TAudioManager.GetClipTrackID(a_nClipID : Integer) : Integer;
var
  Clip : TCasClip;
begin
  Result := -1;

  if m_CasEngine.Playlist.GetClip(a_nClipID, Clip) then
  begin
    Result := Clip.TrackID;
  end;
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
function TAudioManager.GetTrackDataByClipID(a_nClipID    : Integer;
                                            var a_pLeft  : PIntArray;
                                            var a_pRight : PIntArray;
                                            var a_nSize  : Integer) : Boolean;
var
  Clip : TCasClip;
begin
  m_CasEngine.Playlist.GetClip(a_nClipID, Clip);

  Result := GetTrackDataByTrackID(Clip.TrackID, a_pLeft, a_pRight, a_nSize);
end;

//==============================================================================
function TAudioManager.GetTrackDataByTrackID(a_nTrackID   : Integer;
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

//==============================================================================
function TAudioManager.GetTrackById(a_nID: Integer; var a_Castrack : TCasTrack) : Boolean;
begin
  Result := m_CasEngine.Database.GetTrackByID(a_nID, a_CasTrack);
end;

end.

