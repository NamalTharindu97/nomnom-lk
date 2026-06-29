import 'package:flutter/material.dart';

class Spacings {
  const Spacings._();

  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  static const EdgeInsets padH = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets padV = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets padAll = EdgeInsets.all(md);
  static const EdgeInsets padSmH = EdgeInsets.symmetric(horizontal: xs);
  static const EdgeInsets padSmV = EdgeInsets.symmetric(vertical: xs);
  static const EdgeInsets padLgH = EdgeInsets.symmetric(horizontal: xl);
  static const EdgeInsets padLgV = EdgeInsets.symmetric(vertical: xl);
  static const EdgeInsets padTop = EdgeInsets.only(top: md);
  static const EdgeInsets padBottom = EdgeInsets.only(bottom: md);
  static const EdgeInsets padLeft = EdgeInsets.only(left: md);
  static const EdgeInsets padRight = EdgeInsets.only(right: md);
}
