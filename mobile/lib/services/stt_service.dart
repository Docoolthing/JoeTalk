import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'debug_log_service.dart';

String _sttStatusHint(String status) {
  switch (status) {
    case 'listening':
      return 'capturing audio';
    case 'notListening':
      return 'engine idle (pause/timeout/stop); partial text above if any';
    case 'done':
      return 'session finished; look for STT final transcript log — if missing, nothing was recognized';
    default:
      return 'see speech_to_text docs';
  }
}

class SttService {
  final SpeechToText _speech = SpeechToText();
  bool _initialized = false;
  DateTime? _lastPartialLogAt;

  void Function(String text)? onPartialText;
  Future<void> Function(String text)? onFinalText;
  void Function(String message)? onError;

  Future<bool> startListening({required String localeId}) async {
    final granted = await Permission.microphone.request().isGranted;
    if (!granted) {
      DebugLogService.instance.log(
        'microphone permission denied',
        location: 'SttService',
        hypothesisId: 'A',
      );
      onError?.call('未授予麥克風權限。');
      return false;
    }

    if (!_initialized) {
      _initialized = await _speech.initialize(
        onError: (error) {
          DebugLogService.instance.log(
            'SpeechRecognition error',
            location: 'SttService',
            data: {
              'error': error.errorMsg,
              'permanent': error.permanent.toString(),
            },
            hypothesisId: 'A',
          );
          onError?.call(error.errorMsg);
        },
        onStatus: (status) {
          DebugLogService.instance.log(
            'STT engine status',
            location: 'SttService',
            data: {
              'status': status,
              'meaning': _sttStatusHint(status),
            },
            hypothesisId: 'A',
          );
        },
        debugLogging: kDebugMode,
      );
      if (!_initialized) {
        DebugLogService.instance.log(
          'SpeechToText initialize failed',
          location: 'SttService',
          hypothesisId: 'A',
        );
        onError?.call(
          '語音辨識無法使用，請檢查麥克風與系統語言設定。',
        );
        return false;
      }
    }
    DebugLogService.instance.log(
      'STT listen start',
      location: 'SttService',
      data: {
        'localeId': localeId,
      },
      hypothesisId: 'A',
    );

    if (_speech.isListening) {
      await _speech.stop();
    }

    try {
      await _speech.listen(
        localeId: localeId,
        onResult: (result) async {
          onPartialText?.call(result.recognizedWords);
          if (!result.finalResult) {
            final now = DateTime.now();
            if (_lastPartialLogAt == null ||
                now.difference(_lastPartialLogAt!) >
                    const Duration(milliseconds: 500)) {
              _lastPartialLogAt = now;
              DebugLogService.instance.log(
                'STT partial (live transcript)',
                location: 'SttService',
                data: {
                  'wordsLen': result.recognizedWords.length.toString(),
                  'text': clipDebugText(
                    result.recognizedWords,
                    maxChars: 320,
                  ),
                },
                hypothesisId: 'A',
              );
            }
          } else if (onFinalText != null) {
            DebugLogService.instance.log(
              'STT final transcript (recognition complete)',
              location: 'SttService',
              data: {
                'wordsLen': result.recognizedWords.length.toString(),
                'text': clipDebugText(
                  result.recognizedWords,
                  maxChars: 800,
                ),
              },
              hypothesisId: 'A',
            );
          }
          if (result.finalResult && onFinalText != null) {
            await onFinalText!(result.recognizedWords);
          }
        },
        onSoundLevelChange: (_) {},
        pauseFor: const Duration(seconds: 5),
        listenOptions: SpeechListenOptions(
          listenMode: ListenMode.dictation,
        ),
      );
    } on ListenFailedException catch (e) {
      DebugLogService.instance.log(
        'STT listen failed',
        location: 'SttService',
        data: {
          'message': e.message ?? '',
          'details': e.details?.toString() ?? '',
        },
        hypothesisId: 'A',
      );
      onError?.call(e.message ?? '語音聆聽失敗。');
      return false;
    } catch (e, st) {
      DebugLogService.instance.log(
        'STT listen unexpected error',
        location: 'SttService',
        data: {
          'error': e.toString(),
          'stack': st.toString(),
        },
        hypothesisId: 'A',
      );
      onError?.call('語音聆聽失敗：$e');
      return false;
    }
    return true;
  }

  Future<void> stopListening() async {
    if (_speech.isListening) {
      DebugLogService.instance.log(
        'STT stop',
        location: 'SttService',
        hypothesisId: 'A',
      );
      await _speech.stop();
    }
  }

  void dispose() {
    _speech.cancel();
  }
}
