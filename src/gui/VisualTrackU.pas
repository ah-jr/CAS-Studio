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
//  TWaveMapThread = class(TThread)
//  private
//    m_bmpPaint : TBitmap;
//
//  end;


  TVisualTrack = class(TVisualObject)
  private
    m_nTrackID   : Integer;
    m_pmManager  : TPlaylistManager;
    m_nHeight    : Integer;
    m_nPosition  : Integer;
    m_lstWavePoints : TList<TPointF>;
    m_dPathScale : Double;
    m_bUpdatePath: Boolean;

    Brush   : ID2D1SolidColorBrush;
    Target  : ID2D1DCRenderTarget;
    Factory : ID2D1Factory;

    bmpWaveForm : VCL.Graphics.TBitmap;

  procedure CalculateWaveSink;
  procedure SetupD2DObjects;

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
  Winapi.DxgiFormat,
  System.UITypes,
  System.Diagnostics,
  System.TimeSpan,
  VisualUtilsU,
  TypesU,
  Math;

//==============================================================================
constructor TVisualTrack.Create(a_piInfo : TPlaylistManager; a_nTrackID : Integer);
begin
  Inherited Create;
  m_nTrackID   := a_nTrackID;
  m_pmManager  := a_piInfo;
  m_nPosition  := 0;
  m_nHeight    := 0;
  m_bUpdatePath:= False;

  m_lstWavePoints := TList<TPointF>.Create;

  bmpWaveForm := VCL.Graphics.TBitmap.Create;         SetupD2DObjects;
  bmpWaveForm.PixelFormat := pf32Bit;
  bmpWaveForm.HandleType :=  bmDIB;
  bmpWaveForm.alphaformat := afDefined;
end;

//==============================================================================
destructor TVisualTrack.Destroy;
begin
  bmpWaveForm.Free;

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
  recSelf   : TRect;
  d2dMatrix : TD2DMatrix3x2F;
  pntScale  : TPointF;
  pntScaleChange : TPointF;
  //d2dScaledPath : ID2D1TransformedGeometry;
  nIndex : Integer;

  Stopwatch: TStopwatch;
  Elapsed: TTimeSpan;

  d2dBmp : ID2D1Bitmap;

  dc : hdc;
  rec : TRect;                 d2dRect : TD2D1RectF;         nVisibleWidth : Integer;
begin
  recSelf := GetRect;

  pntScale := m_pmManager.Transform.Scale;

  if m_dPathScale > 0 then
    pntScaleChange := PointF(pntScale.X/m_dPathScale, pntScale.Y);

  d2dMatrix := TD2DMatrix3x2F.Translation(recSelf.Left, recSelf.Top);
  a_d2dKit.Target.SetTransform(d2dMatrix);

//  if (m_d2dPath = nil) or (m_bUpdatePath) then
//  begin
//    a_d2dKit.Factory.CreatePathGeometry(m_d2dPath);
//    m_d2dPath.Open(m_d2dSink);
//    CalculateWaveSink(m_d2dSink);
//    m_bUpdatePath := False;
//  end
//  else
//  begin
//    m_d2dPath.Stream(m_d2dSink);
//  end;

//  if (m_lstWavePoints.Count = 0) or
//     (pntScaleChange.X > 2) or
//     (pntScaleChange.X < 0.5) then
//  begin
//    CalculateWaveSink;
//    pntScaleChange.X := 1;
//  end;

//  if (m_lstWavePoints.Count = 0) then
  //Stopwatch := TStopwatch.StartNew;

  //Elapsed := Stopwatch.Elapsed;

  nVisibleWidth := recSelf.Width;

  if recSelf.Left < 0 then
    nVisibleWidth := nVisibleWidth + recSelf.Left;

  if recSelf.Right > m_pmManager.GetPlaylistRect.Width then
    nVisibleWidth := nVisibleWidth - (recSelf.Right - m_pmManager.GetPlaylistRect.Width);

  if (nVisibleWidth > 0) and
     ((m_dPathScale = 0) or
     (pntScaleChange.X > 1.2) or
     (pntScaleChange.X < 0.8)) then
  begin
    bmpWaveForm.SetSize(nVisibleWidth, recSelf.Height);

    CalculateWaveSink;

    //bmpWaveForm.SetSize(nVisibleWidth, recSelf.Height);
    bmpWaveForm.Canvas.Brush.Color := $000000;
    bmpWaveForm.Canvas.Rectangle(0, 0, nVisibleWidth, recSelf.Height);

    dc := bmpWaveForm.Canvas.Handle;

    rec.Left := 0;
    rec.Top := 0;
    rec.Width := bmpWaveForm.Width;
    rec.Height := bmpWaveForm.Height;

    Target.BindDC(dc, rec);
    Target.BeginDraw;

    Brush.SetColor(D2D1ColorF(clWhite));
    Target.SetAntialiasMode(D2D1_ANTIALIAS_MODE_PER_PRIMITIVE);

    pntScaleChange := PointF(pntScale.X/m_dPathScale, pntScale.Y);

    Stopwatch := TStopwatch.StartNew;
    for nIndex := 0 to m_lstWavePoints.Count - 2 do
    begin
      Target.DrawLine(D2D1PointF(m_lstWavePoints.Items[nIndex].X * pntScaleChange.X,
                                 m_lstWavePoints.Items[nIndex].Y),
                      D2D1PointF(m_lstWavePoints.Items[nIndex + 1].X * pntScaleChange.X,
                                 m_lstWavePoints.Items[nIndex + 1].Y),
                      Brush, 1.5);
    end;
    Elapsed := Stopwatch.Elapsed;
    Target.EndDraw;
  end;

  d2dRect.Left := 0;
  d2dRect.Top := 0;
  d2dRect.Right := bmpWaveForm.Width * pntScaleChange.X;
  d2dRect.Bottom := recSelf.Height;

  d2dBmp := CreateD2DBitmap(a_d2dKit.Target, bmpWaveForm);
  a_d2dKit.Target.DrawBitmap(d2dBmp, @d2dRect);

//  d2dMatrix := TD2DMatrix3x2F.Scale(pntScale.X/m_dPathScale, 1, D2D1PointF(0, 0));
//  a_d2dKit.Factory.CreateTransformedGeometry(m_d2dPath, d2dMatrix, d2dScaledPath);

//  a_d2dKit.Target.DrawGeometry(d2dScaledPath, a_d2dKit.Brush, 1.5, ssStyle);
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
  pData        : PIntArray;
  nDataSize    : Integer;
  nFirstPointIdx : Integer;
  nLastPointIdx  : Integer;
const
  DATAOFFSET = 0;//5;
  m_nTitleBarHeight = 0;
begin
  recSelf      := GetRect;
  nPathSize    := Trunc(10*recSelf.Width);
  pData        := nil;

  m_pmManager.GetTrackData(m_nTrackID, pData, pData, nDataSize);

  m_lstWavePoints.Clear;
  m_dPathScale := m_pmManager.Transform.Scale.X;
  dScreenRatio := (recSelf.Width - 2 * DATAOFFSET) / nPathSize;
  dTrackRatio  := nDataSize / nPathSize;
  nAmplitude   := (recSelf.Height - m_nTitleBarHeight - 10) div 2;
  nOffset      := (recSelf.Height + m_nTitleBarHeight) div 2;
  nMax         := Trunc(Math.Power(2, 24)); // FIX THAT
  pntPrev.X    := DATAOFFSET;
  pntPrev.Y    := nOffset;
  bSwitch      := True;

//  for nTrackIdx := 0 to nDataSize -1 do
//    nMax := Max(nMax, Abs(TIntArray(pData^)[nTrackIdx]));

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

//==============================================================================
procedure TVisualTrack.SetupD2DObjects;
var
  d2dBProp      : TD2D1BrushProperties;
  d2dRTProp     : TD2D1RenderTargetProperties;

  resSelf : TRect;
begin
  resSelf := GetRect;

  d2dRTProp.&type       := D2D1_RENDER_TARGET_TYPE_DEFAULT;
  d2dRTProp.pixelFormat := D2D1PixelFormat(DXGI_FORMAT_B8G8R8A8_UNORM, D2D1_ALPHA_MODE_IGNORE);
  d2dRTProp.dpiX        := 0;
  d2dRTProp.dpiY        := 0;
  d2dRTProp.usage       := D2D1_RENDER_TARGET_USAGE_NONE;
  d2dRTProp.minLevel    := D2D1_FEATURE_LEVEL_DEFAULT;

  D2D1CreateFactory(D2D1_FACTORY_TYPE_SINGLE_THREADED, IID_ID2D1Factory, nil, Factory);
  Factory.CreateDCRenderTarget(d2dRTProp, Target);

  d2dBProp.Transform := TD2DMatrix3X2F.Identity;
  d2dBProp.Opacity   := 1;
  Target.CreateSolidColorBrush(D2D1ColorF(clWhite), @d2dBProp, Brush);
end;

end.

