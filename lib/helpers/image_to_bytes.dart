import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

Future<Uint8List> imageToBytes(
  String path, {
  int? targetWidth,
  int? targetHeight,
  bool fromNetwork = false,
}) async {
  late Uint8List dataList;
  if (fromNetwork) {
    final file = await DefaultCacheManager().getSingleFile(path);
    dataList = await file.readAsBytes();
  } else {
    ByteData? bytes = await rootBundle.load(path);
    dataList = bytes.buffer.asUint8List();
  }
  Codec codec = await instantiateImageCodec(
    dataList,
    targetWidth: targetWidth,
    targetHeight: targetHeight,
  );
  FrameInfo frame = await codec.getNextFrame();
  final newBytes = await frame.image.toByteData(
    format: ImageByteFormat.png,
  );
  return newBytes!.buffer.asUint8List();
}
