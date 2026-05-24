import 'package:ecopulse/core/environment/environment.dart';
import 'package:ecopulse/data/models/ai_chat_message_model.dart';
import 'package:ecopulse/data/repositories/ai_conversation_repository.dart';
import 'package:ecopulse/data/repositories/vehicle_repository.dart';
import 'package:ecopulse/presentation/map/map_colors.dart';
import 'package:ecopulse/services/ai/vehicle_assistant_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AiAssistantScreen extends ConsumerStatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  ConsumerState<AiAssistantScreen> createState() {
    return _AiAssistantScreenState();
  }
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  final List<AiChatMessageModel> _messages = [];

  bool _isLoading = false;
  bool _showComposerGlow = false;
  bool? _manualDark;

  // Key que cambia cada vez que llega una nueva respuesta del asistente,
  // forzando que los chips reaparezcan con animación.
  int _suggestionAnimationKey = 0;

  static const List<String> _suggestions = [
    '¿Cómo puedo reducir el consumo?',
    '¿Cuál es la presión de mis llantas recomendada?',
    '¿Cada cuánto debo cambiar mi aceite?',
  ];

  @override
  void initState() {
    super.initState();

    _messages.add(
      AiChatMessageModel(
        role: 'assistant',
        content:
            'Hola, soy el asistente de EcoPulse. Puedo ayudarte con conducción eficiente, mantenimiento preventivo y explicación de métricas del vehículo.',
        createdAt: DateTime.now(),
      ),
    );

    _messageController.addListener(_handleComposerState);
    _inputFocusNode.addListener(_handleComposerState);
  }

  @override
  void dispose() {
    _messageController.removeListener(_handleComposerState);
    _inputFocusNode.removeListener(_handleComposerState);
    _messageController.dispose();
    _inputFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleComposerState() {
    final shouldGlow =
        _inputFocusNode.hasFocus || _messageController.text.trim().isNotEmpty;

    if (_showComposerGlow != shouldGlow && mounted) {
      setState(() {
        _showComposerGlow = shouldGlow;
      });
    }
  }

  bool _isDark(BuildContext context) =>
      _manualDark ??
      (MediaQuery.of(context).platformBrightness == Brightness.dark);

  void _toggleTheme() {
    HapticFeedback.lightImpact();
    setState(() => _manualDark = !_isDark(context));
  }

  Future<void> _scrollToBottom() async {
    await Future.delayed(const Duration(milliseconds: 60));

    if (!_scrollController.hasClients) return;

    await _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  String _sanitizeAssistantText(String input) {
    var text = input.replaceAll('\r\n', '\n');

    text = text.replaceAllMapped(
      RegExp(r'^[\-\*\•]\s+', multiLine: true),
      (match) => '• ',
    );

    text = text.replaceAllMapped(
      RegExp(r'`([^`]+)`'),
      (match) => match.group(1) ?? '',
    );

    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();

    return text;
  }

  List<_TextSegment> _parseInlineSegments(String text) {
    final segments = <_TextSegment>[];
    final exp = RegExp(r'\*\*(.*?)\*\*');
    int lastIndex = 0;

    for (final match in exp.allMatches(text)) {
      if (match.start > lastIndex) {
        segments.add(_TextSegment(
          text: text.substring(lastIndex, match.start),
          isBold: false,
        ));
      }

      final boldText = match.group(1) ?? '';
      if (boldText.isNotEmpty) {
        segments.add(_TextSegment(text: boldText, isBold: true));
      }

      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      segments.add(_TextSegment(
        text: text.substring(lastIndex),
        isBold: false,
      ));
    }

    if (segments.isEmpty) {
      segments.add(_TextSegment(text: text, isBold: false));
    }

    return segments;
  }

  List<TextSpan> _buildFormattedSpans({
    required String text,
    required Color color,
    required bool isUser,
  }) {
    final spans = <TextSpan>[];
    final lines = _sanitizeAssistantText(text).split('\n');

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final segments = _parseInlineSegments(line);

      for (final segment in segments) {
        spans.add(
          TextSpan(
            text: segment.text,
            style: TextStyle(
              color: color,
              fontSize: 13.6,
              height: 1.42,
              fontWeight: segment.isBold ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        );
      }

      if (i != lines.length - 1) {
        spans.add(const TextSpan(text: '\n'));
      }
    }

    return spans;
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();

    if (text.isEmpty || _isLoading) {
      return;
    }

    HapticFeedback.lightImpact();

    setState(() {
      _isLoading = true;
      _messageController.clear();
      _messages.add(
        AiChatMessageModel(
          role: 'user',
          content: text,
          createdAt: DateTime.now(),
        ),
      );
    });

    _handleComposerState();
    _scrollToBottom();

    try {
      final selectedVehicle =
          await ref.read(vehicleRepositoryProvider).getSelectedVehicle();

      final response = await ref.read(vehicleAssistantServiceProvider).ask(
            question: text,
            vehicle: selectedVehicle,
            history: _messages,
          );

      await ref.read(aiConversationRepositoryProvider).saveConversation(
            userMessage: text,
            assistantResponse: response,
            vehicleId: selectedVehicle?.id,
            modelName: Environment.groqModel,
          );

      if (!mounted) {
        return;
      }

      setState(() {
        _messages.add(
          AiChatMessageModel(
            role: 'assistant',
            content: _sanitizeAssistantText(response),
            createdAt: DateTime.now(),
          ),
        );
        // Incrementar clave para re-animar los chips.
        _suggestionAnimationKey++;
      });

      _scrollToBottom();
    } catch (exception) {
      if (!mounted) {
        return;
      }

      setState(() {
        _messages.add(
          AiChatMessageModel(
            role: 'assistant',
            content:
                'No fue posible responder en este momento. **Intenta nuevamente** en unos segundos.',
            createdAt: DateTime.now(),
          ),
        );
        _suggestionAnimationKey++;
      });

      _scrollToBottom();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _useSuggestion(String text) {
    HapticFeedback.selectionClick();
    _messageController.text = text;
    _messageController.selection = TextSelection.fromPosition(
      TextPosition(offset: _messageController.text.length),
    );
    _inputFocusNode.requestFocus();
    _handleComposerState();
  }

  String _timeLabel(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Widget _buildMessageBubble(
    BuildContext context,
    AiChatMessageModel message,
    int index,
    MapColors colors,
  ) {
    final isUser = message.isUser;
    final bubbleColor = isUser
        ? colors.textPrimary.withOpacity(0.92)
        : colors.card.withOpacity(0.98);
    final borderColor = isUser
        ? colors.textPrimary.withOpacity(0.08)
        : colors.border.withOpacity(0.92);
    final textColor = isUser ? colors.card : colors.textPrimary;
    final metaColor =
        isUser ? colors.card.withOpacity(0.72) : colors.textSecondary;

    const baseRadius = Radius.circular(22);

    final borderRadius = BorderRadius.only(
      topLeft: baseRadius,
      topRight: baseRadius,
      bottomLeft: isUser ? baseRadius : const Radius.circular(8),
      bottomRight: isUser ? const Radius.circular(8) : baseRadius,
    );

    return TweenAnimationBuilder<double>(
      key: ValueKey(
          '${message.role}-$index-${message.createdAt.toIso8601String()}'),
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 260 + (index * 18).clamp(0, 120)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 18),
            child: child,
          ),
        );
      },
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width < 700 ? 320 : 460,
          ),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 7),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: borderRadius,
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: colors.shadow.withOpacity(isUser ? 0.32 : 0.20),
                  blurRadius: isUser ? 14 : 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isUser)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: colors.primary.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: colors.primary.withOpacity(0.14),
                            ),
                          ),
                          child: Icon(
                            Icons.auto_awesome_rounded,
                            size: 12,
                            color: colors.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'EcoPulse AI',
                          style: TextStyle(
                            fontSize: 11.2,
                            fontWeight: FontWeight.w800,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                RichText(
                  text: TextSpan(
                    children: _buildFormattedSpans(
                      text: message.content,
                      color: textColor,
                      isUser: isUser,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _timeLabel(message.createdAt),
                  style: TextStyle(
                    fontSize: 10.6,
                    fontWeight: FontWeight.w700,
                    color: metaColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _isDark(context);
    final colors = MapColors(isDark);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isTablet = width >= 760;
            final isDesktop = width >= 1140;
            final horizontalPadding = isDesktop
                ? 30.0
                : isTablet
                    ? 24.0
                    : 18.0;

            return Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    14,
                    horizontalPadding,
                    14,
                  ),
                  child: _AiHeader(
                    colors: colors,
                    isDark: isDark,
                    isLoading: _isLoading,
                    onBack: () => Navigator.of(context).maybePop(),
                    onToggleTheme: _toggleTheme,
                    onFocusInput: () {
                      _inputFocusNode.requestFocus();
                    },
                  ),
                ),
                Expanded(
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            0,
                            horizontalPadding,
                            12,
                          ),
                          child: _AiHeroCard(
                            colors: colors,
                            isWide: isTablet,
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            0,
                            horizontalPadding,
                            14,
                          ),
                          child: _AiNoticeCard(colors: colors),
                        ),
                      ),
                      // Mensajes
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          2,
                          horizontalPadding,
                          0,
                        ),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              return _buildMessageBubble(
                                context,
                                _messages[index],
                                index,
                                colors,
                              );
                            },
                            childCount: _messages.length,
                          ),
                        ),
                      ),
                      // Indicador de escritura
                      SliverToBoxAdapter(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: _isLoading
                              ? Padding(
                                  padding: EdgeInsets.fromLTRB(
                                    horizontalPadding,
                                    6,
                                    horizontalPadding,
                                    8,
                                  ),
                                  child: _TypingAssistantCard(colors: colors),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ),
                      // Chips SIEMPRE al final de los mensajes
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            8,
                            horizontalPadding,
                            24,
                          ),
                          child: _SuggestionRow(
                            key: ValueKey(_suggestionAnimationKey),
                            colors: colors,
                            onTap: _useSuggestion,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    10,
                    horizontalPadding,
                    MediaQuery.of(context).padding.bottom > 0 ? 10 : 14,
                  ),
                  decoration: BoxDecoration(
                    color: colors.background.withOpacity(0.94),
                    border: Border(
                      top: BorderSide(
                        color: colors.border.withOpacity(0.72),
                      ),
                    ),
                    boxShadow: [
                      if (_showComposerGlow)
                        BoxShadow(
                          color: colors.primary.withOpacity(0.08),
                          blurRadius: 22,
                          offset: const Offset(0, -8),
                        ),
                    ],
                  ),
                  child: _AiComposer(
                    colors: colors,
                    controller: _messageController,
                    focusNode: _inputFocusNode,
                    isLoading: _isLoading,
                    onSend: _sendMessage,
                    showGlow: _showComposerGlow,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _AiHeader extends StatelessWidget {
  final MapColors colors;
  final bool isDark;
  final bool isLoading;
  final VoidCallback onBack;
  final VoidCallback onToggleTheme;
  final VoidCallback onFocusInput;

  const _AiHeader({
    required this.colors,
    required this.isDark,
    required this.isLoading,
    required this.onBack,
    required this.onToggleTheme,
    required this.onFocusInput,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 560;

        if (compact) {
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.card.withOpacity(0.96),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: colors.border),
              boxShadow: [
                BoxShadow(
                  color: colors.shadow,
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _AiCircleAction(
                      icon: Icons.arrow_back_rounded,
                      color: colors.primary,
                      bg: colors.chip,
                      border: colors.chipBorder,
                      onTap: onBack,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Asistente IA',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Conversa con EcoPulse.',
                    style: TextStyle(
                      fontSize: 12.2,
                      height: 1.4,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _AiHeaderActionButton(
                        colors: colors,
                        icon: isDark
                            ? Icons.light_mode_rounded
                            : Icons.dark_mode_rounded,
                        label: isDark ? 'Modo claro' : 'Modo oscuro',
                        color: isDark ? colors.warning : colors.primary,
                        onTap: onToggleTheme,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _AiHeaderActionButton(
                        colors: colors,
                        icon: isLoading
                            ? Icons.hourglass_top_rounded
                            : Icons.edit_rounded,
                        label: isLoading ? 'Pensando' : 'Escribir',
                        color: isLoading ? colors.warning : colors.accent,
                        onTap: onFocusInput,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.card.withOpacity(0.96),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colors.border),
            boxShadow: [
              BoxShadow(
                color: colors.shadow,
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              _AiCircleAction(
                icon: Icons.arrow_back_rounded,
                color: colors.primary,
                bg: colors.chip,
                border: colors.chipBorder,
                onTap: onBack,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Asistente IA',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Conversa con EcoPulse para entender métricas, mantenimiento y hábitos de conducción.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.2,
                        height: 1.4,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _AiCircleAction(
                icon: isDark
                    ? Icons.light_mode_rounded
                    : Icons.dark_mode_rounded,
                color: isDark ? colors.warning : colors.primary,
                bg: colors.chip,
                border: colors.chipBorder,
                onTap: onToggleTheme,
              ),
              const SizedBox(width: 8),
              _AiCircleAction(
                icon:
                    isLoading ? Icons.hourglass_top_rounded : Icons.edit_rounded,
                color: isLoading ? colors.warning : colors.accent,
                bg: (isLoading ? colors.warning : colors.accent).withOpacity(
                  0.12,
                ),
                border: (isLoading ? colors.warning : colors.accent)
                    .withOpacity(0.24),
                onTap: onFocusInput,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Hero ─────────────────────────────────────────────────────────────────────

class _AiHeroCard extends StatelessWidget {
  final MapColors colors;
  final bool isWide;

  const _AiHeroCard({
    required this.colors,
    required this.isWide,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 16 : 14,
        vertical: isWide ? 14 : 12,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.heroTop.withOpacity(0.94),
            colors.heroBottom.withOpacity(0.94),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.primary.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 22,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tu copiloto inteligente',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15.4,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Haz preguntas sobre tu vehículo y cómo ahorrar combustible.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.1,
                    height: 1.35,
                    color: Colors.white.withOpacity(0.84),
                  ),
                ),
              ],
            ),
          ),
          if (isWide) ...[
            const SizedBox(width: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.10),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.10)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Modo',
                    style: TextStyle(
                      fontSize: 10.4,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withOpacity(0.66),
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Asistencia IA',
                    style: TextStyle(
                      fontSize: 11.6,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Notice ───────────────────────────────────────────────────────────────────

class _AiNoticeCard extends StatelessWidget {
  final MapColors colors;

  const _AiNoticeCard({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 14),
      decoration: BoxDecoration(
        color: colors.card.withOpacity(0.98),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.warning.withOpacity(0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withOpacity(0.14),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: colors.warning.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colors.warning.withOpacity(0.16),
              ),
            ),
            child: Icon(
              Icons.shield_outlined,
              size: 18,
              color: colors.warning,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Orientación asistida',
                  style: TextStyle(
                    fontSize: 12.4,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'El asistente no reemplaza una revisión mecánica profesional. Usa sus respuestas como guía cuando no haya un diagnóstico técnico confirmado.',
                  style: TextStyle(
                    fontSize: 11.9,
                    height: 1.5,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Suggestions ──────────────────────────────────────────────────────────────

class _SuggestionRow extends StatelessWidget {
  final MapColors colors;
  final ValueChanged<String> onTap;

  const _SuggestionRow({
    super.key,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const suggestions = [
      '¿Cómo puedo reducir el consumo?',
      '¿Cuál es la presión de mis llantas recomendada?',
      '¿Cada cuánto debo cambiar mi aceite?',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: colors.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.primary.withOpacity(0.14)),
              ),
              child: Icon(
                Icons.tips_and_updates_rounded,
                size: 13,
                color: colors.primary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Sugerencias',
              style: TextStyle(
                fontSize: 11.8,
                fontWeight: FontWeight.w800,
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 46,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            itemCount: suggestions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              return _SuggestionChip(
                text: suggestions[index],
                colors: colors,
                index: index,
                onTap: onTap,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SuggestionChip extends StatefulWidget {
  final String text;
  final MapColors colors;
  final int index;
  final ValueChanged<String> onTap;

  const _SuggestionChip({
    required this.text,
    required this.colors,
    required this.index,
    required this.onTap,
  });

  @override
  State<_SuggestionChip> createState() => _SuggestionChipState();
}

class _SuggestionChipState extends State<_SuggestionChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _opacityAnim;
  late final Animation<double> _slideAnim;

  bool _pressed = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 560),
    );

    final delay = widget.index * 0.18;

    final curved = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        delay.clamp(0.0, 0.8),
        1.0,
        curve: Curves.elasticOut,
      ),
    );

    final curvedOpacity = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        delay.clamp(0.0, 0.8),
        1.0,
        curve: Curves.easeOut,
      ),
    );

    _scaleAnim = Tween<double>(begin: 0.52, end: 1.0).animate(curved);
    _opacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(curvedOpacity);
    _slideAnim = Tween<double>(begin: 20.0, end: 0.0).animate(curvedOpacity);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnim.value,
          child: Transform.translate(
            offset: Offset(_slideAnim.value, 0),
            child: Transform.scale(
              scale: _scaleAnim.value,
              alignment: Alignment.centerLeft,
              child: child,
            ),
          ),
        );
      },
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          HapticFeedback.selectionClick();
          widget.onTap(widget.text);
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.95 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colors.chip.withOpacity(_pressed ? 0.70 : 0.95),
                  colors.chip.withOpacity(_pressed ? 0.50 : 0.82),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: _pressed
                    ? colors.primary.withOpacity(0.30)
                    : colors.chipBorder,
              ),
              boxShadow: _pressed
                  ? []
                  : [
                      BoxShadow(
                        color: colors.shadow.withOpacity(0.14),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.bolt_rounded,
                  size: 14,
                  color: colors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.text,
                  style: TextStyle(
                    fontSize: 12.2,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Typing indicator ─────────────────────────────────────────────────────────

class _TypingAssistantCard extends StatefulWidget {
  final MapColors colors;

  const _TypingAssistantCard({required this.colors});

  @override
  State<_TypingAssistantCard> createState() => _TypingAssistantCardState();
}

class _TypingAssistantCardState extends State<_TypingAssistantCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _dot(int index) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = (_controller.value + (index * 0.18)) % 1;
        final opacity =
            0.35 + (0.65 * (1 - (progress - 0.5).abs() * 2).clamp(0, 1));
        final scale =
            0.82 + (0.28 * (1 - (progress - 0.5).abs() * 2).clamp(0, 1));

        return Opacity(
          opacity: opacity,
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: widget.colors.primary,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 240),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.card.withOpacity(0.98),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(22),
              topRight: Radius.circular(22),
              bottomLeft: Radius.circular(8),
              bottomRight: Radius.circular(22),
            ),
            border: Border.all(color: colors.border),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withOpacity(0.18),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: colors.primary.withOpacity(0.14)),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: 13,
                  color: colors.primary,
                ),
              ),
              const SizedBox(width: 10),
              _dot(0),
              const SizedBox(width: 5),
              _dot(1),
              const SizedBox(width: 5),
              _dot(2),
              const SizedBox(width: 10),
              Text(
                'Pensando...',
                style: TextStyle(
                  fontSize: 12.2,
                  fontWeight: FontWeight.w700,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Composer ─────────────────────────────────────────────────────────────────

class _AiComposer extends StatelessWidget {
  final MapColors colors;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLoading;
  final bool showGlow;
  final VoidCallback onSend;

  const _AiComposer({
    required this.colors,
    required this.controller,
    required this.focusNode,
    required this.isLoading,
    required this.onSend,
    required this.showGlow,
  });

  @override
  Widget build(BuildContext context) {
    final hasText = controller.text.trim().isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colors.card.withOpacity(0.98),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: showGlow
              ? colors.primary.withOpacity(0.30)
              : colors.border.withOpacity(0.92),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withOpacity(showGlow ? 0.24 : 0.12),
            blurRadius: showGlow ? 18 : 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: colors.chip.withOpacity(0.82),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: showGlow
                      ? colors.primary.withOpacity(0.14)
                      : colors.chipBorder.withOpacity(0.88),
                ),
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.newline,
                cursorColor: colors.primary,
                style: TextStyle(
                  fontSize: 13.8,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                  height: 1.45,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  filled: false,
                  border: InputBorder.none,
                  hintText: 'Pregunta por consumo, alertas o tu vehículo',
                  hintStyle: TextStyle(
                    fontSize: 13.0,
                    fontWeight: FontWeight.w500,
                    color: colors.textSecondary.withOpacity(0.78),
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 4, right: 6),
                    child: Container(
                      width: 18,
                      height: 18,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        size: 18,
                        color: colors.primary.withOpacity(0.92),
                      ),
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 34,
                    minHeight: 34,
                  ),
                  contentPadding: const EdgeInsets.fromLTRB(4, 13, 8, 13),
                ),
                onSubmitted: (_) {
                  if (!isLoading && hasText) {
                    onSend();
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedScale(
            scale: hasText && !isLoading ? 1 : 0.96,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            child: SizedBox(
              width: 48,
              height: 48,
              child: FilledButton(
                onPressed: isLoading ? null : onSend,
                style: FilledButton.styleFrom(
                  backgroundColor: colors.textPrimary.withOpacity(0.92),
                  disabledBackgroundColor:
                      colors.textPrimary.withOpacity(0.50),
                  foregroundColor: colors.card,
                  elevation: 0,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: isLoading
                      ? SizedBox(
                          key: const ValueKey('loading'),
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.1,
                            color: colors.card,
                          ),
                        )
                      : Icon(
                          Icons.send_rounded,
                          key: const ValueKey('send'),
                          size: 20,
                          color: colors.card,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared primitives ────────────────────────────────────────────────────────

class _AiHeaderActionButton extends StatelessWidget {
  final MapColors colors;
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AiHeaderActionButton({
    required this.colors,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.10),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.20)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AiCircleAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;
  final Color border;
  final VoidCallback onTap;

  const _AiCircleAction({
    required this.icon,
    required this.color,
    required this.bg,
    required this.border,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: Icon(icon, color: color, size: 21),
        ),
      ),
    );
  }
}

// ─── Model ────────────────────────────────────────────────────────────────────

class _TextSegment {
  final String text;
  final bool isBold;

  const _TextSegment({
    required this.text,
    required this.isBold,
  });
}