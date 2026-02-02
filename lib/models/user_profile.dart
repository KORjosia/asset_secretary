// 위치: lib/models/user_profile.dart
class UserProfile {
  final String job;
  final String company;
  final String region;

  final int monthlyIncomeWon;
  final int sideIncomeWon;
  final int savingsGoalWon;

  // ✅ 월급날 (1~28)
  final int paydayDay;

  const UserProfile({
    required this.job,
    required this.company,
    required this.region,
    required this.monthlyIncomeWon,
    required this.sideIncomeWon,
    required this.savingsGoalWon,
    required this.paydayDay,
  });

  factory UserProfile.empty() => const UserProfile(
        job: '',
        company: '',
        region: '',
        monthlyIncomeWon: 0,
        sideIncomeWon: 0,
        savingsGoalWon: 0,
        paydayDay: 25,
      );

  Map<String, dynamic> toJson() => {
        'job': job,
        'company': company,
        'region': region,
        'monthlyIncomeWon': monthlyIncomeWon,
        'sideIncomeWon': sideIncomeWon,
        'savingsGoalWon': savingsGoalWon,
        'paydayDay': paydayDay,
      };

  static UserProfile fromJson(Map<dynamic, dynamic> json) => UserProfile(
        job: (json['job'] as String?) ?? '',
        company: (json['company'] as String?) ?? '',
        region: (json['region'] as String?) ?? '',
        monthlyIncomeWon: (json['monthlyIncomeWon'] as int?) ?? 0,
        sideIncomeWon: (json['sideIncomeWon'] as int?) ?? 0,
        savingsGoalWon: (json['savingsGoalWon'] as int?) ?? 0,
        paydayDay: ((json['paydayDay'] as int?) ?? 25).clamp(1, 28),
      );

  UserProfile copyWith({
    String? job,
    String? company,
    String? region,
    int? monthlyIncomeWon,
    int? sideIncomeWon,
    int? savingsGoalWon,
    int? paydayDay,
  }) {
    return UserProfile(
      job: job ?? this.job,
      company: company ?? this.company,
      region: region ?? this.region,
      monthlyIncomeWon: monthlyIncomeWon ?? this.monthlyIncomeWon,
      sideIncomeWon: sideIncomeWon ?? this.sideIncomeWon,
      savingsGoalWon: savingsGoalWon ?? this.savingsGoalWon,
      paydayDay: (paydayDay ?? this.paydayDay).clamp(1, 28),
    );
  }

  bool get isBasicComplete =>
      job.trim().isNotEmpty && region.trim().isNotEmpty && monthlyIncomeWon > 0;
}
