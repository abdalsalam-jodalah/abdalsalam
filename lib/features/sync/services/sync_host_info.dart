// lib/features/sync/services/sync_host_info.dart — the port and PIN a hosting device shows so the other device can connect.

import 'package:equatable/equatable.dart';

class SyncHostInfo extends Equatable {
  final int port;
  final String pin;

  const SyncHostInfo({required this.port, required this.pin});

  @override
  List<Object?> get props => [port, pin];
}
