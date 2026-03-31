import 'package:equatable/equatable.dart';

abstract class BaseModel extends Equatable {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const BaseModel({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  /// Convert model to JSON
  Map<String, dynamic> toJson();

  /// Check if model is soft deleted
  bool get isDeleted => deletedAt != null;

  /// Check if model is active
  bool get isActive => deletedAt == null;

  @override
  List<Object?> get props => [id];

  @override
  String toString() => '$runtimeType(id: $id)';
}
