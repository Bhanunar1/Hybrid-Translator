import 'package:flutter/material.dart';

extension ColorExtension on Color {
  Color darken([int percent = 10]) {
    assert(1 <= percent && percent <= 100);
    var f = 1 - percent / 100;
    return Color.fromARGB(
        (a * 255).round(),
        (r * 255 * f).round(),
        (g * 255 * f).round(),
        (b * 255 * f).round());
  }
}
