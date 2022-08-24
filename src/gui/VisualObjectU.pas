unit VisualObjectU;

interface

uses
  System.Types,
  System.Classes,
  VCL.Direct2D,
  VCL.Controls,
  VisualTypesU;

type
  TVisualObject = class
  protected
    m_vlLocation : TVisualLocation;
    m_vosState   : TVisualObjectState;

    m_pntMouseClick : TPoint;

  public
    constructor Create;

    procedure Paint(a_d2dKit : TD2DKit); virtual; abstract;

    procedure MouseMove(Shift: TShiftState; X, Y: Integer); virtual;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); virtual;
    procedure MouseUp  (Button: TMouseButton; Shift: TShiftState; X, Y: Integer); virtual;

    property Location : TVisualLocation    read m_vlLocation  write m_vlLocation;
    property State    : TVisualObjectState read m_vosState    write m_vosState;

  end;

implementation

//==============================================================================
constructor TVisualObject.Create;
begin
  m_vlLocation    := TVisualLocation.Create(-1,-1,-1,-1);
  m_pntMouseClick := Point(-1, -1);
end;

//==============================================================================
procedure TVisualObject.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  if m_vosState.Clicked then
  begin
    m_vlLocation.X := X - m_pntMouseClick.X;
    m_vlLocation.Y := Y - m_pntMouseClick.Y;
  end;
end;

//==============================================================================
procedure TVisualObject.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  m_vosState.Clicked := True;
  m_pntMouseClick    := Point(X - m_vlLocation.X, Y - m_vlLocation.Y);
end;

//==============================================================================
procedure TVisualObject.MouseUp  (Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  m_vosState.Clicked := False;
  m_pntMouseClick    := Point(-1, -1);
end;

end.
