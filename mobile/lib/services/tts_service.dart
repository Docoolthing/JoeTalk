import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_tts/flutter_tts.dart';

import 'debug_log_service.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _configured = false;

  Future<void> Function()? onComplete;

  Future<void> _ensureConfigured() async {
    if (_configured) {
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
    _configured = true;
  }

  Future<void> speak(String text) async {
    await _ensureConfigured();
    await _tts.stop();
    DebugLogService.instance.log(
      'TTS speak (synthesizing audio)',
      location: 'TtsService',
      data: {
        'textLen': text.length.toString(),
        'text': clipDebugText(text, maxChars: 800),
      },
      hypothesisId: 'A',
    );
    await _tts.speak(text);
  }

  Future<void> stop() async {
    DebugLogService.instance.log(
      'TTS stop',
      location: 'TtsService',
      hypothesisId: 'A',
    );
    await _tts.stop();
  }

  void dispose() {
    _tts.stop();
  }
}
