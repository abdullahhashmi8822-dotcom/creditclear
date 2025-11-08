class TransactionModel {
  final int? id;
  final String personName;
  final double amount;
  final String type;
  final String category;
  final String? description;
  final DateTime date;
  final DateTime? dueDate;
  final String status;
  final DateTime createdAt;

  TransactionModel({
    this.id,
    required this.personName,
    required this.amount,
    required this.type,
    required this.category,
    this.description,
    required this.date,
    this.dueDate,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'personName': personName,
      'amount': amount,
      'type': type,
      'category': category,
      'description': description,
      'date': date.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as int?,
      personName: map['personName'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: map['type'] as String,
      category: map['category'] as String,
      description: map['description'] as String?,
      date: DateTime.parse(map['date'] as String),
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate'] as String) : null,
      status: map['status'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  TransactionModel copyWith({
    int? id,
    String? personName,
    double? amount,
    String? type,
    String? category,
    String? description,
    DateTime? date,
    DateTime? dueDate,
    String? status,
    DateTime? createdAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      personName: personName ?? this.personName,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      description: description ?? this.description,
      date: date ?? this.date,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}