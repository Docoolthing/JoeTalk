import 'package:flutter/material.dart';

import 'features/conversation/conversation_page.dart';
import 'theme/joeai2_theme.dart';

void main() {
  runApp(const JoeTalkApp());
}

class JoeTalkApp extends StatelessWidget {
  const JoeTalkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '圓玄學院陳國超興德小學',
      theme: buildJoeAi2Theme(),
      home: const ConversationPage(),
    );
  }
}
