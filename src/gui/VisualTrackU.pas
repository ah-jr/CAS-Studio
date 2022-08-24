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
  PlaylistInfoU;

type

  TVisualTrack = class(TVisualObject)
  private
    m_nTrackID : Integer;
    m_piInfo   : TPlaylistInfo;

  public
    constructor Create(a_piInfo : TPlaylistInfo; a_nTrackID : Integer);
    destructor Destroy; override;

    procedure Paint(a_d2dKit : TD2DKit); override;

    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp  (Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
  end;

implementation

//==============================================================================
constructor TVisualTrack.Create(a_piInfo : TPlaylistInfo; a_nTrackID : Integer);
begin
  Inherited Create;
  m_nTrackID := a_nTrackID;
  m_piInfo   := a_piInfo;
end;

//==============================================================================
destructor TVisualTrack.Destroy;
begin
  Inherited;
end;

//==============================================================================
procedure TVisualTrack.Paint(a_d2dKit : TD2DKit);
var
  d2dRect : TD2D1RectF;
begin
  a_d2dKit.D2D1Brush.SetColor(D2D1ColorF(clGreen));

//  d2dRect.Top    := 10;
//  d2dRect.Bottom := 30;
//  d2dRect.Left   := a_vpiInfo.Transform.Offset + (m_CasTrack.Position / a_vpiInfo.Size) * 1000;
//  d2dRect.Right  := d2dRect.Left + (m_CasTrack.Size / a_vpiInfo.Size) * 1000;


  d2dRect.Left   := m_vlLocation.X;
  d2dRect.Top    := m_vlLocation.Y;
  d2dRect.Right  := m_vlLocation.X + m_vlLocation.Width;
  d2dRect.Bottom := m_vlLocation.Y + m_vlLocation.Height;

  a_d2dKit.Canvas.RenderTarget.FillRectangle(d2dRect, a_d2dKit.D2D1Brush);
end;

//==============================================================================
procedure TVisualTrack.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  Inherited;
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
    m_piInfo.SetTrackPosition(m_nTrackID, m_vlLocation.X);
  end;

  Inherited;
end;

end.

