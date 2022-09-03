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


    DC : HDC;
    hrc: HGLRC;
    AAFormat: Integer;

    bGlInit : Boolean;

    procedure WMNCSize     (var Msg: TWMSize);       message WM_SIZE;
    procedure WMEraseBkgnd (var Msg: TWmEraseBkgnd); message WM_ERASEBKGND;
    procedure CMMouseWheel (var Msg: TCMMouseWheel); message CM_MOUSEWHEEL;

    procedure Invalidate(a_nInterval : Integer); reintroduce; overload;

    procedure SetupD2DOBjects;

    procedure GetPixelFormat;
    procedure SetDCPixelFormat (hdc : HDC);
    procedure glInit;

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
  OpenGL,
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

  //SetupD2DOBjects;

  bGlInit := False;
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

  Invalidate(20);
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
//  d2dRect.Left   := 0;
//  d2dRect.Top    := 0;
//  d2dRect.Right  := ClientWidth;
//  d2dRect.Bottom := ClientHeight;
//
//  m_d2dKit.Target.Clear(D2D1ColorF(clBlack));
//
//  m_d2dKit.Brush.SetColor(D2D1ColorF(clDkGray, 1));
//  m_d2dKit.Target.FillRectangle(d2dRect, m_d2dKit.Brush);

  glColor4f($1F/$FF,$1F/$FF,$1F/$FF,1);
  glRect(0, 0, ClientWidth, ClientHeight);
end;

//==============================================================================
procedure TPlaylistSurface.PaintGrid;
var
  pntUp   : TPointF;
  pntDown : TPointF;
  nIndex  : Integer;
begin
//  m_d2dKit.Target.SetAntialiasMode(D2D1_ANTIALIAS_MODE_ALIASED);
//  m_d2dKit.Brush.SetColor(D2D1ColorF(clWhite));

  glColor4f(1,1,1,0.2);
  glLineWidth(1);

  glBegin(GL_LINES);

  for nIndex := 0 to 10 do
  begin
    pntUp   := PointF(Trunc(m_pmManager.BeatToX(nIndex)) + 0.5, 0.5);
    pntDown := PointF(Trunc(m_pmManager.BeatToX(nIndex)) + 0.5, Height + 0.5);

    glVertex2f(pntUp.X, pntUp.Y);
    glVertex2f(pntDown.X, pntDown.Y);
    //m_d2dKit.Target.DrawLine(pntUp, pntDown, m_d2dKit.Brush);
  end;

  for nIndex := 0 to 10 do
  begin
    pntUp   := PointF(0.5,         nIndex*c_nLineHeight + 0.5);
    pntDown := PointF(Width + 0.5, nIndex*c_nLineHeight + 0.5);

    glVertex2f(pntUp.X, pntUp.Y);
    glVertex2f(pntDown.X, pntDown.Y);
    //m_d2dKit.Target.DrawLine(pntUp, pntDown, m_d2dKit.Brush);
  end;

  glEnd;
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
  pntUp   : TPointF;
  pntDown : TPointF;
begin
  //m_d2dKit.Target.SetAntialiasMode(D2D1_ANTIALIAS_MODE_ALIASED);

  glColor4f(0,0.5,1,1);
  glLineWidth(1);

  glBegin(GL_LINES);

  pntUp.X := m_pmManager.GetProgressX;
  pntUp.Y := 0;

  pntDown.X := m_pmManager.GetProgressX;
  pntDown.Y := Height;

  glVertex2f(pntUp.X, pntUp.Y);
  glVertex2f(pntDown.X, pntDown.Y);

  glEnd;

  //m_d2dKit.Brush.SetColor(D2D1ColorF(clBlue));
  //m_d2dKit.Target.DrawLine(pntUp, pntDown, m_d2dKit.Brush);
end;

//==============================================================================
procedure TPlaylistSurface.Paint;
var
  recSelf : TRect;
begin
//  recSelf := GetClientRect;
//
//  m_d2dKit.Target.BindDC(Canvas.Handle, recSelf);
//  m_d2dKit.Target.BeginDraw;
//  m_d2dKit.Target.SetTransform(TD2DMatrix3X2F.Identity);
//
//  PaintBackground;
//  PaintGrid;
//  PaintVisualObjects;
//  PaintPosLine;
//
//  m_d2dKit.Target.EndDraw;

  if not bGlInit then
  begin
    GlInit;
    bGlInit := True;
  end;

  //wglMakeCurrent(DC, hrc);

  glViewport(0, 0, ClientWidth, ClientHeight); ;
  glLoadIdentity();
  glOrtho(0, ClientWidth, ClientHeight, 0, -1, 1);
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);

  PaintBackground;
  PaintGrid;
  PaintVisualObjects;
  PaintPosLine;

  SwapBuffers(wglGetCurrentDC);
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

procedure TPlaylistSurface.SetDCPixelFormat (hdc : HDC);
var
  nPixelFormat: Integer;
  pfd: TPixelFormatDescriptor;
begin
  FillChar(pfd, SizeOf(pfd), 0);

  With pfd do begin
	dwFlags   := PFD_DRAW_TO_WINDOW or
				 PFD_SUPPORT_OPENGL or
				 PFD_DOUBLEBUFFER;
	cDepthBits:= 32;
  end;

  if (AAFormat > 0) then nPixelFormat := AAFormat
  else nPixelFormat := ChoosePixelFormat(DC, @pfd);

  SetPixelFormat(DC, nPixelFormat, @pfd);
end;

//*********************************************
procedure TPlaylistSurface.GetPixelFormat;
const
  WGL_SAMPLE_BUFFERS_ARB = $2041;
  WGL_SAMPLES_ARB		   = $2042;
  WGL_DRAW_TO_WINDOW_ARB = $2001;
  WGL_SUPPORT_OPENGL_ARB = $2010;
  WGL_DOUBLE_BUFFER_ARB  = $2011;
  WGL_COLOR_BITS_ARB	 = $2014;
  WGL_DEPTH_BITS_ARB	 = $2022;
  WGL_STENCIL_BITS_ARB   = $2023;
  AASamples : Integer	= 8;
var
  wglChoosePixelFormatARB:
  function  (hdc: HDC;
			 const piAttribIList: PGLint;
			 const pfAttribFList: PGLfloat;
			 nMaxFormats: GLuint;
			 piFormats: PGLint;
			 nNumFormats: PGLuint): BOOL; stdcall;

  fAttributes: array [0..1] of Single;
  iAttributes: array [0..17] of Integer;
  pfd		: PIXELFORMATDESCRIPTOR;
  iFormat	: Integer;
  hwnd	   : Cardinal;
  wnd		: TWndClassEx;
  numFormats : Cardinal;
  Format	 : Integer;
begin
  ZeroMemory(@wnd, SizeOf(wnd));
  with wnd do
  begin
	cbSize		:= SizeOf(wnd);
	lpfnWndProc   := @DefWindowProc;
	hCursor	   := LoadCursor(0, IDC_ARROW);
	lpszClassName := 'GetPixelFormat';
  end;
  RegisterClassEx(wnd);
  hwnd := CreateWindow('GetPixelFormat', nil, WS_POPUP, 0, 0, 0, 0, 0, 0, HInstance, nil);
  DC := GetDC(hwnd);
  FillChar(pfd, SizeOf(pfd), 0);
  with pfd do
  begin
	nSize		:= SizeOf(TPIXELFORMATDESCRIPTOR);
	nVersion	 := 1;
	dwFlags	  := PFD_DRAW_TO_WINDOW or
					PFD_SUPPORT_OPENGL or
					PFD_DOUBLEBUFFER;
	iPixelType   := PFD_TYPE_RGBA;
	cColorBits   := 32;
	cDepthBits   := 24;
	cStencilBits := 8;
	iLayerType   := PFD_MAIN_PLANE;
  end;
  SetPixelFormat(DC, ChoosePixelFormat(DC, @pfd), @pfd);
  wglMakeCurrent(DC, wglCreateContext(DC));
  fAttributes[0]  := 0;
  fAttributes[1]  := 0;
  iAttributes[0]  := WGL_DRAW_TO_WINDOW_ARB;
  iAttributes[1]  := 1;
  iAttributes[2]  := WGL_SUPPORT_OPENGL_ARB;
  iAttributes[3]  := 1;
  iAttributes[4]  := WGL_SAMPLE_BUFFERS_ARB;
  iAttributes[5]  := 1;
  iAttributes[6]  := WGL_SAMPLES_ARB;
  //iAttributes[7]:= calc;
  iAttributes[8]  := WGL_DOUBLE_BUFFER_ARB;
  iAttributes[9]  := 1;
  iAttributes[10] := WGL_COLOR_BITS_ARB;
  iAttributes[11] := 32;
  iAttributes[12] := WGL_DEPTH_BITS_ARB;
  iAttributes[13] := 24;
  iAttributes[14] := WGL_STENCIL_BITS_ARB;
  iAttributes[15] := 8;
  iAttributes[16] := 0;
  iAttributes[17] := 0;
  wglChoosePixelFormatARB := wglGetProcAddress('wglChoosePixelFormatARB');
  iAttributes[7] := AASamples;
  if wglChoosePixelFormatARB(GetDC(hWnd), @iattributes, @fattributes, 1, @Format, @numFormats) and (numFormats >= 1) then
  begin
	AAFormat := Format;
  end;
  ReleaseDC(hwnd, DC);
  DestroyWindow(hwnd);
  wglMakeCurrent(0, 0);
  wglDeleteContext(DC);
end;

procedure TPlaylistSurface.glInit;
begin
  GetPixelFormat;
  DC := GetDC(Handle);
  SetDCPixelFormat(DC);
  hrc := wglCreateContext(DC);
  wglMakeCurrent(DC, hrc);

  glEnable(GL_BLEND);
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
  glLoadIdentity();
  glOrtho(0, ClientWidth, ClientHeight, 0, -1, 1);
  glMatrixMode(GL_MODELVIEW);
end;

end.
