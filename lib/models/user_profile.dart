// 위치: lib/models/user_profile.dart
class UserProfile {
  final int monthlyIncomeWon;

  /// MVP: 급여일(1~28 추천). 지금은 “사이클 계산”용 기반만 깔아둠.
  final int paydayDay;

  const UserProfile({
    required this.monthlyIncomeWon,
    required this.paydayDay,
  });

  UserProfile copyWith({
    int? monthlyIncomeWon,
    int? paydayDay,
  }) {
    return UserProfile(
      monthlyIncomeWon: monthlyIncomeWon ?? this.monthlyIncomeWon,
      paydayDay: paydayDay ?? this.paydayDay,
    );
  }

  Map<String, dynamic> toJson() => {
        'monthlyIncomeWon': monthlyIncomeWon,
        'paydayDay': paydayDay,
      };

  static UserProfile fromJson(Map<dynamic, dynamic> json) => UserProfile(
        monthlyIncomeWon: (json['monthlyIncomeWon'] as int?) ?? 0,
        paydayDay: (json['paydayDay'] as int?) ?? 25,
      );
}
