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

    m_vtTransform : TVisualTransform;
    m_nSize       : Integer;
    m_dProgress   : Double;
    m_recMixer   : TRect;


  public
    constructor Create(a_AudioManager : TAudioManager);
    destructor  Destroy; override;

    function  XToBeat              (a_dX          : Double)  : Double;
    function  XToSample            (a_dX          : Double)  : Double;
    function  BeatToX              (a_dBeat       : Double)  : Double;
    function  SampleToX            (a_dSample     : Double)  : Double;
    function  GetVisualSize        (a_dSampleSize : Double)  : Double;
    function  GetSampleSize        (a_dVisualSize : Double)  : Double;
    function  GetTrackVisualWidth  (a_nTrackID    : Integer) : Double;
    function  GetTrackVisualHeight : Double;
    function  GetBeatCount    : Double;
    function  GetProgressX    : Double;
    function  GetMixerRect    : TRect;

    function  GetTrackData(a_nTrackID   : Integer;
                           var a_pLeft  : PIntArray;
                           var a_pRight : PIntArray;
                           var a_nSize  : Integer) : Boolean;

    procedure SetMixerRect    (a_recMixer : TRect);
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
constructor TMixerManager.Create(a_AudioManager : TAudioManager);
begin
  m_AudioManager := a_AudioManager;
  m_recMixer  := TRect.Create(-1,-1,-1,-1);
end;

//==============================================================================
destructor  TMixerManager.Destroy;
begin
  //
end;

//==============================================================================
function TMixerManager.GetBeatCount : Double;
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
function TMixerManager.GetProgressX : Double;
var
  dProgress : Double;
  dX        : Double;
begin
  dProgress := m_AudioManager.Engine.Progress;
  dX        := dProgress*GetBeatCount*c_nBarWidth;

  Result := (dX - m_vtTransform.Offset.X) * m_vtTransform.Scale.X;
end;

//==============================================================================
function TMixerManager.XToBeat(a_dX : Double) : Double;
begin
  Result := (a_dX/m_vtTransform.Scale.X + m_vtTransform.Offset.X) / c_nBarWidth;
end;

//==============================================================================
function TMixerManager.BeatToX(a_dBeat : Double) : Double;
begin
  Result := (a_dBeat * c_nBarWidth - m_vtTransform.Offset.X) * m_vtTransform.Scale.X;
end;

//==============================================================================
function TMixerManager.XToSample(a_dX : Double) : Double;
var
  dSampleRate : Double;
  dBPM        : Double;
begin
  dSampleRate := m_AudioManager.Engine.SampleRate;
  dBPM        := m_AudioManager.BPM;

  Result := MsToSampleCount(BeatsToMs(dBPM, XToBeat(a_dX)), dSampleRate);
end;

//==============================================================================
function TMixerManager.SampleToX(a_dSample : Double) : Double;
var
  dSampleRate : Double;
  dBPM        : Double;
begin
  dSampleRate := m_AudioManager.Engine.SampleRate;
  dBPM        := m_AudioManager.BPM;

  Result := BeatToX(MsToBeats(dBPM, SampleCountToMs(a_dSample, dSampleRate)));
end;

//==============================================================================
function TMixerManager.GetVisualSize(a_dSampleSize : Double) : Double;
var
  dSampleRate : Double;
  dBPM        : Double;
  dBeats      : Double;
begin
  dSampleRate    := m_AudioManager.Engine.SampleRate;
  dBPM           := m_AudioManager.BPM;
  dBeats         := MsToBeats(dBPM, SampleCountToMs(a_dSampleSize, dSampleRate));

  Result := dBeats * c_nBarWidth * m_vtTransform.Scale.X;
end;

//==============================================================================
function TMixerManager.GetSampleSize(a_dVisualSize : Double) : Double;
var
  dSampleRate : Double;
  dBPM        : Double;
  dMs         : Double;
begin
  dSampleRate    := m_AudioManager.Engine.SampleRate;
  dBPM           := m_AudioManager.BPM;
  dMs            := BeatsToMs(dBPM, a_dVisualSize / (c_nBarWidth * m_vtTransform.Scale.X));

  Result := MsToSampleCount(dMs, dSampleRate);
end;

//==============================================================================
function TMixerManager.GetTrackVisualWidth(a_nTrackID : Integer) : Double;
var
  dSampleRate : Double;
  dBPM        : Double;
  dBeats      : Double;
  nSize       : Integer;
begin
  dSampleRate    := m_AudioManager.Engine.SampleRate;
  dBPM           := m_AudioManager.BPM;
  nSize          := m_AudioManager.GetTrackSize(a_nTrackID);
  dBeats         := MsToBeats(dBPM, SampleCountToMs(nSize, dSampleRate));

  Result := (dBeats * c_nBarWidth * m_vtTransform.Scale.X);
end;

//==============================================================================
function TMixerManager.GetTrackVisualHeight : Double;
begin
  Result := c_nLineHeight * m_vtTransform.Scale.Y;
end;

//==============================================================================
procedure TMixerManager.SetTrackPosition(a_nTrackID : Integer; a_nPos : Integer);
begin
  m_AudioManager.SetTrackPosition(a_nTrackID, a_nPos);
end;

//==============================================================================
function TMixerManager.GetTrackData(a_nTrackID   : Integer;
                                       var a_pLeft  : PIntArray;
                                       var a_pRight : PIntArray;
                                       var a_nSize  : Integer) : Boolean;
begin
  Result := m_AudioManager.GetTrackData(a_nTrackID, a_pLeft, a_pRight, a_nSize);
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
end.
