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
  F2DCanvasU,
  F2DTypesU,
  PlaylistManagerU;

type

  TVisualAvgPoint = record
    Max: Integer;
    Min: Integer;
    MaxPos : Integer;
    MinPos : Integer;
  end;

  TVisualTrack = class(TVisualObject)
  private
    m_nTrackID   : Integer;
    m_pmManager  : TPlaylistManager;
    m_nHeight    : Integer;
    m_nPosition  : Integer;
    m_lstWavePoints : TList<TPointF>;
    m_dPathScale : Double;
    m_bUpdatePath: Boolean;

    m_dctAvgPoints10   : TDictionary<Integer, TVisualAvgPoint>;
    m_dctAvgPoints100  : TDictionary<Integer, TVisualAvgPoint>;
    m_dctAvgPoints1000 : TDictionary<Integer, TVisualAvgPoint>;

  procedure CalculateWaveSink;
  procedure CreateAvgPointsList(a_dctAvgPoints : TDictionary<Integer, TVisualAvgPoint>; a_nInterval : Integer);

  public
    constructor Create(a_piInfo : TPlaylistManager; a_nTrackID : Integer);
    destructor Destroy; override;

    procedure Paint        (a_f2dCanvas : TF2DCanvas); override;
    procedure PaintWavePath(a_f2dCanvas : TF2DCanvas);

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
  m_dctAvgPoints10   := TDictionary<Integer, TVisualAvgPoint>.Create;
  m_dctAvgPoints100  := TDictionary<Integer, TVisualAvgPoint>.Create;
  m_dctAvgPoints1000 := TDictionary<Integer, TVisualAvgPoint>.Create;

  CreateAvgPointsList(m_dctAvgPoints10, 10);
  CreateAvgPointsList(m_dctAvgPoints100, 100);
  CreateAvgPointsList(m_dctAvgPoints1000, 1000);
end;

//==============================================================================
destructor TVisualTrack.Destroy;
begin
  m_lstWavePoints.Free;

  m_dctAvgPoints10.Free;
  m_dctAvgPoints100.Free;
  m_dctAvgPoints1000.Free;

  Inherited;
end;

//==============================================================================
procedure TVisualTrack.SetLine(a_nLine : Integer);
begin
  if a_nLine >= 0 then
    m_nHeight := a_nLine;
end;

//==============================================================================
procedure TVisualTrack.Paint(a_f2dCanvas : TF2DCanvas);
var
  recSelf : TRect;
begin
  recSelf := GetRect;

  a_f2dCanvas.FillColor := c_clTrackBack;
  a_f2dCanvas.FillRoundRect(recSelf.TopLeft, recSelf.BottomRight, 5);

  PaintWavePath(a_f2dCanvas);
end;

//==============================================================================
procedure TVisualTrack.PaintWavePath(a_f2dCanvas : TF2DCanvas);
var
  recSelf        : TRect;
  pntScale       : TPointF;
  pntScaleChange : TPointF;
  nIndex         : Integer;
  pntCurr        : TPointF;
  pntNext        : TPointF;
begin
  recSelf := GetRect;

  CalculateWaveSink;

  pntScale := m_pmManager.Transform.Scale;
  pntScaleChange := PointF(pntScale.X/m_dPathScale, pntScale.Y);

  a_f2dCanvas.DrawColor := $FFA0B4BE;
  a_f2dCanvas.LineWidth := 1.8;

  for nIndex := 0 to m_lstWavePoints.Count - 2 do
  begin
    pntCurr.X := recSelf.Left + m_lstWavePoints.Items[nIndex].X * pntScaleChange.X;
    pntCurr.Y := recSelf.Top  + m_lstWavePoints.Items[nIndex].Y;

    pntNext.X := recSelf.Left + m_lstWavePoints.Items[nIndex + 1].X * pntScaleChange.X;
    pntNext.Y := recSelf.Top  + m_lstWavePoints.Items[nIndex + 1].Y;

    a_f2dCanvas.DrawLine(pntCurr, pntNext);
  end;
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

    if Abs(recSelf.Top + m_pmManager.GetTrackVisualHeight div 2 - nControlY) > m_pmManager.GetTrackVisualHeight then
      m_nHeight := Trunc(nControlY / m_pmManager.GetTrackVisualHeight);

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
  Result.Left   := Trunc(m_pmManager.SampleToX(m_nPosition)) + 1;
  Result.Top    := (m_nHeight - m_pmManager.Transform.Offset.Y) * m_pmManager.GetTrackVisualHeight + 1;
  Result.Right  := Result.Left + m_pmManager.GetTrackVisualWidth(m_nTrackID) - 1;
  Result.Bottom := Result.Top  + m_pmManager.GetTrackVisualHeight - 1;

  // Prevent negative or null width/height
  if Result.Right - Result.Left <= 0 then
    Result.Right := Result.Left + 1;

  if Result.Bottom - Result.Top <= 0 then
    Result.Bottom := Result.Top + 1;    
end;

//==============================================================================
procedure TVisualTrack.CreateAvgPointsList(a_dctAvgPoints : TDictionary<Integer, TVisualAvgPoint>; a_nInterval : Integer);
var
  pData          : PIntArray;
  nDataSize      : Integer;
  avgPoint       : TVisualAvgPoint;
  nIndex      : Integer;
  nMax : Integer;
  nMin : Integer;
  nMaxPos : Integer;
  nMinPos : Integer;
  nPos : Integer;
begin
  m_pmManager.GetTrackData(m_nTrackID, pData, pData, nDataSize);
  nPos := 0;
  nMin :=  MaxInt;
  nMax := -MaxInt;

  for nIndex := 0 to nDataSize - 1 do
  begin
    if nMax < TIntArray(pData^)[nIndex] then
    begin
      nMax := TIntArray(pData^)[nIndex];
      nMaxPos := nIndex - nPos;
    end;
    
    if nMin > TIntArray(pData^)[nIndex] then
    begin
      nMin := TIntArray(pData^)[nIndex];
      nMinPos := nIndex - nPos;
    end;

    if (nPos + a_nInterval <= nIndex) then
    begin
      avgPoint.Min := nMin;
      avgPoint.Max := nMax;
      avgPoint.MinPos := nMinPos;
      avgPoint.MaxPos := nMaxPos;

      a_dctAvgPoints.AddOrSetValue(nPos, avgPoint);

      nPos :=  nIndex;
      nMin :=  MaxInt;
      nMax := -MaxInt;
    end;
  end;

  avgPoint.Min := nMin;
  avgPoint.Max := nMax;
  avgPoint.MinPos := nMinPos;
  avgPoint.MaxPos := nMaxPos;

  a_dctAvgPoints.AddOrSetValue(nPos, avgPoint);
end;

//==============================================================================
procedure TVisualTrack.CalculateWaveSink;
var
  recSelf        : TRect;
  nTrackIdx      : Integer;
  nFragIdx       : Integer;
  nMax           : Integer;
  nLocMin        : Integer;
  nLocMax        : Integer;
  nCurrent       : Integer;
  nAmplitude     : Integer;
  nOffset        : Integer;                                            tmin, tmax :  Integer;
  dTrackRatio    : Double;
  dScreenRatio   : Double;
  pntCurr        : TPointF;                          size : Integer;                               mod10, mod100, mod1000 : Integer;
  nPathSize      : Integer;
  pData          : PIntArray;                     avgPoint : TVisualAvgPoint;
  nDataSize      : Integer;
  nFirstPointIdx : Integer;                            mode : Integer;
  nLastPointIdx  : Integer;                    nMinPos, nMaxPos : Integer;   nFirst, nSec, nThird : Integer;     nSecPos, nTrdPos : Integer;
const
  DATAOFFSET = 0;
  m_nTitleBarHeight = 0;
begin
  recSelf      := GetRect;
  nPathSize    := Trunc(recSelf.Width) + 1;
  pData        := nil;

  m_pmManager.GetTrackData(m_nTrackID, pData, pData, nDataSize);                       size := 10;

  m_lstWavePoints.Clear;
  m_dPathScale := m_pmManager.Transform.Scale.X;
  dScreenRatio := (recSelf.Width - 2 * DATAOFFSET) / nPathSize;
  dTrackRatio  := nDataSize / nPathSize;
  nAmplitude   := (recSelf.Height - m_nTitleBarHeight - 10) div 2;
  nOffset      := (recSelf.Height + m_nTitleBarHeight) div 2;
  nMax         := Trunc(Math.Power(2, 24 - 1)); // FIX THAT

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

    nLocMin :=  MaxInt;
    nLocMax := -MaxInt;

    nFirst := TIntArray(pData^)[Ceil(nTrackIdx * dTrackRatio)];

    mod1000 := Ceil(nTrackIdx * dTrackRatio) mod 1000;
    mod100  := Ceil(nTrackIdx * dTrackRatio) mod 100;
    mod10   := Ceil(nTrackIdx * dTrackRatio) mod 10;

    mode := 1;

    if 1000 < Ceil(dTrackRatio) - (1000 - mod1000) then
    begin
      nFragIdx := 1000 - mod1000;
      mode := 1000;
    end
    else if 100 < Ceil(dTrackRatio) - (100 - mod100) then
    begin
      nFragIdx := 100 - mod100;
      mode := 100;
    end
    else if 10 < Ceil(dTrackRatio) - (10 - mod10) then
    begin
      nFragIdx := 10 - mod10;
      mode := 10;
    end;

    while nFragIdx <= Ceil(dTrackRatio) do
    begin
      //////////////////////////////////////////////////////////////////////////
      // Get the largest value in the samples covered
      if mode = 1000 then
      begin
        avgPoint := m_dctAvgPoints1000[Ceil(nTrackIdx * dTrackRatio) + nFragIdx];
        tmin := avgPoint.MinPos + nFragIdx;
        tmax := avgPoint.MaxPos + nFragIdx;
        nFragIdx := nFragIdx + 1000;
      end
      else if mode = 100 then
      begin
        avgPoint := m_dctAvgPoints100[Ceil(nTrackIdx * dTrackRatio) + nFragIdx];
        tmin := avgPoint.MinPos + nFragIdx;
        tmax := avgPoint.MaxPos + nFragIdx;
        nFragIdx := nFragIdx + 100;
      end
      else if mode = 10 then
      begin
        avgPoint := m_dctAvgPoints10[Ceil(nTrackIdx * dTrackRatio) + nFragIdx];
        tmin := avgPoint.MinPos + nFragIdx;
        tmax := avgPoint.MaxPos + nFragIdx;
        nFragIdx := nFragIdx + 10;
      end
      else
      begin
        avgPoint.Min := TIntArray(pData^)[Ceil(nTrackIdx * dTrackRatio) + nFragIdx];
        avgPoint.Max := TIntArray(pData^)[Ceil(nTrackIdx * dTrackRatio) + nFragIdx];
        tmin := nFragIdx;
        tmax := nFragIdx;

        nFragIdx := nFragIdx + 1;
      end;

      if nLocMin > avgPoint.Min then
      begin
        nLocMin := avgPoint.Min;
        nMinPos := tmin;
      end;

      if nLocMax < avgPoint.Max then
      begin
        nLocMax := avgPoint.Max;
        nMaxPos := tmax;
      end;
    end;

    if nMaxPos >= nMinPos then
    begin
      nSec := nLocMin;
      nThird   := nLocMax;
      nSecPos := nMinPos;
      nTrdPos := nMaxPos;
    end
    else
    begin
      nSec := nLocMax;
      nThird   := nLocMin;
      nSecPos := nMaxPos;
      nTrdPos := nMinPos;
    end;

    if (nFirst <> nSec) then
    begin
      pntCurr.X := nTrackIdx * dScreenRatio + DATAOFFSET;
      pntCurr.Y := nAmplitude * (nFirst/nMax) + nOffset;
      m_lstWavePoints.Add(pntCurr);
    end;

    pntCurr.X := nTrackIdx * dScreenRatio + DATAOFFSET + (nSecPos/dTrackRatio);
    pntCurr.Y := nAmplitude * (nSec/nMax) + nOffset;
    m_lstWavePoints.Add(pntCurr);

    pntCurr.X := nTrackIdx * dScreenRatio + DATAOFFSET + (nTrdPos/dTrackRatio);
    pntCurr.Y := nAmplitude * (nThird/nMax) + nOffset;
    m_lstWavePoints.Add(pntCurr);
  end;
end;

end.

