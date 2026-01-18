import 'package:Spicify/model/book_model.dart';
import 'package:Spicify/utilities/navigator_helper_class.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookDirectory {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Method to fetch all books from Firestore
  Future<List<Book>> getBooks() async {
    try {
      final QuerySnapshot snapshot =
          await _firestore.collection('audiobooks').get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;

        // --- Parse Chapters with NEW structure ---
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
        [];

        return Book(
          id: doc.id,
          poster: data['poster'] ?? '',
          bookCover: data['bookCover'] ?? '',
          title: data['title'] ?? '',
          authoer: data['author'] ?? data['authoer'] ?? '',
          rate: data['rate']?.toInt() ?? 0,
          tags: List<String>.from(data['tags'] ?? []),
          summary: data['summary'] ?? '',
          audioUrl: data['audioUrl'] ?? '',
          teaserQuote: data['teaserQuote'] ?? '',
          isRecommended: data['isRecommended'] ?? false,
          spiceLevel: data['spiceLevel'] ?? '',

          // NEW
          readingModeEnabled: data['readingModeEnabled'] ?? false,
          watchModeEnabled: data['watchModeEnabled'] ?? false,
          hubButtons: HubButtons.fromMap(data['hubButtons'] ?? {}),

          chapters: chapters,
        );
      }).toList();
    } catch (e) {
      print('Error fetching books: $e');
      await logAppError(message: e.toString(), location: "getBooks/home");
      return [];
    }
  }

  // Method to fetch all books from Firestore
  Future<List<Book>> getBookByTitle(String title) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('audiobooks')
          .where('title', isEqualTo: title)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;

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
        [];

        return Book(
          id: doc.id,
          poster: data['poster'] ?? '',
          bookCover: data['bookCover'] ?? '',
          title: data['title'] ?? '',
          authoer: data['author'] ?? data['authoer'] ?? '',
          rate: data['rate']?.toInt() ?? 0,
          tags: List<String>.from(data['tags'] ?? []),
          summary: data['summary'] ?? '',
          audioUrl: data['audioUrl'] ?? '',
          teaserQuote: data['teaserQuote'] ?? '',
          isRecommended: data['isRecommended'] ?? false,
          spiceLevel: data['spiceLevel'] ?? '',
          readingModeEnabled: data['readingModeEnabled'] ?? false,
          watchModeEnabled: data['watchModeEnabled'] ?? false,
          hubButtons: HubButtons.fromMap(data['hubButtons'] ?? {}),
          chapters: chapters,
        );
      }).toList();
    } catch (e) {
      print('Error fetching book by title: $e');
      await logAppError(message: e.toString(), location: "getBookByTitle/home");
      return [];
    }
  }

  // Method to fetch recommended books
  Future<List<Book>> getRecommendedBooks() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('audiobooks')
          .where('isRecommended', isEqualTo: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;

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
        [];

        return Book(
          id: doc.id,
          poster: data['poster'] ?? '',
          bookCover: data['bookCover'] ?? '',
          title: data['title'] ?? '',
          authoer: data['author'] ?? data['authoer'] ?? '',
          rate: data['rate']?.toInt() ?? 0,
          tags: List<String>.from(data['tags'] ?? []),
          summary: data['summary'] ?? '',
          audioUrl: data['audioUrl'] ?? '',
          teaserQuote: data['teaserQuote'] ?? '',
          isRecommended: true,
          spiceLevel: data['spiceLevel'] ?? '',
          readingModeEnabled: data['readingModeEnabled'] ?? false,
          watchModeEnabled: data['watchModeEnabled'] ?? false,
          hubButtons: HubButtons.fromMap(data['hubButtons'] ?? {}),
          chapters: chapters,
        );
      }).toList();
    } catch (e) {
      print('Error fetching recommended books: $e');
      await logAppError(
          message: e.toString(), location: "getRecommendedBooks/home");
      return [];
    }
  }

  // Fetch all categories
  Future<List<String>> getCategories() async {
    try {
      final DocumentSnapshot snapshot =
          await _firestore.collection('categories').doc('topics').get();

      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        return List<String>.from(data['list'] ?? []);
      }
      return [];
    } catch (e) {
      print('Error fetching categories: $e');
      await logAppError(message: e.toString(), location: "getCategories/Home");
      return [];
    }
  }
}
