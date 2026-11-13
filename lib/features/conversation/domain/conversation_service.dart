import 'package:flutter/foundation.dart';

/// What the ongoing-conversation notification's buttons and the earphones' play/pause button ask for, plus
/// [stopped]: Android ended the service by itself (the conversation then pauses in the background, as before).
enum SessionCommand { listen, speak, finishReply, pause, end, playReply, discardReply, earphoneButton, stopped }

/// One notification button.
@immutable
class SessionAction {
  const SessionAction(this.command, this.label);

  final SessionCommand command;
  final String label;

  @override
  bool operator ==(Object other) => other is SessionAction && other.command == command && other.label == label;

  @override
  int get hashCode => Object.hash(command, label);

  @override
  String toString() => 'SessionAction(${command.name}, $label)';
}

/// The notification shown while a conversation runs (spec §8.3: ongoing microphone work is user-visible).
@immutable
class SessionNotification {
  const SessionNotification({
    required this.title,
    required this.text,
    this.privateText,
    this.actions = const [],
    this.active = true,
  });

  /// What is happening now ("Listening to Hindi").
  final String title;

  /// Safe for a locked screen: the languages.
  final String text;

  /// The latest translation, shown only where the phone allows private notification content.
  final String? privateText;

  final List<SessionAction> actions;

  /// Listening or working (not paused): Android keeps the processor awake for it.
  final bool active;

  Map<String, Object?> toMap() => {
        'title': title,
        'text': text,
        'privateText': privateText,
        'commands': [for (final a in actions) a.command.name],
        'labels': [for (final a in actions) a.label],
        'active': active,
      };

  @override
  bool operator ==(Object other) =>
      other is SessionNotification &&
      other.title == title &&
      other.text == text &&
      other.privateText == privateText &&
      listEquals(other.actions, actions) &&
      other.active == active;

  @override
  int get hashCode => Object.hash(title, text, privateText, Object.hashAll(actions), active);

  @override
  String toString() => 'SessionNotification($title · $text · ${actions.map((a) => a.command.name).join(',')})';
}

/// Android's foreground service that keeps a conversation's microphone with the screen off or the app in the
/// background, with [SessionNotification] showing while it runs.
abstract interface class ConversationServicePort {
  /// Starts it; Android allows that only while the app is on screen. False when it was refused: the conversation then
  /// pauses in the background, as before. [earphoneButton]: the earphones' play/pause button sends
  /// [SessionCommand.earphoneButton] while it runs.
  Future<bool> start(SessionNotification notification, {required String channelName, required bool earphoneButton});

  Future<void> update(SessionNotification notification);

  Future<void> stop();

  Stream<SessionCommand> get commands;
}
