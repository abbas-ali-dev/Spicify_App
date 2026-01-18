import 'package:Spicify/screens/reader_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../gen_l10n/app_localizations.dart';
import '../model/book_model.dart';
import '../provider_book/reader_provider.dart';
import '../screens/book_details_screen.dart';
import '../utilities/navigator_helper_class.dart';
import '../utilities/app_colors.dart';
import '../utilities/app_typography.dart';

class ContinueReadingCard extends StatelessWidget {
  final String userId;
  const ContinueReadingCard({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection("reading_progress")
          .doc(userId)
          .snapshots(), // REAL-TIME LISTENER
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox.shrink();
        }

        var data = snapshot.data!.data() as Map<String, dynamic>;

        Book book = Book.fromMap(data["book"], snapshot.data!.id);
        String lastChapter = data["chapter"] ?? "";
        int lastPage = data["page"] ?? 0;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: GestureDetector(
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              final readerProv = ReaderProvider(
                  book: book,
                  prefs: prefs,
                  initialOrderFromFirestore: lastPage);

              print('Book Reading ${book.chapters}');

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider.value(
                    value: readerProv,
                    child: ReaderScreen(),
                  ),
                ),
              );
            },
            child: Container(
              height: 140,
              decoration: BoxDecoration(
                color: AppColors.cardGrey,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.buttonRed, width: 1),
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      book.bookCover,
                      height: 110,
                      width: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppLocalizations.of(context).continueReading,
                          style: AppTypography.sectionHeaderLabel,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          book.title,
                          style: AppTypography.medium14Text,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "$lastChapter • Page $lastPage",
                          style: AppTypography.regular16Text
                              .copyWith(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
