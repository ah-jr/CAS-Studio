unit VisualTrackU;

interface

uses
  System.Classes,
  System.Types,
  System.Generics.Collections,
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
    m_lstWavePoints : TList<TPointF>;
    m_dPathScale : Double;
    m_bUpdatePath: Boolean;

  procedure CalculateWaveSink;

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
  m_nTrackID    := a_nTrackID;
  m_pmManager   := a_piInfo;
  m_nPosition   := 0;
  m_nHeight     := 0;
  m_bUpdatePath := False;

  m_lstWavePoints := TList<TPointF>.Create;
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
  a_d2dKit.Brush.SetColor(D2D1ColorF(clBlack, 0.9));
  recSelf := GetRect;

  d2dRect.Left   := recSelf.Left;
  d2dRect.Top    := recSelf.Top;
  d2dRect.Right  := d2dRect.Left + recSelf.Width;
  d2dRect.Bottom := d2dRect.Top  + recSelf.Height;

  a_d2dKit.Target.FillRectangle(d2dRect, a_d2dKit.Brush);

  PaintWavePath(a_d2dKit);
end;

//==============================================================================
procedure TVisualTrack.PaintWavePath(a_d2dKit : TD2DKit);
var
  recSelf        : TRect;
  d2dMatrix      : TD2DMatrix3x2F;
  pntScale       : TPointF;
  pntScaleChange : TPointF;
  nIndex         : Integer;
  pntCurr        : TD2D1Point2F;
  pntNext        : TD2D1Point2F;
begin
  recSelf := GetRect;

  a_d2dKit.Brush.SetColor(D2D1ColorF(clWhite));
  a_d2dKit.Target.SetAntialiasMode(D2D1_ANTIALIAS_MODE_PER_PRIMITIVE);

  d2dMatrix := TD2DMatrix3x2F.Translation(recSelf.Left, recSelf.Top);
  a_d2dKit.Target.SetTransform(d2dMatrix);

  CalculateWaveSink;

  pntScale := m_pmManager.Transform.Scale;
  pntScaleChange := PointF(pntScale.X/m_dPathScale, pntScale.Y);

  for nIndex := 0 to m_lstWavePoints.Count - 2 do
  begin
    pntCurr.X := m_lstWavePoints.Items[nIndex].X * pntScaleChange.X;
    pntCurr.Y := m_lstWavePoints.Items[nIndex].Y;

    pntNext.X := m_lstWavePoints.Items[nIndex + 1].X * pntScaleChange.X;
    pntNext.Y := m_lstWavePoints.Items[nIndex + 1].Y;

    a_d2dKit.Target.DrawLine(pntCurr, pntNext, a_d2dKit.Brush, 1);
  end;

  a_d2dKit.Target.SetTransform(TD2DMatrix3x2F.Identity);
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
procedure TVisualTrack.CalculateWaveSink;
var
  recSelf        : TRect;
  nTrackIdx      : Integer;
  nFragIdx       : Integer;
  nMax           : Integer;
  nAverage       : Integer;
  nCurrent       : Integer;
  nAmplitude     : Integer;
  nOffset        : Integer;
  bSwitch        : Boolean;
  dTrackRatio    : Double;
  dScreenRatio   : Double;
  pntPrev        : TPointF;
  pntCurr        : TPointF;
  nPathSize      : Integer;
  pData          : PIntArray;
  nDataSize      : Integer;
  nFirstPointIdx : Integer;
  nLastPointIdx  : Integer;
const
  DATAOFFSET = 0;
  m_nTitleBarHeight = 0;
begin
  recSelf      := GetRect;
  nPathSize    := Trunc(4*recSelf.Width);
  pData        := nil;

  m_pmManager.GetTrackData(m_nTrackID, pData, pData, nDataSize);

  m_lstWavePoints.Clear;
  m_dPathScale := m_pmManager.Transform.Scale.X;
  dScreenRatio := (recSelf.Width - 2 * DATAOFFSET) / nPathSize;
  dTrackRatio  := nDataSize / nPathSize;
  nAmplitude   := (recSelf.Height - m_nTitleBarHeight - 10) div 2;
  nOffset      := (recSelf.Height + m_nTitleBarHeight) div 2;
  nMax         := Trunc(Math.Power(2, 24 - 1)); // FIX THAT
  pntPrev.X    := DATAOFFSET;
  pntPrev.Y    := nOffset;
  bSwitch      := True;

  //////////////////////////////////////////////////////////////////////////////
  nFirstPointIdx := 0;
  nLastPointIdx  := nPathSize - 1;

  if recSelf.Left < 0 then
    nFirstPointIdx := Trunc((-recSelf.Left/recSelf.Width) * nLastPointIdx);

  if recSelf.Right > m_pmManager.GetPlaylistRect.Width then
    nLastPointIdx := Ceil(((m_pmManager.GetPlaylistRect.Width - recSelf.Left)/recSelf.Width) * nLastPointIdx);

  //////////////////////////////////////////////////////////////////////////////
  // Narrow down data to fit in the PATHSIZE
  for nTrackIdx := nFirstPointIdx to nLastPointIdx do
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

    m_lstWavePoints.Add(pntCurr);

    pntPrev.X := pntCurr.X;
    pntPrev.Y := pntCurr.Y;

    bSwitch := not bSwitch;
  end;
end;

end.

