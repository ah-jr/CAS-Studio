unit VisualObjectU;

interface

uses
  System.Types,
  VCL.Direct2D,
  VisualTypesU;

type
  TVisualObject = class
  public
    procedure Paint(a_d2dKit : TD2DKit; a_vpiInfo : TVisualPaintInfo); virtual; abstract;
  end;

implementation

end.
