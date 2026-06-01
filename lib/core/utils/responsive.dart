import 'package:flutter/widgets.dart';

class Responsive {
  static late double screenWidth;
  static late double screenHeight;
  static late double devicePixelRatio;
  static late double statusBarHeight;
  static late double bottomBarHeight;

  // Figma Dimensions
  static const double designWidth = 390.0;
  static const double designHeight = 844.0;

  static void init(BuildContext context) {
    final mq = MediaQuery.of(context);
    screenWidth = mq.size.width;
    screenHeight = mq.size.height;
    devicePixelRatio = mq.devicePixelRatio;
    statusBarHeight = mq.padding.top;
    bottomBarHeight = mq.padding.bottom;
  }

  // Use width as the primary scale to maintain aspect ratio
  static double get scaleFactor => screenWidth / designWidth;

  static double w(double width) => width * scaleFactor;
  
  // Use h only when you specifically want to fill vertical space 
  // otherwise, use .w for height too to keep things square.
  static double h(double height) => height * (screenHeight / designHeight);

  // Font scaling
  static double sp(double fontSize) => fontSize * scaleFactor;
}

extension SizeExtension on num {
  // Get responsive width
  double get w => Responsive.w(toDouble());

  // Get responsive height
  double get h => Responsive.h(toDouble());

  // Get responsive font size
  double get sp => Responsive.sp(toDouble());

  // Use this for things that MUST stay square (like icons or circular avatars)
  // It uses the width scale for both dimensions.
  double get r => toDouble() * Responsive.scaleFactor;
}