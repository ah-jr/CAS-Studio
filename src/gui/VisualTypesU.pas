Unit VisualTypesU;

interface

uses
  System.Types,
  VCL.Direct2D,
  Winapi.D2D1;

const
  //////////////////////////////////////////////////////////////////////////////
  ///  PlaylistSurface
  c_nBarWidth   = 120;
  c_nLineHeight = 90;

  c_nBarSplit   = 12;

  c_nBarMinDistance = 20;
  c_nBarMaxDistance = 50;

  c_dMinScaleY = 0.05;
  c_dMaxScaleY = 2;

  //////////////////////////////////////////////////////////////////////////////
  ///  PlaylistSurface
  c_nMixerWidth  = 40;
  c_nSliderCount = 5;

  //////////////////////////////////////////////////////////////////////////////
  ///  Colors
  c_clPlayList   = $E0252525;
  c_clGridLines  = $50AFAFAF;
  c_clTrackBack  = $D0161718;
  c_clPosLine    = $FF0080FF;
  c_clMixer      = $E0252525;
  c_clSliderBack   = $FFFF8B64;
  c_clSliderBorder = $90FFFFFF;


type

  TD2DKit = record
    Brush   : ID2D1SolidColorBrush;
    Target  : ID2D1DCRenderTarget;
    Factory : ID2D1Factory;
  end;

  TVisualTransform = record
    Offset  : TPoint;
    Scale   : TPointF;

    procedure SetOffset(a_pntOffset : TPoint); overload;
    procedure SetOffset(a_nX, a_nY : Double); overload;
    procedure SetOffsetX(a_nX : Double);
    procedure SetOffsetY(a_nY : Double);
    procedure SetScale(a_pntScale : TPointF);
    procedure SetScaleX(a_nX : Double);
    procedure SetScaleY(a_nY : Double);
  end;

  TVisualObjectState = record
    Clicked : Boolean;
    Hovered : Boolean;
  end;

implementation

uses
  Math;

//==============================================================================
procedure TVisualTransform.SetOffset(a_pntOffset : TPoint);
begin
  Offset.X := Max(0, a_pntOffset.X);
  Offset.Y := Max(0, a_pntOffset.Y);
end;

//==============================================================================
procedure TVisualTransform.SetOffset(a_nX, a_nY : Double);
begin
  Offset.X := Max(0, Trunc(a_nX));
  Offset.Y := Max(0, Trunc(a_nY));
end;

//==============================================================================
procedure TVisualTransform.SetOffsetX(a_nX : Double);
begin
  Offset.X := Max(0, Trunc(a_nX));
end;

//==============================================================================
procedure TVisualTransform.SetOffsetY(a_nY : Double);
begin
  Offset.Y := Max(0, Trunc(a_nY));
end;

//==============================================================================
procedure TVisualTransform.SetScale(a_pntScale : TPointF);
begin
  Scale.X := Max(0, a_pntScale.X);
  Scale.Y := Min(c_dMaxScaleY, Max(c_dMinScaleY, a_pntScale.Y));
end;

//==============================================================================
procedure TVisualTransform.SetScaleX(a_nX : Double);
begin
  Scale.X := Max(0, a_nX);
end;

//==============================================================================
procedure TVisualTransform.SetScaleY(a_nY : Double);
begin
  Scale.Y := Min(c_dMaxScaleY, Max(c_dMinScaleY, a_nY));
end;

end.
