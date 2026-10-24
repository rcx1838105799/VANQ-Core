part of '../state.dart';

@Riverpod(keepAlive: true)
class VanqBackground extends _$VanqBackground {
  @override
  Future<String> build() async {
    return preferences.getVanqBackgroundId();
  }

  Future<void> setBackground(String id) async {
    await preferences.saveVanqBackgroundId(id);
    state = AsyncData(id);
  }

  Future<void> clearBackground() async {
    await preferences.saveVanqBackgroundId('');
    state = const AsyncData('');
  }
}
