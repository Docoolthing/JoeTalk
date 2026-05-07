import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/debug_log_service.dart';
import '../../services/stt_service.dart';
import '../../services/tts_service.dart';
import '../../theme/joeai2_theme.dart';
import 'conversation_controller.dart';

String _conversationStateLabelZh(ConversationState state) {
  switch (state) {
    case ConversationState.idle:
      return '待機';
    case ConversationState.listening:
      return '聆聽中';
    case ConversationState.processing:
      return '處理中';
    case ConversationState.speaking:
      return '播報中';
    case ConversationState.error:
      return '錯誤';
  }
}

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
    DebugLogService.instance.addListener(_onDebugLogServiceChanged);
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

  void _onDebugLogServiceChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    DebugLogService.instance.removeListener(_onDebugLogServiceChanged);
    _controller
      ..removeListener(_onControllerChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final running = _controller.isRunning;
    final debug = DebugLogService.instance;
    final debugOn = debug.enabled;

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: joeAi2PageGradient),
            ),
          ),
          Positioned(
            left: -0.08 * MediaQuery.sizeOf(context).width,
            top: MediaQuery.sizeOf(context).height * 0.05,
            child: _AmbientBlob(
              size: 320,
              color: CkcpsColors.blue.withValues(alpha: 0.2),
            ),
          ),
          Positioned(
            right: -0.06 * MediaQuery.sizeOf(context).width,
            bottom: 0,
            child: _AmbientBlob(
              size: 380,
              color: CkcpsColors.tealDark.withValues(alpha: 0.2),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 920,
                      maxHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _BrandRibbon(
                            onClearLog: () => debug.clear(),
                          ),
                          Expanded(
                            child: Container(
                              decoration: ckcpsChatWindowDecoration(),
                              clipBehavior: Clip.antiAlias,
                              child: Column(
                                children: [
                                  _ChatHeader(
                                    debugOn: debugOn,
                                    onDebugChanged: (v) {
                                      debug.enabled = v;
                                      if (v) {
                                        debug.log(
                                          '從介面啟用偵錯記錄',
                                          location: 'ConversationPage',
                                          hypothesisId: 'B',
                                        );
                                      }
                                    },
                                  ),
                                  Expanded(
                                    child: Container(
                                      color: CkcpsColors.panel,
                                      child: _MessageArea(
                                        key: const ValueKey('messageArea'),
                                        controller: _controller,
                                        backendBaseUrl: _backendBaseUrl,
                                        debugOn: debugOn,
                                        debugLines: debug.lines,
                                      ),
                                    ),
                                  ),
                                  _ComposerBar(
                                    running: running,
                                    onPressed: _controller.toggleConversation,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AmbientBlob extends StatelessWidget {
  const _AmbientBlob({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _BrandRibbon extends StatelessWidget {
  const _BrandRibbon({
    required this.onClearLog,
  });

  final VoidCallback onClearLog;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: ckcpsBrandRibbonDecoration(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '圓玄學院陳國超興德小學',
                    style: GoogleFonts.notoSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: CkcpsColors.blueMid,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'The Yuen Yuen Institute Chan Kwok Chiu Hing Tak Primary School',
                    style: GoogleFonts.notoSans(
                      fontSize: 12,
                      color: CkcpsColors.muted,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            OutlinedButton(
              onPressed: onClearLog,
              style: ckcpsGhostButtonStyle(),
              child: const Text('清除偵錯記錄'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({
    required this.debugOn,
    required this.onDebugChanged,
  });

  final bool debugOn;
  final ValueChanged<bool> onDebugChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 18),
      decoration: const BoxDecoration(
        color: CkcpsColors.navBg,
        border: Border(
          bottom: BorderSide(color: CkcpsColors.hairline),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x0F000000),
            offset: Offset(0, -2),
            blurRadius: 3,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('語音 · 學與教', style: ckcpsEyebrowStyle()),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.only(left: 12, top: 4, bottom: 4, right: 4),
            decoration: const BoxDecoration(
              color: Color(0xA6FFFFFF),
              border: Border(
                left: BorderSide(
                  color: CkcpsColors.blue,
                  width: 2,
                ),
              ),
            ),
            child: Text('語音導師對話', style: ckcpsAppTitleStyle()),
          ),
          const SizedBox(height: 10),
          Text(
            '以語音提問，導師以文字與語音回覆。下方顯示狀態與服務位址。僅供學習示範。',
            style: ckcpsSubtitleStyle(),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              gradient: const LinearGradient(
                colors: [CkcpsColors.yellow, Color(0xFFFFE066)],
              ),
            ),
            child: Text(
              '請在寧靜環境下使用麥克風',
              style: GoogleFonts.notoSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF292500),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('偵錯記錄', style: TextStyle(fontSize: 14)),
              Switch(
                value: debugOn,
                onChanged: onDebugChanged,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MessageArea extends StatefulWidget {
  const _MessageArea({
    super.key,
    required this.controller,
    required this.backendBaseUrl,
    required this.debugOn,
    required this.debugLines,
  });

  final ConversationController controller;
  final String backendBaseUrl;
  final bool debugOn;
  final List<String> debugLines;

  @override
  State<_MessageArea> createState() => _MessageAreaState();
}

class _MessageAreaState extends State<_MessageArea> {
  final ScrollController _scroll = ScrollController();
  int _lastScrollSignature = 0;

  int _chatScrollSignature(ConversationController c) {
    return Object.hash(
      c.messages.length,
      c.messages.isEmpty
          ? 0
          : Object.hash(
              c.messages.last.isUser,
              c.messages.last.text,
            ),
      c.latestTranscript,
    );
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final sig = _chatScrollSignature(c);
    if (sig != _lastScrollSignature) {
      _lastScrollSignature = sig;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scroll.hasClients) {
          return;
        }
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        );
      });
    }

    return Column(
      children: [
        Expanded(
          flex: widget.debugOn ? 2 : 1,
          child: ListView(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(28, 20, 28, 20),
            children: [
              _StatusBubble(
                text: c.statusText,
                meta:
                    '服務位址：${widget.backendBaseUrl} · 狀態：${_conversationStateLabelZh(c.state)}',
              ),
              if (c.messages.isEmpty && c.latestTranscript.isEmpty) ...[
                const SizedBox(height: 20),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Text(
                      '點「開始」後再說話。您與導師的往來訊息會如聊天一樣累積顯示在此。',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.notoSans(
                        fontSize: 15,
                        height: 1.5,
                        color: CkcpsColors.muted,
                      ),
                    ),
                  ),
                ),
              ],
              for (var i = 0; i < c.messages.length; i++) ...[
                const SizedBox(height: 14),
                c.messages[i].isUser
                    ? _UserBubble(
                        key: ValueKey('user:$i'),
                        text: c.messages[i].text,
                      )
                    : _AssistantBubble(
                        key: ValueKey('tutor:$i'),
                        text: c.messages[i].text,
                      ),
              ],
              if (c.latestTranscript.isNotEmpty) ...[
                const SizedBox(height: 14),
                _UserBubble(
                  key: const ValueKey('draftUser'),
                  text: c.latestTranscript,
                  isDraft: true,
                ),
              ],
            ],
          ),
        ),
        if (widget.debugOn)
          Expanded(
            child: _DebugLogPanel(
              key: const ValueKey('debugLogPanel'),
              lines: widget.debugLines,
            ),
          ),
      ],
    );
  }
}

class _StatusBubble extends StatelessWidget {
  const _StatusBubble({required this.text, required this.meta});

  final String text;
  final String meta;

  @override
  Widget build(BuildContext context) {
    return Align(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                border: Border.all(color: CkcpsColors.hairline),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSans(
                  fontSize: 14,
                  color: CkcpsColors.muted,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              meta,
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSans(
                fontSize: 12,
                color: CkcpsColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssistantBubble extends StatelessWidget {
  const _AssistantBubble({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(6)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [CkcpsColors.blue, CkcpsColors.blueMid],
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x4005236B),
                offset: Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
          child: Text(
            '導',
            style: GoogleFonts.notoSans(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: CkcpsColors.assistantPanel,
              border: Border.all(
                color: CkcpsColors.tealBorder,
                width: 2,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
                bottomRight: Radius.circular(6),
                bottomLeft: Radius.circular(2),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0F000000),
                  offset: Offset(0, 1),
                  blurRadius: 2,
                ),
              ],
            ),
            child: Text(
              text,
              style: GoogleFonts.notoSans(
                fontSize: 16,
                height: 1.65,
                color: CkcpsColors.text,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _UserBubble extends StatelessWidget {
  const _UserBubble({super.key, required this.text, this.isDraft = false});

  final String text;
  final bool isDraft;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.9,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isDraft
                      ? CkcpsColors.tealDark.withValues(alpha: 0.75)
                      : CkcpsColors.tealDark,
                  border: Border.all(
                    color: isDraft
                        ? CkcpsColors.tealDark.withValues(alpha: 0.4)
                        : CkcpsColors.tealDark,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                    bottomLeft: Radius.circular(6),
                    bottomRight: Radius.circular(2),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x4D0A828F),
                      offset: Offset(0, 2),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Text(
                  text,
                  style: GoogleFonts.notoSans(
                    fontSize: 16,
                    height: 1.65,
                    color: Colors.white,
                    fontStyle: isDraft ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(6)),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [CkcpsColors.ctaBlue, CkcpsColors.tealDark],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x4005236B),
                    offset: Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Text(
                '我',
                style: GoogleFonts.notoSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComposerBar extends StatelessWidget {
  const _ComposerBar({
    required this.running,
    required this.onPressed,
  });

  final bool running;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CkcpsColors.navBg,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: CkcpsColors.hairline),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x0F000000),
              offset: Offset(0, 2),
              blurRadius: 3,
            ),
          ],
        ),
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: CkcpsColors.sendBlue,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            textStyle: GoogleFonts.notoSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
            shadowColor: const Color(0x592FA2DB),
            elevation: 2,
          ),
          child: Text(running ? '停止' : '開始'),
        ),
      ),
    );
  }
}

class _DebugLogPanel extends StatefulWidget {
  const _DebugLogPanel({super.key, required this.lines});

  final List<String> lines;

  @override
  State<_DebugLogPanel> createState() => _DebugLogPanelState();
}

class _DebugLogPanelState extends State<_DebugLogPanel> {
  final ScrollController _scroll = ScrollController();

  @override
  void didUpdateWidget(covariant _DebugLogPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lines.length < widget.lines.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.jumpTo(_scroll.position.maxScrollExtent);
        }
      });
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: CkcpsColors.navBg,
        border: Border.all(color: CkcpsColors.hairline),
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            offset: Offset(0, 1),
            blurRadius: 2,
          ),
        ],
      ),
      child: widget.lines.isEmpty
          ? Center(
              child: Text(
                '偵錯記錄已開啟，使用應用程式後即可在此檢視輸出。',
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSans(
                  fontSize: 12,
                  color: CkcpsColors.muted,
                ),
              ),
            )
          : ListView.separated(
              controller: _scroll,
              itemCount: widget.lines.length,
              separatorBuilder: (_, __) => const Divider(
                height: 1,
                color: CkcpsColors.hairline,
              ),
              itemBuilder: (context, i) {
                return SelectableText(
                  widget.lines[i],
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    height: 1.3,
                    color: CkcpsColors.text,
                  ),
                );
              },
            ),
    );
  }
}
