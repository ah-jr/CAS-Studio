unit VisualMixerSliderU;

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
  MixerManagerU;
type
  TVisualMixerSlider = class(TVisualObject)
  private
    m_nMixerID   : Integer;
    m_nPosition  : Integer;
    m_mmManager  : TMixerManager;

  public
    constructor Create(a_mmManager : TMixerManager; a_nMixerID : Integer);
    destructor  Destroy; override;

    procedure Paint        (a_f2dCanvas : TF2DCanvas); override;

    procedure MouseMove(Shift : TShiftState; X, Y: Integer); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp  (Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;

    function GetRect : TRect; override;

    property Position : Integer read m_nPosition;
    property MixerID  : Integer read m_nMixerID  write m_nMixerID;
  end;

implementation

uses
  Winapi.Windows,
  System.UITypes,
  TypesU,
  Math;

//==============================================================================
constructor TVisualMixerSlider.Create(a_mmManager : TMixerManager; a_nMixerID : Integer);
begin
  Inherited Create;
  m_nMixerID    := a_nMixerID;
  m_mmManager   := a_mmManager;
  m_nPosition   := a_mmManager.IncMixer;
end;

//==============================================================================
destructor TVisualMixerSlider.Destroy;
begin
  Inherited;
end;

//==============================================================================
procedure TVisualMixerSlider.Paint(a_f2dCanvas : TF2DCanvas);
var
  recSelf : TRect;
begin
  recSelf := GetRect;

  a_f2dCanvas.FillColor := c_clSliderBack;
  a_f2dCanvas.DrawColor := c_clSliderBorder;
  a_f2dCanvas.LineWidth := 2;

  a_f2dCanvas.FillRoundRect(recSelf.TopLeft, recSelf.BottomRight, 5);
  a_f2dCanvas.DrawRoundRect(recSelf.TopLeft, recSelf.BottomRight, 5);
end;

//==============================================================================
procedure TVisualMixerSlider.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  Inherited;
end;

//==============================================================================
procedure TVisualMixerSlider.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  Inherited;
end;

//==============================================================================
procedure TVisualMixerSlider.MouseUp  (Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  Inherited;
end;

//==============================================================================
function TVisualMixerSlider.GetRect : TRect;
begin
  Result.Left   := c_nMixerWidth * m_nPosition;
  Result.Top    := 0;
  Result.Right  := Result.Left + c_nMixerWidth - 1;
  Result.Bottom := m_mmManager.GetMixerRect.Height;

  // Prevent negative or null width/height
  if Result.Right - Result.Left <= 0 then
    Result.Right := Result.Left + 1;

  if Result.Bottom - Result.Top <= 0 then
    Result.Bottom := Result.Top + 1;    
end;

end.

