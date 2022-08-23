unit AudioManagerU;

interface

uses
  System.Generics.Collections,
  CasTrackU,
  CasEngineU;

type
  IAudioListener = interface
    procedure UpdateProgress(a_dProgress : Double);
    procedure AddTrack(a_CasTrack : TCasTrack);
  end;

  TAudioManager = class

  private
    m_lstListeners : TList<IAudioListener>;
    m_CasEngine    : TCasEngine;

  public
    constructor Create(CasEngine : TCasEngine);
    destructor  Destroy; override;

    procedure AddListener(a_alListener : IAudioListener);
    procedure RemoveListener(a_alListener : IAudioListener);

    procedure BroadcastProgress(a_dProgress : Double);

    property Engine : TCasEngine read m_CasEngine write m_CasEngine;

  end;

  procedure CreateAudioManager(CasEngine : TCasEngine);

var
  g_AudioManager : TAudioManager = nil;

implementation

//==============================================================================
constructor TAudioManager.Create(CasEngine : TCasEngine);
begin
  m_CasEngine    := CasEngine;
  m_lstListeners := TList<IAudioListener>.Create;
end;

//==============================================================================
destructor TAudioManager.Destroy;
begin
  inherited;
  m_lstListeners.Free;
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
procedure CreateAudioManager(CasEngine : TCasEngine);
begin
  g_AudioManager := TAudioManager.Create(CasEngine);
end;

end.
