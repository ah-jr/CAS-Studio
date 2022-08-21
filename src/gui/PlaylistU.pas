unit PlaylistU;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Variants,
  System.Classes,
  System.UITypes,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.StdCtrls,
  Vcl.ExtCtrls,
  Vcl.Direct2D,
  AudioManagerU,
  VisualObjectU,
  Winapi.D2D1;

type
  TPlaylist = class(TCustomControl, IAudioListener)
  private
    m_d2dCanvas   : TDirect2DCanvas;
    m_d2dBrush    : ID2D1SolidColorBrush;
    m_dtUpdate    : TDateTime;
    m_dProgress   : Double;
    m_nSize       : Integer;

    m_vtTransform : TVisualTransform;

    m_lstVisualObjects : TList<TVisualObject>;

    procedure WMEraseBkgnd (var Msg: TWmEraseBkgnd); message WM_ERASEBKGND;
    procedure WMMouseMove  (var Msg: TMessage);      message WM_MOUSEMOVE;
    procedure CMMouseWheel (var Msg: TCMMouseWheel); message CM_MOUSEWHEEL;

  protected
    procedure Paint; override;
    procedure PaintBackground;
    procedure PaintGrid;
    procedure PaintTracks;
    procedure PaintPosLine;

  public
    constructor Create(AOwner : TComponent); override;
    destructor  Destroy; override;

    procedure UpdateProgress(a_dProgress : Double);

    property Progress : Double read m_dProgress write m_dProgress;

  end;

implementation

uses
  DateUtils,
  System.Types,
  CasTrackU;

//==============================================================================
constructor TPlaylist.Create(AOwner : TComponent);
begin
  Inherited;

  m_dtUpdate  := Now;
  m_dProgress := 0;
  m_nSize     := 0;

  m_vtTransform.Offset := 0;
  m_vtTransform.pntScale := PointF(1, 1);

  m_lstVisualObjects := TList<TVisualObject>.Create;

  g_AudioManager.AddListener(Self);
end;

//==============================================================================
destructor  TPlaylist.Destroy;
var 
  VisualObject : TVisualObject;
begin
  for VisualObject in m_lstVisualObjects do
     VisualObject.Free; 

  m_lstVisualObjects.Free;
     
  Inherited;
end;

//==============================================================================
procedure TPlaylist.UpdateProgress(a_dProgress : Double);
begin
  m_dProgress := a_dProgress;

  Invalidate;
end;

//==============================================================================
procedure TPlaylist.PaintBackground;
var
  d2dRect    : TD2D1RectF;
begin
  d2dRect.Left   := 0;
  d2dRect.Top    := 0;
  d2dRect.Right  := ClientWidth;
  d2dRect.Bottom := ClientHeight;

  m_d2dCanvas.RenderTarget.FillRectangle(d2dRect, m_d2dBrush);
end;

//==============================================================================
procedure TPlaylist.PaintGrid;
var
  pntUp   : TPoint;
  pntDown : TPoint;
  nIndex  : Integer;
begin
  m_d2dCanvas.RenderTarget.SetAntialiasMode(D2D1_ANTIALIAS_MODE_ALIASED);
  m_d2dBrush.SetColor(D2D1ColorF(clWhite));

  for nIndex := 0 to 10 do
  begin
    pntUp   := Point(m_vtTransform.Offset + nIndex*100, 0);
    pntDown := Point(m_vtTransform.Offset + nIndex*100, Height);

    m_d2dCanvas.RenderTarget.DrawLine(pntUp, pntDown, m_d2dBrush);
  end;
end;

//==============================================================================
procedure TPlaylist.PaintTracks;
var
  d2dRect  : TD2D1RectF;
  nIndex   : Integer;
  CasTrack : TCasTrack;
begin
  m_d2dBrush.SetColor(D2D1ColorF(clGreen));

  for nIndex := 0 to g_AudioManager.Engine.Database.Tracks.Count- 1 do
  begin
    CasTrack := g_AudioManager.Engine.Database.Tracks.Items[nIndex];

    d2dRect.Top    := 10 + (20*nIndex);
    d2dRect.Bottom := 30 + (20*nIndex);

    d2dRect.Left   := m_vtTransform.Offset + (CasTrack.Position / m_nSize) * 1000;
    d2dRect.Right  := d2dRect.Left + (CasTrack.Size / m_nSize) * 1000;

    m_d2dCanvas.RenderTarget.FillRectangle(d2dRect, m_d2dBrush);
  end;
end;

//==============================================================================
procedure TPlaylist.PaintPosLine;
var
  pntUp   : TD2DPoint2f;
  pntDown : TD2DPoint2f;
begin
  m_d2dCanvas.RenderTarget.SetAntialiasMode(D2D1_ANTIALIAS_MODE_ALIASED);

  pntUp.X := m_vtTransform.Offset + m_dProgress*1000;
  pntUp.Y := 0;

  pntDown.X := m_vtTransform.Offset + m_dProgress*1000;
  pntDown.Y := Height;

  m_d2dBrush.SetColor(D2D1ColorF(clBlue));
  m_d2dCanvas.RenderTarget.DrawLine(pntUp, pntDown, m_d2dBrush);
end;

//==============================================================================
procedure TPlaylist.Paint;
var
  d2dBProp : TD2D1BrushProperties;
begin
  m_nSize := g_AudioManager.Engine.Length;

  d2dBProp.Transform := TD2DMatrix3X2F.Identity;
  d2dBProp.Opacity := 1.0;

  m_d2dCanvas := TDirect2DCanvas.Create(Handle);
  m_d2dCanvas.RenderTarget.CreateSolidColorBrush(D2D1ColorF(clGray), @d2dBProp, m_d2dBrush);
  m_d2dCanvas.BeginDraw;

  PaintBackground;
  PaintGrid;
  PaintTracks;
  PaintPosLine;

  m_d2dCanvas.EndDraw;
  m_d2dCanvas.Free;
end;

//==============================================================================
procedure TPlaylist.WMEraseBkgnd(var Msg: TWmEraseBkgnd);
begin
  //
end;

//==============================================================================
procedure TPlaylist.WMMouseMove(var Msg: TMessage);
begin
  inherited;

  if DateUtils.MilliSecondsBetween(Now, m_dtUpdate) > 10 then
  begin
    Invalidate;
    m_dtUpdate := Now;
  end;
end;

//==============================================================================
procedure TPlaylist.CMMouseWheel(var Msg: TCMMouseWheel);
const
  c_ntDeltaOffset = 10;
begin
  Inherited;

  if Msg.WheelDelta > 0 then
    m_vtTransform.Offset := m_vtTransform.Offset + c_ntDeltaOffset;

  if Msg.WheelDelta < 0 then
    m_vtTransform.Offset := m_vtTransform.Offset - c_ntDeltaOffset;

  Invalidate;
end;

end.
