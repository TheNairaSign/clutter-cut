import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A base class for all UI events that can be triggered by providers.
abstract class UiEvent {
  const UiEvent();
}

/// An event to show a SnackBar.
class ShowSnackbar extends UiEvent {
  final String message;
  final bool isError;

  const ShowSnackbar(this.message, {this.isError = false});
}

/// An event to request confirmation for deleting a single file.
class ShowFileDeleteConfirmation extends UiEvent {
  final File file;

  const ShowFileDeleteConfirmation(this.file);
}

/// An event to request confirmation for deleting all duplicate files.
class ShowBulkDeleteConfirmation extends UiEvent {
  const ShowBulkDeleteConfirmation();
}

/// An event to show a dialog that directs the user to the app settings.
class ShowSettingsDialog extends UiEvent {
  final String title;
  final String message;

  const ShowSettingsDialog(this.title, this.message);
}

/// This provider holds the latest, unhandled UI event.
/// The UI layer should listen to this provider and handle the event,
/// then set the state to null to signify that the event has been handled.
final uiEventProvider = StateProvider<UiEvent?>((ref) => null);
