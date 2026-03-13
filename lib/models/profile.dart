class Profile {
  final String deviceId;
  final String subscriptionId;
  final String vlessUrl;
  final String planCode;
  final DateTime expiresAt;

  Profile({
    required this.deviceId,
    required this.subscriptionId,
    required this.vlessUrl,
    required this.planCode,
    required this.expiresAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      deviceId: json['device_id'],
      subscriptionId: json['subscription_id'],
      vlessUrl: json['vless_url'],
      planCode: json['plan_code'],
      expiresAt: DateTime.parse(json['expires_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'device_id': deviceId,
    'subscription_id': subscriptionId,
    'vless_url': vlessUrl,
    'plan_code': planCode,
    'expires_at': expiresAt.toIso8601String(),
  };
}