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
  c_nLineHeight = 150;

  c_nBarSplit   = 16;

  //////////////////////////////////////////////////////////////////////////////
  ///  Colors
  c_clPlayList  = $E0252525;
  c_clGridLines = $80FFFFFF;
  c_clTrackBack = $DF131415;
  c_clPosLine   = $FF0080FF;


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

uses
  Math;

//==============================================================================
procedure TVisualTransform.SetOffset(a_nOffset : Integer);
begin
  Offset := Max(0, a_nOffset);
end;

//==============================================================================
procedure TVisualTransform.SetScale(a_pntScale : TPointF);
begin
  Scale := a_pntScale;
end;

end.
