unit PlaylistU;

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
  PlaylistInfoU,
  TypesU;


type
  TPlaylist = class(TCustomControl, IAudioListener)
  private
    m_d2dKit      : TD2DKit;
    m_dtUpdate    : TDateTime;
    m_piInfo      : TPlaylistInfo;

    m_lstVisualObjects : TList<TVisualObject>;

    procedure WMEraseBkgnd (var Msg: TWmEraseBkgnd); message WM_ERASEBKGND;
    procedure CMMouseWheel (var Msg: TCMMouseWheel); message CM_MOUSEWHEEL;

    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp  (Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;

  protected
    procedure Paint; override;
    procedure PaintBackground;
    procedure PaintGrid;
    procedure PaintVisualObjects;
    procedure PaintPosLine;

  public
    constructor Create(AOwner : TComponent); override;
    destructor  Destroy; override;

    procedure UpdateProgress(a_dProgress : Double);
    procedure AddTrack(a_nTrackID : Integer);

    //property Progress : Double read m_vpiInfo.Progress write m_vpiInfo.Progress;

  end;

implementation

uses
  DateUtils,
  VisualTrackU,
  AudioManagerU,
  CasTrackU,
  System.Types;

//==============================================================================
constructor TPlaylist.Create(AOwner : TComponent);
begin
  Inherited;

  m_dtUpdate  := Now;

  m_piInfo           := TPlaylistInfo.Create(g_AudioManager);
  m_piInfo.Progress  := 0;
  m_piInfo.Size      := 0;
  m_piInfo.Transform.SetOffset(0);
  m_piInfo.Transform.SetScale(PointF(1, 1));

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
  m_piInfo.Destroy;

  Inherited;
end;

//==============================================================================
procedure TPlaylist.UpdateProgress(a_dProgress : Double);
begin
  m_piInfo.Progress := a_dProgress;

  Invalidate;
end;

//==============================================================================
procedure TPlaylist.AddTrack(a_nTrackID : Integer);
var
  vtTrack     : TVisualTrack;
  CasTrack    : TCasTrack;
begin
  if g_AudioManager.Engine.Database.GetTrackById(a_nTrackID, CasTrack) then
  begin
    m_piInfo.Size  := g_AudioManager.Engine.Length;
    vtTrack        := TVisualTrack.Create(m_piInfo, a_nTrackID);

    vtTrack.Location.SetX(0);
    vtTrack.Location.SetY(0);
    vtTrack.Location.SetWidth(m_piInfo.GetVisualSize(CasTrack.Size));
    vtTrack.Location.SetHeight(80);

    m_lstVisualObjects.Add(vtTrack);
  end;
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

  m_d2dKit.Canvas.RenderTarget.FillRectangle(d2dRect, m_d2dKit.D2D1Brush);
end;

//==============================================================================
procedure TPlaylist.PaintGrid;
var
  pntUp   : TPoint;
  pntDown : TPoint;
  nIndex  : Integer;
begin
  m_d2dKit.Canvas.RenderTarget.SetAntialiasMode(D2D1_ANTIALIAS_MODE_ALIASED);
  m_d2dKit.D2D1Brush.SetColor(D2D1ColorF(clWhite));

  for nIndex := 0 to 10 do
  begin
    pntUp   := Point(m_piInfo.Transform.Offset + nIndex*c_nBarWidth, 0);
    pntDown := Point(m_piInfo.Transform.Offset + nIndex*c_nBarWidth, Height);

    m_d2dKit.Canvas.RenderTarget.DrawLine(pntUp, pntDown, m_d2dKit.D2D1Brush);
  end;
end;

//==============================================================================
procedure TPlaylist.PaintVisualObjects;
var
  nIndex : Integer;
begin
  for nIndex := 0 to m_lstVisualObjects.Count - 1 do
  begin
    m_lstVisualObjects.Items[nIndex].Paint(m_D2DKit);
  end;
end;

//==============================================================================
procedure TPlaylist.PaintPosLine;
var
  pntUp   : TD2DPoint2f;
  pntDown : TD2DPoint2f;
begin
  m_d2dKit.Canvas.RenderTarget.SetAntialiasMode(D2D1_ANTIALIAS_MODE_ALIASED);

  pntUp.X := m_piInfo.Transform.Offset + m_piInfo.Progress*g_AudioManager.BeatCount*c_nBarWidth;
  pntUp.Y := 0;

  pntDown.X := m_piInfo.Transform.Offset + m_piInfo.Progress*g_AudioManager.BeatCount*c_nBarWidth;
  pntDown.Y := Height;

  m_d2dKit.D2D1Brush.SetColor(D2D1ColorF(clBlue));
  m_d2dKit.Canvas.RenderTarget.DrawLine(pntUp, pntDown, m_d2dKit.D2D1Brush);
end;

//==============================================================================
procedure TPlaylist.Paint;
var
  d2dBProp : TD2D1BrushProperties;
begin
  d2dBProp.Transform := TD2DMatrix3X2F.Identity;
  d2dBProp.Opacity := 1.0;

  m_d2dKit.Canvas := TDirect2DCanvas.Create(Handle);
  m_d2dKit.Canvas.RenderTarget.CreateSolidColorBrush(D2D1ColorF(clGray), @d2dBProp, m_d2dKit.D2D1Brush);
  m_d2dKit.Canvas.BeginDraw;

  PaintBackground;
  PaintGrid;
  PaintVisualObjects;
  PaintPosLine;

  m_d2dKit.Canvas.EndDraw;
  m_d2dKit.Canvas.Free;
end;

//==============================================================================
procedure TPlaylist.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  nIndex   : Integer;
  voObject : TVisualObject;
begin
  for nIndex := 0 to m_lstVisualObjects.Count - 1 do
  begin
    voObject := m_lstVisualObjects.Items[nIndex];

    if voObject.Location.Contains(X, Y) then
      voObject.MouseDown(Button, Shift, X, Y);
  end;
end;

//==============================================================================
procedure TPlaylist.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  nIndex   : Integer;
  voObject : TVisualObject;
begin
  for nIndex := 0 to m_lstVisualObjects.Count - 1 do
  begin
    voObject := m_lstVisualObjects.Items[nIndex];

    if voObject.Location.Contains(X, Y) then
      voObject.MouseUp(Button, Shift, X, Y);
  end;
end;

//==============================================================================
procedure TPlaylist.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  nIndex   : Integer;
  voObject : TVisualObject;
begin
  inherited;

  for nIndex := 0 to m_lstVisualObjects.Count - 1 do
  begin
    voObject := m_lstVisualObjects.Items[nIndex];

    if voObject.Location.Contains(X, Y) then
      voObject.MouseMove(Shift, X, Y);
  end;

  if DateUtils.MilliSecondsBetween(Now, m_dtUpdate) > 10 then
  begin
    Invalidate;
    m_dtUpdate := Now;
  end;
end;

//==============================================================================
procedure TPlaylist.WMEraseBkgnd(var Msg: TWmEraseBkgnd);
begin
  //
end;

//==============================================================================
procedure TPlaylist.CMMouseWheel(var Msg: TCMMouseWheel);
const
  c_ntDeltaOffset = 10;
begin
  Inherited;

  if Msg.WheelDelta > 0 then
    m_piInfo.Transform.SetOffset(m_piInfo.Transform.Offset + c_ntDeltaOffset);

  if Msg.WheelDelta < 0 then
    m_piInfo.Transform.SetOffset(m_piInfo.Transform.Offset - c_ntDeltaOffset);

  Invalidate;
end;

end.
