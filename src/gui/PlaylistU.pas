unit PlaylistU;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Variants,
  System.Classes,
  System.UITypes,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.StdCtrls,
  Vcl.ExtCtrls;

type
  TPlaylist = class(TCustomControl)
  private

  protected
    procedure Paint; override;

  public

  end;

implementation

uses
  Vcl.Direct2D, Winapi.D2D1;

//==============================================================================
procedure TPlaylist.Paint;
var
  d2dCanvas : TDirect2DCanvas;
  d2dBrush  : ID2D1SolidColorBrush;
  d2dBProp  : TD2D1BrushProperties;
  d2dRect   : TD2D1RectF;
begin
  d2dRect.Left   := 0;
  d2dRect.Top    := 0;
  d2dRect.Right  := ClientWidth;
  d2dRect.Bottom := ClientHeight;

  d2dCanvas := TDirect2DCanvas.Create(Canvas, TRect.Create(0, 0, ClientWidth, ClientHeight));
  d2dCanvas.BeginDraw;

  d2dBProp.Transform := TD2DMatrix3X2F.Identity;
  d2dBProp.Opacity := 1.0;
  d2dCanvas.RenderTarget.CreateSolidColorBrush(D2D1ColorF(clBlue), @d2dBProp, d2dBrush);
  d2dCanvas.RenderTarget.FillRectangle(d2dRect, d2dBrush);

  d2dCanvas.EndDraw;
  d2dCanvas.Free;
end;

end.
