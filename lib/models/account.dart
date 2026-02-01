// 위치: lib/models/account.dart
enum AccountPurpose {
  saving,
  investing,
  deposit,
  emergencyFund,
  debt,
  living,
  other,
}

class Account {
  final String id;
  final String name;
  final AccountPurpose purpose;

  /// 현재 잔액(스냅샷)
  final int balanceWon;

  /// 계좌 ID 기반 고정색을 만들 seed
  final int colorSeed;

  const Account({
    required this.id,
    required this.name,
    required this.purpose,
    required this.balanceWon,
    required this.colorSeed,
  });

  Account copyWith({
    String? name,
    AccountPurpose? purpose,
    int? balanceWon,
    int? colorSeed,
  }) {
    return Account(
      id: id,
      name: name ?? this.name,
      purpose: purpose ?? this.purpose,
      balanceWon: balanceWon ?? this.balanceWon,
      colorSeed: colorSeed ?? this.colorSeed,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'purpose': purpose.name,
        'balanceWon': balanceWon,
        'colorSeed': colorSeed,
      };

  static Account fromJson(Map<dynamic, dynamic> json) => Account(
        id: json['id'] as String,
        name: json['name'] as String,
        purpose: AccountPurpose.values.byName(json['purpose'] as String),
        balanceWon: (json['balanceWon'] as int?) ?? 0,
        colorSeed: (json['colorSeed'] as int?) ?? 0,
      );
}
