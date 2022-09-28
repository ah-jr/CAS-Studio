unit MixerManagerU;

interface

uses
  System.Types,
  AudioManagerU,
  VisualTypesU,
  TypesU;

type
  TMixerManager = class
  private
    m_AudioManager : TAudioManager;
    m_vtTransform  : TVisualTransform;
    m_recMixer     : TRect;
    m_nMixerCount  : Integer;

  public
    constructor Create(a_AudioManager : TAudioManager);
    destructor  Destroy; override;

    function  GetMixerRect : TRect;
    procedure SetMixerRect(a_recMixer : TRect);

    function IncMixer : Integer;
    function DecMixer : Integer;

    property Transform  : TVisualTransform read m_vtTransform write m_vtTransform;
    property MixerCount : Integer          read m_nMixerCount;

  end;

implementation

uses
  UtilsU;

//==============================================================================
constructor TMixerManager.Create(a_AudioManager : TAudioManager);
begin
  m_AudioManager := a_AudioManager;
  m_recMixer     := TRect.Create(-1,-1,-1,-1);
  m_nMixerCount  := 0;
end;

//==============================================================================
destructor  TMixerManager.Destroy;
begin
  //
end;

//==============================================================================
function TMixerManager.GetMixerRect : TRect;
begin
  Result.Left   := m_recMixer.Left;
  Result.Top    := m_recMixer.Top;
  Result.Width  := m_recMixer.Width;
  Result.Height := m_recMixer.Height;
end;

//==============================================================================
procedure TMixerManager.SetMixerRect(a_recMixer : TRect);
begin
  m_recMixer.Left   := a_recMixer.Left;
  m_recMixer.Top    := a_recMixer.Top;
  m_recMixer.Width  := a_recMixer.Width;
  m_recMixer.Height := a_recMixer.Height;
end;

//==============================================================================
function TMixerManager.IncMixer : Integer;
begin
  Result := m_nMixerCount;
  Inc(m_nMixerCount);
end;

//==============================================================================
function TMixerManager.DecMixer : Integer;
begin
  Result := m_nMixerCount;
  Dec(m_nMixerCount);
end;

//==============================================================================
end.
