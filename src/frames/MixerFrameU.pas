unit MixerFrameU;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Variants,
  System.Classes,
  System.UITypes,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.StdCtrls,
  Vcl.ExtCtrls,
  AcrylicFrameU,
  MixerManagerU,
  MixerSurfaceU,
  AudioManagerU;


  type
  TMixerFrame = class(TAcrylicFrame)
  private
    m_Mixer        : TMixerSurface;
    m_mmManager    : TMixerManager;
    m_AudioManager : TAudioManager;

    procedure WMNCSize   (var Msg: TWMSize);  message WM_SIZE;

  public
    constructor Create(AOwner : TComponent; a_AudioManager : TAudioManager); reintroduce; overload;
    destructor  Destroy; override;

  public
    property Mixer : TMixerSurface read m_Mixer write m_Mixer;

  end;

implementation
uses
  System.Types,
  AcrylicLabelU;

//==============================================================================
constructor TMixerFrame.Create(AOwner : TComponent; a_AudioManager : TAudioManager);
begin
  Inherited Create(AOwner);

  Name      := 'MixerFrame';
  Title     := 'Mixer';
  Resisable := True;

  m_AudioManager := a_AudioManager;

  m_mmManager           := TMixerManager.Create(m_AudioManager);
  m_mmManager.Transform.SetOffset(0, 0);
  m_mmManager.Transform.SetScale(PointF(1, 1));

  m_Mixer        := TMixerSurface.Create(Body, m_mmManager);
  m_Mixer.Parent := Body;
  m_Mixer.Left   := 0;
  m_Mixer.Top    := 0;

  m_AudioManager.AddListener(m_Mixer);
end;

//==============================================================================
destructor  TMixerFrame.Destroy;
begin
  m_AudioManager.RemoveListener(m_Mixer);
  m_mmManager.Free;

  Inherited;
end;

//==============================================================================
procedure TMixerFrame.WMNCSize(var Msg: TWMSize);
begin
  inherited;

  m_Mixer.Width  := Body.Width;
  m_Mixer.Height := Body.Height;
end;

end.
