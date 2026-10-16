MODULE TestCairo;
IMPORT Cairo, Out;
VAR surface: Cairo.Surface; context: Cairo.Context; pattern: Cairo.Pattern;
  x1, y1, x2, y2: LONGREAL;
BEGIN
  ASSERT(Cairo.Version() >= 11200);
  surface := Cairo.ImageSurfaceCreate(Cairo.FARGB32, 32, 24);
  ASSERT(Cairo.SurfaceStatus(surface) = Cairo.SSUCCESS);
  ASSERT(Cairo.ImageSurfaceGetWidth(surface) = 32);
  ASSERT(Cairo.ImageSurfaceGetHeight(surface) = 24);
  ASSERT(Cairo.ImageSurfaceGetFormat(surface) = Cairo.FARGB32);
  ASSERT(Cairo.ImageSurfaceGetStride(surface) >= 128);
  ASSERT(Cairo.SurfaceGetReferenceCount(surface) = 1);
  context := Cairo.Create(surface);
  ASSERT(Cairo.Status(context) = Cairo.SSUCCESS);
  ASSERT(Cairo.SurfaceGetReferenceCount(surface) > 1);
  Cairo.SetSourceRGB(context, 1, 0, 0); Cairo.Paint(context);
  Cairo.Rectangle(context, 2, 3, 10, 12);
  Cairo.PathExtents(context, x1, y1, x2, y2);
  ASSERT((x1 = 2) & (y1 = 3) & (x2 = 12) & (y2 = 15));
  Cairo.SetSourceRGBA(context, 0, 0, 1, 0.5); Cairo.Fill(context);
  pattern := Cairo.PatternCreateRGB(0, 1, 0);
  ASSERT(Cairo.PatternStatus(pattern) = Cairo.SSUCCESS);
  ASSERT(Cairo.PatternGetReferenceCount(pattern) = 1);
  Cairo.SetSource(context, pattern); Cairo.PatternDestroy(pattern);
  Cairo.MoveTo(context, 0, 0); Cairo.LineTo(context, 20, 20);
  Cairo.Stroke(context);
  ASSERT(Cairo.Status(context) = Cairo.SSUCCESS);
  ASSERT(Cairo.SurfaceWriteToPNG(surface, "test-cairo.png") = Cairo.SSUCCESS);
  Cairo.Destroy(context); Cairo.SurfaceDestroy(surface);
  surface := Cairo.ImageSurfaceCreateFromPNG("test-cairo.png");
  ASSERT(Cairo.SurfaceStatus(surface) = Cairo.SSUCCESS);
  ASSERT(Cairo.ImageSurfaceGetWidth(surface) = 32);
  ASSERT(Cairo.ImageSurfaceGetHeight(surface) = 24);
  Cairo.SurfaceDestroy(surface);
  Out.String("Cairo image binding checks passed"); Out.Ln
END TestCairo.
