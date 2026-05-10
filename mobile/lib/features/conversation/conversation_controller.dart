import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../services/debug_log_service.dart';
import '../../services/stt_service.dart';
import '../../services/tts_service.dart';

/// Trims and removes a trailing `/` so `…/api/chat` is never `…//api/chat`.
String normalizeBackendBaseUrl(String url) {
  final t = url.trim();
  if (t.isEmpty) {
    return t;
  }
  return t.endsWith('/') ? t.substring(0, t.length - 1) : t;
}

enum ConversationState { idle, listening, processing, speaking, error }

class ChatMessage {
  const ChatMessage({required this.isUser, required this.text});
  final bool isUser;
  final String text;
}

class ConversationController extends ChangeNotifier {
  /// Web: Simplified Chinese STT/TTS and API language (zh-CN). Native: English.
  static String get _speechLocaleId => kIsWeb ? 'zh-CN' : 'en_US';
  static String get _apiLanguage => kIsWeb ? 'zh-CN' : 'en';

  ConversationController({
    required SttService sttService,
    required TtsService ttsService,
    required String backendBaseUrl,
    http.Client? httpClient,
  })  : _sttService = sttService,
        _ttsService = ttsService,
        _backendBaseUrl = normalizeBackendBaseUrl(backendBaseUrl),
        _httpClient = httpClient ?? http.Client(),
        _ownsHttpClient = httpClient == null {
    _sttService.onFinalText = _handleFinalTranscript;
    _sttService.onPartialText = _handlePartialTranscript;
    _sttService.onError = _handleSttError;
    _ttsService.onComplete = _handleTtsComplete;
  }

  final SttService _sttService;
  final TtsService _ttsService;
  final String _backendBaseUrl;
  final http.Client _httpClient;
  final bool _ownsHttpClient;

  ConversationState _state = ConversationState.idle;
  String _statusText = '點「開始」以開始對話。';
  final List<ChatMessage> _messages = [];
  String _latestTranscript = '';
  bool _conversationEnabled = false;

  ConversationState get state => _state;
  String get statusText => _statusText;
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  /// Live speech-to-text while listening (shown as a draft user bubble, not in [messages] until final).
  String get latestTranscript => _latestTranscript;
  bool get isRunning => _conversationEnabled;

  Future<void> toggleConversation() async {
    DebugLogService.instance.log(
      'toggleConversation: running=$_conversationEnabled',
      location: 'ConversationController',
      hypothesisId: 'A',
    );
    if (_conversationEnabled) {
      await stopConversation();
      return;
    }
    await startConversation();
  }

  Future<void> startConversation() async {
    _conversationEnabled = true;
    _latestTranscript = '';
    _statusText = '正在聆聽…';
    _state = ConversationState.listening;
    DebugLogService.instance.log(
      'startConversation: listening (locale $_speechLocaleId)',
      location: 'ConversationController',
      data: {'backendBaseUrl': _backendBaseUrl},
      hypothesisId: 'A',
    );
    notifyListeners();
    final ok = await _sttService.startListening(localeId: _speechLocaleId);
    if (!ok) {
      _setError('未授予麥克風權限，或語音辨識無法使用。');
      _conversationEnabled = false;
      notifyListeners();
    }
  }

  Future<void> stopConversation() async {
    _conversationEnabled = false;
    DebugLogService.instance.log(
      'stopConversation',
      location: 'ConversationController',
      hypothesisId: 'A',
    );
    await _sttService.stopListening();
    await _ttsService.stop();
    _state = ConversationState.idle;
    _statusText = '已停止對話。';
    notifyListeners();
  }

  Future<void> _handleFinalTranscript(String text) async {
    if (!_conversationEnabled) {
      return;
    }
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      DebugLogService.instance.log(
        'STT returned empty final text — skipping backend and TTS (try again or check locale/mic)',
        location: 'ConversationController',
        hypothesisId: 'A',
      );
      return;
    }

    _messages.add(ChatMessage(isUser: true, text: trimmed));
    _latestTranscript = '';
    await _sttService.stopListening();
    _state = ConversationState.processing;
    _statusText = '導師思考中…';
    DebugLogService.instance.log(
      'Sending recognized text to backend /api/chat',
      location: 'ConversationController',
      data: {
        'charCount': trimmed.length.toString(),
        'transcript': clipDebugText(trimmed, maxChars: 800),
      },
      hypothesisId: 'A',
    );
    notifyListeners();

    try {
      final reply = await _sendToBackend(trimmed);
      _messages.add(ChatMessage(isUser: false, text: reply));
      _state = ConversationState.speaking;
      _statusText = '正在播報回覆…';
      DebugLogService.instance.log(
        'Backend text received — starting TTS',
        location: 'ConversationController',
        data: {
          'replyLength': reply.length.toString(),
          'replyText': clipDebugText(reply, maxChars: 800),
        },
        hypothesisId: 'A',
      );
      notifyListeners();
      await _ttsService.speak(reply);
    } catch (e) {
      DebugLogService.instance.log(
        'backend or TTS chain failed',
        location: 'ConversationController',
        data: {
          'error': e.toString(),
        },
        hypothesisId: 'A',
      );
      const msg = '連線導師時發生網路或伺服器錯誤。';
      _messages.add(const ChatMessage(isUser: false, text: msg));
      _setError(msg);
    }
  }

  void _handlePartialTranscript(String text) {
    if (!_conversationEnabled || _state != ConversationState.listening) {
      return;
    }
    _latestTranscript = text;
    notifyListeners();
  }

  void _handleSttError(String message) {
    if (!_conversationEnabled) {
      return;
    }
    DebugLogService.instance.log(
      'STT error',
      location: 'ConversationController',
      data: {
        'message': message.length > 200 ? message.substring(0, 200) : message,
      },
      hypothesisId: 'A',
    );
    _setError('語音辨識失敗：$message');
  }

  Future<String> _sendToBackend(String transcript) async {
    final uri = Uri.parse('$_backendBaseUrl/api/chat');
    DebugLogService.instance.log(
      'POST /api/chat (request body studentMessage)',
      location: 'ConversationController._sendToBackend',
      data: {
        'uri': uri.toString(),
        'studentMessage': clipDebugText(transcript, maxChars: 800),
      },
      hypothesisId: 'A',
    );
    final response = await _httpClient
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
        'studentMessage': transcript,
        'language': _apiLanguage,
      }),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      DebugLogService.instance.log(
        'HTTP error from backend',
        location: 'ConversationController._sendToBackend',
        data: {
          'status': response.statusCode.toString(),
          'bodyPreview': clipDebugText(response.body, maxChars: 400),
        },
        hypothesisId: 'A',
      );
      final snippet = response.body.length > 280
          ? '${response.body.substring(0, 280)}…'
          : response.body;
      throw Exception('Bad response: ${response.statusCode} $snippet');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final reply = data['reply'] as String?;
    if (reply == null || reply.isEmpty) {
      DebugLogService.instance.log(
        'Backend JSON missing reply',
        location: 'ConversationController._sendToBackend',
        data: {
          'bodyPreview': clipDebugText(response.body, maxChars: 400),
        },
        hypothesisId: 'A',
      );
      throw Exception('Empty reply');
    }

    DebugLogService.instance.log(
      'HTTP 200 /api/chat — reply JSON parsed',
      location: 'ConversationController._sendToBackend',
      data: {
        'bodyLength': response.body.length.toString(),
        'replyText': clipDebugText(reply, maxChars: 800),
      },
      hypothesisId: 'A',
    );
    return reply;
  }

  Future<void> _handleTtsComplete() async {
    if (!_conversationEnabled) {
      return;
    }
    _latestTranscript = '';
    _state = ConversationState.listening;
    _statusText = '正在聆聽…';
    DebugLogService.instance.log(
      'TTS complete, resuming listen',
      location: 'ConversationController',
      hypothesisId: 'A',
    );
    notifyListeners();
    final ok = await _sttService.startListening(localeId: _speechLocaleId);
    if (!ok) {
      _setError('無法繼續聆聽。');
      _conversationEnabled = false;
      notifyListeners();
    }
  }

  void _setError(String message) {
    _conversationEnabled = false;
    _state = ConversationState.error;
    _statusText = message;
    DebugLogService.instance.log(
      'error state',
      location: 'ConversationController._setError',
      data: {
        'message': message.length > 200 ? message.substring(0, 200) : message,
      },
      hypothesisId: 'A',
    );
    notifyListeners();
    unawaited(_sttService.stopListening());
    unawaited(_ttsService.stop());
  }

  @override
  void dispose() {
    if (_ownsHttpClient) {
      _httpClient.close();
    }
    _sttService.dispose();
    _ttsService.dispose();
    super.dispose();
  }
}
