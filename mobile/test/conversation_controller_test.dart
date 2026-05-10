import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:joe_talk_mobile/features/conversation/conversation_controller.dart';
import 'package:joe_talk_mobile/services/stt_service.dart';
import 'package:joe_talk_mobile/services/tts_service.dart';

/// Emits one final transcript on the first [startListening], then stays idle on
/// later calls (e.g. after TTS completes) so the conversation loop does not run
/// forever in tests.
class _FakeStt extends SttService {
  bool _emitted = false;

  @override
  Future<bool> startListening({required String localeId}) async {
    if (_emitted) {
      return true;
    }
    _emitted = true;
    Future.microtask(() async {
      final handler = onFinalText;
      if (handler != null) {
        await handler('Hello');
      }
    });
    return true;
  }

  @override
  void dispose() {
    // Avoid speech_to_text platform channels in unit tests.
  }
}

class _FakeTts extends TtsService {
  @override
  Future<void> speak(String text) async {
    final done = onComplete;
    if (done != null) {
      await done();
    }
  }

  @override
  void dispose() {
    // Avoid flutter_tts platform channels in unit tests.
  }
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  test('POST /api/chat and parses reply', () async {
    http.Client? client;
    addTearDown(() {
      client?.close();
    });

    client = MockClient((request) async {
      expect(request.method, 'POST');
      final url = request.url.toString();
      if (url == 'http://127.0.0.1:9/api/chat') {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['studentMessage'], 'Hello');
        expect(body['language'], 'en');
        return http.Response(
          jsonEncode({'reply': 'Great'}),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      // Cloud TTS is best-effort; returning 503 exercises the fallback path.
      if (url == 'http://127.0.0.1:9/api/tts') {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['text'], 'Great');
        return http.Response(
          jsonEncode({'error': 'TTS is not configured'}),
          503,
          headers: {'content-type': 'application/json'},
        );
      }
      fail('unexpected request: $url');
    });

    final controller = ConversationController(
      sttService: _FakeStt(),
      ttsService: _FakeTts(),
      backendBaseUrl: 'http://127.0.0.1:9',
      httpClient: client,
    );

    await controller.startConversation();
    await pumpEventQueue();

    expect(controller.latestTranscript, isEmpty);
    expect(controller.messages, hasLength(2));
    expect(controller.messages[0].isUser, isTrue);
    expect(controller.messages[0].text, 'Hello');
    expect(controller.messages[1].isUser, isFalse);
    expect(controller.messages[1].text, 'Great');
    expect(controller.state, ConversationState.listening);

    controller.dispose();
  });
}
