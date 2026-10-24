part of '../state.dart';

/// VANQ Core game center: points, check-in streak, daily limits.
///
/// Points are earned via daily check-in and mini-games. 25 points = 1MB
/// of traffic (redeemed via Xboard redemption codes provided by the owner).
/// Anti-farming: each game max 20 plays/day, total game points max
/// 200/day. Check-in is exempt from the daily earnings cap.
class VanqGameData {
  final int points;
  final int streak;
  final String? lastCheckIn;
  final Map<String, int> playsToday;
  final int earnedToday;

  const VanqGameData({
    required this.points,
    required this.streak,
    this.lastCheckIn,
    this.playsToday = const {},
    this.earnedToday = 0,
  });

  static const pointsPerMb = 25;
  static const maxPlaysPerGamePerDay = 20;
  static const maxEarnedPerDay = 200;

  int get redeemableMb => points ~/ pointsPerMb;

  int remainingPlays(String gameId) =>
      maxPlaysPerGamePerDay - (playsToday[gameId] ?? 0);

  VanqGameData copyWith({
    int? points,
    int? streak,
    String? lastCheckIn,
    Map<String, int>? playsToday,
    int? earnedToday,
  }) {
    return VanqGameData(
      points: points ?? this.points,
      streak: streak ?? this.streak,
      lastCheckIn: lastCheckIn ?? this.lastCheckIn,
      playsToday: playsToday ?? this.playsToday,
      earnedToday: earnedToday ?? this.earnedToday,
    );
  }
}

@Riverpod(keepAlive: true)
class VanqGame extends _$VanqGame {
  @override
  Future<VanqGameData> build() async {
    final points = await preferences.getVanqPoints();
    final streak = await preferences.getVanqCheckInStreak();
    final last = await preferences.getVanqLastCheckIn();
    final daily = await preferences.getVanqGameDaily();
    return VanqGameData(
      points: points,
      streak: streak,
      lastCheckIn: last,
      playsToday: daily.plays,
      earnedToday: daily.earned,
    );
  }

  /// Adds [amount] points (can be negative, clamped at 0).
  /// Raw adjustment without daily-limit bookkeeping; used for spending.
  Future<void> addPoints(int amount) async {
    final current = state.value;
    if (current == null) return;
    final next = ((current.points + amount).clamp(0, 1 << 31));
    await preferences.saveVanqPoints(next);
    state = AsyncData(current.copyWith(points: next));
  }

  /// Records one play of [gameId]. Returns false when the daily cap
  /// for that game is already reached.
  Future<bool> recordPlay(String gameId) async {
    final current = state.value;
    if (current == null) return false;
    if (current.remainingPlays(gameId) <= 0) return false;
    final plays = Map<String, int>.of(current.playsToday);
    plays[gameId] = (plays[gameId] ?? 0) + 1;
    await preferences.saveVanqGameDaily(plays, current.earnedToday);
    state = AsyncData(current.copyWith(playsToday: plays));
    return true;
  }

  /// Awards game points under the daily 200 cap. Returns the amount
  /// actually added (may be less than requested, or 0 when capped).
  Future<int> awardGamePoints(int amount) async {
    final current = state.value;
    if (current == null || amount <= 0) return 0;
    final room = VanqGameData.maxEarnedPerDay - current.earnedToday;
    if (room <= 0) return 0;
    final actual = amount < room ? amount : room;
    final next = current.points + actual;
    await preferences.saveVanqPoints(next);
    await preferences.saveVanqGameDaily(
      current.playsToday,
      current.earnedToday + actual,
    );
    state = AsyncData(
      current.copyWith(points: next, earnedToday: current.earnedToday + actual),
    );
    return actual;
  }

  /// One full round: counts a play, then awards points under the cap.
  /// Returns -1 when the game is out of plays today, otherwise the
  /// amount actually awarded.
  Future<int> playGame(String gameId, int award) async {
    if (!await recordPlay(gameId)) return -1;
    return awardGamePoints(award);
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
      current.copyWith(points: next, streak: streak, lastCheckIn: today),
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
