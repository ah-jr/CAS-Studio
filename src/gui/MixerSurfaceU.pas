unit MixerSurfaceU;

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
  MixerManagerU,
  TypesU;


type
  TMixerSurface = class(TCustomControl, IAudioListener)
  private
    m_f2dCanvas : TF2DCanvas;
    m_dtUpdate  : TDateTime;
    m_mmManager : TMixerManager;

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
    constructor Create(AOwner : TComponent; a_mmManager : TMixerManager); reintroduce; overload;
    destructor  Destroy; override;

    procedure UpdateBPM     (a_dOldBPM, a_dNewBPM : Double);
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
constructor TMixerSurface.Create(AOwner : TComponent; a_mmManager : TMixerManager);
begin
  Inherited Create(AOwner);

  m_mmManager := a_mmManager;
  m_dtUpdate  := Now;

  m_lstVisualObjects := TList<TVisualObject>.Create;
end;

//==============================================================================
destructor  TMixerSurface.Destroy;
var 
  VisualObject : TVisualObject;
begin
  for VisualObject in m_lstVisualObjects do
     VisualObject.Free;

  m_lstVisualObjects.Free;

  Inherited;
end;

//==============================================================================
procedure TMixerSurface.UpdateBPM(a_dOldBPM, a_dNewBPM : Double);
var
  VisualObject : TVisualObject;
  a_nNewPos : Integer;
begin
  for VisualObject in m_lstVisualObjects do
  begin
    if VisualObject is TVisualTrack then
    begin
      a_nNewPos := Trunc((VisualObject as TVisualTrack).Position * (a_dOldBPM/a_dNewBPM));
      m_mmManager.SetTrackPosition((VisualObject as TVisualTrack).TrackID, a_nNewPos);
      (VisualObject as TVisualTrack).Position := a_nNewPos;
    end;
  end;
end;

//==============================================================================
procedure TMixerSurface.UpdateProgress(a_dProgress : Double);
begin
  m_mmManager.Progress := a_dProgress;

  Invalidate(10);
end;

//==============================================================================
procedure TMixerSurface.UpdateGUI;
begin
  //
end;

//==============================================================================
procedure TMixerSurface.DriverChange;
begin
  //
end;

//==============================================================================
procedure TMixerSurface.AddTrack(a_nTrackID : Integer);
begin
  //
end;

//==============================================================================
procedure TMixerSurface.RemoveTrack(a_nTrackID : Integer);
begin
  //
end;

//==============================================================================
procedure TMixerSurface.PaintBackground;
var
  d2dRect : TD2D1RectF;
begin
  m_f2dCanvas.Clear($00000000);
  m_f2dCanvas.FillColor := c_clMixer;
  m_f2dCanvas.FillRect(0, 0, ClientWidth, ClientHeight);
end;

//==============================================================================
procedure TMixerSurface.PaintGrid;
var
  pntA     : TPointF;
  pntB     : TPointF;
  nIndex   : Integer;
  dBeatGap : Double;
  nBeatMul : Integer;
begin
  m_f2dCanvas.LineWidth := 1;
  m_f2dCanvas.DrawColor := c_clGridLines;

  //////////////////////////////////////////////////////////////////////////////
  ///  Vertical Lines
  dBeatGap := c_nBarWidth * m_mmManager.Transform.Scale.X;
  nBeatMul := 1;

  while(dBeatGap * nBeatMul < c_nBarMinDistance) do
  begin
    nBeatMul := nBeatMul * 2;
  end;

  nIndex := Trunc(m_mmManager.Transform.Offset.X / c_nBarWidth);
  pntA   := PointF(m_mmManager.BeatToX(nIndex), 0);
  pntB   := PointF(m_mmManager.BeatToX(nIndex), Height);

  nIndex := nIndex - nIndex mod nBeatMul;

  while pntA.X < ClientWidth do
  begin
    m_f2dCanvas.DrawLine(pntA, pntB);

    Inc(nIndex, nBeatMul);
    pntA := PointF(m_mmManager.BeatToX(nIndex), 0);
    pntB := PointF(m_mmManager.BeatToX(nIndex), Height);
  end;

  //////////////////////////////////////////////////////////////////////////////
  ///  Horizontal Lines
  nIndex := 0;
  pntA := PointF(0,     nIndex*m_mmManager.GetTrackVisualHeight + 0.5);
  pntB := PointF(Width, nIndex*m_mmManager.GetTrackVisualHeight + 0.5);

  while pntA.Y < ClientHeight do
  begin
    m_f2dCanvas.DrawLine(pntA, pntB);

    Inc(nIndex);
    pntA := PointF(0,     nIndex*m_mmManager.GetTrackVisualHeight + 0.5);
    pntB := PointF(Width, nIndex*m_mmManager.GetTrackVisualHeight + 0.5);
  end;
end;

//==============================================================================
procedure TMixerSurface.PaintVisualObjects;
var
  nIndex : Integer;
begin
  for nIndex := 0 to m_lstVisualObjects.Count - 1 do
  begin
    m_lstVisualObjects.Items[nIndex].Paint(m_f2dCanvas);
  end;
end;

//==============================================================================
procedure TMixerSurface.PaintPosLine;
var
  pntUp   : TPointF;
  pntDown : TPointF;
begin
  m_f2dCanvas.DrawColor := c_clPosLine;

  pntUp.X := m_mmManager.GetProgressX;
  pntUp.Y := 0;

  pntDown.X := m_mmManager.GetProgressX;
  pntDown.Y := Height;

  m_f2dCanvas.DrawLine(pntUp, pntDown);
end;

//==============================================================================
procedure TMixerSurface.Paint;
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
procedure TMixerSurface.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  nIndex   : Integer;
  voObject : TVisualObject;
begin
  for nIndex := m_lstVisualObjects.Count - 1 downto 0 do
  begin
    voObject := m_lstVisualObjects.Items[nIndex];

    if voObject.GetRect.Contains(Point(X, Y)) then
    begin
      voObject.MouseDown(Button, Shift, X, Y);
      Break;
    end;
  end;
end;

//==============================================================================
procedure TMixerSurface.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
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
procedure TMixerSurface.MouseMove(Shift: TShiftState; X, Y: Integer);
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
procedure TMixerSurface.WMEraseBkgnd(var Msg: TWmEraseBkgnd);
begin
  //
end;

//==============================================================================
procedure TMixerSurface.CMMouseWheel(var Msg: TCMMouseWheel);
var
  nDeltaOffset : Integer;
  pntMouse     : TPoint;
const
  c_ntDeltaOffset = 10;
begin
  Inherited;

  if (ssCtrl  in Msg.ShiftState) and
     (ssShift in Msg.ShiftState) then
  begin
    if Msg.WheelDelta > 0 then
    begin
      m_mmManager.Transform.SetScaleY(m_mmManager.Transform.Scale.Y * 1.2);
    end;
    if Msg.WheelDelta < 0 then
    begin
      m_mmManager.Transform.SetScaleY(m_mmManager.Transform.Scale.Y / 1.2);
    end;

  end
  else if ssCtrl in Msg.ShiftState then
  begin
    pntMouse.X := Msg.XPos;
    pntMouse.Y := Msg.YPos;
    pntMouse := ScreenToClient(pntMouse);

    if Msg.WheelDelta > 0 then
    begin
      m_mmManager.Transform.SetScaleX(m_mmManager.Transform.Scale.X * 1.2);
      nDeltaOffset := Trunc(m_mmManager.Transform.Offset.X + (pntMouse.X/m_mmManager.Transform.Scale.X)*(0.2));
      m_mmManager.Transform.SetOffsetX(nDeltaOffset);
    end;

    if Msg.WheelDelta < 0 then
    begin
      nDeltaOffset := Trunc(m_mmManager.Transform.Offset.X - (pntMouse.X/m_mmManager.Transform.Scale.X)*(0.2));
      m_mmManager.Transform.SetScaleX(m_mmManager.Transform.Scale.X / 1.2);
      m_mmManager.Transform.SetOffsetX(nDeltaOffset);
    end;
  end
  else if ssShift in Msg.ShiftState then
  begin
    nDeltaOffset := Trunc(c_ntDeltaOffset / m_mmManager.Transform.Scale.X);
    nDeltaOffset := Max(nDeltaOffset, 1);

    if Msg.WheelDelta > 0 then
      m_mmManager.Transform.SetOffsetX(m_mmManager.Transform.Offset.X - nDeltaOffset);

    if Msg.WheelDelta < 0 then
      m_mmManager.Transform.SetOffsetX(m_mmManager.Transform.Offset.X + nDeltaOffset);
  end
  else
  begin
    if Msg.WheelDelta > 0 then
      m_mmManager.Transform.SetOffsetY(m_mmManager.Transform.Offset.Y - 1);

    if Msg.WheelDelta < 0 then
      m_mmManager.Transform.SetOffsetY(m_mmManager.Transform.Offset.Y + 1);
  end;

  Invalidate(20);
end;

//==============================================================================
procedure TMixerSurface.WMNCSize(var Msg: TWMSize);
var
  dScaleChange : Double;
begin
  if m_mmManager.GetMixerRect.Width <> 0 then
  begin
    dScaleChange := ClientRect.Width/m_mmManager.GetMixerRect.Width;
    m_mmManager.Transform.SetScaleX(m_mmManager.Transform.Scale.X * dScaleChange);
  end;

  if m_f2dCanvas <> nil then
    m_f2dCanvas.ChangeSize(ClientWidth, ClientHeight);

  m_mmManager.SetMixerRect(ClientRect);
end;

//==============================================================================
procedure TMixerSurface.Invalidate(a_nInterval : Integer);
begin
  if DateUtils.MilliSecondsBetween(Now, m_dtUpdate) > a_nInterval then
  begin
    Invalidate;
    m_dtUpdate := Now;
  end;
end;

//==============================================================================
procedure TMixerSurface.F2DInit;
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
