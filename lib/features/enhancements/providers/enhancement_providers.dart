// lib/features/enhancements/providers/enhancement_providers.dart: Riverpod wiring for app enhancement notes.
import 'package:abdalsalam_logic_flutter/abdalsalam_logic_flutter.dart' as logic;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/enhancements/enhancement_note.dart';
import '../../../data/repositories/enhancements/enhancement_note_repository.dart';
import '../../../providers/app_providers.dart';
import '../../../shared/infrastructure/logger_service.dart';
import '../services/enhancement_note_service.dart';

const String enhancementUserId = 'user1';

final enhancementNoteRepositoryProvider = Provider<EnhancementNoteRepository>((ref) {
  return EnhancementNoteRepositoryImpl(
    ref.watch(storageGatewayProvider),
    LoggerService.forModule('EnhancementNoteRepository', moduleType: logic.ModuleType.repository),
  );
});

final enhancementNoteServiceProvider = Provider<EnhancementNoteService>((ref) {
  return EnhancementNoteService(
    ref.watch(enhancementNoteRepositoryProvider),
    LoggerService.forModule('EnhancementNoteService', moduleType: logic.ModuleType.service),
  );
});

final enhancementNotesProvider = FutureProvider<List<EnhancementNote>>((ref) async {
  final result = await ref.watch(enhancementNoteServiceProvider).getActive();
  return EnhancementNoteService.sortForDisplay(result.getOrThrow());
});
