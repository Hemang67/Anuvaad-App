import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/audio_output.dart';
import '../domain/voice.dart';

/// Android text-to-speech, output devices and routed playback through `AudioPlugin.kt`.
class AndroidAudio implements SpeechSynthPort, AudioOutputPort {
  static const _methods = MethodChannel('app.anuvaad/audio');
  static const _eventChannel = EventChannel('app.anuvaad/audio/events');

  Stream<AudioEvent>? _events;

  @override
  Future<VoiceAvailability> availability(String locale) async {
    final raw = await _methods.invokeMethod<String>('voiceAvailability', {'locale': locale});
    return switch (raw) {
      'available' => VoiceAvailability.available,
      'needsDownload' => VoiceAvailability.needsDownload,
      _ => VoiceAvailability.unsupported,
    };
  }

  @override
  Future<void> synthesize({required String text, required String locale, required String path}) async {
    try {
      await _methods.invokeMethod<void>('synthesize', {'text': text, 'locale': locale, 'path': path});
    } on PlatformException catch (e) {
      if (e.code == 'voiceMissing') throw VoiceMissing(locale);
      throw SynthesisFailed(e.code);
    }
  }

  @override
  Future<bool> openVoiceInstall(String locale) async =>
      await _methods.invokeMethod<bool>('openVoiceInstall', {'locale': locale}) ?? false;

  @override
  Future<List<AudioOutput>> outputs() async =>
      _parseOutputs(await _methods.invokeMethod<List<Object?>>('outputs'));

  @override
  Future<void> play({required String path, required int? deviceId, required String playbackId}) =>
      _methods.invokeMethod<void>('play', {'path': path, 'deviceId': deviceId, 'playbackId': playbackId});

  @override
  Future<void> stop() => _methods.invokeMethod<void>('stop');

  @override
  Future<AudioOutput?> playTestTone({required int? deviceId}) async =>
      _parseOutput(await _methods.invokeMethod<Object?>('playTestTone', {'deviceId': deviceId}));

  @override
  Stream<AudioEvent> get events => _events ??= _eventChannel
      .receiveBroadcastStream()
      .map(_parseEvent)
      .where((event) => event != null)
      .cast<AudioEvent>();

  static AudioEvent? _parseEvent(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['playbackId'];
    return switch (raw['type']) {
      'outputs' => OutputsChanged(_parseOutputs(raw['outputs'])),
      'started' when id is String => switch (_parseOutput(raw['routed'])) {
          final routed? => PlaybackStarted(id, routed),
          null => null,
        },
      'completed' when id is String => PlaybackCompleted(id),
      'failed' when id is String => PlaybackFailed(id, '${raw['code']}'),
      'focusLost' when id is String => PlaybackFocusLost(id),
      _ => null,
    };
  }

  static List<AudioOutput> _parseOutputs(Object? raw) => [
        if (raw is List)
          for (final item in raw) ?_parseOutput(item),
      ];

  static AudioOutput? _parseOutput(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    final kind = switch (raw['kind']) {
      'speaker' => OutputKind.speaker,
      'wired' => OutputKind.wired,
      'bluetooth' => OutputKind.bluetooth,
      'usb' => OutputKind.usb,
      _ => null,
    };
    if (id is! int || kind == null) return null;
    final name = raw['name'];
    return AudioOutput(id: id, kind: kind, name: name is String ? name.trim() : '');
  }
}

/// One plugin instance serves both ports.
final audioPluginProvider = Provider<AndroidAudio>((ref) => AndroidAudio());
final speechSynthProvider = Provider<SpeechSynthPort>((ref) => ref.watch(audioPluginProvider));
final audioOutputProvider = Provider<AudioOutputPort>((ref) => ref.watch(audioPluginProvider));
