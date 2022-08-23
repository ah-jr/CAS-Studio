unit VisualTrackU;

interface

uses
  Winapi.D2D1,
  VCL.Direct2D,
  VCL.Graphics,
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
  end;

implementation

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
  d2dRect  : TD2D1RectF;
begin
  a_d2dKit.D2D1Brush.SetColor(D2D1ColorF(clGreen));

  d2dRect.Top    := 10;
  d2dRect.Bottom := 30;
  d2dRect.Left   := a_vpiInfo.Transform.Offset + (m_CasTrack.Position / a_vpiInfo.Size) * 1000;
  d2dRect.Right  := d2dRect.Left + (m_CasTrack.Size / a_vpiInfo.Size) * 1000;

  a_d2dKit.Canvas.RenderTarget.FillRectangle(d2dRect, a_d2dKit.D2D1Brush);
end;

end.

