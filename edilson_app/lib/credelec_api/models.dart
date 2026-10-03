class MeterInfo {
  final String meterNumber;
  final String location;
  final String type;
  final double balanceKwh;

  MeterInfo({
    required this.meterNumber,
    required this.location,
    required this.type,
    this.balanceKwh = 0,
  });

  MeterInfo copyWith({double? balanceKwh}) {
    return MeterInfo(
      meterNumber: meterNumber,
      location: location,
      type: type,
      balanceKwh: balanceKwh ?? this.balanceKwh,
    );
  }

  factory MeterInfo.fromJson(Map<String, dynamic> json) {
    return MeterInfo(
      meterNumber: json['meterNumber'] ?? '',
      location: json['location'] ?? '',
      type: json['type'] ?? '',
      balanceKwh: (json['balanceKwh'] as num?)?.toDouble() ?? 0,
    );
  }
}

class RechargeResponse {
  final String token;
  final double kwh;
  final String status;
  final String meterNumber;
  final double amount;
  final double balanceKwh;

  RechargeResponse({
    required this.token,
    required this.kwh,
    required this.status,
    this.meterNumber = '',
    this.amount = 0,
    this.balanceKwh = 0,
  });

  factory RechargeResponse.fromJson(Map<String, dynamic> json) {
    return RechargeResponse(
      token: json['token'] ?? '',
      kwh: (json['kwh'] as num?)?.toDouble() ?? 0,
      status: json['status'] ?? '',
      meterNumber: json['meterNumber'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      balanceKwh: (json['balanceKwh'] as num?)?.toDouble() ?? 0,
    );
  }
}
