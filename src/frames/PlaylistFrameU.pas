unit PlaylistFrameU;

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
  PlaylistManagerU,
  PlaylistSurfaceU,
  AudioManagerU;


  type
  TPlaylistFrame = class(TAcrylicFrame)
  private
    m_Playlist     : TPlaylistSurface;
    m_pmManager    : TPlaylistManager;
    m_AudioManager : TAudioManager;

    procedure WMNCSize   (var Msg: TWMSize);  message WM_SIZE;

  public
    constructor Create(AOwner : TComponent; a_AudioManager : TAudioManager); reintroduce; overload;
    destructor  Destroy; override;

  public
    property Playlist : TPlaylistSurface read m_Playlist write m_Playlist;

  end;

implementation
uses
  System.Types,
  AcrylicLabelU;

//==============================================================================
constructor TPlaylistFrame.Create(AOwner : TComponent; a_AudioManager : TAudioManager);
begin
  Inherited Create(AOwner);

  Name := 'PlaylistFrame';
  m_AudioManager := a_AudioManager;

  m_pmManager           := TPlaylistManager.Create(m_AudioManager);
  m_pmManager.Progress  := 0;
  m_pmManager.Size      := 0;
  m_pmManager.Transform.SetOffset(0);
  m_pmManager.Transform.SetScale(PointF(1, 1));

  m_Playlist        := TPlaylistSurface.Create(Body, m_pmManager);
  m_Playlist.Parent := Body;
  m_Playlist.Left   := 0;
  m_Playlist.Top    := 0;

  m_AudioManager.AddListener(m_Playlist);
end;

//==============================================================================
destructor  TPlaylistFrame.Destroy;
begin
  m_AudioManager.RemoveListener(m_Playlist);
  m_pmManager.Free;

  Inherited;
end;

//==============================================================================
procedure TPlaylistFrame.WMNCSize(var Msg: TWMSize);
begin
  inherited;

  m_Playlist.Width  := Body.Width;
  m_Playlist.Height := Body.Height;
end;

end.
