import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesManager {
  static const String _prefsKey = 'favorite_colors_v1';

  const FavoritesManager();

  Future<List<Color>> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_prefsKey) ?? [];
    return list
        .map((s) => int.tryParse(s))
        .whereType<int>()
        .map((value) => Color(value))
        .toList(growable: true);
  }

  Future<void> saveFavorites(List<Color> colors) async {
    final prefs = await SharedPreferences.getInstance();
    final list = colors.map((c) => c.value.toString()).toList();
    await prefs.setStringList(_prefsKey, list);
  }

  List<Color> defaultCurated() {
    // Paleta vibrante (alta saturação) adequada para LEDs
    return const [
      Color(0xFFFFFFFF), // White
      Color(0xFFFF0000), // Red
      Color(0xFFFF6D00), // Orange
      Color(0xFFFFFF00), // Yellow
      Color(0xFF76FF03), // Lime
      Color(0xFF00FF00), // Green
      Color(0xFF00E5FF), // Cyan
      Color(0xFF00B0FF), // Azure
      Color(0xFF0000FF), // Blue
      Color(0xFF651FFF), // Indigo/Violet
      Color(0xFFFF00FF), // Magenta
      Color(0xFFFF4081), // Pink
    ];
  }
}


