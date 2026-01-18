import 'package:Spicify/model/book_directory.dart';
import 'package:Spicify/screens/book_details_screen.dart';
import 'package:Spicify/screens/settings_screen.dart';
import 'package:Spicify/utilities/navigator_helper_class.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../gen_l10n/app_localizations.dart';

import '../model/book_model.dart';
import '../utilities/app_colors.dart';
import '../utilities/app_typography.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<String> categories = [];
  List<Book> books = [];
  bool isLoading = true;
  String searchQuery = '';
  String? selectedCategory;

  @override
  void initState() {
    super.initState();
    fetchExploreData();
  }

  Future<void> fetchExploreData() async {
    try {
      final booksList = await BookDirectory().getBooks();
      final fetchedCategories = await fetchCategoriesFromFirestore();

      setState(() {
        books = booksList;
        categories = fetchedCategories;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching explore data: $e");
    }
  }

  Future<List<String>> fetchCategoriesFromFirestore() async {
    try {
      final docSnap = await FirebaseFirestore.instance
          .collection('categories')
          .doc('topics')
          .get();

      if (docSnap.exists) {
        final data = docSnap.data();
        if (data != null && data['list'] is List<dynamic>) {
          return List<String>.from(data['list']);
        }
      }
      return [];
    } catch (e) {
      print('Error fetching categories: $e');
      return [];
    }
  }

  List<Book> get filteredBooks {
    List<Book> result = books;

    if (searchQuery.isNotEmpty) {
      result = result.where((book) {
        return book.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
            book.authoer.toLowerCase().contains(searchQuery.toLowerCase());
      }).toList();
    }

    if (selectedCategory != null) {
      result = result.where((book) {
        return book.tags.contains(selectedCategory);
      }).toList();
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return RepaintBoundary(
      child: Scaffold(
        backgroundColor: AppColors.black,
        appBar: AppBar(
          backgroundColor: AppColors.black,
          elevation: 0,
          titleSpacing: 0,
          title: Padding(
            padding: const EdgeInsets.only(
                left: 20.0, right: 20.0, top: 20.0, bottom: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Image.asset(
                      "asset/image/logo_new.png",
                      height: 40,
                      width: 40,
                      fit: BoxFit.fill,
                    ),
                    const SizedBox(width: 10),
                    RepaintBoundary(
                      child: Text(
                        'Spicify',
                        style: AppTypography.homeTitle
                            .copyWith(color: AppColors.buttonRed),
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    NavigationHelper.pushWithTransition(
                      context: context,
                      targetPage: SettingsScreen(),
                    );
                  },
                  child: Image.asset(
                    "asset/image/Setting.png",
                    height: 24,
                    width: 24,
                    fit: BoxFit.fill,
                  ),
                ),
              ],
            ),
          ),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ListView(
                  children: [
                    const SizedBox(height: 12),
                    RepaintBoundary(
                        child: Text(l10n.exploreTitle,
                            style: AppTypography.heading16Bold)),
                    const SizedBox(height: 12),
                    _buildSearchBox(l10n),
                    const SizedBox(height: 20),
                    if (searchQuery.isEmpty) ...[
                      RepaintBoundary(
                          child: Text(l10n.categoriesTitle,
                              style: AppTypography.labelText)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: categories.map(_buildCategoryChip).toList(),
                      ),
                      const SizedBox(height: 20),
                      RepaintBoundary(
                          child: Text(l10n.booksTitle,
                              style: AppTypography.labelText)),
                    ] else ...[
                      RepaintBoundary(
                          child: Text(l10n.searchResults,
                              style: AppTypography.labelText)),
                    ],
                    const SizedBox(height: 12),
                    if (filteredBooks.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: RepaintBoundary(
                            child: Text(
                              "No Book Found",
                              style: AppTypography.labelText
                                  .copyWith(color: Colors.grey),
                            ),
                          ),
                        ),
                      )
                    else
                      GridView.builder(
                        itemCount: filteredBooks.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisExtent: 260,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemBuilder: (_, index) {
                          return _buildSearchResultCard(filteredBooks[index]);
                        },
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSearchBox(AppLocalizations l10n) {
    return TextField(
      controller: _searchController,
      style: AppTypography.labelText,
      onChanged: (val) {
        setState(() {
          searchQuery = val.trim();
        });
      },
      decoration: InputDecoration(
        hintText: l10n.searchHint,
        hintStyle: AppTypography.hintText,
        filled: true,
        fillColor: AppColors.textFieldGrey,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      ),
    );
  }

  Widget _buildCategoryChip(String text) {
    final bool isSelected = text == selectedCategory;

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            selectedCategory = null;
          } else {
            selectedCategory = text;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.buttonRed.withOpacity(0.2)
              : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppColors.buttonRed : AppColors.buttonRed,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: RepaintBoundary(
          child: Text(
            text,
            style: AppTypography.labelText.copyWith(
              fontSize: 14,
              color: isSelected ? AppColors.buttonRed : AppColors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResultCard(Book book) {
    return GestureDetector(
      onTap: () {
        NavigationHelper.pushWithTransition(
          context: context,
          targetPage: BookDetailsScreen(bookDetail: book),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.buttonRed),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ Fixed height for image
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(8)),
              child: CachedNetworkImage(
                height: 150, // <-- set height to prevent overflow
                width: double.infinity,
                imageUrl: Uri.encodeFull(book.bookCover),
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => Container(
                  height: 150,
                  color: Colors.grey[200],
                  child: const Icon(Icons.error),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ Prevent title overflow
                  RepaintBoundary(
                    child: Text(
                      book.title,
                      style: AppTypography.labelText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 4),
                  RepaintBoundary(
                    child: Text(
                      book.authoer,
                      style: AppTypography.hintText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 4),
                  RepaintBoundary(
                    child: Text(
                      book.teaserQuote,
                      style: AppTypography.hintText,
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
  }
}
