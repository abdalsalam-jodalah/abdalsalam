// lib/features/sync/services/sync_platform_role.dart — which side of the USB link this platform plays.

import 'dart:io';

import '../../../core/constants/sync_ui_text.dart';

enum SyncPlatformRole {
  host(SyncUiText.macDeviceLabel),
  client(SyncUiText.phoneDeviceLabel),
  unsupported(SyncUiText.unknownDeviceLabel);

  final String deviceLabel;

  const SyncPlatformRole(this.deviceLabel);

  static SyncPlatformRole detect() {
    if (Platform.isMacOS) {
      return SyncPlatformRole.host;
    }
    if (Platform.isAndroid) {
      return SyncPlatformRole.client;
    }
    return SyncPlatformRole.unsupported;
  }
}
