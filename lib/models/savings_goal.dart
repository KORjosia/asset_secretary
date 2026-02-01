//asset_secretary\lib\models\savings_goal.dart

class SavingsGoal {
  final int targetWon; // 목표금액 (0이면 미설정)

  const SavingsGoal({required this.targetWon});

  Map<String, dynamic> toJson() => {'targetWon': targetWon};

  static SavingsGoal fromJson(Map<dynamic, dynamic> json) => SavingsGoal(
        targetWon: (json['targetWon'] as int?) ?? 0,
      );
}
