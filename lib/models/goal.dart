//asset_secretary\lib\models\goal.dart

class Goal {
  final String id;
  final String title;
  final int targetAmountWon; // 목표 금액
  final int currentAmountWon; // 현재 모은 금액

  const Goal({
    required this.id,
    required this.title,
    required this.targetAmountWon,
    required this.currentAmountWon,
  });

  int get remainingWon => (targetAmountWon - currentAmountWon).clamp(0, 1 << 60);

  double get progress =>
      targetAmountWon == 0 ? 0 : (currentAmountWon / targetAmountWon).clamp(0, 1);

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'targetAmountWon': targetAmountWon,
        'currentAmountWon': currentAmountWon,
      };

  static Goal fromJson(Map<dynamic, dynamic> json) => Goal(
        id: json['id'] as String,
        title: json['title'] as String,
        targetAmountWon: json['targetAmountWon'] as int,
        currentAmountWon: json['currentAmountWon'] as int,
      );

  Goal copyWith({
    String? title,
    int? targetAmountWon,
    int? currentAmountWon,
  }) =>
      Goal(
        id: id,
        title: title ?? this.title,
        targetAmountWon: targetAmountWon ?? this.targetAmountWon,
        currentAmountWon: currentAmountWon ?? this.currentAmountWon,
      );
}
