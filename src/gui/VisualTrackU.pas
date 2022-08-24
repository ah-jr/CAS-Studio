unit VisualTrackU;

interface

uses
  System.Classes,
  Winapi.D2D1,
  VCL.Direct2D,
  VCL.Graphics,
  VCL.Controls,
  CasTrackU,
  VisualObjectU,
  VisualTypesU;

type

  TVisualTrack = class(TVisualObject)
  private
    m_CasTrack : TCasTrack;

  public
    constructor Create(a_CasTrack : TCasTrack);
    destructor Destroy; override;

    procedure Paint(a_d2dKit : TD2DKit; a_vpiInfo : TVisualPaintInfo); override;

    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp  (Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
  end;

implementation

uses
  AudioManagerU;

//==============================================================================
constructor TVisualTrack.Create(a_CasTrack : TCasTrack);
begin
  Inherited Create;
  m_CasTrack := a_CasTrack;
end;

//==============================================================================
destructor TVisualTrack.Destroy;
begin
  Inherited;
end;

//==============================================================================
procedure TVisualTrack.Paint(a_d2dKit : TD2DKit; a_vpiInfo : TVisualPaintInfo);
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
    m_CasTrack.Position := Trunc(g_AudioManager.Engine.Length * X/1000);

  Inherited;
end;

end.

