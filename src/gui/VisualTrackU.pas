unit VisualTrackU;

interface

uses
  System.Classes,
  Winapi.D2D1,
  VCL.Direct2D,
  VCL.Graphics,
  VCL.Controls,
  VisualObjectU,
  VisualTypesU,
  PlaylistManagerU;

type

  TVisualTrack = class(TVisualObject)
  private
    m_nTrackID  : Integer;
    m_pmManager : TPlaylistManager;

  public
    constructor Create(a_piInfo : TPlaylistManager; a_nTrackID : Integer);
    destructor Destroy; override;

    procedure Paint(a_d2dKit : TD2DKit); override;

    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp  (Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;

    procedure SetLine(a_nLine : Integer);
  end;

implementation

uses
  Math;

//==============================================================================
constructor TVisualTrack.Create(a_piInfo : TPlaylistManager; a_nTrackID : Integer);
begin
  Inherited Create;
  m_nTrackID := a_nTrackID;
  m_pmManager   := a_piInfo;

  m_vlLocation.SetX(0);
  m_vlLocation.SetY(0);
  m_vlLocation.SetWidth(m_pmManager.GetTrackVisualSize(a_nTrackID));
  m_vlLocation.SetHeight(c_nLineHeight);
end;

//==============================================================================
destructor TVisualTrack.Destroy;
begin
  Inherited;
end;

//==============================================================================
procedure TVisualTrack.SetLine(a_nLine : Integer);
begin
  m_vlLocation.Y := a_nLine * c_nLineHeight;
end;

//==============================================================================
procedure TVisualTrack.Paint(a_d2dKit : TD2DKit);
var
  d2dRect : TD2D1RectF;
begin
  a_d2dKit.D2D1Brush.SetColor(D2D1ColorF(clGreen));

  d2dRect.Left   := m_vlLocation.X;
  d2dRect.Top    := m_vlLocation.Y;
  d2dRect.Right  := m_vlLocation.X + m_vlLocation.Width;
  d2dRect.Bottom := m_vlLocation.Y + m_vlLocation.Height;

  a_d2dKit.Canvas.RenderTarget.FillRectangle(d2dRect, a_d2dKit.D2D1Brush);
end;

//==============================================================================
procedure TVisualTrack.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  dStep     : Double;
  nControlX : Integer;
  nControlY : Integer;
begin
  Inherited;

  if m_vosState.Clicked then
  begin
    dStep := c_nBarWidth/c_nBarSplit;

    nControlX := X - m_pntMouseClick.X;
    nControlY := Y;

    if Abs(nControlX - (m_vlLocation.X + dStep/2)) > dStep then
      m_vlLocation.X := Round(Trunc(nControlX / dStep) * dStep);

    if Abs(nControlY - (m_vlLocation.Y + c_nLineHeight div 2)) > c_nLineHeight then
      m_vlLocation.Y := Trunc(nControlY / c_nLineHeight) * c_nLineHeight;

    m_vlLocation.X := Max(m_vlLocation.X, 0);
    m_vlLocation.Y := Max(m_vlLocation.Y, 0);
  end;
end;

//==============================================================================
procedure TVisualTrack.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  Inherited;
end;

//==============================================================================
procedure TVisualTrack.MouseUp  (Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if m_vosState.Clicked then
  begin
    m_pmManager.SetTrackPosition(m_nTrackID, m_vlLocation.X);
  end;

  Inherited;
end;

end.

