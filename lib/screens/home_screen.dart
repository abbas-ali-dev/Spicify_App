import 'package:Spicify/model/book_model.dart';
import 'package:Spicify/model/book_directory.dart';
import 'package:Spicify/screens/book_details_screen.dart';
import 'package:Spicify/screens/continue_listening.dart';
import 'package:Spicify/screens/see_more_screen.dart';
import 'package:Spicify/screens/settings_screen.dart';
import 'package:Spicify/utilities/app_colors.dart';
import 'package:Spicify/utilities/navigator_helper_class.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../gen_l10n/app_localizations.dart'; // Add this import
import '../utilities/app_typography.dart';
import '../utilities/change_selector.dart';
import '../utilities/enter_route.dart';
import './auth_provider.dart' as auth;
import 'continue_reading.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final BookDirectory bookDirectory = BookDirectory();
  String? _selectedCategory;

  late Future<List<Book>> _recommendedBooksFuture;
  late Future<List<Book>> _nonRecommendedBooksFuture;
  late Future<List<Book>> _allBooksFuture;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  void _loadBooks() {
    _recommendedBooksFuture = bookDirectory.getRecommendedBooks();
    _nonRecommendedBooksFuture = bookDirectory.getBooks();
    _allBooksFuture = bookDirectory.getBooks();
  }

// Helper method to load image based on URL
  Widget _buildImage(String imageUrl,
      {double? width, double? height, BoxFit? fit}) {
    if (imageUrl.startsWith('https')) {
      print('ICCCCC ${imageUrl}');
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: CachedNetworkImage(
          imageUrl: Uri.encodeFull(imageUrl),
          width: width,
          height: height,
          fit: fit ?? BoxFit.cover,
          // placeholder: (context, url) => Container(
          //   color: Colors.grey[200],
          //   child: const Center(child: CircularProgressIndicator()),
          // ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey[200],
            child: const Icon(Icons.error),
          ),
        ),
      );
    } else if (imageUrl.startsWith('asset')) {
      return Image.asset(
        imageUrl,
        width: width,
        height: height,
        fit: fit ?? BoxFit.cover,
      );
    } else {
      // Fallback for invalid URLs
      return Container(
        color: Colors.grey[200],
        child: const Icon(Icons.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!; // Localization instance
    final authP = context.watch<auth.AuthProvider>();
    return NotificationListener<OverscrollIndicatorNotification>(
      onNotification: (overScroll) {
        overScroll.disallowIndicator();
        return true;
      },
      child: ListView(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section
              Padding(
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
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              barrierColor: Colors.black54,
                              builder: (_) => LanguageDialog(),
                            );
                          },
                          child: Image.asset(
                            "asset/image/Group 33.png",
                            height: 24,
                            width: 24,
                            fit: BoxFit.fill,
                          ),
                        ),
                        const SizedBox(width: 12),
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
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(
                    left: 20.0, right: 20.0, top: 20.0, bottom: 5),
                child: RepaintBoundary(
                  child: Text(
                    l10n.categoriesTitle,
                    style: AppTypography.sectionHeaderLabel,
                  ),
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.016,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 15.0),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.056,
                  child: FutureBuilder<List<String>>(
                    future: bookDirectory.getCategories(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError || !snapshot.hasData) {
                        return Center(child: Text(l10n.errorLoadingCategories));
                      }

                      final categories = snapshot.data!;
                      return ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          // Add "All" category option
                          categoryItem(l10n.allCategory,
                              isSelected: _selectedCategory == null),

                          ...List.generate(
                            categories.length,
                            (index) => categoryItem(
                              categories[index],
                              isSelected:
                                  _selectedCategory == categories[index],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              if (authP.currentUser != null)
                ContinueListeningCard(
                    userId: FirebaseAuth.instance.currentUser!.uid),
              if (authP.currentUser != null)
                ContinueReadingCard(
                  userId: FirebaseAuth.instance.currentUser!.uid,
                ),
              // Recommended For You section
              Padding(
                padding: const EdgeInsets.only(
                    left: 20.0, right: 20.0, top: 35.0, bottom: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RepaintBoundary(
                      child: Text(
                        l10n.recommendedForYou,
                        style: AppTypography.sectionHeaderLabel,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _navigateToSeeMoreScreen(
                        l10n.recommendedForYou,
                        _recommendedBooksFuture,
                      ),
                      child: RepaintBoundary(
                        child: Text(
                          l10n.seeMore,
                          textAlign: TextAlign.right,
                          style: AppTypography.medium14Text,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 15.0),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.49,
                  child: FutureBuilder<List<Book>>(
                    future: _recommendedBooksFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError || !snapshot.hasData) {
                        return Center(
                            child: Text(l10n.errorLoadingRecommended));
                      }

                      List<Book> books = snapshot.data!;
                      if (_selectedCategory != null) {
                        books = books
                            .where(
                                (book) => book.tags.contains(_selectedCategory))
                            .toList();
                      }

                      return ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          ...List.generate(
                            books.length,
                            (index) => recommendedItem(books[index]),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),

              // Best Seller section
              Padding(
                padding: const EdgeInsets.only(
                    left: 20.0, right: 20.0, top: 35.0, bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RepaintBoundary(
                      child: Text(
                        l10n.bestSeller,
                        style: AppTypography.sectionHeaderLabel,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _navigateToSeeMoreScreen(
                        l10n.bestSeller,
                        _nonRecommendedBooksFuture,
                      ),
                      child: RepaintBoundary(
                        child: Text(
                          l10n.seeMore,
                          textAlign: TextAlign.right,
                          style: AppTypography.medium14Text,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 15.0),
                child: SizedBox(
                  height: 200,
                  child: FutureBuilder<List<Book>>(
                    future: _nonRecommendedBooksFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError || !snapshot.hasData) {
                        return Center(child: Text(l10n.errorLoadingBooks));
                      }

                      List<Book> books = snapshot.data!;
                      if (_selectedCategory != null) {
                        books = books
                            .where(
                                (book) => book.tags.contains(_selectedCategory))
                            .toList();
                      }

                      return ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          ...List.generate(
                            books.length,
                            (index) => bestSellerItem(books[index]),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),

              // New Releases section
              Padding(
                padding: const EdgeInsets.only(
                    left: 20.0, right: 20.0, top: 35.0, bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RepaintBoundary(
                      child: Text(
                        l10n.newReleases,
                        style: AppTypography.sectionHeaderLabel,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _navigateToSeeMoreScreen(
                        l10n.newReleases,
                        _recommendedBooksFuture,
                      ),
                      child: RepaintBoundary(
                        child: Text(
                          l10n.seeMore,
                          textAlign: TextAlign.right,
                          style: AppTypography.medium14Text,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.55,
                child: FutureBuilder<List<Book>>(
                  future: _recommendedBooksFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError || !snapshot.hasData) {
                      return Center(child: Text(l10n.errorLoadingRecommended));
                    }

                    List<Book> books = snapshot.data!;
                    if (_selectedCategory != null) {
                      books = books
                          .where(
                              (book) => book.tags.contains(_selectedCategory))
                          .toList();
                    }

                    return ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        ...List.generate(
                          books.length,
                          (index) => newRelease(books[index]),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Trending Now section
              Padding(
                padding: const EdgeInsets.only(
                    left: 20.0, right: 20.0, top: 15.0, bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RepaintBoundary(
                      child: Text(
                        l10n.trendingNow,
                        style: AppTypography.sectionHeaderLabel,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _navigateToSeeMoreScreen(
                        l10n.trendingNow,
                        _nonRecommendedBooksFuture,
                      ),
                      child: RepaintBoundary(
                        child: Text(
                          l10n.seeMore,
                          textAlign: TextAlign.right,
                          style: AppTypography.medium14Text,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.57,
                child: FutureBuilder<List<Book>>(
                  future: _nonRecommendedBooksFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError || !snapshot.hasData) {
                      return Center(child: Text(l10n.errorLoadingBooks));
                    }

                    List<Book> books = snapshot.data!;
                    if (_selectedCategory != null) {
                      books = books
                          .where(
                              (book) => book.tags.contains(_selectedCategory))
                          .toList();
                    }

                    return ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        ...List.generate(
                          books.length,
                          (index) => newRelease(books[index]),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget categoryItem(String topic, {bool isSelected = false}) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (topic == l10n.allCategory) {
              _selectedCategory = null;
            } else {
              _selectedCategory = topic;
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            border: isSelected
                ? Border.all(width: 1, color: AppColors.buttonRed)
                : null,
            borderRadius: BorderRadius.circular(12),
            //color: isSelected ? AppColors.buttonRed : Colors.transparent,
          ),
          child: Center(
            child: RepaintBoundary(
              // Fix for text distortion after app resume
              child: Text(
                topic, // The category name (String) coming from your list
                style: isSelected
                    ? AppTypography.regular16Text.copyWith(
                        color: Colors.white, // White when selected
                      )
                    : AppTypography
                        .regular16Text, // Default style when not selected
                maxLines: 1, // Ensures text does not wrap into two lines
                overflow:
                    TextOverflow.ellipsis, // Adds "..." if text is too long
                textAlign: TextAlign.center, // Centers the text inside the chip
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToSeeMoreScreen(String title, Future<List<Book>> booksFuture) {
    NavigationHelper.pushWithTransition(
      context: context,
      targetPage: SeeMoreScreen(
        title: title,
        booksFuture: booksFuture,
        selectedCategory: _selectedCategory,
      ),
    );
  }

  // The following widget methods remain unchanged:
  Widget recommendedItem(Book item) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 6, 0),
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
          EnterRoute(
            enterPage: BookDetailsScreen(
              bookDetail: item,
            ),
          ),
        ),
        child: Container(
          width: 200,
          height: 300,
          decoration: BoxDecoration(
            border: Border.all(width: 1, color: AppColors.buttonRed),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _buildImage(
              item.bookCover,
              width: 200,
              height: 300,
              fit: BoxFit.cover, // ✅ ensures no black spaces
            ),
          ),
        ),
      ),
    );
  }

  Widget bestSellerItem(Book item) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(5, 0, 6, 0),
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
          EnterRoute(
              enterPage: BookDetailsScreen(
            bookDetail: item,
          )),
        ),
        child: Container(
          width: 350,
          height: 200,
          padding: const EdgeInsets.all(5),
          decoration: ShapeDecoration(
            color: AppColors.cardGrey,
            shape: RoundedRectangleBorder(
              side: const BorderSide(width: 1, color: AppColors.buttonRed),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 200,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildImage(item.bookCover, width: 120, height: 200)
                    // Container(
                    //   width: 120,
                    //   height: 120,
                    //   decoration: ShapeDecoration(
                    //     image: DecorationImage(
                    //       image: AssetImage(item.bookCover),
                    //       fit: BoxFit.fill,
                    //     ),
                    //     shape: RoundedRectangleBorder(
                    //         borderRadius: BorderRadius.circular(8)),
                    //   ),
                    // ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 190,
                        child: RepaintBoundary(
                          child: Text(
                            item.title,
                            style: AppTypography.sectionHeaderLabel,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: 155,
                        child: RepaintBoundary(
                          child: Text(
                            item.authoer,
                            style: AppTypography.medium14Text,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: 200,
                    height: 60,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: item.tags.length,
                      itemBuilder: (context, index) {
                        return _buildCategoryChip(item.tags[index]);
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    //width: 120,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ...List.generate(
                            1,
                            (index) => Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: starRating(item.spiceLevel),
                                )),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String text) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.buttonRed.withOpacity(0.2),
          border: Border.all(
            color: AppColors.buttonRed,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: RepaintBoundary(
          child: Text(
            text,
            style: AppTypography.labelText.copyWith(
              fontSize: 14,
              color: AppColors.buttonRed,
            ),
          ),
        ),
      ),
    );
  }

  Widget newRelease(Book item) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 5, 0),
      child: GestureDetector(
        onTap: () => NavigationHelper.pushWithTransition(
          context: context,
          targetPage: BookDetailsScreen(bookDetail: item),
        ),
        child: Container(
          width: 210, // fixed width for consistent layout
          decoration: BoxDecoration(
            border: Border.all(width: 1, color: AppColors.buttonRed),
            borderRadius: BorderRadius.circular(12),
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // align text left
            children: [
              // Book Cover
              ClipRRect(
                // borderRadius: const BorderRadius.only(
                //   topLeft: Radius.circular(12),
                //   topRight: Radius.circular(12),
                // ),
                child: _buildImage(
                  item.bookCover,
                  width: double.infinity,
                  height: 250,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 10),

              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: RepaintBoundary(
                  child: Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.sectionHeaderLabel,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Teaser Quote
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: RepaintBoundary(
                  child: Text(
                    item.teaserQuote,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.medium14Text,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Tags

              //_buildCategoryChip(item.tags.last),
              SizedBox(
                height: 60,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  scrollDirection: Axis.horizontal,
                  itemCount: item.tags.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (context, index) {
                    return _buildCategoryChip(item.tags[index]);
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget starRating(String level) {
    switch (level) {
      case 'Mild':
        return RepaintBoundary(
          child: Text(
            '🌶',
            style: AppTypography.labelText,
          ),
        );
      case 'Spicy':
        return RepaintBoundary(
          child: Text(
            '🌶🌶',
            style: AppTypography.labelText,
          ),
        );

      case 'Extreme':
        return RepaintBoundary(
          child: Text(
            '🔥🔥🔥',
            style: AppTypography.labelText,
          ),
        );
      default:
        return RepaintBoundary(
          child: Text(
            '🔥🔥🔥',
            style: AppTypography.labelText,
          ),
        );
    }

    // return Icon(
    //   Icons.star,
    //   color: isFilled ? AppColors.buttonRed : Colors.grey,
    //   size: 16,
    // );
  }
}
