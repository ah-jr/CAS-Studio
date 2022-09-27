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
  F2DCanvasU,
  F2DTypesU,
  PlaylistManagerU,
  TypesU;


type
  TPlaylistSurface = class(TCustomControl, IAudioListener)
  private
    m_f2dCanvas : TF2DCanvas;
    m_dtUpdate  : TDateTime;
    m_pmManager : TPlaylistManager;

    m_lstVisualObjects : TList<TVisualObject>;


    procedure WMNCSize     (var Msg: TWMSize);       message WM_SIZE;
    procedure WMEraseBkgnd (var Msg: TWmEraseBkgnd); message WM_ERASEBKGND;
    procedure CMMouseWheel (var Msg: TCMMouseWheel); message CM_MOUSEWHEEL;

    procedure Invalidate(a_nInterval : Integer); reintroduce; overload;
    procedure F2DInit;


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
    procedure RemoveTrack   (a_nTrackID  : Integer);
    procedure UpdateGUI;
    procedure DriverChange;

  end;

implementation

uses
  System.Types,
  Winapi.DxgiFormat,
  DateUtils,
  VisualTrackU,
  Math,
  CasTrackU;

//==============================================================================
constructor TPlaylistSurface.Create(AOwner : TComponent; a_pmManager : TPlaylistManager);
begin
  Inherited Create(AOwner);

  m_pmManager := a_pmManager;
  m_dtUpdate  := Now;

  m_lstVisualObjects := TList<TVisualObject>.Create;
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
procedure TPlaylistSurface.UpdateGUI;
begin
  //
end;

//==============================================================================
procedure TPlaylistSurface.DriverChange;
begin
  //
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
procedure TPlaylistSurface.RemoveTrack(a_nTrackID : Integer);
var
  nIndex   : Integer;
  voObject : TVisualObject;
begin
  inherited;

  for nIndex := 0 to m_lstVisualObjects.Count - 1 do
  begin
    voObject := m_lstVisualObjects.Items[nIndex];

    if (voObject is TVisualTrack) then
    begin
      m_lstVisualObjects.Remove(voObject);
      (voObject as TVisualTrack).Free;
      Break;
    end
  end;
end;

//==============================================================================
procedure TPlaylistSurface.PaintBackground;
var
  d2dRect : TD2D1RectF;
begin
  m_f2dCanvas.Clear($00000000);
  m_f2dCanvas.FillColor := c_clPlayList;
  m_f2dCanvas.FillRect(0, 0, ClientWidth, ClientHeight);
end;

//==============================================================================
procedure TPlaylistSurface.PaintGrid;
var
  pntUp   : TPointF;
  pntDown : TPointF;
  nIndex  : Integer;
begin
  m_f2dCanvas.LineWidth := 1;
  m_f2dCanvas.DrawColor := c_clGridLines;

  for nIndex := 0 to 10 do
  begin
    pntUp   := PointF(m_pmManager.BeatToX(nIndex), 0);
    pntDown := PointF(m_pmManager.BeatToX(nIndex), Height);

    m_f2dCanvas.DrawLine(pntUp, pntDown);
  end;

  for nIndex := 0 to 10 do
  begin
    pntUp   := PointF(0,     nIndex*c_nLineHeight);
    pntDown := PointF(Width, nIndex*c_nLineHeight);

    m_f2dCanvas.DrawLine(pntUp, pntDown);
  end;
end;

//==============================================================================
procedure TPlaylistSurface.PaintVisualObjects;
var
  nIndex : Integer;
begin
  for nIndex := 0 to m_lstVisualObjects.Count - 1 do
  begin
    m_lstVisualObjects.Items[nIndex].Paint(m_f2dCanvas);
  end;
end;

//==============================================================================
procedure TPlaylistSurface.PaintPosLine;
var
  pntUp   : TPointF;
  pntDown : TPointF;
begin
  m_f2dCanvas.DrawColor := c_clPosLine;

  pntUp.X := m_pmManager.GetProgressX;
  pntUp.Y := 0;

  pntDown.X := m_pmManager.GetProgressX;
  pntDown.Y := Height;

  m_f2dCanvas.DrawLine(pntUp, pntDown);
end;

//==============================================================================
procedure TPlaylistSurface.Paint;
var
  recSelf : TRect;
begin
  if m_f2dCanvas = nil then
    F2DInit;

  m_f2dCanvas.BeginDraw;

  PaintBackground;
  PaintGrid;
  PaintVisualObjects;
  PaintPosLine;

  m_f2dCanvas.EndDraw;
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

  Invalidate(20);
end;

//==============================================================================
procedure TPlaylistSurface.WMEraseBkgnd(var Msg: TWmEraseBkgnd);
begin
  //
end;

//==============================================================================
procedure TPlaylistSurface.CMMouseWheel(var Msg: TCMMouseWheel);
var
  nDeltaOffset : Integer;
  pntMouse     : TPoint;
const
  c_ntDeltaOffset = 10;
begin
  Inherited;

  if ssShift in Msg.ShiftState then
  begin
    pntMouse.X := Msg.XPos;
    pntMouse.Y := Msg.YPos;
    pntMouse := ScreenToClient(pntMouse);


    if Msg.WheelDelta > 0 then
    begin
      m_pmManager.Transform.SetScale(PointF(m_pmManager.Transform.Scale.X * 1.2, m_pmManager.Transform.Scale.Y));
      nDeltaOffset := Trunc(m_pmManager.Transform.Offset + (pntMouse.X/m_pmManager.Transform.Scale.X)*(0.2));
      m_pmManager.Transform.SetOffset(nDeltaOffset);
    end;

    if Msg.WheelDelta < 0 then
    begin
      nDeltaOffset := Trunc(m_pmManager.Transform.Offset - (pntMouse.X/m_pmManager.Transform.Scale.X)*(0.2));
      m_pmManager.Transform.SetScale(PointF(m_pmManager.Transform.Scale.X / 1.2, m_pmManager.Transform.Scale.Y));
      m_pmManager.Transform.SetOffset(nDeltaOffset);
    end;
  end
  else
  begin
    nDeltaOffset := Trunc(c_ntDeltaOffset / m_pmManager.Transform.Scale.X);
    nDeltaOffset := Max(nDeltaOffset, 1);

    if Msg.WheelDelta > 0 then
      m_pmManager.Transform.SetOffset(m_pmManager.Transform.Offset - nDeltaOffset);

    if Msg.WheelDelta < 0 then
      m_pmManager.Transform.SetOffset(m_pmManager.Transform.Offset + nDeltaOffset);
  end;

  Invalidate(20);
end;

//==============================================================================
procedure TPlaylistSurface.WMNCSize(var Msg: TWMSize);
var
  dScaleChange : Double;
begin
  if m_pmManager.GetPlaylistRect.Width <> 0 then
  begin
    dScaleChange := ClientRect.Width/m_pmManager.GetPlaylistRect.Width;
    m_pmManager.Transform.SetScale(PointF(m_pmManager.Transform.Scale.X * dScaleChange, 1));
  end;

  if m_f2dCanvas <> nil then
    m_f2dCanvas.ChangeSize(ClientWidth, ClientHeight);

  m_pmManager.SetPlaylistRect(ClientRect);
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
procedure TPlaylistSurface.F2DInit;
var
  f2dProp : TF2DCanvasProperties;
begin
  with f2dProp do
  begin
    Hwnd   := Handle;
    Width  := ClientWidth;
    Height := ClientHeight;
    MSAA   := 8;
    Debug  := False;
  end;

  m_f2dCanvas := TF2DCanvas.Create(f2dProp);
end;

end.
