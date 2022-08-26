Unit VisualTypesU;

interface

uses
  System.Types,
  VCL.Direct2D,
  Winapi.D2D1;

const
  //////////////////////////////////////////////////////////////////////////////
  ///  PlaylistSurface
  c_nBarWidth   = 100;
  c_nLineHeight = 50;

  c_nBarSplit   = 16;

type

  TD2DKit = record
    Brush   : ID2D1SolidColorBrush;
    Target  : ID2D1DCRenderTarget;
    Factory : ID2D1Factory;
  end;

  TVisualTransform = record
    Offset  : Integer;
    Scale   : TPointF;

    procedure SetOffset(a_nOffset : Integer);
    procedure SetScale(a_pntScale : TPointF);
  end;

  TVisualObjectState = record
    Clicked : Boolean;
    Hovered : Boolean;
  end;

implementation

//==============================================================================
procedure TVisualTransform.SetOffset(a_nOffset : Integer);
begin
  Offset := a_nOffset;
end;

//==============================================================================
procedure TVisualTransform.SetScale(a_pntScale : TPointF);
begin
  Scale := a_pntScale;
end;

end.
