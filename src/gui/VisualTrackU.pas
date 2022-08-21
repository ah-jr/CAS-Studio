unit VisualTrackU;

interface

uses
  VCL.Direct2D,
  VisualObjectU;

type

  TVisualTrack = class(TVisualObject)
  private
//    m_rec

  public
    procedure Paint(a_d2dCanvas : TDirect2DCanvas; a_vtTransform : TVisualTransform); override;
  end;

implementation

//==============================================================================
procedure TVisualTrack.Paint(a_d2dCanvas : TDirect2DCanvas; a_vtTransform : TVisualTransform);
begin

end;

end.

