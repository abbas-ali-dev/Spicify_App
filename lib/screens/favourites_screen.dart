import 'package:Spicify/screens/book_details_screen.dart';
import 'package:Spicify/screens/settings_screen.dart';
import 'package:Spicify/utilities/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../model/book_directory.dart';
import '../model/book_model.dart';
import '../utilities/app_typography.dart';
import '../utilities/navigator_helper_class.dart';
import 'auth/login_screen.dart';
import 'auth_provider.dart';
import '../gen_l10n/app_localizations.dart';

class FavouritesScreen extends StatelessWidget {
  FavouritesScreen({super.key});

  final BookDirectory bookDirectory = BookDirectory();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final user = authProvider.currentUser;

        return RepaintBoundary(
          child: Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              elevation: 0,
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
                          child: Text('Spicify',
                              style: AppTypography.homeTitle
                                  .copyWith(color: AppColors.buttonRed)),
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
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: user == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          RepaintBoundary(
                            child: Text(
                              l10n.loginPrompt,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 18),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            style: ButtonStyle(
                                backgroundColor: MaterialStateProperty.all(
                                    AppColors.buttonRed)),
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => LoginScreen()),
                              );
                              if (authProvider.currentUser != null) {
                                // Automatically rebuilds
                              }
                            },
                            child: RepaintBoundary(
                              child: Text(
                                l10n.loginTitle,
                                style: AppTypography.buttonText,
                              ),
                            ),
                          )
                        ],
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RepaintBoundary(
                          child: Text(
                            l10n.favoritesTab,
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: TextField(
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: l10n.searchHint,
                              hintStyle: const TextStyle(color: Colors.white54),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: StreamBuilder<List<Book>>(
                            stream: authProvider.getFavouriteBooksStream(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }

                              if (snapshot.hasError) {
                                return Center(
                                    child: RepaintBoundary(
                                  child: Text("${snapshot.error}",
                                      style:
                                          const TextStyle(color: Colors.white)),
                                ));
                              }

                              final books = snapshot.data ?? [];

                              if (books.isEmpty) {
                                return Center(
                                    child: RepaintBoundary(
                                  child: Text(l10n.noFavourites,
                                      style:
                                          const TextStyle(color: Colors.white)),
                                ));
                              }

                              return ListView.builder(
                                itemCount: books.length,
                                itemBuilder: (context, index) {
                                  final item = books[index];
                                  return GestureDetector(
                                    onTap: () {
                                      NavigationHelper.pushWithTransition(
                                          context: context,
                                          targetPage: BookDetailsScreen(
                                              bookDetail: item));
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.red),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Book Cover
                                          const SizedBox(width: 12),
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
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
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                RepaintBoundary(
                                                  child: Text(
                                                    item.title,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                RepaintBoundary(
                                                  child: Text(
                                                    item.teaserQuote,
                                                    style: const TextStyle(
                                                        color: Colors.white70),
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                RepaintBoundary(
                                                  child: Text(
                                                    item.tags.join("  "),
                                                    style: const TextStyle(
                                                        color: Colors.white70),
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                // Text(
                                                //   item.teaserQuote,
                                                //   style: const TextStyle(
                                                //       color: Colors.white70),
                                                //   maxLines: 2,
                                                //   overflow: TextOverflow.ellipsis,
                                                // ),
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
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
}
