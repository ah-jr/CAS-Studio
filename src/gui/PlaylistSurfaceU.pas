unit PlaylistSurfaceU;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  Winapi.D2D1,
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
  Vcl.Direct2D,
  VisualObjectU,
  VisualTypesU,
  PlaylistManagerU,
  TypesU;


type
  TPlaylistSurface = class(TCustomControl, IAudioListener)
  private
    m_d2dKit    : TD2DKit;
    m_dtUpdate  : TDateTime;
    m_pmManager : TPlaylistManager;

    m_lstVisualObjects : TList<TVisualObject>;

    procedure WMEraseBkgnd (var Msg: TWmEraseBkgnd); message WM_ERASEBKGND;
    procedure CMMouseWheel (var Msg: TCMMouseWheel); message CM_MOUSEWHEEL;

    procedure Invalidate(a_nInterval : Integer); reintroduce; overload;

    procedure SetupD2DOBjects;

  protected
    procedure Paint; override;
    procedure PaintBackground;
    procedure PaintGrid;
    procedure PaintVisualObjects;
    procedure PaintPosLine;

    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp  (Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;

  public
    constructor Create(AOwner : TComponent; a_pmManager : TPlaylistManager); reintroduce; overload;
    destructor  Destroy; override;

    procedure UpdateProgress(a_dProgress : Double);
    procedure AddTrack      (a_nTrackID  : Integer);

  end;

implementation

uses
  System.Types,
  Winapi.DxgiFormat,
  DateUtils,
  VisualTrackU,
  CasTrackU;

//==============================================================================
constructor TPlaylistSurface.Create(AOwner : TComponent; a_pmManager : TPlaylistManager);
begin
  Inherited Create(AOwner);

  m_pmManager := a_pmManager;
  m_dtUpdate  := Now;

  m_lstVisualObjects := TList<TVisualObject>.Create;

  SetupD2DOBjects;
end;

//==============================================================================
destructor  TPlaylistSurface.Destroy;
var 
  VisualObject : TVisualObject;
begin
  for VisualObject in m_lstVisualObjects do
     VisualObject.Free; 

  m_lstVisualObjects.Free;

  Inherited;
end;

//==============================================================================
procedure TPlaylistSurface.UpdateProgress(a_dProgress : Double);
begin
  m_pmManager.Progress := a_dProgress;

  Invalidate(10);
end;

//==============================================================================
procedure TPlaylistSurface.AddTrack(a_nTrackID : Integer);
var
  vtTrack : TVisualTrack;
begin
  vtTrack := TVisualTrack.Create(m_pmManager, a_nTrackID);
  vtTrack.SetLine(m_lstVisualObjects.Count);

  m_lstVisualObjects.Add(vtTrack);
end;

//==============================================================================
procedure TPlaylistSurface.PaintBackground;
var
  d2dRect : TD2D1RectF;
begin
  d2dRect.Left   := 0;
  d2dRect.Top    := 0;
  d2dRect.Right  := ClientWidth;
  d2dRect.Bottom := ClientHeight;

  m_d2dKit.Target.Clear(D2D1ColorF(clBlack));

  m_d2dKit.Brush.SetColor(D2D1ColorF(clDkGray, 1));
  m_d2dKit.Target.FillRectangle(d2dRect, m_d2dKit.Brush);
end;

//==============================================================================
procedure TPlaylistSurface.PaintGrid;
var
  pntUp   : TPoint;
  pntDown : TPoint;
  nIndex  : Integer;
begin
  m_d2dKit.Target.SetAntialiasMode(D2D1_ANTIALIAS_MODE_ALIASED);
  m_d2dKit.Brush.SetColor(D2D1ColorF(clWhite));

  for nIndex := 0 to 10 do
  begin
    pntUp   := Point(Trunc(m_pmManager.BeatToX(nIndex)), 0);
    pntDown := Point(Trunc(m_pmManager.BeatToX(nIndex)), Height);

    m_d2dKit.Target.DrawLine(pntUp, pntDown, m_d2dKit.Brush);
  end;

  for nIndex := 0 to 10 do
  begin
    pntUp   := Point(0,     nIndex*c_nLineHeight);
    pntDown := Point(Width, nIndex*c_nLineHeight);

    m_d2dKit.Target.DrawLine(pntUp, pntDown, m_d2dKit.Brush);
  end;
end;

//==============================================================================
procedure TPlaylistSurface.PaintVisualObjects;
var
  nIndex : Integer;
begin
  for nIndex := 0 to m_lstVisualObjects.Count - 1 do
  begin
    m_lstVisualObjects.Items[nIndex].Paint(m_D2DKit);
  end;
end;

//==============================================================================
procedure TPlaylistSurface.PaintPosLine;
var
  pntUp   : TD2DPoint2f;
  pntDown : TD2DPoint2f;
begin
  m_d2dKit.Target.SetAntialiasMode(D2D1_ANTIALIAS_MODE_ALIASED);

  pntUp.X := m_pmManager.GetProgressX;
  pntUp.Y := 0;

  pntDown.X := m_pmManager.GetProgressX;
  pntDown.Y := Height;

  m_d2dKit.Brush.SetColor(D2D1ColorF(clBlue));
  m_d2dKit.Target.DrawLine(pntUp, pntDown, m_d2dKit.Brush);
end;

//==============================================================================
procedure TPlaylistSurface.Paint;
var
  recSelf : TRect;
begin
  recSelf := GetClientRect;

  m_d2dKit.Target.BindDC(Canvas.Handle, recSelf);
  m_d2dKit.Target.BeginDraw;
  m_d2dKit.Target.SetTransform(TD2DMatrix3X2F.Identity);

  PaintBackground;
  PaintGrid;
  PaintVisualObjects;
  PaintPosLine;

  m_d2dKit.Target.EndDraw;
end;

//==============================================================================
procedure TPlaylistSurface.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  nIndex   : Integer;
  voObject : TVisualObject;
begin
  for nIndex := 0 to m_lstVisualObjects.Count - 1 do
  begin
    voObject := m_lstVisualObjects.Items[nIndex];

    if voObject.GetRect.Contains(Point(X, Y)) then
      voObject.MouseDown(Button, Shift, X, Y);
  end;
end;

//==============================================================================
procedure TPlaylistSurface.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  nIndex   : Integer;
  voObject : TVisualObject;
begin
  for nIndex := 0 to m_lstVisualObjects.Count - 1 do
  begin
    voObject := m_lstVisualObjects.Items[nIndex];

    if voObject.GetRect.Contains(Point(X, Y)) then
      voObject.MouseUp(Button, Shift, X, Y);

    if voObject.State.Clicked then
      voObject.MouseUp(Button, Shift, X, Y);
  end;
end;

//==============================================================================
procedure TPlaylistSurface.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  nIndex   : Integer;
  voObject : TVisualObject;
begin
  inherited;

  for nIndex := 0 to m_lstVisualObjects.Count - 1 do
  begin
    voObject := m_lstVisualObjects.Items[nIndex];

    if voObject.GetRect.Contains(Point(X, Y)) or (voObject.State.Clicked) then
    begin
      voObject.MouseMove(Shift, X, Y);
    end
  end;

  Invalidate(10);
end;

//==============================================================================
procedure TPlaylistSurface.WMEraseBkgnd(var Msg: TWmEraseBkgnd);
begin
  //
end;

//==============================================================================
procedure TPlaylistSurface.CMMouseWheel(var Msg: TCMMouseWheel);
const
  c_ntDeltaOffset = 10;
begin
  Inherited;

  if ssShift in Msg.ShiftState then
  begin
    if Msg.WheelDelta > 0 then
      m_pmManager.Transform.SetScale(PointF(m_pmManager.Transform.Scale.X * 1.2, m_pmManager.Transform.Scale.Y));

    if Msg.WheelDelta < 0 then
      m_pmManager.Transform.SetScale(PointF(m_pmManager.Transform.Scale.X / 1.2, m_pmManager.Transform.Scale.Y));
  end
  else
  begin
    if Msg.WheelDelta > 0 then
      m_pmManager.Transform.SetOffset(m_pmManager.Transform.Offset - c_ntDeltaOffset);

    if Msg.WheelDelta < 0 then
      m_pmManager.Transform.SetOffset(m_pmManager.Transform.Offset + c_ntDeltaOffset);
  end;

  Invalidate(10);
end;

//==============================================================================
procedure TPlaylistSurface.Invalidate(a_nInterval : Integer);
begin
  if DateUtils.MilliSecondsBetween(Now, m_dtUpdate) > a_nInterval then
  begin
    Invalidate;
    m_dtUpdate := Now;
  end;
end;

//==============================================================================
procedure TPlaylistSurface.SetupD2DObjects;
var
  d2dBProp  : TD2D1BrushProperties;
  d2dRTProp : TD2D1RenderTargetProperties;
begin
  d2dRTProp.&type       := D2D1_RENDER_TARGET_TYPE_DEFAULT;
  d2dRTProp.pixelFormat := D2D1PixelFormat(DXGI_FORMAT_B8G8R8A8_UNORM, D2D1_ALPHA_MODE_IGNORE);
  d2dRTProp.dpiX        := 0;
  d2dRTProp.dpiY        := 0;
  d2dRTProp.usage       := D2D1_RENDER_TARGET_USAGE_NONE;
  d2dRTProp.minLevel    := D2D1_FEATURE_LEVEL_DEFAULT;
  D2D1CreateFactory(D2D1_FACTORY_TYPE_SINGLE_THREADED, IID_ID2D1Factory, nil, m_D2DKit.Factory);

  m_D2DKit.Factory.CreateDCRenderTarget(d2dRTProp, m_D2DKit.Target);

  d2dBProp.Transform := TD2DMatrix3X2F.Identity;
  d2dBProp.Opacity   := 1;
  m_D2DKit.Target.CreateSolidColorBrush(D2D1ColorF(clWhite), @d2dBProp, m_d2dKit.Brush);
end;

end.
