import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:petrimonium/core/constants/app_colors.dart';
import 'package:petrimonium/core/constants/app_strings.dart';
import 'package:petrimonium/core/theme/app_color_tokens.dart';
import 'package:petrimonium/core/utils/translator.dart';
import 'package:petrimonium/core/widgets/glass_card.dart';
import 'package:petrimonium/features/mentor/domain/entities/chat_message.dart';

/// Maps a real source key from `MentorSystemPromptBuilder.walletSourcesFor`
/// to its translated label — falls back to the raw key for a source added
/// backend-side before the client knows about it, rather than hiding it.
String _sourceLabel(String key) {
  final stringKey = switch (key) {
    'portfolio_summary' => AppStrings.mentorSourcePortfolioSummary,
    'portfolio_allocation' => AppStrings.mentorSourcePortfolioAllocation,
    'pet' => AppStrings.mentorSourcePet,
    'client_goal' => AppStrings.mentorSourceClientGoal,
    'client_horizon' => AppStrings.mentorSourceClientHorizon,
    'client_screen' => AppStrings.mentorSourceClientScreen,
    _ => null,
  };
  return stringKey == null ? key : Translator.translate(stringKey);
}

/// A single chat bubble: user messages are a solid neon-gradient pill
/// (right-aligned, plain text), mentor replies are a `GlassCard` with
/// markdown rendering (left-aligned) — mirrors this app's existing split
/// between player-action chrome and system/glass surfaces. A mentor reply
/// with real cited [ChatMessage.sources] gets a "Por que estou vendo isto?"
/// toggle revealing them — the Wallet design system's guardrail that every
/// Mentor interpretation cites its real RAG sources, applied per-message
/// rather than only on Home's summary card.
class ChatBubble extends StatefulWidget {
  const ChatBubble({super.key, required this.message});

  final ChatMessage message;

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  bool _showSources = false;

  bool get _isUser => widget.message.role == ChatRole.user;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: _isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: _isUser ? _buildUserBubble() : _buildMentorBubble(context),
      ),
    );
  }

  Widget _buildUserBubble() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.neonViolet, AppColors.neonPink],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(4),
        ),
      ),
      child: Text(
        widget.message.text,
        style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
      ),
    );
  }

  Widget _buildMentorBubble(BuildContext context) {
    final tokens = context.colors;
    final message = widget.message;
    final borderColor = message.isError
        ? AppColors.warningAmber.withValues(alpha: 0.5)
        : AppColors.neonCyan.withValues(alpha: 0.35);

    return GlassCard(
      borderColor: borderColor,
      borderRadius: 18,
      borderWidth: 1,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: message.text.isEmpty
          ? const SizedBox(height: 4)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                MarkdownBody(
                  data: message.text,
                  selectable: true,
                  shrinkWrap: true,
                  styleSheet: MarkdownStyleSheet(
                    p: TextStyle(color: tokens.textPrimary, fontSize: 14, height: 1.4),
                    strong: TextStyle(color: tokens.textPrimary, fontWeight: FontWeight.bold),
                    em: TextStyle(color: tokens.textSecondary, fontStyle: FontStyle.italic),
                    listBullet: const TextStyle(color: AppColors.neonCyan, fontSize: 14),
                    h1: TextStyle(color: tokens.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
                    h2: TextStyle(color: tokens.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                    code: TextStyle(
                      color: AppColors.neonCyan,
                      fontFamily: 'monospace',
                      backgroundColor: tokens.backgroundSecondary.withValues(alpha: 0.5),
                    ),
                    blockquoteDecoration: BoxDecoration(
                      color: tokens.backgroundSecondary.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    tableBorder: TableBorder.all(color: tokens.border),
                    tableHead: TextStyle(color: tokens.textPrimary, fontWeight: FontWeight.bold),
                    tableBody: TextStyle(color: tokens.textSecondary),
                  ),
                ),
                if (message.sources.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => setState(() => _showSources = !_showSources),
                    child: Text(
                      Translator.translate(AppStrings.homeMentorWhySeeing),
                      style: TextStyle(color: tokens.primary, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (_showSources) ...[
                    const SizedBox(height: 6),
                    Text(
                      Translator.translate(AppStrings.mentorSourcesLabel).toUpperCase(),
                      style: TextStyle(
                        color: tokens.textTertiary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    for (final source in message.sources)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              margin: const EdgeInsets.only(top: 5),
                              decoration: BoxDecoration(color: tokens.primary, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _sourceLabel(source),
                                style: TextStyle(color: tokens.textSecondary, fontSize: 12, height: 1.3),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ],
              ],
            ),
    );
  }
}
