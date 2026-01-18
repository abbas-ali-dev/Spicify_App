import 'package:Spicify/screens/audio_player_screen.dart';
import 'package:Spicify/screens/reader_screen.dart';
import 'package:Spicify/utilities/app_colors.dart';
import 'package:Spicify/utilities/navigator_helper_class.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/book_model.dart';
import '../provider_book/reader_provider.dart';
import '../utilities/app_typography.dart';
import '../utilities/enter_route.dart';

class BookDetailsScreen extends StatefulWidget {
  final Book bookDetail;

  const BookDetailsScreen({super.key, required this.bookDetail});

  @override
  State<BookDetailsScreen> createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends State<BookDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return RepaintBoundary(
      child: Scaffold(
        backgroundColor: AppColors.black,
        appBar: AppBar(
          elevation: 0,
          centerTitle: true,
          backgroundColor: AppColors.black,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: RepaintBoundary(
            child: Text(
              l10n.detail,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        body: NotificationListener<OverscrollIndicatorNotification>(
          onNotification: (overScroll) {
            overScroll.disallowIndicator();
            return true;
          },
          child: Padding(
            padding: const EdgeInsets.only(
                left: 20.0, right: 20.0, top: 20.0, bottom: 0),
            child: ListView(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: Uri.encodeFull(widget.bookDetail.bookCover),
                        width: MediaQuery.of(context).size.width * 0.85,
                        height: 340,
                        fit: BoxFit.cover,
                        // placeholder: (context, url) => Container(
                        //   color: Colors.grey[200],
                        //   child: const Center(child: CircularProgressIndicator()),
                        // ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.error),
                        ),
                      ),
                    ),
                    // Container(
                    //   width: 300,
                    //   height: 300,
                    //   decoration: BoxDecoration(
                    //     image: DecorationImage(
                    //       image: AssetImage(widget.bookDetail.bookCover),
                    //       fit: BoxFit.fill,
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
                Container(
                  width: MediaQuery.of(context).size.width * 1,
                  padding: const EdgeInsets.only(
                      left: 10.0, right: 10.0, top: 20.0, bottom: 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.01,
                      ),
                      RepaintBoundary(
                        child: Text(
                          widget.bookDetail.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.005,
                      ),
                      RepaintBoundary(
                        child: Text(
                          widget.bookDetail.authoer,
                          style: const TextStyle(
                            color: Color(0xFFEBEBF5),
                            fontSize: 17,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.02,
                      ),

                      RepaintBoundary(
                        child: Text(
                          widget.bookDetail.teaserQuote,
                          style: const TextStyle(
                            color: Color(0xFFEBEBF5),
                            fontSize: 17,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),

                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.02,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          ...List.generate(
                              1,
                              (index) => Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: starRating(
                                        widget.bookDetail.spiceLevel),
                                  )),
                          const SizedBox(width: 10),
                          SizedBox(
                            height: 28,
                            child: RepaintBoundary(
                              child: Text(
                                "${widget.bookDetail.spiceLevel.toString()}",
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.white,
                                  fontSize: 20,
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.015,
                      ),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ...List.generate(
                                widget.bookDetail.tags.toList().length,
                                (index) => tags(widget.bookDetail.tags[index]))
                          ],
                        ),
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.035,
                      ),

                      buildHubButtons(context),
                      // SizedBox(
                      //   width: MediaQuery.of(context).size.width * 0.9,
                      //   height: 53,
                      //   child: ElevatedButton(
                      //     onPressed: () async {
                      //       if (widget.bookDetail.chapters.isNotEmpty) {
                      //         // NavigationHelper.pushWithTransition(
                      //         //     context: context,
                      //         //     targetPage: AudioPlayerScreen(
                      //         //         bookDetail: widget.bookDetail));
                      //
                      //         final prefs = await SharedPreferences.getInstance();
                      //
                      //         Navigator.push(
                      //             context,
                      //             MaterialPageRoute(
                      //               builder: (_) => ChangeNotifierProvider(
                      //                 create: (_) => ReaderProvider(
                      //                     book: widget.bookDetail, prefs: prefs),
                      //                 child: ReaderScreen(),
                      //               ),
                      //             ));
                      //       } else {
                      //         ScaffoldMessenger.of(context).showSnackBar(
                      //           SnackBar(content: Text('No Chapters Found')),
                      //         );
                      //       }
                      //     },
                      //     child: Text(
                      //       l10n.playAudio,
                      //       textAlign: TextAlign.center,
                      //       style: const TextStyle(
                      //         color: Colors.white,
                      //         fontSize: 14,
                      //         fontFamily: 'Poppins',
                      //         fontWeight: FontWeight.w500,
                      //       ),
                      //     ),
                      //     style: ButtonStyle(
                      //         backgroundColor:
                      //             WidgetStateProperty.all(AppColors.buttonRed)),
                      //   ),
                      // ),

                      // GestureDetector(
                      //   onTap: () => NavigationHelper.pushWithTransition(
                      //       context: context,
                      //       targetPage:
                      //           AudioPlayerScreen(bookDetail: widget.bookDetail)),
                      //   child: Container(
                      //     width: MediaQuery.of(context).size.width * 0.9,
                      //     height: 53,
                      //     padding: const EdgeInsets.all(16),
                      //     decoration: ShapeDecoration(
                      //       color: Color.fromRGBO(216, 39, 42, 1),
                      //       shape: RoundedRectangleBorder(
                      //           borderRadius: BorderRadius.circular(26)),
                      //     ),
                      //     child: Row(
                      //       mainAxisSize: MainAxisSize.min,
                      //       mainAxisAlignment: MainAxisAlignment.center,
                      //       crossAxisAlignment: CrossAxisAlignment.start,
                      //       children: [
                      //         Container(
                      //           width: 20,
                      //           height: 20,
                      //           decoration: const BoxDecoration(
                      //             image: DecorationImage(
                      //               image: AssetImage("asset/image/Play.png"),
                      //               fit: BoxFit.fill,
                      //             ),
                      //           ),
                      //         ),
                      //         const SizedBox(width: 5),
                      //         Text(
                      //           l10n.playAudio,
                      //           textAlign: TextAlign.center,
                      //           style: const TextStyle(
                      //             color: Colors.white,
                      //             fontSize: 14,
                      //             fontFamily: 'Poppins',
                      //             fontWeight: FontWeight.w500,
                      //           ),
                      //         ),
                      //       ],
                      //     ),
                      //   ),
                      // ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.05,
                      ),
                      RepaintBoundary(
                        child: Text(
                          l10n.bookDetails,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 14,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.02,
                      ),

                      RepaintBoundary(
                        child: Text(
                          widget.bookDetail.summary,
                          textAlign: TextAlign.start,
                          style: const TextStyle(
                            color: AppColors.white,
                            letterSpacing: 0,
                            wordSpacing: 0,
                            fontSize: 14,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.02,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildHubButtons(BuildContext context) {
    final hub = widget.bookDetail.hubButtons; // your HubButtons instance

    List<Widget> buttons = [];

    buttons.add(buildReadButton(context));
    buttons.add(buildListenButton(context));
    buttons.add(buildWatchButton(context));
    // if (hub.listen) buttons.add(buildListenButton(context));
    // if (hub.read) buttons.add(buildReadButton(context));
    // // if (hub.watch) buttons.add(buildWatchButton(context));

    return Column(
      children: [
        for (var btn in buttons) ...[
          btn,
          const SizedBox(height: 12), // spacing between buttons
        ]
      ],
    );
  }

  Widget buildListenButton(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.9,
      height: 53,
      child: ElevatedButton(
        onPressed: () async {
          if (widget.bookDetail.chapters
              .where((c) => c.chapterUrl.trim().isNotEmpty)
              .toList()
              .isNotEmpty) {
            NavigationHelper.pushWithTransition(
                context: context,
                targetPage: AudioPlayerScreen(bookDetail: widget.bookDetail));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No Chapters Found')),
            );
          }
        },
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(AppColors.buttonRed),
        ),
        child: RepaintBoundary(
          child: const Text(
            "Listen",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget buildReadButton(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.9,
      height: 53,
      child: ElevatedButton(
        onPressed: () async {
          final prefs = await SharedPreferences.getInstance();
          final readerProv =
              ReaderProvider(book: widget.bookDetail, prefs: prefs);

          if (widget.bookDetail.chapters.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChangeNotifierProvider.value(
                  value: readerProv,
                  child: ReaderScreen(),
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Coming soon')),
            );
          }
        },
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(AppColors.buttonRed),
        ),
        child: RepaintBoundary(
          child: const Text(
            "Read",
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget buildWatchButton(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.9,
      height: 53,
      child: ElevatedButton(
        onPressed: () async {
          final prefs = await SharedPreferences.getInstance();
          final readerProv =
              ReaderProvider(book: widget.bookDetail, prefs: prefs);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Coming Soon')),
          );

          // if (widget.bookDetail.chapters.isNotEmpty) {
          //   // Navigator.push(
          //   //   context,
          //   //   MaterialPageRoute(
          //   //     builder: (_) => ChangeNotifierProvider.value(
          //   //       value: readerProv,
          //   //       child: ReaderScreen(),
          //   //     ),
          //   //   ),
          //   // );
          // } else {
          //   ScaffoldMessenger.of(context).showSnackBar(
          //     const SnackBar(content: Text('No Chapters Found')),
          //   );
          // }
        },
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(AppColors.buttonRed),
        ),
        child: RepaintBoundary(
          child: const Text(
            "Watch",
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget tags(String tag) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Container(
        height: 29,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: ShapeDecoration(
          color: null,
          shape: RoundedRectangleBorder(
            side: const BorderSide(width: 1, color: AppColors.buttonRed),
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RepaintBoundary(
              child: Text(
                tag,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
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
