import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
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

Future<img.Image?> decodeImage(Uint8List bytes) async {
  try {
    return img.decodeImage(bytes);
  } catch (e) {
    debugPrint('Ошибка декодирования: $e');
    return null;
  }
}

Future<Uint8List> encodeImage(img.Image image) async {
  try {
    return Uint8List.fromList(
        img.encodePng(image, level: 4)); // Уменьшил сжатие для скорости
  } catch (e) {
    debugPrint('Ошибка кодирования: $e');
    throw Exception('Не удалось закодировать: $e');
  }
}

img.Image _copyImage(img.Image src) {
  return img.Image.from(src); // Эффективное копирование
}

final List<Effect> effects = [
  Effect(
    name: 'Original',
    params: [],
    defaultParams: {},
    apply: (img.Image image, Map<String, double> params) async =>
        _copyImage(image),
  ),
  Effect(
    name: 'Grayscale',
    params: [],
    defaultParams: {},
    apply: (img.Image image, Map<String, double> params) async =>
        img.grayscale(_copyImage(image)),
  ),
  Effect(
    name: 'Invert',
    params: [],
    defaultParams: {},
    apply: (img.Image image, Map<String, double> params) async =>
        img.invert(_copyImage(image)),
  ),
  Effect(
    name: 'Pixelate',
    params: [
      EffectParam(
          name: 'Size', minValue: 1, maxValue: 15, defaultValue: 5, step: 1),
    ],
    defaultParams: {'Size': 5},
    apply: (img.Image image, Map<String, double> params) async {
      final size = (params['Size'] ?? 5).toInt().clamp(1, 15);
      return img.pixelate(_copyImage(image),
          size: size, mode: img.PixelateMode.average);
    },
  ),
  Effect(
    name: 'Sobel',
    params: [],
    defaultParams: {},
    apply: (img.Image image, Map<String, double> params) async =>
        img.sobel(_copyImage(image)),
  ),
  Effect(
    name: 'Edge Glow',
    params: [
      EffectParam(
          name: 'Amount', minValue: 0, maxValue: 8, defaultValue: 3, step: 0.1),
    ],
    defaultParams: {'Amount': 3},
    apply: (img.Image image, Map<String, double> params) async {
      final amount = (params['Amount'] ?? 3).clamp(0.0, 8.0);
      final sobel = img.sobel(_copyImage(image));
      return img.adjustColor(sobel,
          brightness: (amount * 8).toInt(), contrast: 1 + amount / 12);
    },
  ),
  Effect(
    name: 'Bump To Normal',
    params: [
      EffectParam(
          name: 'Strength',
          minValue: 0,
          maxValue: 8,
          defaultValue: 2,
          step: 0.1),
    ],
    defaultParams: {'Strength': 2},
    apply: (img.Image image, Map<String, double> params) async {
      final strength = (params['Strength'] ?? 2).clamp(0.0, 8.0);
      final sobel = img.sobel(_copyImage(image));
      return img.adjustColor(sobel, contrast: 1 + strength / 12);
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
          step: 0.05),
      EffectParam(
          name: 'End',
          minValue: 0,
          maxValue: 1,
          defaultValue: 0.75,
          step: 0.05),
    ],
    defaultParams: {'Start': 0.3, 'End': 0.75},
    apply: (img.Image image, Map<String, double> params) async {
      final start = (params['Start'] ?? 0.3).clamp(0.0, 1.0);
      final end = (params['End'] ?? 0.75).clamp(0.0, 1.0);
      return img.vignette(_copyImage(image), start: start, end: end);
    },
  ),
  Effect(
    name: 'Convolution',
    params: [
      EffectParam(
          name: 'Kernel', minValue: 1, maxValue: 4, defaultValue: 1, step: 1),
    ],
    defaultParams: {'Kernel': 1},
    apply: (img.Image image, Map<String, double> params) async {
      final kernel = (params['Kernel'] ?? 1).toInt().clamp(1, 4);
      final filters = {
        1: [0.0, -1.0, 0.0, -1.0, 5.0, -1.0, 0.0, -1.0, 0.0], // Резкость
        2: [
          1 / 9,
          1 / 9,
          1 / 9,
          1 / 9,
          1 / 9,
          1 / 9,
          1 / 9,
          1 / 9,
          1 / 9
        ], // Размытие рамки
        3: [
          1 / 16,
          2 / 16,
          1 / 16,
          2 / 16,
          4 / 16,
          2 / 16,
          1 / 16,
          2 / 16,
          1 / 16
        ], // Размытие по Гауссу
        4: [
          0.0,
          -1.0,
          0.0,
          -1.0,
          4.0,
          -1.0,
          0.0,
          -1.0,
          0.0
        ], // Обнаружение краев
      };
      return img.convolution(_copyImage(image), filter: filters[kernel]!);
    },
  ),
  Effect(
    name: 'Normalize',
    params: [
      EffectParam(
          name: 'Min', minValue: 0, maxValue: 255, defaultValue: 0, step: 1),
      EffectParam(
          name: 'Max', minValue: 0, maxValue: 255, defaultValue: 255, step: 1),
    ],
    defaultParams: {'Min': 0, 'Max': 255},
    apply: (img.Image image, Map<String, double> params) async {
      final min = (params['Min'] ?? 0).toInt().clamp(0, 255);
      final max = (params['Max'] ?? 255).toInt().clamp(0, 255);
      return img.normalize(_copyImage(image), min: min, max: max);
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
          step: 1),
      EffectParam(
          name: 'Green Source',
          minValue: 0,
          maxValue: 2,
          defaultValue: 1,
          step: 1),
      EffectParam(
          name: 'Blue Source',
          minValue: 0,
          maxValue: 2,
          defaultValue: 2,
          step: 1),
    ],
    defaultParams: {'Red Source': 0, 'Green Source': 1, 'Blue Source': 2},
    apply: (img.Image image, Map<String, double> params) async {
      final redSource = (params['Red Source'] ?? 0).toInt().clamp(0, 2);
      final greenSource = (params['Green Source'] ?? 1).toInt().clamp(0, 2);
      final blueSource = (params['Blue Source'] ?? 2).toInt().clamp(0, 2);
      final result = _copyImage(image);
      final channels = [redSource, greenSource, blueSource];
      for (var y = 0; y < result.height; y++) {
        for (var x = 0; x < result.width; x++) {
          final pixel = result.getPixel(x, y);
          final newPixel = [
            pixel[channels[0]],
            pixel[channels[1]],
            pixel[channels[2]],
            pixel[3]
          ];
          result.setPixelRgba(
              x, y, newPixel[0], newPixel[1], newPixel[2], newPixel[3]);
        }
      }
      return result;
    },
  ),
];
