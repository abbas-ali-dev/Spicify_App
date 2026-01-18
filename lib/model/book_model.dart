// class Book {
//   final String id;
//   final String poster;
//   final String bookCover;
//   final String title;
//   final String authoer;
//   final int rate;
//   final List<String> tags;
//   final String summary;
//   final String teaserQuote;
//   final String audioUrl;
//   final String spiceLevel;
//   final bool isRecommended;
//   final List<Chapters> chapters;
//
//   Book(
//       {required this.id,
//       required this.poster,
//       required this.bookCover,
//       required this.title,
//       required this.authoer,
//       required this.rate,
//       required this.tags,
//       required this.summary,
//       required this.teaserQuote,
//       required this.audioUrl,
//       required this.spiceLevel,
//       required this.isRecommended,
//       required this.chapters});
//
//   /// ✅ Convert Firestore Map -> Book object
//   factory Book.fromMap(Map<String, dynamic> map, String docId) {
//     return Book(
//       id: docId,
//       poster: map['poster'] ?? '',
//       bookCover: map['bookCover'] ?? '',
//       title: map['title'] ?? '',
//       authoer: map['authoer'] ?? '',
//       rate: (map['rate'] ?? 0).toInt(),
//       tags: List<String>.from(map['tags'] ?? []),
//       summary: map['summary'] ?? '',
//       teaserQuote: map['teaserQuote'] ?? '',
//       audioUrl: map['audioUrl'] ?? '',
//       spiceLevel: map['spiceLevel'] ?? '',
//       isRecommended: map['isRecommended'] ?? false,
//       chapters: (map['chapters'] as List<dynamic>? ?? [])
//           .map((c) => Chapters.fromMap(c as Map<String, dynamic>))
//           .toList(),
//     );
//   }
//
//   Book copyWithUpdated(Map<String, dynamic> map) {
//     return Book(
//       id: id, // keep same id unless Firestore has it
//       poster: map['poster'] ?? poster,
//       bookCover: map['bookCover'] ?? bookCover,
//       title: map['title'] ?? title,
//       authoer: map['authoer'] ?? authoer,
//       rate: (map['rate'] ?? rate).toInt(),
//       tags: List<String>.from(map['tags'] ?? tags),
//       summary: map['summary'] ?? summary,
//       teaserQuote: map['teaserQuote'] ?? teaserQuote,
//       audioUrl: map['audioUrl'] ?? audioUrl,
//       spiceLevel: map['spiceLevel'] ?? spiceLevel,
//       isRecommended: map['isRecommended'] ?? isRecommended,
//       chapters: (map['chapters'] as List<dynamic>? ??
//               chapters.map((c) => c.toMap()).toList())
//           .map((c) => Chapters.fromMap(c as Map<String, dynamic>))
//           .toList(),
//     );
//   }
//
//   Map<String, dynamic> toMap() {
//     return {
//       'id': id,
//       'poster': poster,
//       'bookCover': bookCover,
//       'title': title,
//       'authoer': authoer,
//       'rate': rate,
//       'tags': tags,
//       'summary': summary,
//       'audioUrl': audioUrl,
//       'teaserQuote': teaserQuote,
//       'isRecommended': isRecommended,
//       'spiceLevel': spiceLevel,
//       'chapters': chapters.map((c) => c.toMap()).toList(),
//     };
//   }
// }
//
// class Chapters {
//   final int chapterId;
//   final String chapterName;
//   final String chapterUrl;
//   final bool isLocked;
//
//   Chapters(
//       {required this.chapterId,
//       required this.chapterName,
//       required this.chapterUrl,
//       required this.isLocked});
//
//   /// ✅ Convert Firestore Map -> Chapter object
//   factory Chapters.fromMap(Map<String, dynamic> map) {
//     return Chapters(
//       chapterId: (map['chapterId'] ?? 0).toInt(),
//       chapterName: map['chapterName'] ?? '',
//       chapterUrl: map['chapterUrl'] ?? '',
//       isLocked: map['isLocked'] ?? true,
//     );
//   }
//
//   Map<String, dynamic> toMap() {
//     return {
//       'chapterId': chapterId,
//       'chapterName': chapterName,
//       'chapterUrl': chapterUrl,
//       'isLocked': isLocked
//     };
//   }
// }

class Book {
  final String id;
  final String poster;
  final String bookCover;
  final String title;
  final String authoer;
  final int rate;
  final List<String> tags;
  final String summary;
  final String teaserQuote;
  final String audioUrl; // OLD audio (keep for compatibility)
  final String spiceLevel;
  final bool isRecommended;

  // NEW
  final bool readingModeEnabled;
  final bool watchModeEnabled;
  final HubButtons hubButtons;

  final List<Chapter> chapters;

  Book({
    required this.id,
    required this.poster,
    required this.bookCover,
    required this.title,
    required this.authoer,
    required this.rate,
    required this.tags,
    required this.summary,
    required this.teaserQuote,
    required this.audioUrl,
    required this.spiceLevel,
    required this.isRecommended,
    required this.chapters,
    required this.readingModeEnabled,
    required this.watchModeEnabled,
    required this.hubButtons,
  });

  factory Book.fromMap(Map<String, dynamic> map, String docId) {
    return Book(
      id: docId,
      poster: map['poster'] ?? '',
      bookCover: map['bookCover'] ?? '',
      title: map['title'] ?? '',
      authoer: map['authoer'] ?? '',
      rate: (map['rate'] ?? 0).toInt(),
      tags: List<String>.from(map['tags'] ?? []),
      summary: map['summary'] ?? '',
      teaserQuote: map['teaserQuote'] ?? '',
      audioUrl: map['audioUrl'] ?? '',

      spiceLevel: map['spiceLevel'] ?? '',
      isRecommended: map['isRecommended'] ?? false,

      // NEW
      readingModeEnabled: map['readingModeEnabled'] ?? false,
      watchModeEnabled: map['watchModeEnabled'] ?? false,
      hubButtons: HubButtons.fromMap(map['hubButtons'] ?? {}),

      chapters: (map['chapters'] as List<dynamic>? ?? [])
          .map((c) => Chapter.fromMap(c))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'poster': poster,
      'bookCover': bookCover,
      'title': title,
      'authoer': authoer,
      'rate': rate,
      'tags': tags,
      'summary': summary,
      'audioUrl': audioUrl,
      'teaserQuote': teaserQuote,
      'isRecommended': isRecommended,
      'spiceLevel': spiceLevel,

      // NEW
      'readingModeEnabled': readingModeEnabled,
      'watchModeEnabled': watchModeEnabled,
      'hubButtons': hubButtons.toMap(),

      'chapters': chapters.map((c) => c?.toMap()).toList(),
    };
  }

  Book copyWithUpdated(Map<String, dynamic> map) {
    return Book(
      id: id,
      poster: map['poster'] ?? poster,
      bookCover: map['bookCover'] ?? bookCover,
      title: map['title'] ?? title,
      authoer: map['authoer'] ?? authoer,
      rate: (map['rate'] ?? rate).toInt(),
      tags: List<String>.from(map['tags'] ?? tags),
      summary: map['summary'] ?? summary,
      teaserQuote: map['teaserQuote'] ?? teaserQuote,
      audioUrl: map['audioUrl'] ?? audioUrl,
      spiceLevel: map['spiceLevel'] ?? spiceLevel,
      isRecommended: map['isRecommended'] ?? isRecommended,
      readingModeEnabled: map['readingModeEnabled'] ?? readingModeEnabled,
      watchModeEnabled: map['watchModeEnabled'] ?? watchModeEnabled,
      hubButtons: map['hubButtons'] != null
          ? HubButtons.fromMap(map['hubButtons'])
          : hubButtons,
      chapters: (map['chapters'] as List<dynamic>? ??
              chapters.map((c) => c.toMap()).toList())
          .map((c) => Chapter.fromMap(c))
          .toList(),
    );
  }
}

// HUB BUTTONS
class HubButtons {
  final bool listen;
  final bool read;
  final bool watch;

  HubButtons({
    required this.listen,
    required this.read,
    required this.watch,
  });

  factory HubButtons.fromMap(Map<String, dynamic> map) {
    return HubButtons(
      listen: map['listen'] ?? true,
      read: map['read'] ?? false,
      watch: map['watch'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'listen': listen,
        'read': read,
        'watch': watch,
      };
}

class Chapter {
  final int chapterId;
  final String chapterName;
  final String chapterUrl; // audio url (may be empty)
  final String? chapterType; // e.g. "text" for reading chapters
  final bool isLocked;
  final bool isFree;
  final int order;
  final bool isDownloadable;
  final String textContent;
  final List<ContentBlock> contentBlocks;

  Chapter({
    required this.chapterId,
    required this.chapterName,
    required this.chapterUrl,
    required this.chapterType,
    required this.isLocked,
    required this.isFree,
    required this.order,
    required this.isDownloadable,
    required this.textContent,
    required this.contentBlocks,
  });

  factory Chapter.fromMap(Map<String, dynamic> map) {
    final blocksRaw = (map['contentBlocks'] as List<dynamic>? ?? []);

    final contentBlocks = blocksRaw
        .map((b) => ContentBlock.fromMap(Map<String, dynamic>.from(b)))
        .toList();

    return Chapter(
      chapterId: map['chapterId'] ?? 0,
      chapterName: map['chapterName'] ?? '',
      chapterUrl: map['chapterUrl'] ?? '',
      chapterType: map['chapterType']?.toString(),
      isLocked: map['isLocked'] ?? false,
      isFree: map['isFree'] ?? false,
      order: map['order'] ?? 0,
      isDownloadable: map['isDownloadable'] ?? false,
      textContent: map['textContent'] ?? '',
      contentBlocks: contentBlocks,
    );
  }

  Map<String, dynamic> toMap() => {
        'chapterId': chapterId,
        'chapterName': chapterName,
        'chapterUrl': chapterUrl,
        'chapterType': chapterType,
        'isLocked': isLocked,
        'isFree': isFree,
        'order': order,
        'isDownloadable': isDownloadable,
        'textContent': textContent,
        'contentBlocks': contentBlocks.map((e) => e.toMap()).toList(),
      };
}

class ContentBlock {
  final String type; // "text" or "image"
  final String? text;
  final String? url;

  ContentBlock({
    required this.type,
    this.text,
    this.url,
  });

  factory ContentBlock.fromMap(Map<String, dynamic> map) {
    final rawType = map['type']?.toString() ?? 'text';

    if (rawType == "paragraph") {
      return ContentBlock(
        type: "text",
        text: map['content']?.toString() ?? "",
      );
    }

    if (rawType == "image") {
      return ContentBlock(
        type: "image",
        url: map['url']?.toString() ?? "",
      );
    }

    // fallback (safe)
    return ContentBlock(
      type: "text",
      text: map['content']?.toString() ?? map['text']?.toString() ?? "",
    );
  }

  Map<String, dynamic> toMap() => {
        "type": type == "text" ? "paragraph" : type,
        if (text != null) "content": text,
        if (url != null) "url": url,
      };
}
