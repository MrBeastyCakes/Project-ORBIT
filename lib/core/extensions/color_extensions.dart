import 'package:flutter/material.dart';

extension ColorExtensions on Color {
  /// Returns a copy of this color with its saturation set to [saturation] (0.0–1.0).
  Color withSaturation(double saturation) {
    final hsl = HSLColor.fromColor(this);
    return hsl
        .withSaturation(saturation.clamp(0.0, 1.0))
        .toColor();
  }

  /// Returns a fully desaturated (greyscale) version of this color.
  /// Used for dwarf planet visuals.
  Color desaturated() => withSaturation(0.0);
}
