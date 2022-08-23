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

implementation

end.
