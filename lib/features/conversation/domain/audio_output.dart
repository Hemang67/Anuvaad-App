/// The kinds of output Anuvaad plays to; anything else Android lists (earpiece, HDMI…) is ignored.
enum OutputKind { speaker, wired, bluetooth, usb }

/// An output device Android reports as connected right now.
class AudioOutput {
  const AudioOutput({required this.id, required this.kind, required this.name});

  /// Android's AudioDeviceInfo id; valid while the device stays connected.
  final int id;
  final OutputKind kind;

  /// Product name, or empty (the UI then shows a type label).
  final String name;

  bool get isEarphones => kind != OutputKind.speaker;

  @override
  bool operator ==(Object other) => other is AudioOutput && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'AudioOutput($id, ${kind.name}, "$name")';
}

/// Who a spoken translation is for: you (privately) or the other person (aloud).
enum OutputRole { forMe, forOther }

sealed class AudioEvent {
  const AudioEvent();
}

class OutputsChanged extends AudioEvent {
  const OutputsChanged(this.outputs);
  final List<AudioOutput> outputs;
}

/// Playback began; [routed] is the device Android actually uses.
class PlaybackStarted extends AudioEvent {
  const PlaybackStarted(this.playbackId, this.routed);
  final String playbackId;
  final AudioOutput routed;
}

class PlaybackCompleted extends AudioEvent {
  const PlaybackCompleted(this.playbackId);
  final String playbackId;
}

class PlaybackFailed extends AudioEvent {
  const PlaybackFailed(this.playbackId, this.code);
  final String playbackId;
  final String code;
}

/// Another app (a call, an alarm) took the audio; playback stopped.
class PlaybackFocusLost extends AudioEvent {
  const PlaybackFocusLost(this.playbackId);
  final String playbackId;
}

/// Port for output devices and routed playback (spec §3.2 AudioRoutePort).
abstract interface class AudioOutputPort {
  Stream<AudioEvent> get events;
  Future<List<AudioOutput>> outputs();

  /// Plays the file; [deviceId] is the preferred output (null lets Android choose).
  Future<void> play({required String path, required int? deviceId, required String playbackId});

  /// Stops and releases playback; returns once nothing is playing.
  Future<void> stop();

  /// Plays a short tone and returns the device it was routed to.
  Future<AudioOutput?> playTestTone({required int? deviceId});
}
