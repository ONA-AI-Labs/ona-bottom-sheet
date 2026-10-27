import 'dart:math';

/// Small numeric helpers the sheet's physics share.
extension DoubleUtils on double {
  /// This value, clamped to the range -[norm]..[norm].
  double clampAbs(double norm) => min(max(-norm, this), norm);

  /// Whichever of [a] and [b] is nearer to this value.
  double nearest(double a, double b) => (a - this).abs() < (b - this).abs() ? a : b;

  /// Where this value sits between [min] (0) and [max] (1); 1 when they are equal.
  double inverseLerp(double min, double max) {
    return min == max ? 1.0 : (this - min) / (max - min);
  }
}
