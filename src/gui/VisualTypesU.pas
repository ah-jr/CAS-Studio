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
  c_clPlayList   = $80202020;
  c_clGridLines  = $406F6F6F;
  c_clTrackBack  = $D0161718;
  c_clPosLine    = $FF0080FF;
  c_clMixer      = $80202020;
  c_clSliderBack   = $BFFF8B64;
  c_clSliderBorder = $90FFFFFF;


type

  TD2DKit = record
    Brush   : ID2D1SolidColorBrush;
    Target  : ID2D1DCRenderTarget;
    Factory : ID2D1Factory;
  end;

  TVisualTransform = record
    Offset  : TPointF;
    Scale   : TPointF;

    class operator Initialize (out rec: TVisualTransform);
    procedure SetOffset(a_pntOffset : TPointF); overload;
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
class operator TVisualTransform.Initialize (out rec: TVisualTransform);
begin
  rec.Offset := TPointF.Create(1, 1);
  rec.Scale  := TPointF.Create(1, 1);
end;

//==============================================================================
procedure TVisualTransform.SetOffset(a_pntOffset : TPointF);
begin
  Offset.X := Max(0, a_pntOffset.X);
  Offset.Y := Max(0, a_pntOffset.Y);
end;

//==============================================================================
procedure TVisualTransform.SetOffset(a_nX, a_nY : Double);
begin
  Offset.X := Max(0, a_nX);
  Offset.Y := Max(0, a_nY);
end;

//==============================================================================
procedure TVisualTransform.SetOffsetX(a_nX : Double);
begin
  Offset.X := Max(0, a_nX);
end;

//==============================================================================
procedure TVisualTransform.SetOffsetY(a_nY : Double);
begin
  Offset.Y := Max(0, a_nY);
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
