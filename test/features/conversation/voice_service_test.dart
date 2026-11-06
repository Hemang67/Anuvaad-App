import 'dart:io';

import 'package:anuvaad/features/conversation/application/voice_service.dart';
import 'package:anuvaad/features/conversation/domain/voice.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/conversation_fakes.dart';

void main() {
  late Directory cache;
  late FakeSpeechSynth synth;
  late VoiceService service;

  setUp(() {
    cache = Directory.systemTemp.createTempSync('anuvaad_voice_test');
    synth = FakeSpeechSynth();
    service = VoiceService(synth: synth, cacheDir: () async => cache);
  });

  tearDown(() {
    if (cache.existsSync()) cache.deleteSync(recursive: true);
  });

  test('writes one file per segment under tts/', () async {
    final first = await service.synthesize(segmentId: 's1', text: 'नमस्ते', language: 'hi-IN');
    final second = await service.synthesize(segmentId: 's2', text: 'Hello', language: 'en-IN');
    expect(first, '${cache.path}${Platform.pathSeparator}tts${Platform.pathSeparator}s1.wav');
    expect(File(first).readAsStringSync(), 'wav:hi-IN:नमस्ते');
    expect(File(second).existsSync(), isTrue);
    expect(synth.synthesizedPaths, [first, second]);
  });

  test('missing voice throws VoiceMissing without synthesizing', () async {
    synth.availabilityByLocale['gu-IN'] = VoiceAvailability.needsDownload;
    synth.availabilityByLocale['hi-IN'] = VoiceAvailability.unsupported;
    for (final language in ['gu-IN', 'hi-IN']) {
      await expectLater(
        service.synthesize(segmentId: 's-$language', text: 'x', language: language),
        throwsA(isA<VoiceMissing>().having((e) => e.locale, 'locale', language)),
      );
    }
    expect(synth.synthesizedPaths, isEmpty);
  });

  test('availability is cached until forgotten', () async {
    expect(await service.availability('gu-IN'), VoiceAvailability.available);
    await service.availability('gu-IN');
    await service.synthesize(segmentId: 's1', text: 'x', language: 'gu-IN');
    expect(synth.availabilityChecks, 1);

    service.forgetAvailability('gu-IN');
    await service.availability('gu-IN');
    expect(synth.availabilityChecks, 2);
  });

  test('clear deletes the synthesized files', () async {
    final path = await service.synthesize(segmentId: 's1', text: 'x', language: 'en-IN');
    await service.clear();
    expect(File(path).existsSync(), isFalse);
    expect(Directory('${cache.path}${Platform.pathSeparator}tts').existsSync(), isFalse);
    await service.clear(); // clearing twice is fine
  });

  test('only an available voice is remembered; a missing one is asked again', () async {
    synth.availabilityByLocale['gu-IN'] = VoiceAvailability.needsDownload;
    await service.availability('gu-IN');
    await service.availability('gu-IN');
    expect(synth.availabilityChecks, 2);
  });

  test('a speech engine that fails reads as no voice, and is asked again next time', () async {
    synth.availabilityError = const SynthesisFailed('synthesisFailed');
    expect(await service.availability('gu-IN'), VoiceAvailability.unsupported);
    await expectLater(service.synthesize(segmentId: 's1', text: 'x', language: 'gu-IN'), throwsA(isA<VoiceMissing>()));
    synth.availabilityError = null;
    expect(await service.availability('gu-IN'), VoiceAvailability.available);
  });

  test('the first synthesis clears files left by an earlier session, once', () async {
    final leftover = File('${cache.path}${Platform.pathSeparator}tts${Platform.pathSeparator}old.wav')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync('wav');
    final first = await service.synthesize(segmentId: 's1', text: 'x', language: 'en-IN');
    expect(leftover.existsSync(), isFalse);
    expect(File(first).existsSync(), isTrue);
    await service.synthesize(segmentId: 's2', text: 'y', language: 'en-IN');
    expect(File(first).existsSync(), isTrue, reason: 'the sweep runs once per conversation');
  });
}
