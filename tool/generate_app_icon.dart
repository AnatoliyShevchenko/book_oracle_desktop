// Regenerates windows/runner/resources/app_icon.ico from the vector logo.
//
//   fvm flutter test tool/generate_app_icon.dart
//
// It lives under tool/ rather than test/ so a normal `flutter test` run does
// not rewrite a checked-in binary.
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:book_oracle/ui/widgets/logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Graphite `bg`, as the spec asks for.
const Color kIconBackground = Color(0xFF141517);
const Color kIconAccent = Color(0xFFE8A33D);

const List<int> kIconSizes = <int>[16, 24, 32, 48, 64, 128, 256];

/// Stroke width in 48-unit grid space; thicker at small sizes so the mark
/// survives downscaling.
double strokeForSize(int size) => switch (size) {
      <= 16 => 4.5,
      <= 24 => 4.0,
      <= 32 => 3.6,
      <= 48 => 3.2,
      <= 64 => 3.0,
      <= 128 => 2.4,
      _ => 2.0,
    };

Future<Uint8List> renderIconPng(int size) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final box = Size(size.toDouble(), size.toDouble());

  canvas.drawRect(Offset.zero & box, Paint()..color = kIconBackground);

  // Leave a small margin so the mark is not flush with the tile edge.
  final inset = size * 0.08;
  canvas.save();
  canvas.translate(inset, inset);
  paintBookOracleLogo(
    canvas,
    Size(size - inset * 2, size - inset * 2),
    accent: kIconAccent,
    background: kIconBackground,
    strokeWidth: strokeForSize(size),
  );
  canvas.restore();

  final image = await recorder.endRecording().toImage(size, size);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}

/// Packs PNG payloads into an ICO container.
Uint8List buildIco(Map<int, Uint8List> images) {
  final entries = images.keys.toList()..sort();
  final header = BytesBuilder();
  // ICONDIR: reserved, type 1 (icon), image count.
  header.add(_u16(0));
  header.add(_u16(1));
  header.add(_u16(entries.length));

  var offset = 6 + entries.length * 16;
  final directory = BytesBuilder();
  for (final size in entries) {
    final png = images[size]!;
    directory.addByte(size >= 256 ? 0 : size); // width, 0 means 256
    directory.addByte(size >= 256 ? 0 : size); // height
    directory.addByte(0); // palette size
    directory.addByte(0); // reserved
    directory.add(_u16(1)); // colour planes
    directory.add(_u16(32)); // bits per pixel
    directory.add(_u32(png.length));
    directory.add(_u32(offset));
    offset += png.length;
  }

  final out = BytesBuilder()
    ..add(header.takeBytes())
    ..add(directory.takeBytes());
  for (final size in entries) {
    out.add(images[size]!);
  }
  return out.takeBytes();
}

Uint8List _u16(int v) => Uint8List(2)..buffer.asByteData().setUint16(0, v, Endian.little);
Uint8List _u32(int v) => Uint8List(4)..buffer.asByteData().setUint32(0, v, Endian.little);

void main() {
  testWidgets('writes windows/runner/resources/app_icon.ico', (tester) async {
    final images = <int, Uint8List>{};
    await tester.runAsync(() async {
      for (final size in kIconSizes) {
        images[size] = await renderIconPng(size);
      }
    });

    expect(images.length, kIconSizes.length);
    for (final png in images.values) {
      // PNG magic, so we know the encoder actually ran.
      expect(png.sublist(0, 4), <int>[0x89, 0x50, 0x4E, 0x47]);
    }

    final ico = buildIco(images);
    final target = File('windows/runner/resources/app_icon.ico');
    target.parent.createSync(recursive: true);
    target.writeAsBytesSync(ico);

    // Also drop a 256 px PNG next to it, handy for installers and the README.
    File('windows/runner/resources/app_icon.png')
        .writeAsBytesSync(images[256]!);

    expect(target.lengthSync(), greaterThan(1000));
  });
}
