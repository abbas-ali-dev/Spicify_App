import 'package:Spicify/gen_l10n/app_localizations.dart';
import 'package:Spicify/utilities/app_colors.dart';
import 'package:Spicify/utilities/app_typography.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../model/book_directory.dart';
import 'audio_player_screen.dart';

class ContinueListeningCard extends StatefulWidget {
  final String userId;

  const ContinueListeningCard({
    super.key,
    required this.userId,
  });

  @override
  State<ContinueListeningCard> createState() => _ContinueListeningCardState();
}

class _ContinueListeningCardState extends State<ContinueListeningCard> {
  final BookDirectory bookDirectory = BookDirectory();

  /// REAL-TIME STREAM: always returns the most recent audio progress
  Stream<Map<String, dynamic>?> listeningProgressStream() {
    return FirebaseFirestore.instance
        .collection('userProgress')
        .doc(widget.userId)
        .collection('audioProgress')
        .orderBy('lastUpdated', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.data();
      } else {
        return null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>?>(
      stream: listeningProgressStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data!;
        final bookTitle = data['bookId'];
        final currentChapter = data['currentChapter'];

        /// Safely get chapter progress
        final chapterProgressMs =
            data['chapters']?[currentChapter.toString()] ?? 0;
        final duration = Duration(milliseconds: chapterProgressMs);

        return Card(
          margin: const EdgeInsets.all(16),
          color: AppColors.cardGrey,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: AppColors.buttonRed,
              width: 1,
            ),
          ),
          child: ListTile(
            leading: const Icon(
              Icons.headphones,
              size: 32,
              color: Colors.white,
            ),
            title: Text(
              AppLocalizations.of(context).continueListening,
              style: AppTypography.regular16Text.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              "$bookTitle • Chapter ${currentChapter + 1} • ${formatDuration(duration)}",
              maxLines: 2,
              style: AppTypography.hintText,
            ),
            onTap: () async {
              final books = await bookDirectory.getBookByTitle(bookTitle);
              if (books.isEmpty) return;

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AudioPlayerScreen(
                    bookDetail: books[0],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  String formatDuration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final minutes = two(d.inMinutes.remainder(60));
    final seconds = two(d.inSeconds.remainder(60));
    return "${d.inHours > 0 ? '${two(d.inHours)}:' : ''}$minutes:$seconds";
  }
}
