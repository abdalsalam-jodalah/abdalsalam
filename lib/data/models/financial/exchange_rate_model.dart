import '../../../core/json/json_reader.dart';
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
    final reader = JsonReader(json, source: 'ExchangeRateModel');
    final createdAt = reader.requireDate('createdAt');
    return ExchangeRateModel(
      id: reader.requireString('id'),
      fromCurrency: reader.requireString('fromCurrency'),
      toCurrency: reader.requireString('toCurrency'),
      rate: reader.requireDouble('rate'),
      date: reader.requireDate('date'),
      createdAt: createdAt,
      updatedAt: reader.readDate('updatedAt', fallback: createdAt),
      deletedAt: reader.optionalDate('deletedAt'),
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
