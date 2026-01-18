import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:Spicify/model/book_model.dart';
import 'package:Spicify/utilities/app_colors.dart';
import 'package:Spicify/utilities/app_typography.dart';
import 'package:Spicify/utilities/navigator_helper_class.dart';
import 'package:Spicify/screens/book_details_screen.dart';

class SeeMoreScreen extends StatelessWidget {
  final String title;
  final Future<List<Book>> booksFuture;
  final String? selectedCategory;

  const SeeMoreScreen({
    super.key,
    required this.title,
    required this.booksFuture,
    this.selectedCategory,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Scaffold(
        backgroundColor: AppColors.black,
        appBar: AppBar(
          title: RepaintBoundary(
            child: Text(
              title,
              style: AppTypography.homeTitle,
            ),
          ),
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          ),
          elevation: 0,
          backgroundColor: AppColors.black,
        ),
        body: FutureBuilder<List<Book>>(
          future: booksFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError || !snapshot.hasData) {
              return Center(child: Text('Error loading $title books'));
            }

            List<Book> books = snapshot.data!;

            // Filter by category if one is selected
            if (selectedCategory != null) {
              books = books
                  .where((book) => book.tags.contains(selectedCategory))
                  .toList();
            }

            return ListView.builder(
              itemCount: books.length,
              itemBuilder: (context, index) {
                final item = books[index];

                return GestureDetector(
                  onTap: () {
                    NavigationHelper.pushWithTransition(
                      context: context,
                      targetPage: BookDetailsScreen(bookDetail: item),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.red),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Book Cover
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: item.bookCover,
                            width: 100, // bigger image
                            height: 140, // keep proportion
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Book Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RepaintBoundary(
                                child: Text(
                                  item.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              RepaintBoundary(
                                child: Text(
                                  item.authoer,
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ),
                              const SizedBox(height: 6),
                              RepaintBoundary(
                                child: Text(
                                  item.tags.join("  "),
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ),
                              const SizedBox(height: 6),
                              RepaintBoundary(
                                child: Text(
                                  item.teaserQuote,
                                  style: const TextStyle(color: Colors.white70),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
