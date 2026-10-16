part of '../state.dart';

/// The signed-in VANQ Core (airport) account, if any.
class VanqAccountData {
  final String authData;
  final VanqSubscribeInfo info;

  const VanqAccountData({required this.authData, required this.info});

  Map<String, dynamic> toJson() => {
    'authData': authData,
    'info': info.toJson(),
  };

  factory VanqAccountData.fromJson(Map<String, dynamic> json) {
    return VanqAccountData(
      authData: json['authData'] as String,
      info: VanqSubscribeInfo.fromStoredJson(
        json['info'] as Map<String, dynamic>,
      ),
    );
  }
}

@Riverpod(keepAlive: true)
class VanqAccount extends _$VanqAccount {
  final _api = VanqApi();

  @override
  Future<VanqAccountData?> build() async {
    final json = await preferences.getVanqAccountJson();
    if (json == null) return null;
    try {
      return VanqAccountData.fromJson(json);
    } catch (error) {
      commonPrint.log(
        'persisted vanq account unreadable: ${compactError(error)}',
        logLevel: LogLevel.warning,
      );
      return null;
    }
  }

  /// Signs in with the airport account, persists the token and fetches the
  /// subscription info. Callers handle profile auto-import via [subscribeUrl].
  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final authData = await _api.login(email: email, password: password);
      final info = await _api.getSubscribe(authData);
      final data = VanqAccountData(authData: authData, info: info);
      await preferences.saveVanqAccount(data);
      return data;
    });
  }

  Future<void> signOut() async {
    await preferences.clearVanqAccount();
    state = const AsyncData(null);
  }

  /// Re-fetches subscription info (traffic, expiry) for the signed-in account.
  Future<void> refresh() async {
    final current = state.value;
    if (current == null) return;
    final account = await AsyncValue.guard(() async {
      final info = await _api.getSubscribe(current.authData);
      final data = VanqAccountData(authData: current.authData, info: info);
      await preferences.saveVanqAccount(data);
      return data;
    });
    // Keep the old data on failure so the card doesn't blank out.
    if (account.hasValue) {
      state = account;
    } else if (account.hasError) {
      commonPrint.log(
        'vanq account refresh failed: ${compactError(account.error!)}',
        logLevel: LogLevel.warning,
      );
    }
  }
}
