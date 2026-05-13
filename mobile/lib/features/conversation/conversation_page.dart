import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../../services/stt_service.dart';
import '../../services/tts_service.dart';
import 'conversation_controller.dart';

class ConversationPage extends StatefulWidget {
  const ConversationPage({super.key});

  @override
  State<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends State<ConversationPage> {
  late final ConversationController _controller;
  static const _backendFromEnv = String.fromEnvironment('BACKEND_BASE_URL');

  String get _backendBaseUrl {
    if (_backendFromEnv.isNotEmpty) {
      return _backendFromEnv;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://localhost:3000';
  }

  @override
  void initState() {
    super.initState();
    _controller = ConversationController(
      sttService: SttService(),
      ttsService: TtsService(),
      backendBaseUrl: _backendBaseUrl,
    )..addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onControllerChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final running = _controller.isRunning;
    return Scaffold(
      appBar: AppBar(title: const Text('Chinese Tutor Chat')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _controller.statusText,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Backend: $_backendBaseUrl | State: ${_controller.state.name}',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _controller.toggleConversation,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 58),
              ),
              child: Text(running ? 'Stop Conversation' : 'Start Conversation'),
            ),
            const SizedBox(height: 24),
            Text('You said: ${_controller.latestTranscript.isEmpty ? "-" : _controller.latestTranscript}'),
            const SizedBox(height: 12),
            Text('Tutor said: ${_controller.latestReply.isEmpty ? "-" : _controller.latestReply}'),
          ],
        ),
      ),
    );
  }
}
