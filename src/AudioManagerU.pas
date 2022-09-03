unit AudioManagerU;

interface

uses
  System.Generics.Collections,
  System.Classes,
  Windows,
  Messages,
  CasEngineU,
  CasDecoderU,
  CasTrackU,
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
    procedure BroadcastNewTrack(a_nTrackID : Integer);
    procedure BroadcastRemoveTrack(a_nTrackID : Integer);
    procedure BroadcastUpdateGUI;
    procedure BroadcastDriverChange;

    procedure SetTrackPosition(a_nTrackID : Integer; a_nPosition : Integer);

    function  GetTrackSize(a_nTrackID   : Integer) : Integer;
    function  GetTrackData(a_nTrackID   : Integer;
                           var a_pLeft  : PIntArray;
                           var a_pRight : PIntArray;
                           var a_nSize  : Integer) : Boolean;

    function GetTrackById(a_nID: Integer; var a_Castrack : TCasTrack) : Boolean;

    //==========================================================================
    // CasEngine Interface:
    procedure Play;
    procedure Pause;
    procedure Stop;
    procedure Prev;
    procedure Next;
    procedure GoToTrack(a_nID: Integer);

    function  GetLevel      : Double;
    function  GetPosition   : Integer;
    function  GetProgress   : Double;
    function  GetLength     : Integer;
    function  GetReady      : Boolean;
    function  GetPlaying    : Boolean;
    function  GetSampleRate : Double;
    function  GetBufferSize : Cardinal;
    function  GetTime       : String;
    function  GetDuration   : String;
    function  GenerateID    : Integer;

    function  GetTrackCount : Integer;
    function  GetActiveTracks : TList<Integer>;
    function  GetTrackProgress(a_nTrackId : Integer) : Double;
    function  AddTrackToPlaylist(a_nTrackId, a_nPosition : Integer) : Boolean;
    function  AddTrack(a_CasTrack : TCasTrack; a_nMixerId : Integer) : Boolean;

    procedure ControlPanel;
    procedure SetLevel     (a_dLevel : Double);
    procedure SetPosition  (a_nPosition : Integer);
    procedure ChangeDriver (a_dtDriverType : TDriverType; a_nID : Integer);
    procedure DeleteTrack(a_nTrackId : Integer);
    procedure ClearTracks;
    procedure CalculateBuffers(a_LeftOut : CasTypesU.PIntArray; a_RightOut : CasTypesU.PIntArray);

    //==========================================================================


    property Engine    : TCasEngine read m_CasEngine write m_CasEngine;
    property BPM       : Double     read m_dBpm      write m_dBpm;
    property BeatCount : Double     read GetBeatCount;

  end;

implementation

uses
  UtilsU;

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
  m_lstListeners := TList<IAudioListener>.Create;

  m_dBpm := 130;
end;

//==============================================================================
procedure TAudioManager.DecodeReady(var MsgRec: TMessage);
var
  CasTrack : TCasTrack;
begin
  for CasTrack in m_CasDecoder.Tracks do
  begin
    CasTrack.Level := 0.7;
    CasTrack.ID    := m_CasEngine.GenerateID;
    m_CasEngine.AddTrack(CasTrack, 0);
    m_CasEngine.AddTrackToPlaylist(CasTrack.ID, m_CasEngine.GetLength);

    BroadcastNewTrack(CasTrack.ID);
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
procedure AudioExport(a_asOut : TAudioSpecs; a_strFileName : String);
begin
  //m_CasExport.Export(Engine.Playlist, a_asOut, a_strFileName);
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
    m_lstListeners.Items[nIndex].UpdateProgress(GetProgress);
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

//==============================================================================
function TAudioManager.GetTrackById(a_nID: Integer; var a_Castrack : TCasTrack) : Boolean;
begin
  Result := m_CasEngine.Database.GetTrackByID(a_nID, a_CasTrack);
end;

//==========================================================================
// CasEngine Interface:
procedure TAudioManager.Play;  begin m_CasEngine.Play;  end;
procedure TAudioManager.Pause; begin m_CasEngine.Pause; end;
procedure TAudioManager.Stop;  begin m_CasEngine.Stop;  end;
procedure TAudioManager.Prev;  begin m_CasEngine.Prev;  end;
procedure TAudioManager.Next;  begin m_CasEngine.Next;  end;
procedure TAudioManager.GoToTrack(a_nID: Integer);  begin m_CasEngine.GoToTrack(a_nID); end;

function  TAudioManager.GetLevel      : Double;   begin Result := m_CasEngine.GetLevel; end;
function  TAudioManager.GetPosition   : Integer;  begin Result := m_CasEngine.GetPosition; end;
function  TAudioManager.GetProgress   : Double;   begin Result := m_CasEngine.GetProgress; end;
function  TAudioManager.GetLength     : Integer;  begin Result := m_CasEngine.GetLength; end;
function  TAudioManager.GetReady      : Boolean;  begin Result := m_CasEngine.GetReady; end;
function  TAudioManager.GetPlaying    : Boolean;  begin Result := m_CasEngine.GetPlaying; end;
function  TAudioManager.GetSampleRate : Double;   begin Result := m_CasEngine.GetSampleRate; end;
function  TAudioManager.GetBufferSize : Cardinal; begin Result := m_CasEngine.GetBufferSize; end;
function  TAudioManager.GetTime       : String;   begin Result := m_CasEngine.GetTime; end;
function  TAudioManager.GetDuration   : String;   begin Result := m_CasEngine.GetDuration; end;
function  TAudioManager.GenerateID    : Integer;  begin Result := m_CasEngine.GenerateID; end;

function TAudioManager.GetTrackCount : Integer;
begin Result := m_CasEngine.GetTrackCount end;

function TAudioManager.GetActiveTracks : TList<Integer>;
begin Result := m_CasEngine.GetActiveTracks; end;

function TAudioManager.GetTrackProgress(a_nTrackId : Integer) : Double;
begin Result := m_CasEngine.GetTrackProgress(a_nTrackId); end;

function TAudioManager.AddTrackToPlaylist(a_nTrackId, a_nPosition : Integer) : Boolean;
begin Result := m_CasEngine.AddTrackToPlaylist(a_nTrackId, a_nPosition); end;

function TAudioManager.AddTrack(a_CasTrack : TCasTrack; a_nMixerId : Integer) : Boolean;
begin Result := m_CasEngine.AddTrack(a_CasTrack, a_nMixerId); end;

procedure TAudioManager.ControlPanel;
begin m_CasEngine.ControlPanel; end;

procedure TAudioManager.SetLevel(a_dLevel : Double);
begin m_CasEngine.SetLevel(a_dLevel); end;

procedure TAudioManager.SetPosition(a_nPosition : Integer);
begin m_CasEngine.SetPosition(a_nPosition); end;

procedure TAudioManager.ChangeDriver(a_dtDriverType : TDriverType; a_nID : Integer);
begin m_CasEngine.ChangeDriver(a_dtDriverType, a_nID); end;

procedure TAudioManager.DeleteTrack(a_nTrackId : Integer);
begin m_CasEngine.DeleteTrack(a_nTrackId); end;

procedure TAudioManager.ClearTracks;
begin m_CasEngine.ClearTracks; end;

procedure TAudioManager.CalculateBuffers(a_LeftOut : CasTypesU.PIntArray; a_RightOut : CasTypesU.PIntArray);
begin m_CasEngine.CalculateBuffers(a_LeftOut, a_RightOut); end;

//==========================================================================

end.

