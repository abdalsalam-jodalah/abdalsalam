import '../base_model.dart';

class ExchangeRateModel extends BaseModel {
  final String fromCurrency;
  final String toCurrency;
  final double rate;
  final DateTime date;

  const ExchangeRateModel({
    required super.id,
    required this.fromCurrency,
    required this.toCurrency,
    required this.rate,
    required this.date,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
  });

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'fromCurrency': fromCurrency,
        'toCurrency': toCurrency,
        'rate': rate,
        'date': date.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
      };

  factory ExchangeRateModel.fromJson(Map<String, dynamic> json) {
    return ExchangeRateModel(
      id: json['id'] as String,
      fromCurrency: json['fromCurrency'] as String,
      toCurrency: json['toCurrency'] as String,
      rate: (json['rate'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'] as String)
          : null,
    );
  }

  ExchangeRateModel copyWith({
    String? id,
    String? fromCurrency,
    String? toCurrency,
    double? rate,
    DateTime? date,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return ExchangeRateModel(
      id: id ?? this.id,
      fromCurrency: fromCurrency ?? this.fromCurrency,
      toCurrency: toCurrency ?? this.toCurrency,
      rate: rate ?? this.rate,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        fromCurrency,
        toCurrency,
        rate,
        date,
        createdAt,
        updatedAt,
        deletedAt,
      ];
}
