enum TransferType {
  saving,  // 저축/투자 (목표 달성에 기여)
  expense, // 고정지출 (월세, 구독 등)
}
class AutoTransferPlan {
  final String id;
  final String name; // 예: "투자 자동이체"
  final int amountWon; // 금액
  final int dayOfMonth; // 매월 n일
  final bool isActive;
  final TransferType type;

  const AutoTransferPlan({
    required this.id,
    required this.name,
    required this.amountWon,
    required this.dayOfMonth,
    required this.isActive,
    this.type = TransferType.saving,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'amountWon': amountWon,
        'dayOfMonth': dayOfMonth,
        'isActive': isActive,
        'type': type.name,
      };

  static AutoTransferPlan fromJson(Map<dynamic, dynamic> json) => AutoTransferPlan(
    id: json['id'] as String,
    name: json['name'] as String,
    amountWon: json['amountWon'] as int,
    dayOfMonth: json['dayOfMonth'] as int,
    isActive: json['isActive'] as bool,
    type: json['type'] == null //기존에 저장된 자동이체(월세 포함!)도 안죽음.
        ? TransferType.saving
        : TransferType.values.byName(json['type']),
  );


  AutoTransferPlan copyWith({
    String? name,
    int? amountWon,
    int? dayOfMonth,
    bool? isActive,
    TransferType? type,
  }) =>
      AutoTransferPlan(
        id: id,
        name: name ?? this.name,
        amountWon: amountWon ?? this.amountWon,
        dayOfMonth: dayOfMonth ?? this.dayOfMonth,
        isActive: isActive ?? this.isActive,
        type: type ?? this.type,
      );
}
