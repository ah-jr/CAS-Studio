unit VisualObjectU;

interface

uses
  System.Types,
  VCL.Direct2D;

type
  TVisualTransform = record
    Offset   : Integer;
    pntScale : TPointF;
  end;

  TVisualObject = class
  public
    procedure Paint(a_d2dCanvas : TDirect2DCanvas; a_vtTransform : TVisualTransform); virtual; abstract;
  end;

implementation

end.
