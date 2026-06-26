/// Design-token: a single spacing & radius scale used everywhere.
///
/// Using a fixed scale (instead of arbitrary numbers like `padding: 13`) is
/// what makes a UI feel consistent. Think of these like Tailwind's spacing
/// steps. `abstract final class` = a pure namespace: it can't be instantiated
/// or subclassed, it only holds `static const` values.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

/// Corner-radius scale.
abstract final class AppRadii {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double pill = 999;
}
