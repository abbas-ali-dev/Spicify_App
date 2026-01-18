import 'package:Spicify/model/book_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../utilities/app_colors.dart';
import '../utilities/app_typography.dart';
import 'audio_manager/audio_manager.dart';

class BonusScenePlayer extends StatefulWidget {
  final Map scene;
  final AudioManager audioManager;

  const BonusScenePlayer({
    super.key,
    required this.scene,
    required this.audioManager,
  });

  @override
  State<BonusScenePlayer> createState() => _BonusScenePlayerState();
}

class _BonusScenePlayerState extends State<BonusScenePlayer> {
  Book? _book;

  @override
  void initState() {
    super.initState();
    WidgetsFlutterBinding.ensureInitialized()
        .addPostFrameCallback((_) => _fetchBook());
  }

  Future<void> _togglePlay() async {
    if (widget.scene['audioUrl'] != null) {
      await widget.audioManager.toggleAudio(widget.scene['audioUrl']);
    }
  }

  Future<void> _fetchBook() async {
    final audioId = widget.scene['selectedBookId'];
    if (audioId == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('audiobooks')
          .doc(audioId)
          .get();

      if (!doc.exists) {
        print('Book not found');
        return;
      }

      final data = doc.data() as Map<String, dynamic>;

      // ------- Parse Chapters -------
      final List<Chapter> chapters =
          (data['chapters'] as List<dynamic>? ?? []).map((chapterData) {
        final c = Map<String, dynamic>.from(chapterData);

        // Parse contentBlocks correctly
        final rawBlocks = (c['contentBlocks'] as List<dynamic>? ?? []);

        final contentBlocks = rawBlocks.map<ContentBlock>((b) {
          final m = Map<String, dynamic>.from(b);

          final type = (m['type'] ?? '').toString();

          if (type == "image") {
            return ContentBlock(
              type: "image",
              text: null,
              url: m['url']?.toString(),
            );
          }

          // paragraph → treat as text
          return ContentBlock(
            type: "text",
            text: (m['content'] ?? '').toString(),
            url: null,
          );
        }).toList();

        return Chapter(
          chapterId: c['chapterId'] ?? 0,
          chapterName: c['chapterName'] ?? '',
          chapterUrl: c['chapterUrl'] ?? '',
          chapterType:
              c['chapterType']?.toString(), // <-- IMPORTANT for reading mode
          isLocked: c['isLocked'] ?? false,
          isFree: c['isFree'] ?? false,
          order: c['order'] ?? 0,
          isDownloadable: c['isDownloadable'] ?? false,
          textContent: c['textContent'] ?? '',
          contentBlocks: contentBlocks,
        );
      }).toList();

      // ------- Parse Hub Buttons -------
      final hubButtonsData = data['hubButtons'] ?? {};
      final HubButtons hubButtons = HubButtons(
        listen: hubButtonsData['listen'] ?? false,
        read: hubButtonsData['read'] ?? false,
        watch: hubButtonsData['watch'] ?? false,
      );

      // ------- Set the Book -------
      setState(() {
        _book = Book(
          id: doc.id,
          poster: data['poster'] ?? '',
          bookCover: data['bookCover'] ?? '',
          title: data['title'] ?? '',
          authoer: data['author'] ?? '',
          rate: (data['rate'] ?? 0).toInt(),
          tags: List<String>.from(data['tags'] ?? []),
          summary: data['summary'] ?? '',
          audioUrl: data['audioUrl'] ?? '',
          teaserQuote: data['teaserQuote'] ?? '',
          isRecommended: data['isRecommended'] ?? false,
          spiceLevel: data['spiceLevel'] ?? '',

          // NEW FIELDS
          chapters: chapters,
          readingModeEnabled: data['readingModeEnabled'] ?? false,
          watchModeEnabled: data['watchModeEnabled'] ?? false,
          hubButtons: hubButtons,
        );
      });
    } catch (e) {
      print('Error fetching book: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scene;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.buttonRed, width: 1.2),
          borderRadius: BorderRadius.circular(12),
          color: AppColors.cardGrey,
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                s['imageUrl'],
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RepaintBoundary(
                      child: Text(s['title'], style: AppTypography.labelText)),
                  const SizedBox(height: 4),
                  RepaintBoundary(
                      child: Text(_book?.title ?? '',
                          style: AppTypography.hintText)),
                  const SizedBox(height: 4),
                  Flexible(
                    child: RepaintBoundary(
                      child: Text(
                        _book?.summary ?? '',
                        style: AppTypography.hintText,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ValueListenableBuilder<String?>(
              valueListenable: widget.audioManager.currentAudioUrlNotifier,
              builder: (context, currentAudioUrl, _) {
                final isPlaying = currentAudioUrl == widget.scene['audioUrl'];
                return IconButton(
                  icon: Icon(
                    isPlaying ? Icons.stop_circle : Icons.play_circle_fill,
                    size: 32,
                    color: AppColors.buttonRed,
                  ),
                  onPressed: _togglePlay,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
