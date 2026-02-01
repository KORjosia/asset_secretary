// 위치: lib/models/transaction.dart
enum TxType { inflow, outflow }

/// 막대(행동)에서 제외해야 하는 자동입금들
enum InflowKind { salaryOrManual, interest, dividend, refund }

class Tx {
  final String id;
  final String accountId;
  final TxType type;
  final int amountWon;
  final int createdAtMs;

  /// inflow일 때만 의미 있음
  final InflowKind inflowKind;

  const Tx({
    required this.id,
    required this.accountId,
    required this.type,
    required this.amountWon,
    required this.createdAtMs,
    this.inflowKind = InflowKind.salaryOrManual,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'accountId': accountId,
        'type': type.name,
        'amountWon': amountWon,
        'createdAtMs': createdAtMs,
        'inflowKind': inflowKind.name,
      };

  static Tx fromJson(Map<dynamic, dynamic> json) => Tx(
        id: json['id'] as String,
        accountId: json['accountId'] as String,
        type: TxType.values.byName(json['type'] as String),
        amountWon: (json['amountWon'] as int?) ?? 0,
        createdAtMs: (json['createdAtMs'] as int?) ?? 0,
        inflowKind: json['inflowKind'] == null
            ? InflowKind.salaryOrManual
            : InflowKind.values.byName(json['inflowKind'] as String),
      );
}
