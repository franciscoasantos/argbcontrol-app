class LedStatus {
  final int mode; // 0 static, 1 fade, 2 rainbow
  final int? r;
  final int? g;
  final int? b;
  final int? w;
  final int? fadeIncrease;
  final int? fadeDelay;
  final int? rainbowDelay;

  const LedStatus._({
    required this.mode,
    this.r,
    this.g,
    this.b,
    this.w,
    this.fadeIncrease,
    this.fadeDelay,
    this.rainbowDelay,
  });

  factory LedStatus.staticMode({required int r, required int g, required int b, required int w}) {
    return LedStatus._(mode: 0, r: r, g: g, b: b, w: w);
  }

  factory LedStatus.fadeMode({required int increase, required int delay}) {
    return LedStatus._(mode: 1, fadeIncrease: increase, fadeDelay: delay);
    }

  factory LedStatus.rainbowMode({required int delay}) {
    return LedStatus._(mode: 2, rainbowDelay: delay);
  }

  static LedStatus? tryParse(String message) {
    try {
      if (message.isEmpty) return null;
      final int? m = int.tryParse(message[0]);
      if (m == null) return null;
      // Numeric-only fixed width format only
      if (!RegExp(r'^\d+$').hasMatch(message)) return null;
      switch (m) {
        case 0:
          if (message.length < 13) return null;
          final int r = int.tryParse(message.substring(1, 4)) ?? 0;
          final int g = int.tryParse(message.substring(4, 7)) ?? 0;
          final int b = int.tryParse(message.substring(7, 10)) ?? 0;
          final int w = int.tryParse(message.substring(10, 13)) ?? 0;
          return LedStatus.staticMode(r: r, g: g, b: b, w: w);
        case 1:
          if (message.length < 6) return null;
          final String a = message.substring(1, 6);
          final int inc = int.tryParse(a.substring(0, 2)) ?? 0;
          final int del = int.tryParse(a.substring(2, 5)) ?? 0;
          return LedStatus.fadeMode(increase: inc, delay: del);
        case 2:
          if (message.length < 5) return null;
          final int delay = int.tryParse(message.substring(1, 5)) ?? 0;
          return LedStatus.rainbowMode(delay: delay);
        default:
          return null;
      }
    } catch (_) {
      return null;
    }
  }
}


