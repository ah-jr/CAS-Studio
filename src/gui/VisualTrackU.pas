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
    m_nClipID       : Integer;
    m_pmManager     : TPlaylistManager;
    m_nHeight       : Integer;
    m_nPosition     : Integer;
    m_lstWavePoints : TList<TPointF>;

  procedure CalculateWaveSink;

  public
    constructor Create(a_pmManager : TPlaylistManager; m_aClipID : Integer);
    destructor Destroy; override;

    procedure Paint        (a_f2dCanvas : TF2DCanvas); override;
    procedure PaintWavePath(a_f2dCanvas : TF2DCanvas);

    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp  (Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;

    function GetRect : TRectF; override;

    procedure SetLine(a_nLine : Integer);

    property Height   : Integer read m_nHeight   write SetLine;
    property Position : Integer read m_nPosition write m_nPosition;
    property ClipID   : Integer read m_nClipID   write m_nClipID;
  end;

implementation

uses
  Winapi.Windows,
  System.UITypes,
  TypesU,
  CasClipU,
  CasTrackU,
  CasTypesU,
  Math;

//==============================================================================
constructor TVisualTrack.Create(a_pmManager : TPlaylistManager; m_aClipID : Integer);
begin
  Inherited Create;
  m_nClipID     := m_aClipID;
  m_pmManager   := a_pmManager;
  m_nPosition   := 0;
  m_nHeight     := 0;

  m_lstWavePoints := TList<TPointF>.Create;
end;

//==============================================================================
destructor TVisualTrack.Destroy;
begin
  m_lstWavePoints.Free;

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
  recSelf : TRectF;
begin
  recSelf := GetRect;

  // Paint only if it's visible
  if m_pmManager.GetPlaylistRect.IntersectsWith(recSelf.Ceiling) then
  begin
    a_f2dCanvas.FillColor := c_clTrackBack;
    a_f2dCanvas.FillRoundRect(recSelf.TopLeft, recSelf.BottomRight, 5);

    PaintWavePath(a_f2dCanvas);
  end;
end;

//==============================================================================
procedure TVisualTrack.PaintWavePath(a_f2dCanvas : TF2DCanvas);
var
  recSelf        : TRectF;
  nIndex         : Integer;
  pntCurr        : TPointF;
  pntNext        : TPointF;
begin
  CalculateWaveSink;
  recSelf := GetRect;

  a_f2dCanvas.DrawColor := $FFA0B4BE;
  a_f2dCanvas.LineWidth := 1.6;

  for nIndex := 0 to m_lstWavePoints.Count - 2 do
  begin
    pntCurr.X := recSelf.Left + m_lstWavePoints.Items[nIndex].X;
    pntCurr.Y := recSelf.Top  + m_lstWavePoints.Items[nIndex].Y;

    pntNext.X := recSelf.Left + m_lstWavePoints.Items[nIndex + 1].X;
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
  dPos      : Double;
  dStepSize : Double;
  recSelf   : TRectF;
begin
  Inherited;

  case m_pmManager.SelectedTool of
    ttCut :
      begin
        SetCursor(LoadCursor(0, IDC_IBEAM));
      end;

    ttMove :
      begin
        SetCursor(LoadCursor(0, IDC_SIZEALL));

        if m_vosState.Clicked then
        begin
          recSelf   := GetRect;
          nControlX := X - m_pntMouseClick.X;
          nControlY := Y;

          dStep     := m_pmManager.Transform.Scale.X * c_nBarWidth/c_nBarSplit;
          dStepSize := m_pmManager.GetSampleSize(dStep);
          dPos      := m_pmManager.XToSample(nControlX);

          m_nPosition := Trunc(Trunc(dPos / dStepSize) * dStepSize);

          if Abs(recSelf.Top + m_pmManager.GetClipVisualHeight / 2 - nControlY) > m_pmManager.GetClipVisualHeight then
            m_nHeight := Trunc(nControlY / m_pmManager.GetClipVisualHeight);

          m_nPosition := Max(m_nPosition, 0);
          m_nHeight   := Max(m_nHeight,   0);
        end;
      end;
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
  case m_pmManager.SelectedTool of
    ttCut :
      begin
        m_pmManager.CutClip(m_nClipID, Trunc(m_pmManager.XToSample(X)), m_nHeight);
      end;
    ttMove :
      begin
        if m_vosState.Clicked then
        begin
          m_pmManager.SetClipPos(m_nClipID, m_nPosition);
        end;
      end;
  end;

  Inherited;
end;

//==============================================================================
function TVisualTrack.GetRect : TRectF;
begin
  Result.Left   := m_pmManager.SampleToX(m_nPosition) + 1;
  Result.Top    := (m_nHeight - m_pmManager.Transform.Offset.Y) * m_pmManager.GetClipVisualHeight + 1;
  Result.Right  := Result.Left + m_pmManager.GetClipVisualWidth(m_nClipID) - 1;
  Result.Bottom := Result.Top  + m_pmManager.GetClipVisualHeight - 1;

  // Prevent negative or null width/height
  if Result.Right - Result.Left <= 0 then
    Result.Right := Result.Left + 1;

  if Result.Bottom - Result.Top <= 0 then
    Result.Bottom := Result.Top + 1;
end;

//==============================================================================
procedure TVisualTrack.CalculateWaveSink;
var
  recSelf        : TRectF;
  nTrackIdx      : Integer;
  nMax           : Integer;
  nAmplitude     : Integer;
  nOffset        : Integer;
  dTrackRatio    : Double;
  pntCurr        : TPointF;
  nPathSize      : Integer;
  nFirstPointIdx : Integer;
  nLastPointIdx  : Integer;
  nFirst         : Integer;
  nSecond        : Integer;
  nClipOffset    : Integer;
  nClipSize      : Integer;
  MinMax         : TSmallMinMax;
  CasTrack       : TCasTrack;             nF : Integer;
const
  m_nTitleBarHeight = 0;
begin
  recSelf      := GetRect;
  nPathSize    := Trunc(recSelf.Width);

  nClipOffset := m_pmManager.GetClipOffset(m_nClipID);
  nClipSize   := m_pmManager.GetClipSize(m_nClipID);

  m_pmManager.GetTrackByClipID(m_nClipID, CasTrack);

  m_lstWavePoints.Clear;
  dTrackRatio  := nClipSize / nPathSize;
  nAmplitude   := Trunc(recSelf.Height - m_nTitleBarHeight - 10) div 2;
  nOffset      := Trunc(recSelf.Height + m_nTitleBarHeight) div 2;
  nMax         := 32767; // FIX THAT

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
    MinMax := CasTrack.MinMax.GetMinMax(Ceil((nTrackIdx + 1) * dTrackRatio) + nClipOffset,
                                        Ceil((nTrackIdx + 1) * dTrackRatio) + nClipOffset + 1);

    nF := MinMax.Max;

    MinMax := CasTrack.MinMax.GetMinMax(Ceil((nTrackIdx       ) * dTrackRatio) + nClipOffset,
                                        Ceil((nTrackIdx + 0.75) * dTrackRatio) + nClipOffset);

    nFirst  := MinMax.Max;
    nSecond := MinMax.Min;

    if abs(nF - nFirst) < abs(nF - nSecond) then
    begin
      pntCurr.X := nTrackIdx + 0;
      pntCurr.Y := nAmplitude * (nSecond/nMax) + nOffset;
      m_lstWavePoints.Add(pntCurr);

      pntCurr.X := nTrackIdx + 0.75;
      pntCurr.Y := nAmplitude * (nFirst/nMax) + nOffset;
      m_lstWavePoints.Add(pntCurr);
    end
    else
    begin
      pntCurr.X := nTrackIdx + 0;
      pntCurr.Y := nAmplitude * (nFirst/nMax) + nOffset;
      m_lstWavePoints.Add(pntCurr);

      pntCurr.X := nTrackIdx + 0.75;
      pntCurr.Y := nAmplitude * (nSecond/nMax) + nOffset;
      m_lstWavePoints.Add(pntCurr);
    end;


  end;
end;

end.

