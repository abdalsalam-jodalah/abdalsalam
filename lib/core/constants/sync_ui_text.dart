// lib/core/constants/sync_ui_text.dart — every user-facing string of the device sync screens.

class SyncUiText {
  const SyncUiText._();

  static const String hubTitle = 'Device Sync';
  static const String hubTileSubtitle = 'Sync this device with your Mac or phone over a USB cable';
  static const String reportTitle = 'Sync report';

  static const String macDeviceLabel = 'Mac';
  static const String phoneDeviceLabel = 'Phone';
  static const String unknownDeviceLabel = 'Device';

  static const String unsupportedTitle = 'Device sync is not available here';
  static const String unsupportedMessage = 'USB sync runs between the Android phone and the macOS app only.';

  static const String connectionSection = 'Cable connection';
  static const String linkSection = 'Link';
  static const String progressSection = 'Progress';
  static const String lastRunSection = 'Last sync';
  static const String historySection = 'History';
  static const String phoneSection = 'Sync with your Mac';

  static const String adbMissingTitle = 'adb not found or not allowed to run';
  static const String adbMissingMessage =
      'Install Android platform-tools (brew install android-platform-tools). If adb is installed, macOS may be '
      'blocking this app from running it. Use the manual command below instead.';
  static const String adbFailedTitle = 'adb could not run';
  static const String adbFailedMessage = 'adb exists but failed to start. Use the manual command below instead.';
  static const String noDeviceTitle = 'No phone detected';
  static const String noDeviceMessage =
      'Plug the phone in with a USB cable and turn on USB debugging in Developer options.';
  static const String offlineTitle = 'Phone is offline';
  static const String offlineMessage = 'Unplug and re-plug the cable, then check again.';
  static const String unauthorizedTitle = 'Phone has not authorized this Mac';
  static const String unauthorizedMessage =
      'Unlock the phone and accept the "Allow USB debugging" prompt, then check again.';
  static const String readyTitle = 'Phone connected';
  static const String readyMessagePrefix = 'Ready over USB: ';
  static const String checkingTitle = 'Checking cable connection...';
  static const String checkAgainLabel = 'Check again';

  static const String manualCommandTitle = 'Run this command in Terminal';
  static const String manualCommandMessage =
      'The cable tunnel could not be opened automatically. Run it once with the phone plugged in, then start the '
      'sync on the phone.';
  static const String manualCommandFailurePrefix = 'Reason: ';
  static const String copyCommandTooltip = 'Copy command';
  static const String commandCopiedMessage = 'Command copied';

  static const String startLinkLabel = 'Start link';
  static const String stopLinkLabel = 'Stop link';
  static const String pinLabel = 'Pairing PIN';
  static const String pinHint = 'Enter this PIN on the phone';
  static const String linkStopped = 'Link is off';
  static const String linkStarting = 'Starting link...';
  static const String linkWaiting = 'Waiting for the phone to connect';
  static const String linkSyncing = 'Syncing';
  static const String linkCompleted = 'Sync complete. The link is still open for another run.';
  static const String linkFailed = 'Sync failed. The link is still open, try again on the phone.';

  static const String phoneInstructions =
      'On the Mac open Device Sync and press Start link, plug the phone in with the cable, then enter the PIN '
      'shown on the Mac.';
  static const String pinFieldLabel = 'PIN from the Mac';
  static const String syncNowLabel = 'Sync now';
  static const String syncingLabel = 'Syncing...';
  static const String invalidPinMessage = 'Enter the PIN shown on the Mac.';
  static const String pinFieldKey = 'pin';

  static const String idleProgress = 'Not syncing';
  static const String currentModulePrefix = 'Module: ';
  static const String rowsProgressSeparator = ' of ';
  static const String rowsSuffix = 'rows';

  static const String phaseIdle = 'Idle';
  static const String phaseWaiting = 'Waiting for the other device';
  static const String phaseConnecting = 'Connecting';
  static const String phaseComparing = 'Comparing data';
  static const String phaseSending = 'Sending changes';
  static const String phaseReceiving = 'Receiving changes';
  static const String phaseBackingUp = 'Saving a safety backup';
  static const String phaseApplying = 'Applying changes';
  static const String phaseFinalizing = 'Finishing up';
  static const String phaseCompleted = 'Completed';
  static const String phaseFailed = 'Failed';

  static const String noHistoryMessage = 'No syncs yet';
  static const String historyLoadFailedMessage = 'Could not load the sync history';
  static const String viewReportLabel = 'View report';
  static const String nothingTransferredLabel = 'Already in sync';
  static const String rowsSentPrefix = 'Sent ';
  static const String rowsReceivedPrefix = 'received ';
  static const String withDevicePrefix = 'With ';

  static const String totalsSection = 'Totals';
  static const String modulesSection = 'By module';
  static const String detailsSection = 'Details';
  static const String emptyReportTitle = 'Everything was already in sync';
  static const String emptyReportMessage =
      'Both devices already had the same data, so nothing needed to be transferred.';
  static const String reloadAppLabel = 'Reload app to show new data';
  static const String reloadHint = 'Screens opened before the sync may still show old data until the app reloads.';
  static const String clockSkewWarning =
      'The two device clocks are noticeably out of step. Newer-edit-wins merging depends on accurate clocks, so '
      'check the time on both devices.';
  static const String safetyBackupLabel = 'Safety backup';
  static const String otherDeviceLabel = 'Other device';
  static const String startedLabel = 'Started';
  static const String durationLabel = 'Duration';
  static const String clockOffsetLabel = 'Clock offset';

  static const String rowsSentLabel = 'Rows sent';
  static const String rowsReceivedLabel = 'Rows received';
  static const String addedLabel = 'Added';
  static const String updatedLabel = 'Updated';
  static const String deletedLabel = 'Deleted';
  static const String skippedLabel = 'Unchanged';
  static const String conflictsLabel = 'Conflicts resolved';
  static const String attachmentsLabel = 'Attachments';
  static const String bytesSentLabel = 'Data sent';
  static const String bytesReceivedLabel = 'Data received';

  static const String otherModuleLabel = 'Other';
  static const String upToDateLabel = 'Up to date';

  static const String byteUnitBytes = 'B';
  static const String byteUnitKilobytes = 'KB';
  static const String byteUnitMegabytes = 'MB';
  static const String byteUnitGigabytes = 'GB';
  static const String secondsUnit = 's';
  static const String minutesUnit = 'min';
  static const String millisecondsUnit = 'ms';
}
