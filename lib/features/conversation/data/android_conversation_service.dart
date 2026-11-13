import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../domain/conversation_service.dart';

/// The Kotlin `ConversationService` (a microphone foreground service) over `app.anuvaad/session`.
class AndroidConversationService implements ConversationServicePort {
  AndroidConversationService({MethodChannel? channel, EventChannel? events})
      : _channel = channel ?? const MethodChannel('app.anuvaad/session'),
        _events = events ?? const EventChannel('app.anuvaad/session/commands');

  final MethodChannel _channel;
  final EventChannel _events;
  Stream<SessionCommand>? _commands;

  static final _byName = SessionCommand.values.asNameMap();

  @override
  Future<bool> start(SessionNotification notification, {required String channelName, required bool earphoneButton}) async {
    try {
      // Android 13+: without it the notification (and its lock-screen buttons) stays hidden; the conversation still runs.
      await Permission.notification.request();
    } catch (error) {
      debugPrint('Could not ask to show notifications: $error');
    }
    try {
      final started = await _channel.invokeMethod<bool>('start', {
        ...notification.toMap(),
        'channelName': channelName,
        'earphoneButton': earphoneButton,
      });
      return started ?? false;
    } catch (error) {
      debugPrint('Could not start the conversation service: $error');
      return false;
    }
  }

  @override
  Future<void> update(SessionNotification notification) async {
    try {
      await _channel.invokeMethod<void>('update', notification.toMap());
    } catch (error) {
      debugPrint('Could not update the conversation notification: $error');
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _channel.invokeMethod<void>('stop');
    } catch (error) {
      debugPrint('Could not stop the conversation service: $error');
    }
  }

  @override
  Stream<SessionCommand> get commands => _commands ??= _events
      .receiveBroadcastStream()
      .map((event) => _byName[event])
      .where((command) => command != null)
      .cast<SessionCommand>();
}

final conversationServiceProvider = Provider<ConversationServicePort>((ref) => AndroidConversationService());
