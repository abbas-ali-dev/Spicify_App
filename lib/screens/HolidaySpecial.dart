import 'package:flutter/material.dart';
import '../utilities/app_typography.dart';
import 'audio_manager/audio_manager.dart';

class HolidaySpecialWidget extends StatelessWidget {
  final Map m;
  final AudioManager audioManager;

  const HolidaySpecialWidget({
    required this.m,
    required this.audioManager,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (m['audioUrl'] != null) {
          audioManager.toggleAudio(m['audioUrl']);
        }
      },
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(12),
          image: DecorationImage(
            image: NetworkImage(m['imageUrl']),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: RepaintBoundary(
                  child: Text(
                    m['title'],
                    style: AppTypography.buttonText,
                  ),
                ),
              ),
            ),
            if (m['audioUrl'] != null)
              Positioned(
                top: 8,
                right: 8,
                child: ValueListenableBuilder<String?>(
                  valueListenable: audioManager.currentAudioUrlNotifier,
                  builder: (context, currentAudioUrl, _) {
                    final isPlaying = currentAudioUrl == m['audioUrl'];
                    return Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isPlaying ? Icons.stop : Icons.play_arrow,
                        color: Colors.white,
                        size: 20,
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
