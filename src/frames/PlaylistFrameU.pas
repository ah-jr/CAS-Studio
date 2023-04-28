unit PlaylistFrameU;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Variants,
  System.Classes,
  System.UITypes,
  System.Generics.Collections,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.StdCtrls,
  Vcl.ExtCtrls,
  AcrylicFrameU,
  AcrylicGhostPanelU,
  AcrylicButtonU,
  PlaylistManagerU,
  PlaylistSurfaceU,
  AudioManagerU;


  type
  TPlaylistFrame = class(TAcrylicFrame)
  private
    m_pnlTools     : TAcrylicGhostPanel;
    m_Playlist     : TPlaylistSurface;
    m_pmManager    : TPlaylistManager;
    m_AudioManager : TAudioManager;

    // Tool buttons:
    m_dctButtons : TDictionary<TToolType, TAcrylicButton>;

    procedure ToolButtonClick(Sender : TObject);
    procedure SelectTool(ttTool : TToolType);
    procedure WMNCSize   (var Msg: TWMSize);  message WM_SIZE;

    procedure SetTools;

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

  Name      := 'PlaylistFrame';
  Title     := 'Playlist';
  Resisable := True;

  m_AudioManager := a_AudioManager;

  m_pmManager           := TPlaylistManager.Create(m_AudioManager);
  m_pmManager.Progress  := 0;
  m_pmManager.Size      := 0;
  m_pmManager.Transform.SetOffset(0, 0);
  m_pmManager.Transform.SetScale(PointF(1, 1));

  m_pnlTools         := TAcrylicGhostPanel.Create(Body);
  m_pnlTools.Parent  := Body;
  m_pnlTools.Align   := alTop;
  m_pnlTools.Height  := 25;
  m_pnlTools.Ghost   := False;
  m_pnlTools.Colored := True;
  m_pnlTools.Color   := $10221111;
  m_pnlTools.WithBorder := True;
  m_pnlTools.BorderColor := $40FFFFFF;

  m_Playlist        := TPlaylistSurface.Create(Body, m_pmManager);
  m_Playlist.Parent := Body;
  m_Playlist.Align  := alClient;

  SetTools;

  m_AudioManager.AddListener(m_Playlist);
end;

//==============================================================================
procedure TPlaylistFrame.SetTools;
var
  btnCurr : TAcrylicButton;
begin
  m_dctButtons := TDictionary<TToolType, TAcrylicButton>.Create;

  btnCurr        := TAcrylicButton.Create(m_pnlTools);
  btnCurr.Parent := m_pnlTools;
  btnCurr.Align  := alLeft;
  btnCurr.Width  := 25;
  btnCurr.Text   := 'M';
  btnCurr.BorderColor  := $40FFFFFF;
  btnCurr.Font.Style := [fsBold];
  btnCurr.Font.Size := 10;
  btnCurr.OnClick := ToolButtonClick;
  btnCurr.TypeInfo := Integer(ttMove);
  m_dctButtons.Add(ttMove, btnCurr);

  btnCurr        := TAcrylicButton.Create(m_pnlTools);
  btnCurr.Parent := m_pnlTools;
  btnCurr.Align  := alLeft;
  btnCurr.Width  := 25;
  btnCurr.Text   := 'C';
  btnCurr.BorderColor  := $40FFFFFF;
  btnCurr.Font.Style := [fsBold];
  btnCurr.Font.Size := 10;
  btnCurr.OnClick := ToolButtonClick;
  btnCurr.TypeInfo := Integer(ttCut);
  m_dctButtons.Add(ttCut, btnCurr);
end;

//==============================================================================
procedure TPlaylistFrame.SelectTool(ttTool : TToolType);
var
  Item : TPair<TToolType, TAcrylicButton>;
begin
  m_pmManager.SelectedTool := ttTool;
  m_dctButtons[ttTool].BorderColor := $40FF0000;

  for Item in m_dctButtons do
  begin
    if Item.Key <> ttTool then
    begin
      TAcrylicButton(Item.Value).BorderColor := $40FFFFFF;
      TAcrylicButton(Item.Value).Refresh(True);
    end;
  end;
end;

//==============================================================================
procedure TPlaylistFrame.ToolButtonClick(Sender : TObject);
begin
  SelectTool(TToolType(TAcrylicButton(Sender).TypeInfo));
end;

//==============================================================================
destructor  TPlaylistFrame.Destroy;
begin
  m_AudioManager.RemoveListener(m_Playlist);
  m_pmManager.Free;
  m_dctButtons.Free;

  Inherited;
end;

//==============================================================================
procedure TPlaylistFrame.WMNCSize(var Msg: TWMSize);
begin
  inherited;
end;

end.
