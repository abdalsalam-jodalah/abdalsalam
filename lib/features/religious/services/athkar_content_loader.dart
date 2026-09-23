import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import '../../../core/errors/app_error.dart';
import '../../../core/json/json_reader.dart';
import '../../../core/result/result.dart';
import '../../../data/models/religious/athkar_content.dart';
import '../../../shared/infrastructure/logger_service.dart';
import '../../../shared/services/error_handler.dart';

class AthkarContentLoader {
  static const _assetPath = 'assets/data/athkar_content.json';
  static const _builtInIdPrefix = 'builtin';
  static const _categoriesField = 'categories';
  static const _idField = 'id';
  static const _entriesField = 'entries';
  static const _arabicTextField = 'arabicText';
  static const _transliterationField = 'transliteration';
  static const _translationField = 'translation';
  static const _targetCountField = 'targetCount';
  static const _referenceField = 'reference';
  static const _sortOrderField = 'sortOrder';
  static const _timeWindowStartField = 'timeWindowStart';
  static const _timeWindowEndField = 'timeWindowEnd';

  final LoggerService logger;
  final AssetBundle _bundle;

  AthkarContentLoader(this.logger, {AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  Future<Result<List<AthkarContent>, AppError>> loadBundled() async {
    final categories = await _loadCategories();
    if (categories.isFailure) {
      return Failure(categories.error!);
    }

    final result = <AthkarContent>[];
    final now = DateTime.now();

    for (final category in categories.data!) {
      final reader = JsonReader(category, source: _assetPath);
      final athkarCategory = reader.optionalEnum(_idField, AthkarCategory.values);
      final entries = category[_entriesField];
      if (athkarCategory == null || entries is! List) {
        logger.warning('[AthkarContentLoader] skipping malformed category "${reader.optionalString(_idField)}"');
        continue;
      }

      for (var index = 0; index < entries.length; index++) {
        final content = _parseEntry(entries[index], category: athkarCategory, index: index, now: now);
        if (content == null) {
          logger.warning('[AthkarContentLoader] skipping malformed entry ${athkarCategory.name}[$index]');
          continue;
        }
        result.add(content);
      }
    }

    return Success(result);
  }

  Future<Result<Map<String, ({String start, String end})>, AppError>> loadTimeWindows() async {
    final categories = await _loadCategories();
    if (categories.isFailure) {
      return Failure(categories.error!);
    }

    final windows = <String, ({String start, String end})>{};
    for (final category in categories.data!) {
      final reader = JsonReader(category, source: _assetPath);
      final id = reader.optionalString(_idField);
      final start = reader.optionalString(_timeWindowStartField);
      final end = reader.optionalString(_timeWindowEndField);
      if (id != null && start != null && end != null) {
        windows[id] = (start: start, end: end);
      }
    }
    return Success(windows);
  }

  AthkarContent? _parseEntry(
    Object? raw, {
    required AthkarCategory category,
    required int index,
    required DateTime now,
  }) {
    if (raw is! Map<String, dynamic>) {
      return null;
    }
    final reader = JsonReader(raw, source: _assetPath);
    final arabicText = reader.optionalString(_arabicTextField);
    final targetCount = reader.optionalInt(_targetCountField);
    if (arabicText == null || arabicText.trim().isEmpty || targetCount == null || targetCount <= 0) {
      return null;
    }

    return AthkarContent(
      id: '$_builtInIdPrefix-${category.name}-$index',
      createdAt: now,
      updatedAt: now,
      category: category,
      arabicText: arabicText,
      transliteration: reader.optionalString(_transliterationField),
      translation: reader.optionalString(_translationField),
      targetCount: targetCount,
      reference: reader.optionalString(_referenceField),
      isBuiltIn: true,
      isCustom: false,
      sortOrder: reader.readInt(_sortOrderField, fallback: index),
    );
  }

  Future<Result<List<Map<String, dynamic>>, AppError>> _loadCategories() async {
    try {
      final decoded = jsonDecode(await _bundle.loadString(_assetPath));
      final categories = decoded is Map<String, dynamic> ? decoded[_categoriesField] : null;
      if (categories is! List) {
        final error = CorruptDataError(
          'Athkar asset is missing its categories list',
          source: _assetPath,
          field: _categoriesField,
        );
        logger.error('[AthkarContentLoader] ${error.message}', error: error);
        return Failure(error);
      }
      return Success(categories.whereType<Map<String, dynamic>>().toList(growable: false));
    } catch (error, stackTrace) {
      return Failure(
        ErrorHandler(logger).mapException(error, context: 'AthkarContentLoader.load', stackTrace: stackTrace),
      );
    }
  }
}
