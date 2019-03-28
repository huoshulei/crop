library crop;

import 'dart:ui';

import 'package:flutter/material.dart';
import 'crop_painter.dart';
//import 'package:path_provider/path_provider.dart';

class CropPage extends StatefulWidget {
  var _imageFile;
  var _width;
  var _height;

  CropPage(this._imageFile, this._width, this._height);

  @override
  State<StatefulWidget> createState() {
    return _CropState(_imageFile, _width, _height);
  }
}

class _CropState extends State<CropPage> {
  var _imageFile;
  var _scale;
  bool square; //1:1等比例裁剪
  Offset _offset;
  Offset _startOffset = Offset(0, 0);
  List<Offset> _points; //裁剪框位置

  static const int _CROP_L_T = 0xff; //255
  static const int _CROP_R_T = 0xef; //239
  static const int _CROP_L_B = 0xdf; //223
  static const int _CROP_R_B = 0xcf; //207
  static const int _CROP_L = 0xfe; //254
  static const int _CROP_T = 0xee; //238
  static const int _CROP_R = 0xde; //222
  static const int _CROP_B = 0xce; //206
  static const int _CROP_IN = 0xfd; //253
  static const int _CROP_OUT = 0xed; //237
  var _type;

  _CropState(
    this._imageFile,
    this._width,
    this._height, {
    this.square = true,
  }) : _points = [];

  var _image;
  var _width;
  var _iwidth;
  var _height;
  var _iheight;
  var _iw;
  var _ih;

  @override
  void initState() {
    ImageLoader.load(_imageFile).then((image) {
      setState(() {
        this._image = image;
        if (_image != null) {
          if (_image.width.toDouble() / _width >
              _image.height.toDouble() / _height) {
            _iw = _iwidth = _width;
            _ih = _iheight =
                _image.height.toDouble() * _iw / _image.width.toDouble();
            if (_ih < 50) {
              //图片最小高度50
              _iw = 50 / _ih * _iw;
              _ih = 50;
            }
          } else {
            _ih = _iheight = _height;
            _iw = _iwidth =
                _image.width.toDouble() * _ih / _image.height.toDouble();
            if (_iw < 50) {
              //图片最小宽度50
              _ih = 50 / _iw * _ih;
              _iw = 50;
            }
          }
          _points.clear();
          _points.add(Offset((_width - 200) / 2, (_height - 200) / 2));
          _points.add(Offset((_width + 200) / 2, (_height + 200) / 2));
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xdd888888),
      body: Stack(
        children: <Widget>[
          GestureDetector(
            onScaleStart: (d) {
              _scale = 1.0;
            },
            onScaleUpdate: _onScaleUpdate,
          ),
          GestureDetector(
            onPanDown: _onPanWown,
            onPanUpdate: _onPanUpdate,
            onPanEnd: (d) {
              _offset = null;
//              print('ddddddddd>>>>${d}<<<<');
            },
          ),
          CustomPaint(
              painter: CropPainter(
                  _image, _width, _height, _iw, _ih, _startOffset, _points)),
          Container(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween ,
              children: <Widget>[
                IconButton(
                  icon: Icon(Icons.close, color: Color(0xffffffff)),
                  iconSize: 30,
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                IconButton(
                  onPressed: () async {
                    if (_image != null) {
                      ///像素密度
                      var rateX = _image.width.toDouble() / _iw;
                      var rateY = _image.height.toDouble() / _ih;
                      var l = (_points[0].dx -
                              (_width - _iw) / 2 -
                              _startOffset.dx) *
                          rateX;
                      var t = (_points[0].dy -
                              (_height - _ih) / 2 -
                              _startOffset.dy) *
                          rateY;
                      var r = (_points[1].dx -
                              (_width - _iw) / 2 -
                              _startOffset.dx) *
                          rateX;
                      var b = (_points[1].dy -
                              (_height - _ih) / 2 -
                              _startOffset.dy) *
                          rateY;
                      var w = r - l;
                      var h = b - t;
                      var src = Rect.fromLTRB(l, t, r, b);
                      var dst = Rect.fromLTWH(0, 0, w, h);
                      var recorder = PictureRecorder();
                      var canvas = Canvas(recorder);
                      canvas.drawImageRect(_image, src, dst, Paint());
                      recorder
                          .endRecording()
                          .toImage(w.toInt(), h.toInt())
                          .then((image) async {
                        var pngBytes =
                            await image.toByteData(format: ImageByteFormat.png);
//                        var asUint8List = byteData.buffer.asUint8List();
//                        getApplicationDocumentsDirectory().then((dir) {
//                          var path = dir.path +
//                              '/${DateTime.now().millisecondsSinceEpoch}.png';
//                          File(path).writeAsBytesSync(asUint8List);
//                          Navigator.pop(context, path);
//                        });
                        Navigator.pop(context, pngBytes);
                      });
                    }
                  },
                  iconSize: 30,
                  icon: Icon(Icons.check, color: Color(0xffffffff)),
                )
              ],
            ),
            color: Color(0x88000000),
            alignment: Alignment.topCenter,
            padding: EdgeInsets.all( 20),
            height: 70,
          )
        ],
      ),
    );
  }

  bool inRange(double l, double t, double r, double b, Offset offset) {
    if (offset.dx > l && offset.dx < r && offset.dy > t && offset.dy < b)
      return true;
    return false;
  }

  void _onPanWown(DragDownDetails d) {
    ///根据按下点的位置判断需要处理的逻辑类型
    _type = inRange(_points[0].dx - 15, _points[0].dy - 15, _points[0].dx + 15,
            _points[0].dy + 15, d.globalPosition)
        ? _CROP_L_T //左顶
        : inRange(_points[1].dx - 15, _points[0].dy - 15, _points[1].dx + 15,
                _points[0].dy + 15, d.globalPosition)
            ? _CROP_R_T //右顶
            : inRange(_points[0].dx - 15, _points[1].dy - 15,
                    _points[0].dx + 15, _points[1].dy + 15, d.globalPosition)
                ? _CROP_L_B //左下
                : inRange(
                        _points[1].dx - 15,
                        _points[1].dy - 15,
                        _points[1].dx + 15,
                        _points[1].dy + 15,
                        d.globalPosition)
                    ? _CROP_R_B //右下
                    : inRange(
                            _points[0].dx - 15,
                            _points[0].dy + 15,
                            _points[0].dx + 15,
                            _points[1].dy - 15,
                            d.globalPosition)
                        ? _CROP_L //左边
                        : inRange(
                                _points[0].dx + 15,
                                _points[0].dy - 15,
                                _points[1].dx - 15,
                                _points[0].dy + 15,
                                d.globalPosition)
                            ? _CROP_T //顶边
                            : inRange(
                                    _points[1].dx - 15,
                                    _points[0].dy + 15,
                                    _points[1].dx + 15,
                                    _points[1].dy - 15,
                                    d.globalPosition)
                                ? _CROP_R //右边
                                : inRange(
                                        _points[0].dx + 15,
                                        _points[1].dy - 15,
                                        _points[1].dx - 15,
                                        _points[1].dy + 15,
                                        d.globalPosition)
                                    ? _CROP_B //下边
                                    : inRange(
                                            _points[0].dx + 15,
                                            _points[0].dy + 15,
                                            _points[1].dx - 15,
                                            _points[1].dy - 15,
                                            d.globalPosition)
                                        ? _CROP_IN //裁剪区域
                                        : _CROP_OUT; //区域外
//    print('ddddddddd>>>>${d}<<<<$_type>>>>');
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (details.scale != 1.0)
      setState(() {
        ///最大缩放比例为图片尺寸的（1-3）倍
        var __iw = _iw * details.scale / _scale;
        _iw =
            __iw > _iwidth * 3 ? _iwidth * 3 : __iw < _iwidth ? _iwidth : __iw;
        _ih = __iw > _iwidth * 3
            ? _iheight * 3
            : __iw < _iwidth ? _iheight : _ih * details.scale / _scale;
        _scale = details.scale;
//                  print('ddddddddd>>>>${details.scale}<<<<$_iw');
        ///缩放时判断图片边界是否超出
        ///如果屏幕宽度超过图片宽度 则偏移量为0
        ///否则最大偏移量为图片宽度减去屏幕宽度的一半
        ///高度同理
        var x = _startOffset.dx;
        x = _width > _iw
            ? 0
            : x > (_iw - _width) / 2
                ? (_iw - _width) / 2
                : x < (_width - _iw) / 2 ? (_width - _iw) / 2 : x;
        var y = _startOffset.dy;
        y = _height > _ih
            ? 0
            : y > (_ih - _height) / 2
                ? (_ih - _height) / 2
                : y < (_height - _ih) / 2 ? (_height - _ih) / 2 : y;
        _startOffset = Offset(x, y);

        ///判断裁剪框区域是否超出图片区域
        ///图片宽度大于屏幕宽度时不存在超范围的情况
        ///当图片宽度小于屏幕宽度时 并且裁剪区域超出图片范围时
        /// 图片宽度和高度同时小于屏幕宽度和高度的情况不存在
        if (_width > _iw) {
          ///裁剪宽度小于图片宽度
          if (_points[1].dx - _points[0].dx < _iw) {
            ///左边越界
            if (_points[0].dx < (_width - _iw) / 2) {
              var x = (_width - _iw) / 2 - _points[0].dx; //x轴偏移量
              _points[0] = Offset(_points[0].dx + x, _points[0].dy);
              _points[1] = Offset(_points[1].dx + x, _points[1].dy);
            }

            ///右边越界
            if (_points[1].dx > (_width + _iw) / 2) {
              var x = (_width + _iw) / 2 - _points[1].dx; //x轴偏移量
              _points[0] = Offset(_points[0].dx + x, _points[0].dy);
              _points[1] = Offset(_points[1].dx + x, _points[1].dy);
            }
          } else {
            ///裁剪宽度大于图片宽度
            var w = _points[1].dx - _points[0].dx;
            var h = _points[1].dy - _points[0].dy;
            var xl = (_width - _iw) / 2 - _points[0].dx; //x轴左偏移量
            var xr = (_width + _iw) / 2 - _points[1].dx; //x轴右偏移量
            var yt = xl / w * h; //y轴上偏移量
            var yb = xr / w * h; //y轴下偏移量
            _points[0] = Offset((_width - _iw) / 2, _points[0].dy + yt);
            _points[1] = Offset((_width + _iw) / 2, _points[1].dy + yb);
          }
        }

        ///当图片高度 小于屏幕高度时
        if (_height > _ih) {
          ///裁剪高度小于图片高度
          if (_points[1].dy - _points[0].dy < _ih) {
            ///顶边越界
            if (_points[0].dy < (_height - _ih) / 2) {
              var y = (_height - _ih) / 2 - _points[0].dy; //y轴偏移量
              _points[0] = Offset(_points[0].dx, _points[0].dy + y);
              _points[1] = Offset(_points[1].dx, _points[1].dy + y);
            }

            ///低边越界
            if (_points[1].dy > (_height + _ih) / 2) {
              var y = (_height + _ih) / 2 - _points[1].dy; //y轴偏移量
              _points[0] = Offset(_points[0].dx, _points[0].dy + y);
              _points[1] = Offset(_points[1].dx, _points[1].dy + y);
            }
          } else {
            ///裁剪宽度大于图片宽度
            var h = _points[1].dy - _points[0].dy;
            var w = _points[1].dx - _points[0].dx;
            var yt = (_height - _ih) / 2 - _points[0].dy; //y轴上偏移量
            var yb = (_height + _ih) / 2 - _points[1].dy; //y轴下偏移量
            var xl = yt / h * w; //x轴左偏移量
            var xr = yb / h * w; //x轴右偏移量
            _points[0] = Offset(_points[0].dx + xl, (_height - _ih) / 2);
            _points[1] = Offset(_points[1].dx + xr, (_height + _ih) / 2);
          }
        }
      });
  }

  void _onPanUpdate(DragUpdateDetails d) {
    setState(() {
//      print('ddddddddd>>>>${d.globalPosition}<<<<>>>><<<<');
      if (_offset == null) _offset = d.globalPosition;
      if ((_offset.dx - d.globalPosition.dx).abs() < 30 &&
          (_offset.dy - d.globalPosition.dy).abs() < 30) {
        switch (_type) {
          case _CROP_L_T:
            var x = d.globalPosition.dx - _offset.dx; //x轴偏移量
            var l = _width > _iw ? (_width - _iw) / 2 : 0; //左边界
            var y = d.globalPosition.dy - _offset.dy; //y轴偏移量
            var t = _height > _ih ? (_height - _ih) / 2 : 0; //上边界
            ///1:1等比例裁剪
            if (square) {
              var o = x.abs() > y.abs() ? x : y;
              o = _points[0].dx + o < l
                  ? l - _points[0].dx
                  : _points[0].dx + o > _points[1].dx - 50
                      ? _points[1].dx - _points[0].dx - 50
                      : o;
              o = _points[0].dy + o < t
                  ? t - _points[0].dy
                  : _points[0].dy + o > _points[1].dy - 50
                      ? _points[1].dy - _points[0].dy - 50
                      : o;
              _points[0] = Offset(_points[0].dx + o, _points[0].dy + o);
            } else {
              x = _points[0].dx + x < l
                  ? l - _points[0].dx
                  : _points[0].dx + x > _points[1].dx - 50
                      ? _points[1].dx - _points[0].dx - 50
                      : x;
              y = _points[0].dy + y < t
                  ? t - _points[0].dy
                  : _points[0].dy + y > _points[1].dy - 50
                      ? _points[1].dy - _points[0].dy - 50
                      : y;
              _points[0] = Offset(_points[0].dx + x, _points[0].dy + y);
            }
            break;
          case _CROP_L_B:
            var x = d.globalPosition.dx - _offset.dx; //x轴偏移量
            var l = _width > _iw ? (_width - _iw) / 2 : 0; //左边界
            var y = d.globalPosition.dy - _offset.dy; //y轴偏移量
            var b = _height > _ih ? (_height - _ih) / 2 + _ih : _iheight; //下边界
            ///1:1等比例裁剪
            if (square) {
              var o = x.abs() > y.abs() ? x : -y;
              o = _points[0].dx + o < l
                  ? l - _points[0].dx
                  : _points[0].dx + o > _points[1].dx - 50
                      ? _points[1].dx - _points[0].dx - 50
                      : o;
              o = _points[1].dy - o > b
                  ? _points[1].dy - b
                  : _points[1].dy - o < _points[0].dy + 50
                      ? _points[1].dy - _points[0].dy - 50
                      : o;
              _points[0] = Offset(_points[0].dx + o, _points[0].dy);
              _points[1] = Offset(_points[1].dx, _points[1].dy - o);
            } else {
              x = _points[0].dx + x < l
                  ? l - _points[0].dx
                  : _points[0].dx + x > _points[1].dx - 50
                      ? _points[1].dx - _points[0].dx - 50
                      : x;
              y = _points[1].dy + y > b
                  ? b - _points[1].dy
                  : _points[1].dy + y < _points[0].dy + 50
                      ? _points[0].dy - _points[1].dy + 50
                      : y;
              _points[0] = Offset(_points[0].dx + x, _points[0].dy);
              _points[1] = Offset(_points[1].dx, _points[1].dy + y);
            }
            break;
          case _CROP_R_T:
            var x = d.globalPosition.dx - _offset.dx; //x轴偏移量
            var r = _width > _iw ? (_width - _iw) / 2 + _iw : _width; //右边界
            var y = d.globalPosition.dy - _offset.dy; //y轴偏移量
            var t = _height > _ih ? (_height - _ih) / 2 : 0; //上边界
            ///1:1等比例裁剪
            if (square) {
              var o = x.abs() > y.abs() ? -x : y;
              o = _points[1].dx - o > r
                  ? _points[1].dx - r
                  : _points[1].dx - o < _points[0].dx + 50
                      ? _points[1].dx - _points[0].dx - 50
                      : o;
              o = _points[0].dy + o < t
                  ? t - _points[0].dy
                  : _points[0].dy + o > _points[1].dy - 50
                      ? _points[1].dy - _points[0].dy - 50
                      : o;
              _points[0] = Offset(_points[0].dx, _points[0].dy + o);
              _points[1] = Offset(_points[1].dx - o, _points[1].dy);
            } else {
              x = _points[1].dx + x > r
                  ? r - _points[1].dx
                  : _points[1].dx + x < _points[0].dx + 50
                      ? _points[0].dx - _points[1].dx + 50
                      : x;
              y = _points[0].dy + y < t
                  ? t - _points[0].dy
                  : _points[0].dy + y > _points[1].dy - 50
                      ? _points[1].dy - _points[0].dy - 50
                      : y;
              _points[0] = Offset(_points[0].dx, _points[0].dy + y);
              _points[1] = Offset(_points[1].dx + x, _points[1].dy);
            }
            break;
          case _CROP_R_B:
            var x = d.globalPosition.dx - _offset.dx; //x轴偏移量
            var r = _width > _iw ? (_width - _iw) / 2 + _iw : _width; //右边界
            var y = d.globalPosition.dy - _offset.dy; //y轴偏移量
            var b = _height > _ih ? (_height - _ih) / 2 + _ih : _iheight; //下边界
            ///1:1等比例裁剪
            if (square) {
              var o = x.abs() > y.abs() ? x : y;
              o = _points[1].dx + o > r
                  ? r - _points[1].dx
                  : _points[1].dx + o < _points[0].dx + 50
                      ? _points[0].dx - _points[1].dx + 50
                      : o;
              o = _points[1].dy + o > b
                  ? b - _points[1].dy
                  : _points[1].dy + o < _points[0].dy + 50
                      ? _points[0].dy - _points[1].dy + 50
                      : o;
              _points[1] = Offset(_points[1].dx + o, _points[1].dy + o);
            } else {
              x = _points[1].dx + x > r
                  ? r - _points[1].dx
                  : _points[1].dx + x < _points[0].dx + 50
                      ? _points[0].dx - _points[1].dx + 50
                      : x;
              y = _points[1].dy + y > b
                  ? b - _points[1].dy
                  : _points[1].dy + y < _points[0].dy + 50
                      ? _points[0].dy - _points[1].dy + 50
                      : y;
              _points[1] = Offset(_points[1].dx + x, _points[1].dy + y);
            }
            break;
          case _CROP_L:
            if (!square) {
              //等比例缩放不允许单边移动
              var x = d.globalPosition.dx - _offset.dx; //x轴偏移量
              var l = _width > _iw ? (_width - _iw) / 2 : 0; //左边界
              x = _points[0].dx + x < l
                  ? l - _points[0].dx
                  : _points[0].dx + x > _points[1].dx - 50
                      ? _points[1].dx - _points[0].dx - 50
                      : x;
              _points[0] = Offset(_points[0].dx + x, _points[0].dy);
            }
            break;
          case _CROP_T:
            if (!square) {
              var y = d.globalPosition.dy - _offset.dy; //y轴偏移量
              var t = _height > _ih ? (_height - _ih) / 2 : 0; //上边界
              y = _points[0].dy + y < t
                  ? t - _points[0].dy
                  : _points[0].dy + y > _points[1].dy - 50
                      ? _points[1].dy - _points[0].dy - 50
                      : y;
              _points[0] = Offset(_points[0].dx, _points[0].dy + y);
            }
            break;
          case _CROP_R:
            if (!square) {
              var x = d.globalPosition.dx - _offset.dx; //x轴偏移量
              var r = _width > _iw ? (_width - _iw) / 2 + _iw : _width; //右边界
              x = _points[1].dx + x > r
                  ? r - _points[1].dx
                  : _points[1].dx + x < _points[0].dx + 50
                      ? _points[0].dx - _points[1].dx + 50
                      : x;

              _points[1] = Offset(_points[1].dx + x, _points[1].dy);
            }
            break;
          case _CROP_B:
            if (!square) {
              var y = d.globalPosition.dy - _offset.dy; //y轴偏移量
              var b =
                  _height > _ih ? (_height - _ih) / 2 + _ih : _iheight; //下边界
              y = _points[1].dy + y > b
                  ? b - _points[1].dy
                  : _points[1].dy + y < _points[0].dy + 50
                      ? _points[0].dy - _points[1].dy + 50
                      : y;
              _points[1] = Offset(_points[1].dx, _points[1].dy + y);
            }
            break;

          /// 裁剪区域位移 移动范围不超过图片范围
          case _CROP_IN:
            var x = d.globalPosition.dx - _offset.dx; //x轴偏移量
            var l = _width > _iw ? (_width - _iw) / 2 : 0; //左边界
            var r = _width > _iw ? (_width - _iw) / 2 + _iw : _width; //右边界
            var y = d.globalPosition.dy - _offset.dy; //y轴偏移量
            var t = _height > _ih ? (_height - _ih) / 2 : 0; //上边界
            var b = _height > _ih ? (_height - _ih) / 2 + _ih : _iheight; //下边界
            x = _points[0].dx + x < l
                ? l - _points[0].dx
                : _points[1].dx + x > r ? r - _points[1].dx : x;
            y = _points[0].dy + y < t
                ? t - _points[0].dy
                : _points[1].dy + y > b ? b - _points[1].dy : y;
            _points[0] = Offset(_points[0].dx + x, _points[0].dy + y);
            _points[1] = Offset(_points[1].dx + x, _points[1].dy + y);
            break;

          ///图片平移 移动范围不超过屏幕范围
          ///_width-_iw/2>=_starOffset.dx
          case _CROP_OUT:
            var x = _startOffset.dx - _offset.dx + d.globalPosition.dx;
            x = _width > _iw
                ? 0
                : x > (_iw - _width) / 2
                    ? (_iw - _width) / 2
                    : x < (_width - _iw) / 2 ? (_width - _iw) / 2 : x;
            var y = _startOffset.dy - _offset.dy + d.globalPosition.dy;
            y = _height > _ih
                ? 0
                : y > (_ih - _height) / 2
                    ? (_ih - _height) / 2
                    : y < (_height - _ih) / 2 ? (_height - _ih) / 2 : y;
            _startOffset = Offset(x, y);
            break;
        }
      }
      _offset = d.globalPosition;
    });
  }
}
