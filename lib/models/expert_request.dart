//asset_secretary\lib\models\expert_request.dart

class ExpertRequest {
  final String id;
  final String expertId;
  final int createdAtMs;

  final int monthlyIncomeWon;
  final int targetAmountWon;

  final String purpose;        // 객관식
  final String savingStatus;   // 객관식
  final String spendingStatus; // 객관식

  final String message; // 요청 내용

  const ExpertRequest({
    required this.id,
    required this.expertId,
    required this.createdAtMs,
    required this.monthlyIncomeWon,
    required this.targetAmountWon,
    required this.purpose,
    required this.savingStatus,
    required this.spendingStatus,
    required this.message,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'expertId': expertId,
        'createdAtMs': createdAtMs,
        'monthlyIncomeWon': monthlyIncomeWon,
        'targetAmountWon': targetAmountWon,
        'purpose': purpose,
        'savingStatus': savingStatus,
        'spendingStatus': spendingStatus,
        'message': message,
      };

  static ExpertRequest fromJson(Map<dynamic, dynamic> json) => ExpertRequest(
        id: json['id'] as String,
        expertId: json['expertId'] as String,
        createdAtMs: json['createdAtMs'] as int,
        monthlyIncomeWon: json['monthlyIncomeWon'] as int,
        targetAmountWon: json['targetAmountWon'] as int,
        purpose: json['purpose'] as String,
        savingStatus: json['savingStatus'] as String,
        spendingStatus: json['spendingStatus'] as String,
        message: (json['message'] as String?) ?? '',
      );
}
