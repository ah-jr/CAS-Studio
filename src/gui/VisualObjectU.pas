unit VisualObjectU;

interface

uses
  System.Types,
  System.Classes,
  VCL.Direct2D,
  VCL.Controls,
  F2DCanvasU,
  F2DTypesU,
  VisualTypesU;

type
  TVisualObject = class
  protected
    m_vosState   : TVisualObjectState;

    m_pntMouseClick : TPoint;

  public
    constructor Create;

    procedure Paint(a_f2dCanvas : TF2DCanvas); virtual; abstract;

    procedure MouseMove(Shift: TShiftState; X, Y: Integer); virtual;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); virtual;
    procedure MouseUp  (Button: TMouseButton; Shift: TShiftState; X, Y: Integer); virtual;

    function GetRect : TRectF; virtual; abstract;

    property State    : TVisualObjectState read m_vosState    write m_vosState;

  end;

implementation

//==============================================================================
constructor TVisualObject.Create;
begin
  m_pntMouseClick := Point(-1, -1);
end;

//==============================================================================
procedure TVisualObject.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  //
end;

//==============================================================================
procedure TVisualObject.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  m_vosState.Clicked := True;
  m_pntMouseClick    := Point(X - Trunc(GetRect.Left), Y - Trunc(GetRect.Top));
end;

//==============================================================================
procedure TVisualObject.MouseUp  (Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  m_vosState.Clicked := False;
  m_pntMouseClick    := Point(-1, -1);
end;

end.
