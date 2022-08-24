Unit VisualTypesU;

interface

uses
  System.Types,
  VCL.Direct2D,
  Winapi.D2D1;

type

  TD2DKit = record
    Canvas     : TDirect2DCanvas;
    D2D1Brush  : ID2D1SolidColorBrush;
    Brush      : TDirect2DBrush;
    Pen        : TDirect2DPen;
  end;

  TVisualTransform = record
    Offset   : Integer;
    pntScale : TPointF;
  end;

  TVisualPaintInfo = record
    Transform : TVisualTransform;
    Size      : Integer;
    Progress  : Double;
  end;

  TVisualObjectState = record
    Clicked : Boolean;
    Hovered : Boolean;
  end;

  TVisualLocation = record
    X      : Integer;
    Y      : Integer;
    Width  : Integer;
    Height : Integer;

    function  Contains(a_X : Integer; a_Y: Integer) : Boolean;

    procedure SetX     (a_X      : Integer);
    procedure SetY     (a_Y      : Integer);
    procedure SetWidth (a_Width  : Integer);
    procedure SetHeight(a_Height : Integer);

    class function Create(a_X, a_Y, a_Width, a_Height : Integer) : TVisualLocation; static;

  end;

implementation

//==============================================================================
function TVisualLocation.Contains(a_X : Integer; a_Y: Integer) : Boolean;
begin
  Result := (a_X >= X) and (a_X <= X + Width) and (a_Y >= Y) and (a_Y <= Y + Height);
end;

//==============================================================================
class function TVisualLocation.Create(a_X, a_Y, a_Width, a_Height : Integer) : TVisualLocation;
begin
  Result.X      := a_X;
  Result.Y      := a_Y;
  Result.Width  := a_Width;
  Result.Height := a_Height;
end;

//==============================================================================
procedure TVisualLocation.SetX(a_X : Integer);
begin
  X := a_X;
end;

//==============================================================================
procedure TVisualLocation.SetY(a_Y : Integer);
begin
  Y := a_Y;
end;

//==============================================================================
procedure TVisualLocation.SetWidth(a_Width : Integer);
begin
  Width := a_Width;
end;

//==============================================================================
procedure TVisualLocation.SetHeight(a_Height : Integer);
begin
  Height := a_Height;
end;

end.
