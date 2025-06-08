import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

class ResponsiveUtils {
  static double getResponsiveHeight(BuildContext context, double percentage) {
    return MediaQuery.of(context).size.height * percentage;
  }

  static double getResponsiveWidth(BuildContext context, double percentage) {
    return MediaQuery.of(context).size.width * percentage;
  }

  static double getResponsiveFontSize(BuildContext context, double baseSize) {
    final width = MediaQuery.of(context).size.width;
    return baseSize * (width / 600).clamp(0.8, 1.5);
  }

  static int getGridCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width > 1200 ? 8 : width > 600 ? 6 : 4;
  }

  static bool isDesktop(BuildContext context) {
    if (kIsWeb) {
      return MediaQuery.of(context).size.width > 800;
    }
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }

  static EdgeInsets getResponsivePadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return EdgeInsets.symmetric(
      horizontal: width * 0.03,
      vertical: width * 0.02,
    );
  }
}