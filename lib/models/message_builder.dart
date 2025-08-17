import 'dart:convert';

class MessageBuilder {
  static String staticMode({required int r, required int g, required int b, required int w}) {
    return jsonEncode({
      'M': '0',
      'R': '$r',
      'G': '$g',
      'B': '$b',
      'W': '$w',
    });
  }

  static String fade({required int increase, required int delay}) {
    final a = '${increase.toString().padLeft(2, '0')}${delay.toString().padLeft(3, '0')}';
    return jsonEncode({
      'M': '1',
      'A': a,
    });
  }

  static String rainbow({required int delay}) {
    return jsonEncode({
      'M': '2',
      'A': delay.toString().padLeft(4, '0'),
    });
  }
}


