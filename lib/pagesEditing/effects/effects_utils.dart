import 'dart:typed_data';
import 'package:image/image.dart' as image;

class EffectParam {
  final String name;
  final double minValue;
  final double maxValue;
  final double defaultValue;
  final double step;

  EffectParam({
    required this.name,
    required this.minValue,
    required this.maxValue,
    required this.defaultValue,
    required this.step,
  });
}

class Effect {
  final String name;
  final List<EffectParam> params;
  final Map<String, double> defaultParams;
  final Future<image.Image> Function(image.Image, Map<String, double>) apply;

  Effect({
    required this.name,
    required this.params,
    required this.defaultParams,
    required this.apply,
  });
}

Future<image.Image> decodeImage(Uint8List bytes) async {
  final img = image.decodeImage(bytes);
  if (img == null) {
    throw Exception('Failed to decode image');
  }
  return img;
}

Future<Uint8List> encodeImage(image.Image img) async {
  final bytes = image.encodePng(img);
  if (bytes == null) {
    throw Exception('Failed to encode image');
  }
  return Uint8List.fromList(bytes);
}

final List<Effect> effects = [
  Effect(
    name: 'Original',
    params: [],
    defaultParams: {},
    apply: (img, params) async => img,
  ),
  Effect(
    name: 'Grayscale',
    params: [],
    defaultParams: {},
    apply: (img, params) async => image.grayscale(img),
  ),
  Effect(
    name: 'Sepia',
    params: [],
    defaultParams: {},
    apply: (img, params) async => image.sepia(img),
  ),
  Effect(
    name: 'Blur',
    params: [
      EffectParam(
        name: 'Radius',
        minValue: 0.0,
        maxValue: 10.0,
        defaultValue: 2.0,
        step: 0.1,
      ),
    ],
    defaultParams: {'Radius': 2.0},
    apply: (img, params) async => image.gaussianBlur(img, radius: params['Radius']!.toInt()),
  ),
  Effect(
    name: 'Invert',
    params: [],
    defaultParams: {},
    apply: (img, params) async => image.invert(img),
  ),
  Effect(
    name: 'Brightness',
    params: [
      EffectParam(
        name: 'Level',
        minValue: -100.0,
        maxValue: 100.0,
        defaultValue: 20.0,
        step: 1.0,
      ),
    ],
    defaultParams: {'Level': 20.0},
    apply: (img, params) async => image.adjustColor(img, brightness: params['Level']!.toInt()),
  ),
  Effect(
    name: 'Contrast',
    params: [
      EffectParam(
        name: 'Level',
        minValue: 0.5,
        maxValue: 2.0,
        defaultValue: 1.2,
        step: 0.1,
      ),
    ],
    defaultParams: {'Level': 1.2},
    apply: (img, params) async => image.adjustColor(img, contrast: params['Level']!),
  ),
  Effect(
    name: 'Vignette',
    params: [
      EffectParam(
        name: 'Amount',
        minValue: 0.0,
        maxValue: 1.0,
        defaultValue: 0.5,
        step: 0.1,
      ),
    ],
    defaultParams: {'Amount': 0.5},
    apply: (img, params) async => image.vignette(img, amount: params['Amount']!),
  ),
];