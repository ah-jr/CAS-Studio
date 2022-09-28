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
    procedure CreateMixerSliders;


  protected
    procedure Paint; override;
    procedure PaintBackground;
    procedure PaintVisualObjects;

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
  VisualMixerSliderU,
  Math,
  CasTrackU;

//==============================================================================
constructor TMixerSurface.Create(AOwner : TComponent; a_mmManager : TMixerManager);
begin
  Inherited Create(AOwner);

  m_mmManager := a_mmManager;
  m_dtUpdate  := Now;

  m_lstVisualObjects := TList<TVisualObject>.Create;

  CreateMixerSliders;
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
begin
  //
end;

//==============================================================================
procedure TMixerSurface.UpdateProgress(a_dProgress : Double);
begin
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
begin
  m_f2dCanvas.Clear($00000000);
  m_f2dCanvas.FillColor := c_clMixer;
  m_f2dCanvas.FillRect(0, 0, ClientWidth, ClientHeight);
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
procedure TMixerSurface.Paint;
var
  recSelf : TRect;
begin
  if m_f2dCanvas = nil then
    F2DInit;

  m_f2dCanvas.BeginDraw;

  PaintBackground;
  PaintVisualObjects;

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

//==============================================================================
procedure TMixerSurface.CreateMixerSliders;
var
  nIndex   : Integer;
  vtSlider : TVisualMixerSlider;
begin
  for nIndex := 0 to c_nSliderCount - 1 do
  begin
    vtSlider := TVisualMixerSlider.Create(m_mmManager, 0);
    m_lstVisualObjects.Add(vtSlider);
  end;
end;

end.
