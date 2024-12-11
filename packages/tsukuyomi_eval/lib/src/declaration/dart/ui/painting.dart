part of declaration.dart.ui;

DartClass get _$Paint => DartClass<Paint>(($) => '''
class Paint {
  // ${$.empty('Paint.new', () => Paint.new)}
  external Paint();

  // ${$.debug('isAntiAlias', ($, $$) => $.isAntiAlias = $$)}
  external bool get isAntiAlias;
  external set isAntiAlias(bool value);

  // ${$.debug('color', ($, $$) => $.color = $$)}
  external Color get color;
  external set color(Color value);

  // ${$.debug('blendMode', ($, $$) => $.blendMode = $$)}
  external BlendMode get blendMode;
  external set blendMode(BlendMode value);

  // ${$.debug('style', ($, $$) => $.style = $$)}
  external PaintingStyle get style;
  external set style(PaintingStyle value);

  // ${$.debug('strokeWidth', ($, $$) => $.strokeWidth = $$)}
  external double get strokeWidth;
  external set strokeWidth(double value);

  // ${$.debug('strokeCap', ($, $$) => $.strokeCap = $$)}
  external StrokeCap get strokeCap;
  external set strokeCap(StrokeCap value);

  // ${$.debug('strokeJoin', ($, $$) => $.strokeJoin = $$)}
  external StrokeJoin get strokeJoin;
  external set strokeJoin(StrokeJoin value);

  // ${$.debug('strokeMiterLimit', ($, $$) => $.strokeMiterLimit = $$)}
  external double get strokeMiterLimit;
  external set strokeMiterLimit(double value);

  // ${$.debug('maskFilter', ($, $$) => $.maskFilter = $$)}
  external MaskFilter? get maskFilter;
  external set maskFilter(MaskFilter? value);

  // ${$.debug('filterQuality', ($, $$) => $.filterQuality = $$)}
  external FilterQuality get filterQuality;
  external set filterQuality(FilterQuality value);

  // ${$.debug('shader', ($, $$) => $.shader = $$)}
  external Shader? get shader;
  external set shader(Shader? value);

  // ${$.debug('colorFilter', ($, $$) => $.colorFilter = $$)}
  external ColorFilter? get colorFilter;
  external set colorFilter(ColorFilter? value);

  // ${$.debug('imageFilter', ($, $$) => $.imageFilter = $$)}
  external ImageFilter? get imageFilter;
  external set imageFilter(ImageFilter? value);

  // ${$.debug('invertColors', ($, $$) => $.invertColors = $$)}
  external bool get invertColors;
  external set invertColors(bool value);

  // ${$.empty('Paint.enableDithering', () => Paint.enableDithering)}
  external static bool enableDithering;

  // ${$.debug('toString', ($, $$) => $.toString)}
  external String toString();
}
''');

DartClass get _$Image => DartClass<Image>(($) => '''
class Image {
  // ${$.empty('Image.onCreate', () => Image.onCreate)}
  static ImageEventCallback? onCreate;

  // ${$.empty('Image.onDispose', () => Image.onDispose)}
  static ImageEventCallback? onDispose;

  // ${$.debug('width', ($, $$) => $.width)}
  external final int width;

  // ${$.debug('height', ($, $$) => $.height)}
  external final int height;

  // ${$.debug('dispose', ($, $$) => $.dispose)}
  external void dispose();

  // ${$.debug('debugDisposed', ($, $$) => $.debugDisposed)}
  external bool get debugDisposed;

  // ${$.debug('toByteData', ($, $$) => $.toByteData)}
  external Future<ByteData?> toByteData({ImageByteFormat format = ImageByteFormat.rawRgba});

  // ${$.debug('colorSpace', ($, $$) => $.colorSpace)}
  external ColorSpace get colorSpace;

  // ${$.debug('debugGetOpenHandleStackTraces', ($, $$) => $.debugGetOpenHandleStackTraces)}
  external List<StackTrace>? debugGetOpenHandleStackTraces();

  // ${$.debug('clone', ($, $$) => $.clone)}
  external Image clone();

  // ${$.debug('isCloneOf', ($, $$) => $.isCloneOf)}
  external bool isCloneOf(Image other);

  // ${$.debug('toString', ($, $$) => $.toString)}
  String toString();
}
''');

DartClass get _$Canvas => DartClass<Canvas>(($) => '''
abstract class Canvas {
  // ${$.empty('Canvas.new', () => Canvas.new)}
  external factory Canvas(PictureRecorder recorder, [Rect? cullRect]);

  // ${$.debug('save', ($, $$) => $.save)}
  void save();

  // ${$.debug('saveLayer', ($, $$) => $.saveLayer)}
  void saveLayer(Rect? bounds, Paint paint);

  // ${$.debug('restore', ($, $$) => $.restore)}
  void restore();

  // ${$.debug('restoreToCount', ($, $$) => $.restoreToCount)}
  void restoreToCount(int count);

  // ${$.debug('getSaveCount', ($, $$) => $.getSaveCount)}
  int getSaveCount();

  // ${$.debug('translate', ($, $$) => $.translate)}
  void translate(double dx, double dy);

  // ${$.debug('scale', ($, $$) => $.scale)}
  void scale(double sx, [double? sy]);

  // ${$.debug('rotate', ($, $$) => $.rotate)}
  void rotate(double radians);

  // ${$.debug('skew', ($, $$) => $.skew)}
  void skew(double sx, double sy);

  // ${$.debug('transform', ($, $$) => $.transform)}
  void transform(Float64List matrix4);

  // ${$.debug('getTransform', ($, $$) => $.getTransform)}
  Float64List getTransform();

  // ${$.debug('clipRect', ($, $$) => $.clipRect)}
  void clipRect(Rect rect, {ClipOp clipOp = ClipOp.intersect, bool doAntiAlias = true});

  // ${$.debug('clipRRect', ($, $$) => $.clipRRect)}
  void clipRRect(RRect rrect, {bool doAntiAlias = true});

  // ${$.debug('clipPath', ($, $$) => $.clipPath)}
  void clipPath(Path path, {bool doAntiAlias = true});

  // ${$.debug('getLocalClipBounds', ($, $$) => $.getLocalClipBounds)}
  Rect getLocalClipBounds();

  // ${$.debug('getDestinationClipBounds', ($, $$) => $.getDestinationClipBounds)}
  Rect getDestinationClipBounds();

  // ${$.debug('drawColor', ($, $$) => $.drawColor)}
  void drawColor(Color color, BlendMode blendMode);

  // ${$.debug('drawLine', ($, $$) => $.drawLine)}
  void drawLine(Offset p1, Offset p2, Paint paint);

  // ${$.debug('drawPaint', ($, $$) => $.drawPaint)}
  void drawPaint(Paint paint);

  // ${$.debug('drawRect', ($, $$) => $.drawRect)}
  void drawRect(Rect rect, Paint paint);

  // ${$.debug('drawRRect', ($, $$) => $.drawRRect)}
  void drawRRect(RRect rrect, Paint paint);

  // ${$.debug('drawDRRect', ($, $$) => $.drawDRRect)}
  void drawDRRect(RRect outer, RRect inner, Paint paint);

  // ${$.debug('drawOval', ($, $$) => $.drawOval)}
  void drawOval(Rect rect, Paint paint);

  // ${$.debug('drawCircle', ($, $$) => $.drawCircle)}
  void drawCircle(Offset c, double radius, Paint paint);

  // ${$.debug('drawArc', ($, $$) => $.drawArc)}
  void drawArc(Rect rect, double startAngle, double sweepAngle, bool useCenter, Paint paint);

  // ${$.debug('drawPath', ($, $$) => $.drawPath)}
  void drawPath(Path path, Paint paint);

  // ${$.debug('drawImage', ($, $$) => $.drawImage)}
  void drawImage(Image image, Offset offset, Paint paint);

  // ${$.debug('drawImageRect', ($, $$) => $.drawImageRect)}
  void drawImageRect(Image image, Rect src, Rect dst, Paint paint);

  // ${$.debug('drawImageNine', ($, $$) => $.drawImageNine)}
  void drawImageNine(Image image, Rect center, Rect dst, Paint paint);

  // ${$.debug('drawPicture', ($, $$) => $.drawPicture)}
  void drawPicture(Picture picture);

  // ${$.debug('drawParagraph', ($, $$) => $.drawParagraph)}
  void drawParagraph(Paragraph paragraph, Offset offset);

  // ${$.debug('drawPoints', ($, $$) => $.drawPoints)}
  void drawPoints(PointMode pointMode, List<Offset> points, Paint paint);

  // ${$.debug('drawRawPoints', ($, $$) => $.drawRawPoints)}
  void drawRawPoints(PointMode pointMode, Float32List points, Paint paint);

  // ${$.debug('drawVertices', ($, $$) => $.drawVertices)}
  void drawVertices(Vertices vertices, BlendMode blendMode, Paint paint);

  // ${$.debug('drawAtlas', ($, $$) => $.drawAtlas)}
  void drawAtlas(
    Image atlas,
    List<RSTransform> transforms,
    List<Rect> rects,
    List<Color>? colors,
    BlendMode? blendMode,
    Rect? cullRect,
    Paint paint,
  );

  // ${$.debug('drawRawAtlas', ($, $$) => $.drawRawAtlas)}
  void drawRawAtlas(
    Image atlas,
    Float32List rstTransforms,
    Float32List rects,
    Int32List? colors,
    BlendMode? blendMode,
    Rect? cullRect,
    Paint paint,
  );

  // ${$.debug('drawShadow', ($, $$) => $.drawShadow)}
  void drawShadow(Path path, Color color, double elevation, bool transparentOccluder);
}
''');

DartClass get _$Picture => DartClass<Picture>(($) => '''
abstract class Picture {
  // ${$.empty('Picture.onCreate', () => Picture.onCreate)}
  static PictureEventCallback? onCreate;

  // ${$.empty('Picture.onDispose', () => Picture.onDispose)}
  static PictureEventCallback? onDispose;

  // ${$.debug('toImage', ($, $$) => $.toImage)}
  Future<Image> toImage(int width, int height);

  // ${$.debug('toImageSync', ($, $$) => $.toImageSync)}
  Image toImageSync(int width, int height);

  // ${$.debug('dispose', ($, $$) => $.dispose)}
  void dispose();

  // ${$.debug('debugDisposed', ($, $$) => $.debugDisposed)}
  bool get debugDisposed;

  // ${$.debug('approximateBytesUsed', ($, $$) => $.approximateBytesUsed)}
  int get approximateBytesUsed;
}
''');

DartClass get _$PictureRecorder => DartClass<PictureRecorder>(($) => '''
abstract class PictureRecorder {
  // ${$.empty('PictureRecorder.new', () => PictureRecorder.new)}
  external factory PictureRecorder();

  // ${$.debug('isRecording', ($, $$) => $.isRecording)}
  bool get isRecording;

  // ${$.debug('endRecording', ($, $$) => $.endRecording)}
  Picture endRecording();
}
''');

List<DartDeclaration> get $painting {
  return [
    _$Paint,
    _$Image,
    _$Canvas,
    _$Picture,
    _$PictureRecorder,
  ];
}
