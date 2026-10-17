part of '../state.dart';

/// VANQ Core game center: points, check-in streak, rewards.
///
/// Points are earned via daily check-in and mini-games. 25 points = 1MB
/// of traffic (redeemed via Xboard redemption codes provided by the owner).
class VanqGameData {
  final int points;
  final int streak;
  final String? lastCheckIn; // yyyy-MM-dd

  const VanqGameData({
    required this.points,
    required this.streak,
    this.lastCheckIn,
  });

  static const pointsPerMb = 25;

  int get redeemableMb => points ~/ pointsPerMb;
}

@Riverpod(keepAlive: true)
class VanqGame extends _$VanqGame {
  @override
  Future<VanqGameData> build() async {
    final points = await preferences.getVanqPoints();
    final streak = await preferences.getVanqCheckInStreak();
    final last = await preferences.getVanqLastCheckIn();
    return VanqGameData(points: points, streak: streak, lastCheckIn: last);
  }

  /// Adds [amount] points (can be negative, clamped at 0).
  Future<void> addPoints(int amount) async {
    final current = state.value;
    if (current == null) return;
    final next = ((current.points + amount).clamp(0, 1 << 31));
    await preferences.saveVanqPoints(next);
    state = AsyncData(
      VanqGameData(
        points: next,
        streak: current.streak,
        lastCheckIn: current.lastCheckIn,
      ),
    );
  }

  /// Daily check-in. Returns the points awarded, or 0 if already checked in.
  Future<int> checkIn() async {
    final current = state.value;
    if (current == null) return 0;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (current.lastCheckIn == today) return 0;

    final yesterday = DateTime.now()
        .subtract(const Duration(days: 1))
        .toIso8601String()
        .substring(0, 10);
    final streak = current.lastCheckIn == yesterday ? current.streak + 1 : 1;
    // 10 base + 2 per streak day, capped at 30.
    final award = ((10 + (streak - 1) * 2).clamp(10, 30));

    await preferences.saveVanqLastCheckIn(today);
    await preferences.saveVanqCheckInStreak(streak);
    final next = current.points + award;
    await preferences.saveVanqPoints(next);
    state = AsyncData(
      VanqGameData(points: next, streak: streak, lastCheckIn: today),
    );
    return award;
  }

  /// Spends [mb] MB worth of points. Returns true on success.
  Future<bool> spendPointsForMb(int mb) async {
    final cost = mb * VanqGameData.pointsPerMb;
    final current = state.value;
    if (current == null || current.points < cost) return false;
    await addPoints(-cost);
    return true;
  }
}
