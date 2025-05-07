import 'dart:typed_data';
import 'package:image/image.dart' as img;

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
  final Future<img.Image> Function(img.Image, Map<String, double>) apply;

  Effect({
    required this.name,
    required this.params,
    required this.defaultParams,
    required this.apply,
  });
}

Future<img.Image> decodeImage(Uint8List bytes) async {
  final image = img.decodeImage(bytes);
  if (image == null) {
    throw Exception('Failed to decode image');
  }
  return image;
}

Future<Uint8List> encodeImage(img.Image image) async {
  final bytes = img.encodePng(image);
  if (bytes == null) {
    throw Exception('Failed to encode image');
  }
  return Uint8List.fromList(bytes);
}

img.Image _copyImage(img.Image src) {
  final result = img.Image(width: src.width, height: src.height);
  for (var y = 0; y < src.height; y++) {
    for (var x = 0; x < src.width; x++) {
      result.setPixel(x, y, src.getPixel(x, y));
    }
  }
  return result;
}

final List<Effect> effects = [
  Effect(
    name: 'Original',
    params: [],
    defaultParams: {},
    apply: (img.Image image, Map<String, double> params) async => image,
  ),
  Effect(
    name: 'Grayscale',
    params: [],
    defaultParams: {},
    apply: (img.Image image, Map<String, double> params) async {
      final result = _copyImage(image);
      return img.grayscale(result);
    },
  ),
  Effect(
    name: 'Invert',
    params: [],
    defaultParams: {},
    apply: (img.Image image, Map<String, double> params) async {
      final result = _copyImage(image);
      return img.invert(result);
    },
  ),
  Effect(
    name: 'Pixelate',
    params: [
      EffectParam(
        name: 'Size',
        minValue: 1,
        maxValue: 20,
        defaultValue: 5,
        step: 1,
      ),
    ],
    defaultParams: {'Size': 5},
    apply: (img.Image image, Map<String, double> params) async {
      final result = _copyImage(image);
      final size = params['Size']!.toInt().clamp(1, 20);
      return img.pixelate(result, size: size);
    },
  ),
  Effect(
    name: 'Sobel',
    params: [],
    defaultParams: {},
    apply: (img.Image image, Map<String, double> params) async {
      final result = _copyImage(image);
      return img.sobel(result);
    },
  ),
  Effect(
    name: 'Edge Glow',
    params: [
      EffectParam(
        name: 'Amount',
        minValue: 0,
        maxValue: 10,
        defaultValue: 3,
        step: 0.1,
      ),
    ],
    defaultParams: {'Amount': 3},
    apply: (img.Image image, Map<String, double> params) async {
      final result = _copyImage(image);
      final sobel = img.sobel(result);
      final amount = params['Amount']!.clamp(0.0, 10.0);
      return img.adjustColor(
        sobel,
        brightness: (amount * 10).toInt(),
        contrast: 1 + amount / 10,
      );
    },
  ),
  Effect(
    name: 'Bump To Normal',
    params: [
      EffectParam(
        name: 'Strength',
        minValue: 0,
        maxValue: 10,
        defaultValue: 2,
        step: 0.1,
      ),
    ],
    defaultParams: {'Strength': 2},
    apply: (img.Image image, Map<String, double> params) async {
      final result = _copyImage(image);
      final sobel = img.sobel(result);
      final strength = params['Strength']!.clamp(0.0, 10.0);
      return img.adjustColor(
        sobel,
        contrast: 1 + strength / 10,
      );
    },
  ),
  Effect(
    name: 'Color Offset',
    params: [
      EffectParam(
        name: 'Red',
        minValue: -100,
        maxValue: 100,
        defaultValue: 10,
        step: 1,
      ),
      EffectParam(
        name: 'Green',
        minValue: -100,
        maxValue: 100,
        defaultValue: 0,
        step: 1,
      ),
      EffectParam(
        name: 'Blue',
        minValue: -100,
        maxValue: 100,
        defaultValue: -10,
        step: 1,
      ),
    ],
    defaultParams: {'Red': 10, 'Green': 0, 'Blue': -10},
    apply: (img.Image image, Map<String, double> params) async {
      final result = _copyImage(image);
      final redOffset = params['Red']!.toInt().clamp(-100, 100);
      final greenOffset = params['Green']!.toInt().clamp(-100, 100);
      final blueOffset = params['Blue']!.toInt().clamp(-100, 100);
      for (var y = 0; y < result.height; y++) {
        for (var x = 0; x < result.width; x++) {
          final pixel = result.getPixel(x, y);
          final r = (pixel.r + redOffset).clamp(0, 255).toInt();
          final g = (pixel.g + greenOffset).clamp(0, 255).toInt();
          final b = (pixel.b + blueOffset).clamp(0, 255).toInt();
          result.setPixelRgba(x, y, r, g, b, pixel.a);
        }
      }
      return result;
    },
  ),
  Effect(
    name: 'Vignette',
    params: [
      EffectParam(
        name: 'Start',
        minValue: 0,
        maxValue: 1,
        defaultValue: 0.3,
        step: 0.05,
      ),
      EffectParam(
        name: 'End',
        minValue: 0,
        maxValue: 1,
        defaultValue: 0.75,
        step: 0.05,
      ),
    ],
    defaultParams: {'Start': 0.3, 'End': 0.75},
    apply: (img.Image image, Map<String, double> params) async {
      final result = _copyImage(image);
      final start = params['Start']!.clamp(0.0, 1.0);
      final end = params['End']!.clamp(0.0, 1.0);
      return img.vignette(
        result,
        start: start,
        end: end,
      );
    },
  ),
  Effect(
    name: 'Convolution',
    params: [
      EffectParam(
        name: 'Kernel',
        minValue: 1,
        maxValue: 4,
        defaultValue: 1,
        step: 1,
      ),
    ],
    defaultParams: {'Kernel': 1},
    apply: (img.Image image, Map<String, double> params) async {
      final kernel = params['Kernel']!.toInt().clamp(1, 4);
      final filters = {
        1: [0.0, -1.0, 0.0, -1.0, 5.0, -1.0, 0.0, -1.0, 0.0], // Sharpen
        2: [1 / 9, 1 / 9, 1 / 9, 1 / 9, 1 / 9, 1 / 9, 1 / 9, 1 / 9, 1 / 9], // Box blur
        3: [1 / 16, 2 / 16, 1 / 16, 2 / 16, 4 / 16, 2 / 16, 1 / 16, 2 / 16, 1 / 16], // Gaussian blur
        4: [0.0, -1.0, 0.0, -1.0, 4.0, -1.0, 0.0, -1.0, 0.0], // Edge detection
      };
      final filter = filters[kernel] ?? filters[1]!;
      final result = _copyImage(image);
      return img.convolution(result, filter: filter);
    },
  ),
  Effect(
    name: 'Adjust Color',
    params: [
      EffectParam(
        name: 'Brightness',
        minValue: -100,
        maxValue: 100,
        defaultValue: 0,
        step: 1,
      ),
      EffectParam(
        name: 'Contrast',
        minValue: 0,
        maxValue: 2,
        defaultValue: 1,
        step: 0.1,
      ),
      EffectParam(
        name: 'Saturation',
        minValue: 0,
        maxValue: 2,
        defaultValue: 1,
        step: 0.1,
      ),
      EffectParam(
        name: 'Gamma',
        minValue: 0.1,
        maxValue: 5,
        defaultValue: 1,
        step: 0.1,
      ),
    ],
    defaultParams: {
      'Brightness': 0,
      'Contrast': 1,
      'Saturation': 1,
      'Gamma': 1,
    },
    apply: (img.Image image, Map<String, double> params) async {
      final result = _copyImage(image);
      final brightness = params['Brightness']!.toInt().clamp(-100, 100);
      final contrast = params['Contrast']!.clamp(0.0, 2.0);
      final saturation = params['Saturation']!.clamp(0.0, 2.0);
      final gamma = params['Gamma']!.clamp(0.1, 5.0);
      return img.adjustColor(
        result,
        brightness: brightness,
        contrast: contrast,
        saturation: saturation,
        gamma: gamma,
      );
    },
  ),
  Effect(
    name: 'Normalize',
    params: [
      EffectParam(
        name: 'Min',
        minValue: 0,
        maxValue: 255,
        defaultValue: 0,
        step: 1,
      ),
      EffectParam(
        name: 'Max',
        minValue: 0,
        maxValue: 255,
        defaultValue: 255,
        step: 1,
      ),
    ],
    defaultParams: {'Min': 0, 'Max': 255},
    apply: (img.Image image, Map<String, double> params) async {
      final result = _copyImage(image);
      final min = params['Min']!.toInt().clamp(0, 255);
      final max = params['Max']!.toInt().clamp(0, 255);
      return img.normalize(
        result,
        min: min,
        max: max,
      );
    },
  ),
  Effect(
    name: 'Remap Colors',
    params: [
      EffectParam(
        name: 'Red Source',
        minValue: 0,
        maxValue: 2,
        defaultValue: 0,
        step: 1,
      ),
      EffectParam(
        name: 'Green Source',
        minValue: 0,
        maxValue: 2,
        defaultValue: 1,
        step: 1,
      ),
      EffectParam(
        name: 'Blue Source',
        minValue: 0,
        maxValue: 2,
        defaultValue: 2,
        step: 1,
      ),
    ],
    defaultParams: {'Red Source': 0, 'Green Source': 1, 'Blue Source': 2},
    apply: (img.Image image, Map<String, double> params) async {
      final redSource = params['Red Source']!.toInt().clamp(0, 2);
      final greenSource = params['Green Source']!.toInt().clamp(0, 2);
      final blueSource = params['Blue Source']!.toInt().clamp(0, 2);
      final result = _copyImage(image);
      for (var y = 0; y < result.height; y++) {
        for (var x = 0; x < result.width; x++) {
          final pixel = result.getPixel(x, y);
          final r = switch (redSource) {
            0 => pixel.r,
            1 => pixel.g,
            2 => pixel.b,
            _ => pixel.r,
          };
          final g = switch (greenSource) {
            0 => pixel.r,
            1 => pixel.g,
            2 => pixel.b,
            _ => pixel.g,
          };
          final b = switch (blueSource) {
            0 => pixel.r,
            1 => pixel.g,
            2 => pixel.b,
            _ => pixel.b,
          };
          result.setPixelRgba(x, y, r, g, b, pixel.a);
        }
      }
      return result;
    },
  ),
];