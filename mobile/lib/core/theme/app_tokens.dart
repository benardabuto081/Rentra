import 'package:flutter/animation.dart';

/// 8-point spacing scale. [xxs] is only for tight icon gaps.
class AppSpacing {
  const AppSpacing._();

  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 16;
  static const double md = 24;
  static const double lg = 32;
  static const double xl = 40;
  static const double xxl = 48;
  static const double xxxl = 64;
}

class AppRadii {
  const AppRadii._();

  static const double button = 12;
  static const double input = 12;
  static const double image = 16;
  static const double card = 20;
  static const double dialog = 24;
  static const double sheet = 28;
}

class AppMotion {
  const AppMotion._();

  static const fast = Duration(milliseconds: 150);
  static const normal = Duration(milliseconds: 200);
  static const slow = Duration(milliseconds: 250);
  static const Curve curve = Curves.easeOutCubic;
  static const double pressedScale = 0.98;
}

class AppSizes {
  const AppSizes._();

  static const double minTouchTarget = 48;
  static const double iconSm = 16;
  static const double iconInline = 20;
  static const double iconMd = 24;
  static const double iconLg = 32;
}
