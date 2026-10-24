import 'dart:async';
import 'dart:convert';

import 'package:fl_clash/common/boot_record.dart';
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/common/system_dns.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Preferences {
  static Preferences? _instance;
  Completer<SharedPreferences?> sharedPreferencesCompleter = Completer();

  Future<bool> get isInit async =>
      await sharedPreferencesCompleter.future != null;

  Preferences._internal() {
    SharedPreferences.getInstance()
        .then((value) => sharedPreferencesCompleter.complete(value))
        .onError((_, _) => sharedPreferencesCompleter.complete(null));
  }

  factory Preferences() {
    _instance ??= Preferences._internal();
    return _instance!;
  }

  Future<int> getVersion() async {
    final preferences = await sharedPreferencesCompleter.future;
    return preferences?.getInt('version') ?? 0;
  }

  Future<void> setVersion(int version) async {
    final preferences = await sharedPreferencesCompleter.future;
    await preferences?.setInt('version', version);
  }

  Future<void> saveShareState(SharedState shareState) async {
    final preferences = await sharedPreferencesCompleter.future;
    await preferences?.setString('sharedState', json.encode(shareState));
  }

  Future<Map<String, Object?>?> getConfigMap() async {
    try {
      final preferences = await sharedPreferencesCompleter.future;
      final configString = preferences?.getString(configKey);
      if (configString == null) return null;
      final Map<String, Object?>? configMap = json.decode(configString);
      return configMap;
    } catch (e) {
      commonPrint.log(
        'getConfigMap error ${e.toString()}',
        logLevel: LogLevel.warning,
      );
      return null;
    }
  }

  Future<Map<String, Object?>?> getClashConfigMap() async {
    try {
      final preferences = await sharedPreferencesCompleter.future;
      final clashConfigString = preferences?.getString(clashConfigKey);
      if (clashConfigString == null) return null;
      return json.decode(clashConfigString);
    } catch (e) {
      commonPrint.log(
        'getClashConfigMap error ${e.toString()}',
        logLevel: LogLevel.warning,
      );
      return null;
    }
  }

  Future<void> clearClashConfig() async {
    try {
      final preferences = await sharedPreferencesCompleter.future;
      await preferences?.remove(clashConfigKey);
      return;
    } catch (e) {
      commonPrint.log(
        'clearClashConfig error ${e.toString()}',
        logLevel: LogLevel.warning,
      );
      return;
    }
  }

  Future<Config?> getConfig() async {
    final configMap = await getConfigMap();
    if (configMap == null) {
      return null;
    }
    return Config.fromJson(configMap);
  }

  Future<bool> saveConfig(Config config) async {
    final preferences = await sharedPreferencesCompleter.future;
    return preferences?.setString(configKey, json.encode(config)) ?? false;
  }

  Future<SystemDnsRecord?> getSystemDnsRecord() async {
    try {
      final sharedPreferencesIns = await sharedPreferencesCompleter.future;
      final raw = sharedPreferencesIns?.getString(systemDnsRecordKey);
      if (raw == null) {
        return null;
      }
      return SystemDnsRecord.fromJson(json.decode(raw));
    } catch (e) {
      commonPrint.log(
        'getSystemDnsRecord error ${e.toString()}',
        logLevel: LogLevel.warning,
      );
      return null;
    }
  }

  Future<void> saveSystemDnsRecord(SystemDnsRecord record) async {
    final sharedPreferencesIns = await sharedPreferencesCompleter.future;
    await sharedPreferencesIns?.setString(
      systemDnsRecordKey,
      json.encode(record),
    );
  }

  Future<void> clearSystemDnsRecord() async {
    final sharedPreferencesIns = await sharedPreferencesCompleter.future;
    await sharedPreferencesIns?.remove(systemDnsRecordKey);
  }

  Future<BootRecord?> getBootRecord() async {
    try {
      final sharedPreferencesIns = await sharedPreferencesCompleter.future;
      final raw = sharedPreferencesIns?.getString(bootRecordKey);
      if (raw == null) {
        return null;
      }
      return BootRecord.fromJson(json.decode(raw));
    } catch (e) {
      commonPrint.log(
        'getBootRecord error ${e.toString()}',
        logLevel: LogLevel.warning,
      );
      return null;
    }
  }

  Future<void> saveBootRecord(BootRecord record) async {
    final sharedPreferencesIns = await sharedPreferencesCompleter.future;
    await sharedPreferencesIns?.setString(bootRecordKey, json.encode(record));
  }

  Future<void> clearPreferences() async {
    final sharedPreferencesIns = await sharedPreferencesCompleter.future;
    await sharedPreferencesIns?.clear();
  }

  static const _vanqAccountKey = 'vanqAccount';

  Future<void> saveVanqAccount(dynamic account) async {
    final sharedPreferencesIns = await sharedPreferencesCompleter.future;
    await sharedPreferencesIns?.setString(
      _vanqAccountKey,
      json.encode(account.toJson()),
    );
  }

  /// Returns the persisted VANQ account, or null when signed out.
  ///
  /// The JSON is decoded generically here to avoid a dependency from
  /// common/ on the account model; callers cast it into shape.
  Future<Map<String, dynamic>?> getVanqAccountJson() async {
    try {
      final sharedPreferencesIns = await sharedPreferencesCompleter.future;
      final raw = sharedPreferencesIns?.getString(_vanqAccountKey);
      if (raw == null) return null;
      final decoded = json.decode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (e) {
      commonPrint.log(
        'getVanqAccountJson error ${e.toString()}',
        logLevel: LogLevel.warning,
      );
      return null;
    }
  }

  Future<void> clearVanqAccount() async {
    final sharedPreferencesIns = await sharedPreferencesCompleter.future;
    await sharedPreferencesIns?.remove(_vanqAccountKey);
  }

  static const _vanqPointsKey = 'vanqGamePoints';
  static const _vanqCheckInKey = 'vanqLastCheckIn';
  static const _vanqCheckInStreakKey = 'vanqCheckInStreak';
  static const _vanqOwnedCharsKey = 'vanqOwnedChars';
  static const _vanqCompanionIdKey = 'vanqCompanionId';
  static const _vanqAffectionKey = 'vanqAffection';
  static const _vanqAffectionDayKey = 'vanqAffectionDay';
  static const _vanqAddedTodayKey = 'vanqAddedToday';
  static const _vanqBackgroundIdKey = 'vanqBackgroundId';

  Future<int> getVanqPoints() async {
    final sp = await sharedPreferencesCompleter.future;
    return sp?.getInt(_vanqPointsKey) ?? 0;
  }

  Future<void> saveVanqPoints(int points) async {
    final sp = await sharedPreferencesCompleter.future;
    await sp?.setInt(_vanqPointsKey, points);
  }

  Future<String?> getVanqLastCheckIn() async {
    final sp = await sharedPreferencesCompleter.future;
    return sp?.getString(_vanqCheckInKey);
  }

  Future<void> saveVanqLastCheckIn(String date) async {
    final sp = await sharedPreferencesCompleter.future;
    await sp?.setString(_vanqCheckInKey, date);
  }

  Future<int> getVanqCheckInStreak() async {
    final sp = await sharedPreferencesCompleter.future;
    return sp?.getInt(_vanqCheckInStreakKey) ?? 0;
  }

  Future<void> saveVanqCheckInStreak(int streak) async {
    final sp = await sharedPreferencesCompleter.future;
    await sp?.setInt(_vanqCheckInStreakKey, streak);
  }

  Future<List<String>> getVanqOwnedChars() async {
    final sp = await sharedPreferencesCompleter.future;
    return sp?.getStringList(_vanqOwnedCharsKey) ?? [];
  }

  Future<void> saveVanqOwnedChars(List<String> ids) async {
    final sp = await sharedPreferencesCompleter.future;
    await sp?.setStringList(_vanqOwnedCharsKey, ids);
  }

  Future<String?> getVanqCompanionId() async {
    final sp = await sharedPreferencesCompleter.future;
    return sp?.getString(_vanqCompanionIdKey);
  }

  Future<void> saveVanqCompanionId(String id) async {
    final sp = await sharedPreferencesCompleter.future;
    await sp?.setString(_vanqCompanionIdKey, id);
  }

  Future<Map<String, int>> getVanqAffection() async {
    final sp = await sharedPreferencesCompleter.future;
    final raw = sp?.getString(_vanqAffectionKey);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((key, value) => MapEntry(key, (value as num).toInt()));
    } catch (_) {
      return {};
    }
  }

  Future<void> saveVanqAffection(Map<String, int> affection) async {
    final sp = await sharedPreferencesCompleter.future;
    await sp?.setString(_vanqAffectionKey, jsonEncode(affection));
  }

  Future<String?> getVanqAffectionDay() async {
    final sp = await sharedPreferencesCompleter.future;
    return sp?.getString(_vanqAffectionDayKey);
  }

  Future<void> saveVanqAffectionDay(String day) async {
    final sp = await sharedPreferencesCompleter.future;
    await sp?.setString(_vanqAffectionDayKey, day);
  }

  Future<Map<String, int>> getVanqAddedToday() async {
    final sp = await sharedPreferencesCompleter.future;
    final raw = sp?.getString(_vanqAddedTodayKey);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((key, value) => MapEntry(key, (value as num).toInt()));
    } catch (_) {
      return {};
    }
  }

  Future<void> saveVanqAddedToday(Map<String, int> added) async {
    final sp = await sharedPreferencesCompleter.future;
    await sp?.setString(_vanqAddedTodayKey, jsonEncode(added));
  }

  Future<String> getVanqBackgroundId() async {
    final sp = await sharedPreferencesCompleter.future;
    return sp?.getString(_vanqBackgroundIdKey) ?? '';
  }

  Future<void> saveVanqBackgroundId(String id) async {
    final sp = await sharedPreferencesCompleter.future;
    await sp?.setString(_vanqBackgroundIdKey, id);
  }
}

final preferences = Preferences();
