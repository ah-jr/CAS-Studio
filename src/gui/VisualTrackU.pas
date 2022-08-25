unit VisualTrackU;

interface

uses
  System.Classes,
  System.Types,
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
    m_nTrackID   : Integer;
    m_pmManager  : TPlaylistManager;
    m_nHeight    : Integer;
    m_nPosition  : Integer;
    m_pgWaveForm : ID2D1PathGeometry;

    function CalculateWavePath : ID2D1PathGeometry;

  public
    constructor Create(a_piInfo : TPlaylistManager; a_nTrackID : Integer);
    destructor Destroy; override;

    procedure Paint        (a_d2dKit : TD2DKit); override;
    procedure PaintWavePath(a_d2dKit : TD2DKit);

    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp  (Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;

    function GetRect : TRect; override;

    procedure SetLine(a_nLine : Integer);

    property Height   : Integer read m_nHeight   write SetLine;
    property Position : Integer read m_nPosition write m_nPosition;
  end;

implementation

uses
  Winapi.Windows,
  System.UITypes,
  TypesU,
  Math;

//==============================================================================
constructor TVisualTrack.Create(a_piInfo : TPlaylistManager; a_nTrackID : Integer);
begin
  Inherited Create;
  m_nTrackID   := a_nTrackID;
  m_pmManager  := a_piInfo;
  m_pgWaveForm := CalculateWavePath;

  m_nPosition := 0;
  m_nHeight   := 0;
end;

//==============================================================================
destructor TVisualTrack.Destroy;
begin
  Inherited;
end;

//==============================================================================
procedure TVisualTrack.SetLine(a_nLine : Integer);
begin
  if a_nLine >= 0 then
    m_nHeight := a_nLine;
end;

//==============================================================================
procedure TVisualTrack.Paint(a_d2dKit : TD2DKit);
var
  d2dRect : TD2D1RectF;
  recSelf : TRect;
begin
  a_d2dKit.D2D1Brush.SetColor(D2D1ColorF(clBlack));
  recSelf := GetRect;

  d2dRect.Left   := recSelf.Left;
  d2dRect.Top    := recSelf.Top;
  d2dRect.Right  := d2dRect.Left + recSelf.Width;
  d2dRect.Bottom := d2dRect.Top  + recSelf.Height;

  a_d2dKit.Canvas.RenderTarget.FillRectangle(d2dRect, a_d2dKit.D2D1Brush);

  PaintWavePath(a_d2dKit);
end;

//==============================================================================
procedure TVisualTrack.PaintWavePath(a_d2dKit : TD2DKit);
var
  sspProp : TD2D1StrokeStyleProperties;
  ssStyle : ID2D1StrokeStyle;
  Factory : ID2D1Factory;
  Matrix  : TD2DMatrix3x2F;
  recSelf : TRect;
begin
  recSelf := GetRect;
  Matrix  := TD2DMatrix3x2F.Translation(recSelf.Left, recSelf.Top);

  a_d2dKit.D2D1Brush.SetColor(D2D1ColorF(clWhite));

  sspProp.StartCap   := D2D1_CAP_STYLE_ROUND;
  sspProp.EndCap     := D2D1_CAP_STYLE_ROUND;
  sspProp.DashCap    := D2D1_CAP_STYLE_ROUND;
  sspProp.LineJoin   := D2D1_LINE_JOIN_ROUND;
  sspProp.MiterLimit := 10;
  sspProp.DashStyle  := D2D1_DASH_STYLE_SOLID;
  sspProp.DashOffset := 0;

  a_d2dKit.Canvas.RenderTarget.GetFactory(Factory);
  Factory.CreateStrokeStyle(sspProp, nil, 0, ssStyle);

  a_d2dKit.Canvas.RenderTarget.SetAntialiasMode(D2D1_ANTIALIAS_MODE_PER_PRIMITIVE);
  a_d2dKit.Canvas.RenderTarget.SetTransform(Matrix);
  a_d2dKit.Canvas.RenderTarget.DrawGeometry(m_pgWaveForm, a_d2dKit.D2D1Brush, 2, ssStyle);
  a_d2dKit.Canvas.RenderTarget.SetTransform(TD2DMatrix3x2F.Identity);
end;

//==============================================================================
procedure TVisualTrack.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  dStep     : Double;
  nControlX : Integer;
  nControlY : Integer;
  nPos      : Integer;
  nStepSize : Integer;
  recSelf   : TRect;
begin
  Inherited;

  SetCursor(LoadCursor(0, IDC_SIZEALL));

  if m_vosState.Clicked then
  begin
    recSelf   := GetRect;
    nControlX := X - m_pntMouseClick.X;
    nControlY := Y;

    dStep     := m_pmManager.Transform.Scale.X * c_nBarWidth/c_nBarSplit;
    nStepSize := m_pmManager.GetSampleSize(dStep);
    nPos      := m_pmManager.XToSample(nControlX);

    m_nPosition := Round(nPos / nStepSize) * nStepSize;

    if Abs(recSelf.Top + c_nLineHeight div 2 - nControlY) > c_nLineHeight then
      m_nHeight := Trunc(nControlY / c_nLineHeight);

    m_nPosition := Max(m_nPosition, 0);
    m_nHeight   := Max(m_nHeight,   0);
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
    m_pmManager.SetTrackPosition(m_nTrackID, m_nPosition);
  end;

  Inherited;
end;

//==============================================================================
function TVisualTrack.GetRect : TRect;
begin
  Result.Left   := Trunc(m_pmManager.SampleToX(m_nPosition));
  Result.Top    := m_nHeight * c_nLineHeight;
  Result.Right  := Result.Left + m_pmManager.GetTrackVisualSize(m_nTrackID);
  Result.Bottom := Result.Top  + c_nLineHeight;
end;

//==============================================================================
function TVisualTrack.CalculateWavePath : ID2D1PathGeometry;
var
  recSelf      : TRect;
  nTrackIdx    : Integer;
  nFragIdx     : Integer;
  nMax         : Integer;
  nAverage     : Integer;
  nCurrent     : Integer;
  nAmplitude   : Integer;
  nOffset      : Integer;
  bSwitch      : Boolean;
  dTrackRatio  : Double;
  dScreenRatio : Double;
  pntPrev      : TPointF;
  pntCurr      : TPointF;
  nPathSize    : Integer;
  gsSink       : ID2D1GeometrySink;
  pData        : PIntArray;
  nDataSize    : Integer;
const
  DATAOFFSET = 5;
  m_nTitleBarHeight = 0;
begin
  recSelf      := GetRect;
  nPathSize    := 4*recSelf.Width;
  pData        := nil;

  m_pmManager.GetTrackData(m_nTrackID, pData, pData, nDataSize);

  dScreenRatio := (recSelf.Width - 2 * DATAOFFSET) / nPathSize;
  dTrackRatio  := nDataSize / nPathSize;
  nAmplitude   := (recSelf.Height - m_nTitleBarHeight - 10) div 2;
  nOffset      := (recSelf.Height + m_nTitleBarHeight) div 2;
  nMax         := 1;
  pntPrev.X    := DATAOFFSET;
  pntPrev.Y    := nOffset;
  bSwitch      := True;

  for nTrackIdx := 0 to nDataSize - 1 do
    nMax := Max(nMax, Abs(TIntArray(pData^)[nTrackIdx]));

  D2DFactory.CreatePathGeometry(Result);
  Result.Open(gsSink);
  gsSink.SetFillMode(D2D1_FILL_MODE_WINDING);

  gsSink.BeginFigure(D2D1PointF(DATAOFFSET, nOffset), D2D1_FIGURE_BEGIN_FILLED);

  //////////////////////////////////////////////////////////////////////////////
  // Narrow down data to fit in the PATHSIZE
  for nTrackIdx := 0 to nPathSize - 1 do
  begin
    nFragIdx := 0;

    if bSwitch then
      nAverage :=  MaxInt
    else
      nAverage := -MaxInt;

    while nFragIdx < dTrackRatio do
    begin
      //////////////////////////////////////////////////////////////////////////
      // Get the largest value in the samples covered
      nCurrent := TIntArray(pData^)[Round(nTrackIdx * dTrackRatio) + nFragIdx];

      if bSwitch then
        nAverage := Min(nCurrent, nAverage)
      else
        nAverage := Max(nCurrent, nAverage);

      Inc(nFragIdx);
    end;

    pntCurr.X := nTrackIdx * dScreenRatio + DATAOFFSET;
    pntCurr.Y := nAmplitude * (nAverage/nMax) + nOffset;

    gsSink.AddLine(D2D1PointF(pntCurr.X, pntCurr.Y));

    pntPrev.X := pntCurr.X;
    pntPrev.Y := pntCurr.Y;

    bSwitch := not bSwitch;
  end;

  gsSink.EndFigure(D2D1_FIGURE_END_OPEN);
  gsSink.Close;
end;

end.

