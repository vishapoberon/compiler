MODULE Cairo;
IMPORT SYSTEM;

(* Cairo is free software and is available to be redistributed and/or modified
under the terms of either the GNU Lesser General Public License (LGPL) version 2.1
or the Mozilla Public License (MPL) version 1.1 at your option. *)

TYPE
    Context* = SYSTEM.PTR;
    Path* = SYSTEM.PTR;
    Pattern* = SYSTEM.PTR;
    Surface* = SYSTEM.PTR;

    AntialiasType* = LONGINT;
    ContentType* = LONGINT;
    ExtendType* = LONGINT;
    FillRuleType* = LONGINT;
    FilterType* = LONGINT;
    FontSlantType* = LONGINT;
    FontWeightType* = LONGINT;
    FormatType* = LONGINT;
    LineCapType* = LONGINT;
    LineJoinType* = LONGINT;
    OperatorType* = LONGINT;
    PathType* = LONGINT;
    PatternType* = LONGINT;
    StatusType* = LONGINT;
    SurfaceType* = LONGINT;

CONST
    (* AntialiasType *)
    ADEFAULT* = 0;
    ANONE* = 1;
    AGRAY* = 2;
    ASUBPIXEL* = 3;
    AFAST* = 4;
    AGOOD* = 5;
    ABEST* = 6;

    (* ContentType *)
    CCOLOR* = 1000H;
    CALPHA* = 2000H;
    CCOLORALPHA* = 3000H;

    (* ExtendType *)
    ENONE* = 0;
    EREPEAT* = 1;
    EREFLECT* = 2;
    EPAD* = 3;

    (* FillRuleType *)
    FRWINDING* = 0;
    FREVENODD* = 1;

    (* FilterType *)
    FFAST* = 0;
    FGOOD* = 1;
    FBEST* = 2;
    FNEAREST* = 3;
    FBILINEAR* = 4;
    FGAUSSIAN* = 5;

    (* FontSlantType *)
    FSNORMAL* = 0;
    FSITALIC* = 1;
    FSOBLIQUE* = 2;

    (* FontWeightType *)
    FWNORMAL* = 0;
    FWBOLD* = 1;

    (* FormatType *)
    FINVALID* = -1;
    FARGB32* = 0;
    FRGB24* = 1;
    FA8* = 2;
    FA1* = 3;
    FRGB16565* = 4;
    FRGB30* = 5;

    (* LineCapType *)
    LCBUTT* = 0;
    LCROUND* = 1;
    LCSQUARE* = 2;

    (* LineJoinType *)
    LJMITER* = 0;
    LJROUND* = 1;
    LJBEVEL* = 2;

    (* OperatorType *)
    OCLEAR* = 0;
    OSOURCE* = 1;
    OOVER* = 2;
    OIN* = 3;
    OOUT* = 4;
    OATOP* = 5;
    ODEST* = 6;
    ODESTOVER* = 7;
    ODESTIN* = 8;
    ODESTOUT* = 9;
    ODESTATOP* = 10;
    OXOR* = 11;
    OADD* = 12;
    OSATURATE* = 13;
    OMULTIPLY* = 14;
    OSCREEN* = 15;
    OOVERLAY* = 16;
    ODARKEN* = 17;
    OLIGHTEN* = 18;
    OCOLORDODGE* = 19;
    OCOLORBURN* = 20;
    OHARDLIGHT* = 21;
    OSOFTLIGHT* = 22;
    ODIFFERENCE* = 23;
    OEXCLUSION* = 24;
    OHSLHUE* = 25;
    OHSLSATURATION* = 26;
    OHSLCOLOR* = 27;
    OHSLLUMINOSITY* = 28;

    (* PatternType *)
    PTSOLID* = 0;
    PTSURFACE* = 1;
    PTLINEAR* = 2;
    PTRADIAL* = 3;
    PTMESH* = 4;
    PTRASTERSOURCE* = 5;

    (* PathType *)
    PMOVETO* = 0;
    PLINETO* = 1;
    PCURVETO* = 2;
    PCLOSEPATH* = 3;

    (* RegionOverlapType *)
    ROIN* = 0;
    ROOUT* = 1;
    ROPART* = 2;

    (* SurfaceType *)
    STIMAGE* = 0;
    STPDF* = 1;
    STPS* = 2;
    STXLIB* = 3;
    STXCB* = 4;
    STGLITZ* = 5;
    STQUARTZ* = 6;
    STWIN32* = 7;
    STBEOS* = 8;
    STDIRECTFB* = 9;
    STSVG* = 10;
    STOS2* = 11;
    STWIN32PRINTING* = 12;
    STQUARTZIMAGE* = 13;
    STSCRIPT* = 14;
    STQT* = 15;
    STRECORDING* = 16;
    STVG* = 17;
    STGL* = 18;
    STDRM* = 19;
    STTEE* = 20;
    STXML* = 21;
    STSKIA* = 22;
    STSUBSURFACE* = 23;
    STCOGL* = 24;

    (* StatusType *)
    SSUCCESS* = 0;
    SNOMEMORY* = 1;
    SINVALIDRESTORE* = 2;
    SINVALIDPOPGROUP* = 3;
    SNOCURRENTPOINT* = 4;
    SINVALIDMATRIX* = 5;
    SINVALIDSTATUS* = 6;
    SNULLPOINTER* = 7;
    SINVALIDSTRING* = 8;
    SINVALIDPATHDATA* = 9;
    SREADERROR* = 10;
    SWRITEERROR* = 11;
    SSURFACEFINISHED* = 12; 
    SSURFACETYPEMISMATCH* = 13; 
    SPATTERNTYPEMISMATCH* = 14;
    SINVALIDCONTENT* = 15;
    SINVALIDFORMAT* = 16;
    SINVALIDVISUAL* = 17;
    SFILENOTFOUND* = 18;
    SINVALIDDASH* = 19;
    SINVALIDDSCCOMMENT* = 20;
    SINVALIDINDEX* = 21;
    SCLIPNOTREPRESENTABLE* = 22;
    STEMPFILEERROR* = 23;
    SINVALIDSTRIDE* = 24;
    SFONTTYPEMISMATCH* = 25;
    SUSERFONTIMMUTABLE* = 26;
    SUSERFONTERROR* = 27;
    SNEGATIVECOUNT* = 28;
    SINVALIDCLUSTERS* = 29;
    SINVALIDSLANT* = 30;
    SINVALIDWEIGHT* = 31;
    SINVALIDSIZE* = 32;
    SUSERFONTNOTIMPLEMENTED* = 33;
    SDEVICETYPEMISMATCH* = 34;
    SDEVICEERROR* = 35;
    SINVALIDMESHCONSTRUCTION* = 36;
    SDEVICEFINISHED* = 37;
    SJBIG2GLOBALMISSING* = 38;
    SPNGERROR* = 39;
    SFREETYPEERROR* = 40;
    SWIN32GDIERROR* = 41;
    STAGERROR* = 42;
    SLASTSTATUS* = 43;
    
PROCEDURE -Aincludecairo '#include <cairo/cairo.h>';

PROCEDURE -CairoCreate(target: Surface): Context 'cairo_create(target)';
PROCEDURE Create*(target: Surface): Context;
BEGIN
    RETURN CairoCreate(target);
END Create;

PROCEDURE -CairoReference(cr: Context): Context 'cairo_reference(cr)';
PROCEDURE Reference*(cr: Context): Context;
BEGIN
    RETURN CairoReference(cr);
END Reference;

PROCEDURE -CairoDestroy(cr: Context) 'cairo_destroy(cr)';
PROCEDURE Destroy*(cr: Context);
BEGIN
    CairoDestroy(cr);
END Destroy;

PROCEDURE -CairoGetReferenceCount(cr: Context): LONGINT 'cairo_get_reference_count(cr)';
PROCEDURE GetReferenceCount*(cr: Context): LONGINT;
BEGIN
    RETURN CairoGetReferenceCount(cr);
END GetReferenceCount;

PROCEDURE -CairoSave(cr: Context) 'cairo_save(cr)';
PROCEDURE Save*(cr: Context);
BEGIN
    CairoSave(cr);
END Save;

PROCEDURE -CairoRestore(cr: Context) 'cairo_restore(cr)';
PROCEDURE Restore*(cr: Context);
BEGIN
    CairoRestore(cr);
END Restore;

PROCEDURE -CairoPushGroup(cr: Context) 'cairo_push_group(cr)';
PROCEDURE PushGroup*(cr: Context);
BEGIN
    CairoPushGroup(cr);
END PushGroup;

PROCEDURE -CairoPushGroupWithContent(cr: Context; content: ContentType) 'cairo_push_group_with_content(cr, content)';
PROCEDURE PushGroupWithContent*(cr: Context; content: ContentType);
BEGIN
    CairoPushGroupWithContent(cr, content);
END PushGroupWithContent;

PROCEDURE -CairoPopGroup(cr: Context): Pattern 'cairo_pop_group(cr)';
PROCEDURE PopGroup*(cr: Context): Pattern;
BEGIN
    RETURN CairoPopGroup(cr);
END PopGroup;

PROCEDURE -CairoPopGroupToSource(cr: Context) 'cairo_pop_group_to_source(cr)';
PROCEDURE PopGroupToSource*(cr: Context);
BEGIN
    CairoPopGroupToSource(cr);
END PopGroupToSource;

PROCEDURE -CairoSetOperator(cr: Context; op: OperatorType) 'cairo_set_operator(cr, op)';
PROCEDURE SetOperator*(cr: Context; op: OperatorType);
BEGIN
    CairoSetOperator(cr, op);
END SetOperator;

PROCEDURE -CairoSetSource(cr: Context; source: Pattern) 'cairo_set_source(cr, source)';
PROCEDURE SetSource*(cr: Context; source: Pattern);
BEGIN
    CairoSetSource(cr, source);
END SetSource;

PROCEDURE -CairoSetSourceRGB(cr: Context; red, green, blue: LONGREAL) 'cairo_set_source_rgb(cr, red, green, blue)';
PROCEDURE SetSourceRGB*(cr: Context; red, green, blue: LONGREAL);
BEGIN
    CairoSetSourceRGB(cr, red, green, blue);
END SetSourceRGB;

PROCEDURE -CairoSetSourceRGBA(cr: Context; red, green, blue, alpha: LONGREAL) 'cairo_set_source_rgba(cr, red, green, blue, alpha)';
PROCEDURE SetSourceRGBA*(cr: Context; red, green, blue, alpha: LONGREAL);
BEGIN
    CairoSetSourceRGBA(cr, red, green, blue, alpha);
END SetSourceRGBA;

PROCEDURE -CairoSetSourceSurface(cr: Context; surface: Surface; x, y: LONGREAL) 'cairo_set_source_surface(cr, surface, x, y)';
PROCEDURE SetSourceSurface*(cr: Context; surface: Surface; x, y: LONGREAL);
BEGIN
    CairoSetSourceSurface(cr, surface, x, y);
END SetSourceSurface;

PROCEDURE -CairoSetTolerance(cr: Context; tolerance: LONGREAL) 'cairo_set_tolerance(cr, tolerance)';
PROCEDURE SetTolerance*(cr: Context; tolerance: LONGREAL);
BEGIN
    CairoSetTolerance(cr, tolerance);
END SetTolerance;

PROCEDURE -CairoSetAntialias(cr: Context; antialias: AntialiasType) 'cairo_set_antialias(cr, antialias)';
PROCEDURE SetAntialias*(cr: Context; antialias: AntialiasType);
BEGIN
    CairoSetAntialias(cr, antialias);
END SetAntialias;

PROCEDURE -CairoSetFillRule(cr: Context; fillrule: FillRuleType) 'cairo_set_fill_rule(cr, fillrule)';
PROCEDURE SetFillRule*(cr: Context; fillrule: FillRuleType);
BEGIN
    CairoSetFillRule(cr, fillrule);
END SetFillRule;

PROCEDURE -CairoSetLineWidth(cr: Context; width: LONGREAL) 'cairo_set_line_width(cr, width)';
PROCEDURE SetLineWidth*(cr: Context; width: LONGREAL);
BEGIN
    CairoSetLineWidth(cr, width);
END SetLineWidth;

PROCEDURE -CairoSetLineCap(cr: Context; linecap: LineCapType) 'cairo_set_line_cap(cr, linecap)';
PROCEDURE SetLineCap*(cr: Context; linecap: LineCapType);
BEGIN
    CairoSetLineCap(cr, linecap);
END SetLineCap;

PROCEDURE -CairoSetLineJoin(cr: Context; linejoin: LineJoinType) 'cairo_set_line_join(cr, linejoin)';
PROCEDURE SetLineJoin*(cr: Context; linejoin: LineJoinType);
BEGIN
    CairoSetLineJoin(cr, linejoin);
END SetLineJoin;

PROCEDURE -CairoSetMiterLimit(cr: Context; limit: LONGREAL) 'cairo_set_miter_limit(cr, limit)';
PROCEDURE SetMiterLimit*(cr: Context; limit: LONGREAL);
BEGIN
    CairoSetMiterLimit(cr, limit);
END SetMiterLimit;

PROCEDURE -CairoTranslate(cr: Context; tx, ty: LONGREAL) 'cairo_translate(cr, tx, ty)';
PROCEDURE Translate*(cr: Context; tx, ty: LONGREAL);
BEGIN
    CairoTranslate(cr, tx, ty);
END Translate;

PROCEDURE -CairoScale(cr: Context; sx, sy: LONGREAL) 'cairo_scale(cr, sx, sy)';
PROCEDURE Scale*(cr: Context; sx, sy: LONGREAL);
BEGIN
    CairoScale(cr, sx, sy);
END Scale;

PROCEDURE -CairoRotate(cr: Context; angle: LONGREAL) 'cairo_rotate(cr, angle)';
PROCEDURE Rotate*(cr: Context; angle: LONGREAL);
BEGIN
    CairoRotate(cr, angle);
END Rotate;

PROCEDURE -CairoIdentityMatrix(cr: Context) 'cairo_identity_matrix(cr)';
PROCEDURE IdentityMatrix*(cr: Context);
BEGIN
    CairoIdentityMatrix(cr);
END IdentityMatrix;

PROCEDURE -CairoNewPath(cr: Context) 'cairo_new_path(cr)';
PROCEDURE NewPath*(cr: Context);
BEGIN
    CairoNewPath(cr);
END NewPath;

PROCEDURE -CairoMoveTo(cr: Context; x, y: LONGREAL) 'cairo_move_to(cr, x, y)';
PROCEDURE MoveTo*(cr: Context; x, y: LONGREAL);
BEGIN
    CairoMoveTo(cr, x, y);
END MoveTo;

PROCEDURE -CairoNewSubPath(cr: Context) 'cairo_new_sub_path(cr)';
PROCEDURE NewSubPath*(cr: Context);
BEGIN
    CairoNewSubPath(cr);
END NewSubPath;

PROCEDURE -CairoLineTo(cr: Context; x, y: LONGREAL) 'cairo_line_to(cr, x, y)';
PROCEDURE LineTo*(cr: Context; x, y: LONGREAL);
BEGIN
    CairoLineTo(cr, x, y);
END LineTo;

PROCEDURE -CairoCurveTo(cr: Context; x1, y1, x2, y2, x3, y3: LONGREAL) 'cairo_curve_to(cr, x1, y1, x2, y2, x3, y3)';
PROCEDURE CurveTo*(cr: Context; x1, y1, x2, y2, x3, y3: LONGREAL);
BEGIN
    CairoCurveTo(cr, x1, y1, x2, y2, x3, y3);
END CurveTo;

PROCEDURE -CairoArc(cr: Context; xc, yc, radius, angle1, angle2: LONGREAL) 'cairo_arc(cr, xc, yc, radius, angle1, angle2)';
PROCEDURE Arc*(cr: Context; xc, yc, radius, angle1, angle2: LONGREAL);
BEGIN
    CairoArc(cr, xc, yc, radius, angle1, angle2);
END Arc;

PROCEDURE -CairoArcNegative(cr: Context; xc, yc, radius, angle1, angle2: LONGREAL) 'cairo_arc_negative(cr, xc, yc, radius, angle1, angle2)';
PROCEDURE ArcNegative*(cr: Context; xc, yc, radius, angle1, angle2: LONGREAL);
BEGIN
    CairoArcNegative(cr, xc, yc, radius, angle1, angle2);
END ArcNegative;

PROCEDURE -CairoRelMoveTo(cr: Context; dx, dy: LONGREAL) 'cairo_rel_move_to(cr, dx, dy)';
PROCEDURE RelMoveTo*(cr: Context; dx, dy: LONGREAL);
BEGIN
    CairoRelMoveTo(cr, dx, dy);
END RelMoveTo;

PROCEDURE -CairoRelLineTo(cr: Context; dx, dy: LONGREAL) 'cairo_rel_line_to(cr, dx, dy)';
PROCEDURE RelLineTo*(cr: Context; dx, dy: LONGREAL);
BEGIN
    CairoRelLineTo(cr, dx, dy);
END RelLineTo;

PROCEDURE -CairoRelCurveTo(cr: Context; dx1, dy1, dx2, dy2, dx3, dy3: LONGREAL) 'cairo_rel_curve_to(cr, dx1, dy1, dx2, dy2, dx3, dy3)';
PROCEDURE RelCurveTo*(cr: Context; dx1, dy1, dx2, dy2, dx3, dy3: LONGREAL);
BEGIN
    CairoRelCurveTo(cr, dx1, dy1, dx2, dy2, dx3, dy3);
END RelCurveTo;

PROCEDURE -CairoRectangle(cr: Context; x, y, width, height: LONGREAL) 'cairo_rectangle(cr, x, y, width, height)';
PROCEDURE Rectangle*(cr: Context; x, y, width, height: LONGREAL);
BEGIN
    CairoRectangle(cr, x, y, width, height);
END Rectangle;

PROCEDURE -CairoClosePath(cr: Context) 'cairo_close_path(cr)';
PROCEDURE ClosePath*(cr: Context);
BEGIN
    CairoClosePath(cr);
END ClosePath;

PROCEDURE -CairoPathExtents(cr: Context; VAR x1, y1, x2, y2: LONGREAL) 'cairo_path_extents(cr, x1, y1, x2, y2)';
PROCEDURE PathExtents*(cr: Context; VAR x1, y1, x2, y2: LONGREAL);
BEGIN
    CairoPathExtents(cr, x1, y1, x2, y2);
END PathExtents;

PROCEDURE -CairoPaint(cr: Context) 'cairo_paint(cr)';
PROCEDURE Paint*(cr: Context);
BEGIN
    CairoPaint(cr);
END Paint;

PROCEDURE -CairoPaintWithAlpha(cr: Context; alpha: LONGREAL) 'cairo_paint_with_alpha(cr, alpha)';
PROCEDURE PaintWithAlpha*(cr: Context; alpha: LONGREAL);
BEGIN
    CairoPaintWithAlpha(cr, alpha);
END PaintWithAlpha;

PROCEDURE -CairoMask(cr: Context; pattern: Pattern) 'cairo_mask(cr, pattern)';
PROCEDURE Mask*(cr: Context; pattern: Pattern);
BEGIN
    CairoMask(cr, pattern);
END Mask;

PROCEDURE -CairoMaskSurface(cr: Context; surface: Surface; surfacex, surfacey: LONGREAL) 'cairo_mask_surface(cr, surface, surfacex, surfacey)';
PROCEDURE MaskSurface*(cr: Context; surface: Surface; surfacex, surfacey: LONGREAL);
BEGIN
    CairoMaskSurface(cr, surface, surfacex, surfacey);
END MaskSurface;

PROCEDURE -CairoStroke(cr: Context) 'cairo_stroke(cr)';
PROCEDURE Stroke*(cr: Context);
BEGIN
    CairoStroke(cr);
END Stroke;

PROCEDURE -CairoStrokePreserve(cr: Context) 'cairo_stroke_preserve(cr)';
PROCEDURE StrokePreserve*(cr: Context);
BEGIN
    CairoStrokePreserve(cr);
END StrokePreserve;

PROCEDURE -CairoFill(cr: Context) 'cairo_fill(cr)';
PROCEDURE Fill*(cr: Context);
BEGIN
    CairoFill(cr);
END Fill;

PROCEDURE -CairoFillPreserve(cr: Context) 'cairo_fill_preserve(cr)';
PROCEDURE FillPreserve*(cr: Context);
BEGIN
    CairoFillPreserve(cr);
END FillPreserve;

PROCEDURE -CairoCopyPage(cr: Context) 'cairo_copy_page(cr)';
PROCEDURE CopyPage*(cr: Context);
BEGIN
    CairoCopyPage(cr);
END CopyPage;

PROCEDURE -CairoShowPage(cr: Context) 'cairo_show_page(cr)';
PROCEDURE ShowPage*(cr: Context);
BEGIN
    CairoShowPage(cr);
END ShowPage;

PROCEDURE -CairoResetClip(cr: Context) 'cairo_reset_clip(cr)';
PROCEDURE ResetClip*(cr: Context);
BEGIN
    CairoResetClip(cr);
END ResetClip;

PROCEDURE -CairoClip(cr: Context) 'cairo_clip(cr)';
PROCEDURE Clip*(cr: Context);
BEGIN
    CairoClip(cr);
END Clip;

PROCEDURE -CairoClipPreserve(cr: Context) 'cairo_clip_preserve(cr)';
PROCEDURE ClipPreserve*(cr: Context);
BEGIN
    CairoClipPreserve(cr);
END ClipPreserve;

PROCEDURE -CairoSelectFontFace(cr: Context; family: ARRAY OF CHAR; slant: FontSlantType; weight: FontWeightType) 'cairo_select_font_face(cr, family, slant, weight)';
PROCEDURE SelectFontFace*(cr: Context; family: ARRAY OF CHAR; slant: FontSlantType; weight: FontWeightType);
BEGIN
    CairoSelectFontFace(cr, family, slant, weight);
END SelectFontFace;

PROCEDURE -CairoSetFontSize(cr: Context; size: LONGREAL) 'cairo_set_font_size(cr, size)';
PROCEDURE SetFontSize*(cr: Context; size: LONGREAL);
BEGIN
    CairoSetFontSize(cr, size);
END SetFontSize;

PROCEDURE -CairoShowText(cr: Context; utf8: ARRAY OF CHAR) 'cairo_show_text(cr, utf8)';
PROCEDURE ShowText*(cr: Context; utf8: ARRAY OF CHAR);
BEGIN
    CairoShowText(cr, utf8);
END ShowText;

PROCEDURE -CairoGetOperator(cr: Context): OperatorType 'cairo_get_operator(cr)';
PROCEDURE GetOperator*(cr: Context): OperatorType;
BEGIN
    RETURN CairoGetOperator(cr);
END GetOperator;

PROCEDURE -CairoGetSource(cr: Context): Pattern 'cairo_get_source(cr)';
PROCEDURE GetSource*(cr: Context): Pattern;
BEGIN
    RETURN CairoGetSource(cr);
END GetSource;

PROCEDURE -CairoGetTolerance(cr: Context): LONGREAL 'cairo_get_tolerance(cr)';
PROCEDURE GetTolerance*(cr: Context): LONGREAL;
BEGIN
    RETURN CairoGetTolerance(cr);
END GetTolerance;

PROCEDURE -CairoGetAntialias(cr: Context): AntialiasType 'cairo_get_antialias(cr)';
PROCEDURE GetAntialias*(cr: Context): AntialiasType;
BEGIN
    RETURN CairoGetAntialias(cr);
END GetAntialias;

PROCEDURE -CairoGetFillRule(cr: Context): FillRuleType 'cairo_get_fill_rule(cr)';
PROCEDURE GetFillRule*(cr: Context): FillRuleType;
BEGIN
    RETURN CairoGetFillRule(cr);
END GetFillRule;

PROCEDURE -CairoGetLineWidth(cr: Context): LONGREAL 'cairo_get_line_width(cr)';
PROCEDURE GetLineWidth*(cr: Context): LONGREAL;
BEGIN
    RETURN CairoGetLineWidth(cr);
END GetLineWidth;

PROCEDURE -CairoGetLineCap(cr: Context): LineCapType 'cairo_get_line_cap(cr)';
PROCEDURE GetLineCap*(cr: Context): LineCapType;
BEGIN
    RETURN CairoGetLineCap(cr);
END GetLineCap;

PROCEDURE -CairoGetLineJoin(cr: Context): LineJoinType 'cairo_get_line_join(cr)';
PROCEDURE GetLineJoin*(cr: Context): LineJoinType;
BEGIN
    RETURN CairoGetLineJoin(cr);
END GetLineJoin;

PROCEDURE -CairoGetMiterLimit(cr: Context): LONGREAL 'cairo_get_miter_limit(cr)';
PROCEDURE GetMiterLimit*(cr: Context): LONGREAL;
BEGIN
    RETURN CairoGetMiterLimit(cr);
END GetMiterLimit;

PROCEDURE -CairoGetDashCount(cr: Context): LONGINT 'cairo_get_dash_count(cr)';
PROCEDURE GetDashCount*(cr: Context): LONGINT;
BEGIN
    RETURN CairoGetDashCount(cr);
END GetDashCount;

PROCEDURE -CairoGetTarget(cr: Context): Surface 'cairo_get_target(cr)';
PROCEDURE GetTarget*(cr: Context): Surface;
BEGIN
    RETURN CairoGetTarget(cr);
END GetTarget;

PROCEDURE -CairoGetGroupTarget(cr: Context): Surface 'cairo_get_group_target(cr)';
PROCEDURE GetGroupTarget*(cr: Context): Surface;
BEGIN
    RETURN CairoGetGroupTarget(cr);
END GetGroupTarget;

PROCEDURE -CairoCopyPath(cr: Context): Path 'cairo_copy_path(cr)';
PROCEDURE CopyPath*(cr: Context): Path;
BEGIN
    RETURN CairoCopyPath(cr);
END CopyPath;

PROCEDURE -CairoCopyPathFlat(cr: Context): Path 'cairo_copy_path_flat(cr)';
PROCEDURE CopyPathFlat*(cr: Context): Path;
BEGIN
    RETURN CairoCopyPathFlat(cr);
END CopyPathFlat;

PROCEDURE -CairoAppendPath(cr: Context; path: Path) 'cairo_append_path(cr, path)';
PROCEDURE AppendPath*(cr: Context; path: Path);
BEGIN
    CairoAppendPath(cr, path);
END AppendPath;

PROCEDURE -CairoPathDestroy(path: Path) 'cairo_path_destroy(path)';
PROCEDURE PathDestroy*(path: Path);
BEGIN
    CairoPathDestroy(path);
END PathDestroy;

PROCEDURE -CairoStatus(cr: Context): StatusType 'cairo_status(cr)';
PROCEDURE Status*(cr: Context): StatusType;
BEGIN
    RETURN CairoStatus(cr);
END Status;

PROCEDURE -CairoSurfaceCreateSimilar(other: Surface; content: ContentType; width, height: LONGINT): Surface 'cairo_surface_create_similar(other, content, width, height)';
PROCEDURE SurfaceCreateSimilar*(other: Surface; content: ContentType; width, height: LONGINT): Surface;
BEGIN
    RETURN CairoSurfaceCreateSimilar(other, content, width, height);
END SurfaceCreateSimilar;

PROCEDURE -CairoSurfaceCreateSimilarImage(other: Surface; format: FormatType; width, height: LONGINT): Surface 'cairo_surface_create_similar_image(other, format, width, height)';
PROCEDURE SurfaceCreateSimilarImage*(other: Surface; format: FormatType; width, height: LONGINT): Surface;
BEGIN
    RETURN CairoSurfaceCreateSimilarImage(other, format, width, height);
END SurfaceCreateSimilarImage;

PROCEDURE -CairoSurfaceUnmapImage(surface, image: Surface) 'cairo_surface_unmap_image(surface, image)';
PROCEDURE SurfaceUnmapImage*(surface, image: Surface);
BEGIN
    CairoSurfaceUnmapImage(surface, image);
END SurfaceUnmapImage;

PROCEDURE -CairoSurfaceCreateForRectangle(target: Surface; x, y, width, height: LONGREAL): Surface 'cairo_surface_create_for_rectangle(target, x, y, width, height)';
PROCEDURE SurfaceCreateForRectangle*(target: Surface; x, y, width, height: LONGREAL): Surface;
BEGIN
    RETURN CairoSurfaceCreateForRectangle(target, x, y, width, height);
END SurfaceCreateForRectangle;

PROCEDURE -CairoSurfaceReference(surface: Surface): Surface 'cairo_surface_reference(surface)';
PROCEDURE SurfaceReference*(surface: Surface): Surface;
BEGIN
    RETURN CairoSurfaceReference(surface);
END SurfaceReference;

PROCEDURE -CairoSurfaceFinish(surface: Surface) 'cairo_surface_finish(surface)';
PROCEDURE SurfaceFinish*(surface: Surface);
BEGIN
    CairoSurfaceFinish(surface);
END SurfaceFinish;

PROCEDURE -CairoSurfaceDestroy(surface: Surface) 'cairo_surface_destroy(surface)';
PROCEDURE SurfaceDestroy*(surface: Surface);
BEGIN
    CairoSurfaceDestroy(surface);
END SurfaceDestroy;

PROCEDURE -CairoSurfaceGetReferenceCount(surface: Surface): LONGINT 'cairo_surface_get_reference_count(surface)';
PROCEDURE SurfaceGetReferenceCount*(surface: Surface): LONGINT;
BEGIN
    RETURN CairoSurfaceGetReferenceCount(surface);
END SurfaceGetReferenceCount;

PROCEDURE -CairoSurfaceStatus(surface: Surface): StatusType 'cairo_surface_status(surface)';
PROCEDURE SurfaceStatus*(surface: Surface): StatusType;
BEGIN
    RETURN CairoSurfaceStatus(surface);
END SurfaceStatus;

PROCEDURE -CairoSurfaceGetType(surface: Surface): SurfaceType 'cairo_surface_get_type(surface)';
PROCEDURE SurfaceGetType*(surface: Surface): SurfaceType;
BEGIN
    RETURN CairoSurfaceGetType(surface);
END SurfaceGetType;

PROCEDURE -CairoSurfaceGetContent(surface: Surface): ContentType 'cairo_surface_get_content(surface)';
PROCEDURE SurfaceGetContent*(surface: Surface): ContentType;
BEGIN
    RETURN CairoSurfaceGetContent(surface);
END SurfaceGetContent;

PROCEDURE -CairoSurfaceWriteToPNG(surface: Surface; filename: ARRAY OF CHAR): StatusType 'cairo_surface_write_to_png(surface, filename)';
PROCEDURE SurfaceWriteToPNG*(surface: Surface; filename: ARRAY OF CHAR): StatusType;
BEGIN
    RETURN CairoSurfaceWriteToPNG(surface, filename);
END SurfaceWriteToPNG;

PROCEDURE -CairoSurfaceFlush(surface: Surface) 'cairo_surface_flush(surface)';
PROCEDURE SurfaceFlush*(surface: Surface);
BEGIN
    CairoSurfaceFlush(surface);
END SurfaceFlush;

PROCEDURE -CairoSurfaceMarkDirty(surface: Surface) 'cairo_surface_mark_dirty(surface)';
PROCEDURE SurfaceMarkDirty*(surface: Surface);
BEGIN
    CairoSurfaceMarkDirty(surface);
END SurfaceMarkDirty;

PROCEDURE -CairoSurfaceMarkDirtyRectangle(surface: Surface; x, y, width, height: LONGINT) 'cairo_surface_mark_dirty_rectangle(surface, x, y, width, height)';
PROCEDURE SurfaceMarkDirtyRectangle*(surface: Surface; x, y, width, height: LONGINT);
BEGIN
    CairoSurfaceMarkDirtyRectangle(surface, x, y, width, height);
END SurfaceMarkDirtyRectangle;

PROCEDURE -CairoSurfaceCopyPage(surface: Surface) 'cairo_surface_copy_page(surface)';
PROCEDURE SurfaceCopyPage*(surface: Surface);
BEGIN
    CairoSurfaceCopyPage(surface);
END SurfaceCopyPage;

PROCEDURE -CairoSurfaceShowPage(surface: Surface) 'cairo_surface_show_page(surface)';
PROCEDURE SurfaceShowPage*(surface: Surface);
BEGIN
    CairoSurfaceShowPage(surface);
END SurfaceShowPage;

PROCEDURE -CairoImageSurfaceCreate(format: FormatType; width, height: LONGINT): Surface 'cairo_image_surface_create(format, width, height)';
PROCEDURE ImageSurfaceCreate*(format: FormatType; width, height: LONGINT): Surface;
BEGIN
    RETURN CairoImageSurfaceCreate(format, width, height);
END ImageSurfaceCreate;

PROCEDURE -CairoFormatStrideForWidth(format: FormatType; width: LONGINT): LONGINT 'cairo_format_stride_for_width(format, width)';
PROCEDURE FormatStrideForWidth*(format: FormatType; width: LONGINT): LONGINT;
BEGIN
    RETURN CairoFormatStrideForWidth(format, width);
END FormatStrideForWidth;

PROCEDURE -CairoImageSurfaceGetFormat(surface: Surface): FormatType 'cairo_image_surface_get_format(surface)';
PROCEDURE ImageSurfaceGetFormat*(surface: Surface): FormatType;
BEGIN
    RETURN CairoImageSurfaceGetFormat(surface);
END ImageSurfaceGetFormat;

PROCEDURE -CairoImageSurfaceGetWidth(surface: Surface): LONGINT 'cairo_image_surface_get_width(surface)';
PROCEDURE ImageSurfaceGetWidth*(surface: Surface): LONGINT;
BEGIN
    RETURN CairoImageSurfaceGetWidth(surface);
END ImageSurfaceGetWidth;

PROCEDURE -CairoImageSurfaceGetHeight(surface: Surface): LONGINT 'cairo_image_surface_get_height(surface)';
PROCEDURE ImageSurfaceGetHeight*(surface: Surface): LONGINT;
BEGIN
    RETURN CairoImageSurfaceGetHeight(surface);
END ImageSurfaceGetHeight;

PROCEDURE -CairoImageSurfaceGetStride(surface: Surface): LONGINT 'cairo_image_surface_get_stride(surface)';
PROCEDURE ImageSurfaceGetStride*(surface: Surface): LONGINT;
BEGIN
    RETURN CairoImageSurfaceGetStride(surface);
END ImageSurfaceGetStride;

PROCEDURE -CairoImageSurfaceCreateFromPNG(filename: ARRAY OF CHAR): Surface 'cairo_image_surface_create_from_png(filename)';
PROCEDURE ImageSurfaceCreateFromPNG*(filename: ARRAY OF CHAR): Surface;
BEGIN
    RETURN CairoImageSurfaceCreateFromPNG(filename);
END ImageSurfaceCreateFromPNG;

PROCEDURE -CairoPatternCreateRGB(red, green, blue: LONGREAL): Pattern 'cairo_pattern_create_rgb(red, green, blue)';
PROCEDURE PatternCreateRGB*(red, green, blue: LONGREAL): Pattern;
BEGIN
    RETURN CairoPatternCreateRGB(red, green, blue);
END PatternCreateRGB;

PROCEDURE -CairoPatternCreateRGBA(red, green, blue, alpha: LONGREAL): Pattern 'cairo_pattern_create_rgba(red, green, blue, alpha)';
PROCEDURE PatternCreateRGBA*(red, green, blue, alpha: LONGREAL): Pattern;
BEGIN
    RETURN CairoPatternCreateRGBA(red, green, blue, alpha);
END PatternCreateRGBA;

PROCEDURE -CairoPatternCreateForSurface(surface: Surface): Pattern 'cairo_pattern_create_for_surface(surface)';
PROCEDURE PatternCreateForSurface*(surface: Surface): Pattern;
BEGIN
    RETURN CairoPatternCreateForSurface(surface);
END PatternCreateForSurface;

PROCEDURE -CairoPatternCreateLinear(x0, y0, x1, y1: LONGREAL): Pattern 'cairo_pattern_create_linear(x0, y0, x1, y1)';
PROCEDURE PatternCreateLinear*(x0, y0, x1, y1: LONGREAL): Pattern;
BEGIN
    RETURN CairoPatternCreateLinear(x0, y0, x1, y1);
END PatternCreateLinear;

PROCEDURE -CairoPatternCreateRadial(cx0, cy0, radius0, cx1, cy1, radius1: LONGREAL): Pattern 'cairo_pattern_create_radial(cx0, cy0, radius0, cx1, cy1, radius1)';
PROCEDURE PatternCreateRadial*(cx0, cy0, radius0, cx1, cy1, radius1: LONGREAL): Pattern;
BEGIN
    RETURN CairoPatternCreateRadial(cx0, cy0, radius0, cx1, cy1, radius1);
END PatternCreateRadial;

PROCEDURE -CairoPatternCreateMesh(): Pattern 'cairo_pattern_create_mesh()';
PROCEDURE PatternCreateMesh*(): Pattern;
BEGIN
    RETURN CairoPatternCreateMesh();
END PatternCreateMesh;

PROCEDURE -CairoPatternReference(pattern: Pattern): Pattern 'cairo_pattern_reference(pattern)';
PROCEDURE PatternReference*(pattern: Pattern): Pattern;
BEGIN
    RETURN CairoPatternReference(pattern);
END PatternReference;

PROCEDURE -CairoPatternDestroy(pattern: Pattern) 'cairo_pattern_destroy(pattern)';
PROCEDURE PatternDestroy*(pattern: Pattern);
BEGIN
    CairoPatternDestroy(pattern);
END PatternDestroy;

PROCEDURE -CairoPatternGetReferenceCount(pattern: Pattern): LONGINT 'cairo_pattern_get_reference_count(pattern)';
PROCEDURE PatternGetReferenceCount*(pattern: Pattern): LONGINT;
BEGIN
    RETURN CairoPatternGetReferenceCount(pattern);
END PatternGetReferenceCount;

PROCEDURE -CairoPatternStatus(pattern: Pattern): StatusType 'cairo_pattern_status(pattern)';
PROCEDURE PatternStatus*(pattern: Pattern): StatusType;
BEGIN
    RETURN CairoPatternStatus(pattern);
END PatternStatus;

PROCEDURE -CairoPatternGetType(pattern: Pattern): PatternType 'cairo_pattern_get_type(pattern)';
PROCEDURE PatternGetType*(pattern: Pattern): PatternType;
BEGIN
    RETURN CairoPatternGetType(pattern);
END PatternGetType;

PROCEDURE -CairoPatternAddColorStopRGB(pattern: Pattern; offset, red, green, blue: LONGREAL) 'cairo_pattern_add_color_stop_rgb(pattern, offset, red, green, blue)';
PROCEDURE PatternAddColorStopRGB*(pattern: Pattern; offset, red, green, blue: LONGREAL);
BEGIN
    CairoPatternAddColorStopRGB(pattern, offset, red, green, blue);
END PatternAddColorStopRGB;

PROCEDURE -CairoPatternAddColorStopRGBA(pattern: Pattern; offset, red, green, blue, alpha: LONGREAL) 'cairo_pattern_add_color_stop_rgba(pattern, offset, red, green, blue, alpha)';
PROCEDURE PatternAddColorStopRGBA*(pattern: Pattern; offset, red, green, blue, alpha: LONGREAL);
BEGIN
    CairoPatternAddColorStopRGBA(pattern, offset, red, green, blue, alpha);
END PatternAddColorStopRGBA;

PROCEDURE -CairoPatternSetExtend(pattern: Pattern; extend: ExtendType) 'cairo_pattern_set_extend(pattern, extend)';
PROCEDURE PatternSetExtend*(pattern: Pattern; extend: ExtendType);
BEGIN
    CairoPatternSetExtend(pattern, extend);
END PatternSetExtend;

PROCEDURE -CairoPatternGetExtend(pattern: Pattern): ExtendType 'cairo_pattern_get_extend(pattern)';
PROCEDURE PatternGetExtend*(pattern: Pattern): ExtendType;
BEGIN
    RETURN CairoPatternGetExtend(pattern);
END PatternGetExtend;

PROCEDURE -CairoPatternSetFilter(pattern: Pattern; filter: FilterType) 'cairo_pattern_set_filter(pattern, filter)';
PROCEDURE PatternSetFilter*(pattern: Pattern; filter: FilterType);
BEGIN
    CairoPatternSetFilter(pattern, filter);
END PatternSetFilter;

PROCEDURE -CairoPatternGetFilter(pattern: Pattern): FilterType 'cairo_pattern_get_filter(pattern)';
PROCEDURE PatternGetFilter*(pattern: Pattern): FilterType;
BEGIN
    RETURN CairoPatternGetFilter(pattern);
END PatternGetFilter;

PROCEDURE -CairoVersion(): LONGINT 'cairo_version()';
PROCEDURE Version*(): LONGINT;
BEGIN
    RETURN CairoVersion();
END Version;

END Cairo.
