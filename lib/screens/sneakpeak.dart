import 'dart:ui';

import 'package:flutter/material.dart';
import '../gen_l10n/app_localizations.dart';

import '../utilities/app_colors.dart';
import '../utilities/app_typography.dart';
import 'audio_manager/audio_manager.dart';

class SneakPeekWidget extends StatefulWidget {
  final Map sp;
  final AppLocalizations l10n;
  final AudioManager audioManager;

  const SneakPeekWidget({
    Key? key,
    required this.sp,
    required this.l10n,
    required this.audioManager,
  }) : super(key: key);

  @override
  _SneakPeekWidgetState createState() => _SneakPeekWidgetState();
}

class _SneakPeekWidgetState extends State<SneakPeekWidget> {
  bool _isBlurred = true;

  @override
  Widget build(BuildContext context) {
    final scheduledAt = widget.sp['scheduledAt'];
    final scheduledDate =
        scheduledAt == null ? null : DateTime.tryParse(scheduledAt)?.toUtc();

    final shouldShowSneakPeek =
        scheduledDate == null || scheduledDate.isBefore(DateTime.now().toUtc());

    if (shouldShowSneakPeek) {
      return GestureDetector(
        onTap: () {
          setState(() => _isBlurred = !_isBlurred);
        },
        child: Column(
          children: [
            _buildSectionTitle(widget.l10n.sneakPeekTitle),
            const SizedBox(height: 24),
            Stack(
              alignment: Alignment.center,
              children: [
                Image.network(
                  widget.sp['imageUrl'],
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
                if (_isBlurred) ...[
                  Positioned.fill(
                    child: ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          color: Colors.black.withOpacity(0.4),
                        ),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.visibility_off,
                          color: AppColors.white, size: 48),
                      const SizedBox(height: 8),
                      RepaintBoundary(
                        child: Text(widget.l10n.tapToReveal,
                            style: AppTypography.buttonText),
                      ),
                    ],
                  ),
                ],
                if (!_isBlurred && widget.sp['audioUrl'] != null)
                  Positioned(
                    bottom: 16,
                    child: GestureDetector(
                      onTap: () => widget.audioManager
                          .toggleAudio(widget.sp['audioUrl']),
                      child: ValueListenableBuilder<String?>(
                        valueListenable:
                            widget.audioManager.currentAudioUrlNotifier,
                        builder: (context, currentAudioUrl, _) {
                          final isPlaying =
                              currentAudioUrl == widget.sp['audioUrl'];

                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isPlaying ? Icons.stop : Icons.play_arrow,
                              color: Colors.white,
                              size: 32,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      );
    } else {
      return Container();
    }
  }

  Widget _buildSectionTitle(String text) => Align(
        alignment: Alignment.centerLeft,
        child: RepaintBoundary(
            child: Text(text, style: AppTypography.heading16Bold)),
      );
}
