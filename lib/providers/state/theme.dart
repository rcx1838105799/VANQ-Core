part of '../state.dart';

typedef DynamicColorSeeds = ({
  Color? lightSeed,
  Color? darkSeed,
  Color accentColor,
});

@Riverpod(keepAlive: true)
class DynamicColor extends _$DynamicColor {
  @override
  DynamicColorSeeds build() {
    return (
      lightSeed: null,
      darkSeed: null,
      accentColor: const Color(defaultPrimaryColor),
    );
  }

  void seed({Color? lightSeed, Color? darkSeed, required Color accentColor}) {
    state = (
      lightSeed: lightSeed,
      darkSeed: darkSeed,
      accentColor: accentColor,
    );
  }
}

@riverpod
ColorScheme genColorScheme(
  Ref ref,
  Brightness brightness, {
  Color? color,
  bool ignoreConfig = false,
  bool? pureBlack,
}) {
  final themeSetting = ref.watch(
    themeSettingProvider.select(
      (state) => (
        primaryColor: state.primaryColor,
        schemeVariant: state.schemeVariant,
        pureBlack: state.pureBlack,
      ),
    ),
  );
  final dynamicColor = ref.watch(dynamicColorProvider);
  final Color seedColor;
  if (color == null &&
      (ignoreConfig == true || themeSetting.primaryColor == null)) {
    final seed = switch (brightness) {
      Brightness.light => dynamicColor.lightSeed,
      Brightness.dark => dynamicColor.darkSeed,
    };
    seedColor = seed ?? dynamicColor.accentColor;
  } else {
    seedColor = color ?? Color(themeSetting.primaryColor!);
  }
  return _cachedColorScheme(
    seedColor,
    brightness,
    themeSetting.schemeVariant,
    pureBlack ?? themeSetting.pureBlack,
  );
}

const _maxCachedColorSchemes = 64;

final _colorSchemes =
    <(Color, Brightness, DynamicSchemeVariant, bool), ColorScheme>{};

/// VANQ Core brand surfaces for dark mode (see BRAND.md).
ColorScheme _applyBrandDark(ColorScheme scheme) {
  if (scheme.brightness != Brightness.dark) {
    return scheme;
  }
  return scheme.copyWith(
    surface: const Color(0xFF101026),
    surfaceDim: const Color(0xFF0D0D20),
    surfaceBright: const Color(0xFF3A3270),
    surfaceContainerLowest: const Color(0xFF0C0C22),
    surfaceContainerLow: const Color(0xFF141432),
    surfaceContainer: const Color(0xFF1C1740),
    surfaceContainerHigh: const Color(0xFF231D4A),
    surfaceContainerHighest: const Color(0xFF2C2560),
    onSurface: const Color(0xFFF4F1FF),
    onSurfaceVariant: const Color(0xFFA7A9C9),
  );
}

ColorScheme _cachedColorScheme(
  Color seedColor,
  Brightness brightness,
  DynamicSchemeVariant variant,
  bool pureBlack,
) {
  final key = (seedColor, brightness, variant, pureBlack);
  final colorScheme =
      _colorSchemes.remove(key) ??
      _applyBrandDark(
        ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: brightness,
          dynamicSchemeVariant: variant,
        ),
      ).toPureBlack(pureBlack);
  _colorSchemes[key] = colorScheme;
  if (_colorSchemes.length > _maxCachedColorSchemes) {
    _colorSchemes.remove(_colorSchemes.keys.first);
  }
  return colorScheme;
}

typedef WindowBlurRequest = ({bool enabled, Brightness brightness, Color tint});

@riverpod
WindowBlurRequest windowBlurRequest(Ref ref) {
  final enabled =
      feature.sidebarBlur &&
      ref.watch(themeSettingProvider.select((state) => state.sidebarBlur));
  final brightness = ref.watch(currentBrightnessProvider);
  final colorScheme = ref.watch(genColorSchemeProvider(brightness));
  return (
    enabled: enabled,
    brightness: brightness,
    tint: colorScheme.surfaceContainer,
  );
}

@riverpod
Brightness currentBrightness(Ref ref) {
  final themeMode = ref.watch(
    themeSettingProvider.select((state) => state.themeMode),
  );
  final systemBrightness = ref.watch(systemBrightnessProvider);
  return switch (themeMode) {
    ThemeMode.system => systemBrightness,
    ThemeMode.light => Brightness.light,
    ThemeMode.dark => Brightness.dark,
  };
}
