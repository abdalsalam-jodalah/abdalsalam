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

  Map<String, dynamic> toJson();

  bool get isDeleted => deletedAt != null;
  bool get isActive => deletedAt == null;

  @override
  List<Object?> get props => [id];
}
