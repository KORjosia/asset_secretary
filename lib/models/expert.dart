class Expert {
  final String id;
  final String name;
  final String field; // 예: "재무설계", "투자", "부채관리"

  const Expert({required this.id, required this.name, required this.field});

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'field': field};

  static Expert fromJson(Map<dynamic, dynamic> json) => Expert(
        id: json['id'] as String,
        name: json['name'] as String,
        field: json['field'] as String,
      );
}
