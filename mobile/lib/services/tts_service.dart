import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_tts/flutter_tts.dart';

import 'debug_log_service.dart';

/// Plays tutor speech.
///
/// Two engines are supported:
/// - [speak] — local on-device synthesis via `flutter_tts` (web `speechSynthesis`,
///   Android `TextToSpeech`, iOS `AVSpeechSynthesizer`). Free, offline, voice
///   quality depends on the user's OS.
/// - [speakBytes] — plays cloud-synthesized audio bytes (e.g. mp3 from OpenAI's
///   `/v1/audio/speech`) via `audioplayers`. Higher quality and consistent
///   across devices, but requires a network roundtrip.
///
/// Both paths invoke [onComplete] when playback finishes so the conversation
/// loop can resume listening uniformly.
class TtsService {
  final FlutterTts _tts = FlutterTts();
  AudioPlayer? _playerInstance;
  bool _localConfigured = false;
  bool _playerListenerAttached = false;

  Future<void> Function()? onComplete;

  /// Lazy: don't construct the platform [AudioPlayer] until cloud TTS is actually
  /// used. Tests that exercise only [speak] therefore avoid pulling in
  /// `audioplayers` platform channels.
  AudioPlayer get _player => _playerInstance ??= AudioPlayer();

  Future<void> _ensureLocalConfigured() async {
    if (_localConfigured) {
      return;
    }
    await _tts.setLanguage(kIsWeb ? 'zh-CN' : 'en-US');
    await _tts.setSpeechRate(0.45);
    await _tts.awaitSpeakCompletion(true);
    _tts.setCompletionHandler(() async {
      if (onComplete != null) {
        await onComplete!();
      }
    });
    _localConfigured = true;
  }

  void _ensurePlayerListenerAttached() {
    if (_playerListenerAttached) {
      return;
    }
    _playerListenerAttached = true;
    _player.onPlayerComplete.listen((_) async {
      if (onComplete != null) {
        await onComplete!();
      }
    });
  }

  /// On-device synthesis (fallback / no-network path).
  Future<void> speak(String text) async {
    await _ensureLocalConfigured();
    await _tts.stop();
    if (_playerInstance != null) {
      await _playerInstance!.stop();
    }
    DebugLogService.instance.log(
      'TTS speak (local on-device synthesis)',
      location: 'TtsService',
      data: {
        'textLen': text.length.toString(),
        'text': clipDebugText(text, maxChars: 800),
      },
      hypothesisId: 'A',
    );
    await _tts.speak(text);
  }

  /// Plays cloud-synthesized audio bytes (e.g. mp3 from OpenAI TTS).
  ///
  /// `mimeType` is currently informational — `audioplayers` infers the codec
  /// from the bytes themselves — but it's logged for debugging.
  Future<void> speakBytes(Uint8List bytes, {required String mimeType}) async {
    _ensurePlayerListenerAttached();
    await _tts.stop();
    await _player.stop();
    DebugLogService.instance.log(
      'TTS speakBytes (cloud audio playback)',
      location: 'TtsService',
      data: {
        'bytesLen': bytes.length.toString(),
        'mimeType': mimeType,
      },
      hypothesisId: 'A',
    );
    await _player.play(BytesSource(bytes, mimeType: mimeType));
  }

  Future<void> stop() async {
    DebugLogService.instance.log(
      'TTS stop',
      location: 'TtsService',
      hypothesisId: 'A',
    );
    await _tts.stop();
    if (_playerInstance != null) {
      await _playerInstance!.stop();
    }
  }

  void dispose() {
    _tts.stop();
    _playerInstance?.dispose();
  }
}
