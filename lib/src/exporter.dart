import 'dart:ui' as ui show ImageByteFormat;

import 'package:flutter/foundation.dart';

import 'package:image/image.dart' as image;

import 'package:screen_recorder/src/frame.dart';

class Exporter {
  final List<Frame> _frames = [];
  List<Frame> get frames => _frames;

  void onNewFrame(Frame frame) {
    _frames.add(frame);
  }

  void clear() {
    _frames.clear();
  }

  bool get hasFrames => _frames.isNotEmpty;

  Future<List<RawFrame>?> exportFrames() async {
    if (_frames.isEmpty) {
      return null;
    }
    final bytesImages = <RawFrame>[];
    for (final frame in _frames) {
      final bytesImage =
          await frame.image.toByteData(format: ui.ImageByteFormat.png);
      if (bytesImage != null) {
        bytesImages.add(RawFrame(16, bytesImage));
      } else {
        print('Skipped frame while enconding');
      }
    }
    return bytesImages;
  }

  Future<List<int>?> exportGif() async {
    final frames = await exportFrames();
    if (frames == null) {
      return null;
    }
    return compute(_exportGif, frames);
  }

  static Future<List<int>?> _exportGif(List<RawFrame> frames) async {
    image.Image? animation;
    for (final frame in frames) {
      final iAsBytes = frame.image.buffer.asUint8List();
      final decodedImage = image.decodePng(iAsBytes);

      if (decodedImage == null) {
        print('Skipped frame while enconding');
        continue;
      }

      decodedImage.frameDuration = frame.durationInMillis;

      if (animation == null) {
        animation = decodedImage;
        animation.frameType = image.FrameType.animation;
      } else {
        animation.addFrame(decodedImage);
      }
    }
    if (animation == null) {
      return null;
    }
    return image.encodeGif(animation, samplingFactor: 99999999999);
  }
}

class RawFrame {
  RawFrame(this.durationInMillis, this.image);

  final int durationInMillis;
  final ByteData image;
}
