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
  Vcl.ExtCtrls,
  Vcl.Direct2D,
  Winapi.D2D1;

type
  TPlaylist = class(TCustomControl)
  private
    m_d2dCanvas : TDirect2DCanvas;

    procedure WMEraseBkgnd (var Msg: TWmEraseBkgnd); message WM_ERASEBKGND;

  protected
    procedure Paint; override;

  public
    constructor Create(AOwner : TComponent); override;
    destructor  Destroy; override;

  end;

implementation

//==============================================================================
constructor TPlaylist.Create(AOwner : TComponent);
begin
  Inherited;
end;

//==============================================================================
destructor  TPlaylist.Destroy;
begin
  Inherited;
end;

//==============================================================================
procedure TPlaylist.Paint;
var
  d2dBrush  : ID2D1SolidColorBrush;
  d2dBProp  : TD2D1BrushProperties;
  d2dRect   : TD2D1RectF;
begin
  m_d2dCanvas := TDirect2DCanvas.Create(Handle);

  d2dRect.Left   := 0;
  d2dRect.Top    := 0;
  d2dRect.Right  := ClientWidth;
  d2dRect.Bottom := ClientHeight;

  m_d2dCanvas.BeginDraw;

  d2dBProp.Transform := TD2DMatrix3X2F.Identity;
  d2dBProp.Opacity := 1.0;
  m_d2dCanvas.RenderTarget.CreateSolidColorBrush(D2D1ColorF(clBlue), @d2dBProp, d2dBrush);
  m_d2dCanvas.RenderTarget.FillRectangle(d2dRect, d2dBrush);

  m_d2dCanvas.EndDraw;

  m_d2dCanvas.Free;
end;

//==============================================================================
procedure TPlaylist.WMEraseBkgnd(var Msg: TWmEraseBkgnd);
begin
  //
end;

end.
