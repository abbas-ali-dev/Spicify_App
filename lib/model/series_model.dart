class SeriesModel {
  final String id;
  final String title;
  final String description;
  final String trailerUrl;
  final String thumbnailUrl;
  final String bookId;
  final String createdAt;
  final String updatedAt;
  final List<EpisodeModel> episodes;

  SeriesModel({
    required this.id,
    required this.title,
    required this.description,
    required this.trailerUrl,
    required this.thumbnailUrl,
    required this.bookId,
    required this.createdAt,
    required this.updatedAt,
    required this.episodes,
  });

  factory SeriesModel.fromFirestore(
    String docId,
    Map<String, dynamic> data,
  ) {
    return SeriesModel(
      id: docId,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      trailerUrl: data['trailerUrl'] ?? '',
      thumbnailUrl: data['thumbnailUrl'] ?? '',
      bookId: data['bookId'] ?? '',
      createdAt: data['createdAt'] ?? '',
      updatedAt: data['updatedAt'] ?? '',
      episodes: data['episodes'] != null
          ? EpisodeModel.fromList(data['episodes'])
          : [],
    );
  }
}

class EpisodeModel {
  final int id;
  final String title;
  final String description;
  final String videoUrl;
  final String thumbnailUrl;
  final String duration;
  final int order;
  final String createdAt;

  EpisodeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.duration,
    required this.order,
    required this.createdAt,
  });

  factory EpisodeModel.fromMap(Map<String, dynamic> map) {
    return EpisodeModel(
      id: map['id'] ?? 0,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      videoUrl: map['videoUrl'] ?? '',
      thumbnailUrl: map['thumbnailUrl'] ?? '',
      duration: map['duration'] ?? '',
      order: map['order'] ?? 0,
      createdAt: map['createdAt'] ?? '',
    );
  }

  static List<EpisodeModel> fromList(List<dynamic> list) {
    final episodes = list
        .map((e) => EpisodeModel.fromMap(e as Map<String, dynamic>))
        .toList();

    episodes.sort((a, b) => a.order.compareTo(b.order));
    return episodes;
  }
}
