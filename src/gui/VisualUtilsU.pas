unit VisualUtilsU;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  Winapi.D2D1,
  VCL.Graphics,
  GR32;

  function CreateD2DBitmap(d2dTarget : ID2D1RenderTarget; bmpSource : TBitmap): ID2D1Bitmap;

implementation

uses
  TypesU,
  Winapi.DXGIFormat;

//==============================================================================
function CreateD2DBitmap(d2dTarget : ID2D1RenderTarget; bmpSource : TBitmap): ID2D1Bitmap;
var
  biInfo    : TBitmapInfo;
  arrBuffer : array of Byte;
  bpProp    : TD2D1BitmapProperties;
  hbmp      : HBitmap;
begin
  FillChar(biInfo, SizeOf(biInfo), 0);
  biInfo.bmiHeader.biSize     := Sizeof(biInfo.bmiHeader);
  biInfo.bmiHeader.biHeight   := -bmpSource.Height;
  biInfo.bmiHeader.biWidth    := bmpSource.Width;
  biInfo.bmiHeader.biPlanes   := 1;
  biInfo.bmiHeader.biBitCount := 32;

  SetLength(arrBuffer, bmpSource.Height * bmpSource.Width * 4);

  Hbmp := bmpSource.Handle;
  GetDIBits(bmpSource.Canvas.Handle, Hbmp, 0, bmpSource.Height, @arrBuffer[0], biInfo, DIB_RGB_COLORS);

  bpProp.dpiX                  := 0;
  bpProp.dpiY                  := 0;
  bpProp.pixelFormat.format    := DXGI_FORMAT_B8G8R8A8_UNORM;

  if (bmpSource.PixelFormat <> pf32bit) or (bmpSource.AlphaFormat = afIgnored)
    then bpProp.PixelFormat.AlphaMode := D2D1_ALPHA_MODE_IGNORE
    else bpProp.PixelFormat.AlphaMode := D2D1_ALPHA_MODE_PREMULTIPLIED;

  d2dTarget.CreateBitmap(D2D1SizeU(bmpSource.Width, bmpSource.Height), @arrBuffer[0], 4*bmpSource.Width, bpProp, Result)
end;

end.
