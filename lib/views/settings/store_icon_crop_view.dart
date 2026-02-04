import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../widgets/common_header.dart';
import '../../widgets/custom_button.dart';

class StoreIconCropView extends StatefulWidget {
  final Uint8List imageBytes;

  const StoreIconCropView({
    super.key,
    required this.imageBytes,
  });

  @override
  State<StoreIconCropView> createState() => _StoreIconCropViewState();
}

class _StoreIconCropViewState extends State<StoreIconCropView> {
  final TransformationController _controller = TransformationController();
  ui.Image? _image;
  Size? _viewerSize;
  bool _isSaving = false;
  bool _didInitTransform = false;

  static const double _cropScale = 0.82;
  static const double _maxScale = 6.0;
  double _minScale = 1.0;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadImage() async {
    final codec = await ui.instantiateImageCodec(widget.imageBytes);
    final frame = await codec.getNextFrame();
    if (!mounted) return;
    setState(() {
      _image = frame.image;
      _didInitTransform = false;
    });
    if (_viewerSize != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _resetTransform());
    }
  }

  void _resetTransform() {
    if (_image == null || _viewerSize == null) return;
    final viewer = _viewerSize!;
    final cropSize = viewer.shortestSide * _cropScale;
    final imageWidth = _image!.width.toDouble();
    final imageHeight = _image!.height.toDouble();
    final scale = math.max(cropSize / imageWidth, cropSize / imageHeight);
    _minScale = scale;
    final dx = (viewer.width - imageWidth * scale) / 2;
    final dy = (viewer.height - imageHeight * scale) / 2;
    _controller.value = Matrix4.identity()
      ..translate(dx, dy)
      ..scale(scale);
    _didInitTransform = true;
    setState(() {});
    _clampTransform();
  }

  void _clampTransform() {
    if (_image == null || _viewerSize == null) return;
    final viewer = _viewerSize!;
    final cropSize = viewer.shortestSide * _cropScale;
    final cropRect = Rect.fromCenter(
      center: viewer.center(Offset.zero),
      width: cropSize,
      height: cropSize,
    );
    Matrix4 matrix = _controller.value.clone();
    double scale = matrix.getMaxScaleOnAxis();
    if (scale < _minScale) {
      scale = _minScale;
    }
    final translation = matrix.getTranslation();
    double tx = translation.x;
    double ty = translation.y;
    final imageWidth = _image!.width.toDouble() * scale;
    final imageHeight = _image!.height.toDouble() * scale;
    final transformedRect = Rect.fromLTWH(tx, ty, imageWidth, imageHeight);

    double dx = 0;
    double dy = 0;
    if (transformedRect.left > cropRect.left) {
      dx = cropRect.left - transformedRect.left;
    } else if (transformedRect.right < cropRect.right) {
      dx = cropRect.right - transformedRect.right;
    }
    if (transformedRect.top > cropRect.top) {
      dy = cropRect.top - transformedRect.top;
    } else if (transformedRect.bottom < cropRect.bottom) {
      dy = cropRect.bottom - transformedRect.bottom;
    }

    if (dx != 0 || dy != 0 || scale != _controller.value.getMaxScaleOnAxis()) {
      tx += dx;
      ty += dy;
      _controller.value = Matrix4.identity()
        ..translate(tx, ty)
        ..scale(scale);
      setState(() {});
    }
  }

  Future<void> _onSave() async {
    if (_image == null || _viewerSize == null || _isSaving) return;
    setState(() {
      _isSaving = true;
    });
    try {
      final cropped = await _cropImage();
      if (!mounted) return;
      Navigator.of(context).pop(cropped);
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<Uint8List> _cropImage() async {
    final viewer = _viewerSize!;
    final cropSize = viewer.shortestSide * _cropScale;
    final cropRect = Rect.fromCenter(
      center: viewer.center(Offset.zero),
      width: cropSize,
      height: cropSize,
    );
    final inverse = Matrix4.inverted(_controller.value);
    final topLeft = MatrixUtils.transformPoint(inverse, cropRect.topLeft);
    final bottomRight = MatrixUtils.transformPoint(inverse, cropRect.bottomRight);
    Rect srcRect = Rect.fromPoints(topLeft, bottomRight);
    final imageRect = Rect.fromLTWH(
      0,
      0,
      _image!.width.toDouble(),
      _image!.height.toDouble(),
    );
    srcRect = srcRect.intersect(imageRect);

    const int outputSize = 512;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.high;
    canvas.drawImageRect(
      _image!,
      srcRect,
      Rect.fromLTWH(0, 0, outputSize.toDouble(), outputSize.toDouble()),
      paint,
    );
    final outputImage = await recorder.endRecording().toImage(outputSize, outputSize);
    final byteData = await outputImage.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;
    return Scaffold(
      appBar: const CommonHeader(title: 'アイコン調整'),
      backgroundColor: Colors.black,
      body: SafeArea(
        child: image == null
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : Column(
                children: [
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final size = math.min(constraints.maxWidth, constraints.maxHeight);
                        _viewerSize = Size(size, size);
                        if (!_didInitTransform && image != null) {
                          WidgetsBinding.instance.addPostFrameCallback((_) => _resetTransform());
                        }
                        return Center(
                          child: SizedBox(
                            width: size,
                            height: size,
                            child: Stack(
                              children: [
                                InteractiveViewer(
                                  transformationController: _controller,
                                  minScale: _minScale,
                                  maxScale: _maxScale,
                                  boundaryMargin: const EdgeInsets.all(1000),
                                  constrained: false,
                                  onInteractionEnd: (_) => _clampTransform(),
                                  child: SizedBox(
                                    width: image.width.toDouble(),
                                    height: image.height.toDouble(),
                                    child: RawImage(
                                      image: image,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned.fill(
                                  child: IgnorePointer(
                                    child: CustomPaint(
                                      painter: _CropOverlayPainter(
                                        cropScale: _cropScale,
                                        borderColor: Colors.white.withOpacity(0.9),
                                        maskColor: Colors.black.withOpacity(0.55),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: CustomButton(
                      text: 'この範囲で保存',
                      onPressed: _onSave,
                      isLoading: _isSaving,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
      ),
    );
  }

}

class _CropOverlayPainter extends CustomPainter {
  final double cropScale;
  final Color borderColor;
  final Color maskColor;

  _CropOverlayPainter({
    required this.cropScale,
    required this.borderColor,
    required this.maskColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final overlayPaint = Paint()..color = maskColor;
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final cropSize = size.shortestSide * cropScale;
    final rect = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: cropSize,
      height: cropSize,
    );
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addOval(rect);
    canvas.drawPath(path, overlayPaint);
    canvas.drawOval(rect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _CropOverlayPainter oldDelegate) {
    return oldDelegate.cropScale != cropScale ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.maskColor != maskColor;
  }
}
