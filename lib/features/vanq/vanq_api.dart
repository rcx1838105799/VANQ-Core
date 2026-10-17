import 'package:dio/dio.dart';
import 'package:fl_clash/common/common.dart';

/// Xboard panel API client for VANQ Core account features.
///
/// Panel: https://vq.wanwan.biz.id (hardcoded, this is our own brand app).
class VanqApi {
  VanqApi({Dio? dio})
    : _dio = dio ?? Dio(BaseOptions(headers: {'User-Agent': browserUa}));

  static const baseUrl = 'https://vq.wanwan.biz.id';
  static const _loginPath = '/api/v1/passport/auth/login';
  static const _subscribePath = '/api/v1/user/getSubscribe';
  static const _redeemPath = '/api/v1/user/redeem/redeem';
  static const _guestConfigPath = '/api/v1/guest/comm/config';

  final Dio _dio;

  /// Logs in with email + password.
  ///
  /// Returns the `auth_data` value (`"Bearer <token>"`) on success.
  /// Throws [VanqApiException] with the panel message on failure.
  Future<String> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$baseUrl$_loginPath',
      data: {'email': email.trim(), 'password': password},
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
    final body = response.data ?? {};
    if (body['status'] != 'success') {
      throw VanqApiException(_messageOf(body) ?? 'Login failed');
    }
    final data = body['data'];
    final authData = data is Map ? data['auth_data'] as String? : null;
    if (authData == null || authData.isEmpty) {
      throw const VanqApiException('Login succeeded but no token returned');
    }
    return authData;
  }

  /// Fetches the subscription info (plan, traffic, expiry, subscribe URL).
  ///
  /// [authData] is the `"Bearer <token>"` string from [login].
  Future<VanqSubscribeInfo> getSubscribe(String authData) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$baseUrl$_subscribePath',
      options: Options(headers: {'Authorization': authData}),
    );
    final body = response.data ?? {};
    if (body['status'] != 'success') {
      throw VanqApiException(
        _messageOf(body) ?? 'Failed to fetch subscription',
      );
    }
    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw const VanqApiException('Invalid subscription response');
    }
    return VanqSubscribeInfo.fromJson(data);
  }

  /// Fetches the public plan list from the guest config endpoint.
  Future<List<VanqPlan>> getPlans() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$baseUrl$_guestConfigPath',
    );
    final body = response.data ?? {};
    if (body['status'] != 'success') {
      throw VanqApiException(_messageOf(body) ?? 'Failed to fetch plans');
    }
    final data = body['data'];
    final plans = data is Map ? data['plans'] as List? : null;
    if (plans == null) return [];
    return plans
        .whereType<Map<String, dynamic>>()
        .map(VanqPlan.fromJson)
        .toList();
  }

  String? _messageOf(Map<String, dynamic> body) {
    final message = body['message'];
    return message is String && message.isNotEmpty ? message : null;
  }

  /// Redeems an Xboard redemption code for traffic.
  ///
  /// [authData] is the `"Bearer <token>"` string from [login].
  /// Returns the panel's success message. Throws [VanqApiException] on failure.
  Future<String> redeemCode({
    required String authData,
    required String code,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$baseUrl$_redeemPath',
      data: {'code': code.trim()},
      options: Options(
        headers: {'Authorization': authData},
        contentType: Headers.formUrlEncodedContentType,
      ),
    );
    final body = response.data ?? {};
    if (body['status'] != 'success') {
      throw VanqApiException(_messageOf(body) ?? '兑换失败');
    }
    return _messageOf(body) ?? '兑换成功';
  }
}

class VanqApiException implements Exception {
  final String message;

  const VanqApiException(this.message);

  @override
  String toString() => 'VanqApiException: $message';
}

/// A purchasable plan from the Xboard panel.
class VanqPlan {
  final int id;
  final String name;
  final String? content;
  final double price;
  final int? monthPrice;
  final int? quarterPrice;
  final int? halfYearPrice;
  final int? yearPrice;

  const VanqPlan({
    required this.id,
    required this.name,
    this.content,
    required this.price,
    this.monthPrice,
    this.quarterPrice,
    this.halfYearPrice,
    this.yearPrice,
  });

  factory VanqPlan.fromJson(Map<String, dynamic> json) {
    return VanqPlan(
      id: _asInt(json['id']),
      name: json['name'] as String? ?? '',
      content: json['content'] as String?,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      monthPrice: _asIntOrNull(json['month_price']),
      quarterPrice: _asIntOrNull(json['quarter_price']),
      halfYearPrice: _asIntOrNull(json['half_year_price']),
      yearPrice: _asIntOrNull(json['year_price']),
    );
  }

  static int _asInt(Object? v) => _asIntOrNull(v) ?? 0;

  static int? _asIntOrNull(Object? v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }
}

/// The user object returned by `GET /api/v1/user/getSubscribe`.
class VanqSubscribeInfo {
  final String email;
  final String? planName;
  final int transferEnable;
  final int upload;
  final int download;
  final int? expiredAt;
  final String? subscribeUrl;

  const VanqSubscribeInfo({
    required this.email,
    this.planName,
    required this.transferEnable,
    required this.upload,
    required this.download,
    this.expiredAt,
    this.subscribeUrl,
  });

  int get used => upload + download;
  int get remaining => (transferEnable - used).clamp(0, transferEnable);

  factory VanqSubscribeInfo.fromJson(Map<String, dynamic> json) {
    final plan = json['plan'];
    return VanqSubscribeInfo(
      email: json['email'] as String? ?? '',
      planName: plan is Map ? plan['name'] as String? : null,
      transferEnable: _asInt(json['transfer_enable']),
      upload: _asInt(json['u']),
      download: _asInt(json['d']),
      expiredAt: _asIntOrNull(json['expired_at']),
      subscribeUrl: json['subscribe_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'email': email,
    'planName': planName,
    'transferEnable': transferEnable,
    'upload': upload,
    'download': download,
    'expiredAt': expiredAt,
    'subscribeUrl': subscribeUrl,
  };

  factory VanqSubscribeInfo.fromStoredJson(Map<String, dynamic> json) {
    return VanqSubscribeInfo(
      email: json['email'] as String? ?? '',
      planName: json['planName'] as String?,
      transferEnable: _asInt(json['transferEnable']),
      upload: _asInt(json['upload']),
      download: _asInt(json['download']),
      expiredAt: _asIntOrNull(json['expiredAt']),
      subscribeUrl: json['subscribeUrl'] as String?,
    );
  }

  static int _asInt(Object? value) => _asIntOrNull(value) ?? 0;

  static int? _asIntOrNull(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
