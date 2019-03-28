import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class CropPainter extends CustomPainter {
  Offset _startOffset;

  List<Offset> _points;

  CropPainter(this._image, this._width, this._height, this._iw, this._ih,
      this._startOffset, this._points);

  var _width;
  var _iw;
  var _height;
  var _ih;
  ui.Image _image;

  @override
  void paint(Canvas canvas, Size size) {
    if (_image != null) {
      Paint paint = Paint()
        ..color = Colors.blue[200]
        ..isAntiAlias = true
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.square
        ..strokeJoin = StrokeJoin.bevel;

      canvas.drawImageRect(
          _image,
          Rect.fromLTWH(
              0, 0, _image.width.toDouble(), _image.height.toDouble()),
          Rect.fromLTWH((_width - _iw) / 2 + _startOffset.dx,
              (_height - _ih) / 2 + _startOffset.dy, _iw, _ih),
          paint);
      if (_points != null && _points.length > 1) {
        ///绘制区域外半透明阴影
        canvas.drawDRRect(
            RRect.fromLTRBR(0, 0, _width, _height, Radius.circular(0)),
            RRect.fromLTRBR(_points[0].dx, _points[0].dy, _points[1].dx,
                _points[1].dy, Radius.circular(0)),
            paint..color = Color(0x88000000));

        ///绘制四个边
        paint.color = Color(0x99999999);
        paint.strokeWidth = 1.0;
        canvas.drawLine(Offset(_points[0].dx + 15, _points[0].dy),
            Offset(_points[1].dx - 15, _points[0].dy), paint);
        canvas.drawLine(Offset(_points[1].dx, _points[0].dy + 15),
            Offset(_points[1].dx, _points[1].dy - 15), paint);
        canvas.drawLine(Offset(_points[1].dx - 15, _points[1].dy),
            Offset(_points[0].dx + 15, _points[1].dy), paint);
        canvas.drawLine(Offset(_points[0].dx, _points[1].dy - 15),
            Offset(_points[0].dx, _points[0].dy + 15), paint);

        ///绘制四个角
        paint.color = Color(0xff666666);
        paint.strokeWidth = 4.0;
        canvas.drawLine(
            _points[0], Offset(_points[0].dx + 15, _points[0].dy), paint);
        canvas.drawLine(
            _points[0], Offset(_points[0].dx, _points[0].dy + 15), paint);
        canvas.drawLine(Offset(_points[1].dx - 15, _points[0].dy),
            Offset(_points[1].dx, _points[0].dy), paint);
        canvas.drawLine(Offset(_points[1].dx, _points[0].dy),
            Offset(_points[1].dx, _points[0].dy + 15), paint);
        canvas.drawLine(
            _points[1], Offset(_points[1].dx - 15, _points[1].dy), paint);
        canvas.drawLine(
            _points[1], Offset(_points[1].dx, _points[1].dy - 15), paint);
        canvas.drawLine(Offset(_points[0].dx, _points[1].dy),
            Offset(_points[0].dx + 15, _points[1].dy), paint);
        canvas.drawLine(Offset(_points[0].dx, _points[1].dy),
            Offset(_points[0].dx, _points[1].dy - 15), paint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

class ImageLoader {
  static Future<ui.Image> load(File file) {
    ImageStream stream = FileImage(file).resolve(ImageConfiguration.empty);
    Completer completer = Completer<ui.Image>();
    void listener(ImageInfo image, bool synchronousCall) {
      completer.complete(image.image);
      stream.removeListener(listener);
    }

    stream.addListener(listener);
    return completer.future;
  }
}
