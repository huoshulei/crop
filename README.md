
## dart 图片裁剪

![avatar](/img/crop.png)

    使用：
    imageFile 原图文件（File）
    width 屏幕宽度
    height 屏幕高度
    square 是否为正方形裁剪 默认为true
    pngBytes 裁剪后 ByteData 格式的目标图片字节码

```
    Navigator.push(context,CupertinoPageRoute(builder: (context) {
                          var height = MediaQuery.of(context).size.height;
                          var width = MediaQuery.of(context).size.width;
                          return CropPage(imageFile, width, height，square=true);
                        })).then((pngBytes) {
                          if (pngBuffer != null) {
                            setState(() {
                             ...
                            });
                          }
                        });

```
```
  var asUint8List = byteData.buffer.asUint8List();
 getApplicationDocumentsDirectory().then((dir) {
   var path = dir.path +
       '/${DateTime.now().millisecondsSinceEpoch}.png';
   File(path).writeAsBytesSync(asUint8List);
```