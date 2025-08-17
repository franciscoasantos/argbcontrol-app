import 'package:argbcontrol_app/services/ws_client.dart';
import 'package:flutter/material.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:argbcontrol_app/utils/debouncer.dart';
import 'package:argbcontrol_app/models/message_builder.dart';
import 'package:argbcontrol_app/utils/favorites_manager.dart';
import 'dart:math' as math;

class StaticPage extends StatefulWidget {
  const StaticPage({super.key, required this.wsClient});

  final LedWebSocketClient wsClient;

  @override
  _StaticPageState createState() => _StaticPageState();
}

class _StaticPageState extends State<StaticPage>
    with AutomaticKeepAliveClientMixin<StaticPage> {
  Color _currentColor = const Color.fromARGB(0, 0, 0, 0);
  double _whiteIntensity = 0;
  final Debouncer _debouncer = Debouncer(duration: const Duration(milliseconds: 120));
  Color? _lastSentColor;
  bool _appliedInitial = false;
  
  late List<Color> _favoriteColors;
  final FavoritesManager _favoritesManager = const FavoritesManager();
  static const int _maxFavorites = 24;
  static const int _colorTolerance = 30; // distância euclidiana nos canais RGB

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Aplica status inicial quando recebido (M == 0)
    widget.wsClient.statusListenable.addListener(_applyInitialFromStatus);
    // Tenta aplicar imediatamente caso já exista último status
    _applyInitialFromStatus();
    // Inicializa imediatamente com paleta vibrante padrão e carrega persistidos em seguida
    _favoriteColors = _favoritesManager.defaultCurated();
    _loadFavorites();
  }

  @override
  void dispose() {
    widget.wsClient.statusListenable.removeListener(_applyInitialFromStatus);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final size = MediaQuery.of(context).size;
    final double wheelDiameter = math.max(180.0, math.min(320.0, size.width - 48));
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ColorPicker(
                color: _currentColor,
                onColorChanged: (color) {
                  final newColor = Color.fromARGB(
                    _currentColor.alpha,
                    color.red,
                    color.green,
                    color.blue,
                  );
                  _debouncer.run(() => _sendMessage(newColor));
                  setState(() => _currentColor = newColor);
                },
                enableOpacity: false,
                pickersEnabled: const {
                  ColorPickerType.wheel: true,
                  ColorPickerType.primary: false,
                  ColorPickerType.accent: false,
                  ColorPickerType.custom: false,
                },
                width: 36,
                height: 36,
                borderRadius: 8,
                wheelDiameter: wheelDiameter,
                colorCodeHasColor: true,

              ),
            ),
                        const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.wb_sunny_outlined, size: 18),
                      const SizedBox(width: 8),
                      const Text('Intensidade do branco'),
                      const Spacer(),
                      Text('${(_whiteIntensity / 255 * 100).round()}%'),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 6,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 10),
                      overlayShape:
                          const RoundSliderOverlayShape(overlayRadius: 18),
                    ),
                    child: Slider(
                      value: _whiteIntensity,
                      max: 255,
                      min: 0,
                      divisions: 51,
                      onChanged: (double value) {
                        final color = Color.fromARGB(
                          value.round(),
                          _currentColor.red,
                          _currentColor.green,
                          _currentColor.blue,
                        );
                        _debouncer.run(() => _sendMessage(color));
                        setState(() {
                          _whiteIntensity = value;
                          _currentColor = color;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    Text(
                      'Favoritas',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Adicionar favorito',
                      icon: const Icon(Icons.bookmark_add_outlined),
                      onPressed: _addCurrentToFavorites,
                    ),
                    IconButton(
                      tooltip: 'Gerenciar favoritos',
                      icon: const Icon(Icons.settings_outlined),
                      onPressed: _showManageFavorites,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _favoriteColors
                    .map(
                      (c) => ColorIndicator(
                        color: c,
                        width: 34,
                        height: 34,
                        borderRadius: 8,
                        hasBorder: false,
                        onSelect: () {
                          final selected = Color.fromARGB(
                            _currentColor.alpha,
                            c.red,
                            c.green,
                            c.blue,
                          );
                          _debouncer.run(() => _sendMessage(selected));
                          setState(() => _currentColor = selected);
                        },
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage(Color color) {
    if (color != _lastSentColor) {
      widget.wsClient.sendUserMessage(MessageBuilder.staticMode(
        r: color.red,
        g: color.green,
        b: color.blue,
        w: color.alpha,
      ));
      _lastSentColor = color;
    }
  }

  void _applyInitialFromStatus() {
    if (_appliedInitial) return;
    final s = widget.wsClient.statusListenable.value;
    if (s == null || s.mode != 0) return;
    final int r = s.r ?? 0;
    final int g = s.g ?? 0;
    final int b = s.b ?? 0;
    final int w = s.w ?? 0;
    final color = Color.fromARGB(w, r, g, b);
    setState(() {
      _currentColor = color;
      _whiteIntensity = w.toDouble();
    });
    _appliedInitial = true;
  }

  Future<void> _loadFavorites() async {
    final saved = await _favoritesManager.loadFavorites();
    setState(() {
      _favoriteColors = saved.isEmpty
          ? _favoritesManager.defaultCurated()
          : saved;
    });
  }

  Future<void> _addCurrentToFavorites() async {
    final Color normalized = _normalizeFavorite(_currentColor);
    final bool existsNear = _favoriteColors
        .map(_normalizeFavorite)
        .any((c) => _isNearColor(c, normalized));
    if (existsNear) {
      _showSnack('Já existe um favorito semelhante.');
      return;
    }
    if (_favoriteColors.length >= _maxFavorites) {
      _showSnack('Limite de $_maxFavorites favoritos atingido.');
      return;
    }
    setState(() => _favoriteColors = [..._favoriteColors, normalized]);
    await _favoritesManager.saveFavorites(_favoriteColors);
  }

  Future<void> _removeFavorite(Color color) async {
    setState(() => _favoriteColors =
        _favoriteColors.where((c) => c.value != color.value).toList());
    await _favoritesManager.saveFavorites(_favoriteColors);
  }

  void _showManageFavorites() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Gerenciar favoritos', style: Theme.of(context).textTheme.titleMedium),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (dCtx) => AlertDialog(
                                title: const Text('Resetar favoritos?'),
                                content: const Text(
                                  'Isso substituirá seus favoritos atuais pela paleta padrão vibrante.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(dCtx, false),
                                    child: const Text('Cancelar'),
                                  ),
                                  FilledButton(
                                    onPressed: () => Navigator.pop(dCtx, true),
                                    child: const Text('Resetar'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm != true) return;
                            final defaults = _favoritesManager.defaultCurated();
                            setState(() => _favoriteColors = defaults);
                            setModalState(() {});
                            await _favoritesManager.saveFavorites(_favoriteColors);
                          },
                          icon: const Icon(Icons.restore),
                          label: const Text('Reset favoritos'),
                        )
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _favoriteColors
                          .map(
                            (c) => Stack(
                              alignment: Alignment.topRight,
                              children: [
                                ColorIndicator(
                                  color: c,
                                  width: 40,
                                  height: 40,
                                  borderRadius: 10,
                                  hasBorder: true,
                                  onSelect: () {
                                    Navigator.pop(ctx);
                                    _debouncer.run(() => _sendMessage(c));
                                    setState(() => _currentColor = c);
                                  },
                                ),
                                Positioned(
                                  right: -10,
                                  top: -10,
                                  child: IconButton(
                                    icon: const Icon(Icons.close, size: 18),
                                    onPressed: () async {
                                      await _removeFavorite(c);
                                      setModalState(() {});
                                      if (mounted) setState(() {});
                                    },
                                  ),
                                )
                              ],
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  bool _isNearColor(Color a, Color b) {
    final dr = a.red - b.red;
    final dg = a.green - b.green;
    final db = a.blue - b.blue;
    final dist2 = dr * dr + dg * dg + db * db;
    return dist2 <= _colorTolerance * _colorTolerance;
  }

  Color _normalizeFavorite(Color c) => Color.fromARGB(255, c.red, c.green, c.blue);


  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
