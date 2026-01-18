import 'package:Spicify/utilities/navigator_helper_class.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../gen_l10n/app_localizations.dart';
import '../model/series_model.dart';
import '../utilities/app_colors.dart';
import '../utilities/app_typography.dart';
import 'trailer_player.dart';
import 'episode_tile.dart';
import 'video_player_screen.dart';

class SeriesScreen extends StatefulWidget {
  final String seriesId;

  const SeriesScreen({super.key, required this.seriesId});

  @override
  State<SeriesScreen> createState() => _SeriesScreenState();
}

class _SeriesScreenState extends State<SeriesScreen> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // WidgetsFlutterBinding.ensureInitialized()
    //     .addPostFrameCallback((value) async {
    //   await testFirestore();
    // });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Episodes"),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('series')
            .doc(widget.seriesId) // ✅ use widget.seriesId
            .snapshots(),
        builder: (context, snapshot) {
          // 1️⃣ Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2️⃣ Error
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Something went wrong',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          // 3️⃣ No document
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text(
                'Series not found',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          // 4️⃣ Data can still be null (Firestore behavior)
          final data = snapshot.data!.data();
          if (data == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // 5️⃣ Map Firestore → Model safely
          final series = SeriesModel.fromFirestore(
            snapshot.data!.id,
            data,
          );

          // 6️⃣ UI
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TrailerPlayer(url: series.trailerUrl),
              const SizedBox(height: 16),
              Text(
                'Spicify',
                style: AppTypography.homeTitle
                    .copyWith(color: AppColors.buttonRed),
              ),
              const SizedBox(height: 16),
              Text(
                series.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              buildWatchButton(context),
              const SizedBox(height: 8),
              buildContinueButton(context),
              const SizedBox(height: 8),
              Text(
                series.description,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              const Text(
                "Episodes",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...series.episodes.map(
                (episode) => EpisodeTile(
                  episode: episode,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VideoPlayerScreen(
                          url: episode.videoUrl,
                          title: episode.title,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget buildWatchButton(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.9,
      height: 53,
      child: ElevatedButton(
        onPressed: () async {
          // // final prefs = await SharedPreferences.getInstance();
          // // final readerProv =
          // // ReaderProvider(book: widget.bookDetail, prefs: prefs);
          //
          // if (widget.bookDetail.chapters.isNotEmpty) {
          //   Navigator.push(
          //     context,
          //     MaterialPageRoute(
          //       builder: (_) => ChangeNotifierProvider.value(
          //         value: readerProv,
          //         child: ReaderScreen(),
          //       ),
          //     ),
          //   );
          // } else {
          //   ScaffoldMessenger.of(context).showSnackBar(
          //     const SnackBar(content: Text('Coming soon')),
          //   );
          // }
        },
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(AppColors.buttonRed),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.play_arrow,
              color: Colors.white,
              size: 34,
            ),
            const SizedBox(width: 8),
            Text(
              l10n.play,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildContinueButton(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.9,
      height: 53,
      child: ElevatedButton(
        onPressed: () async {
          // // final prefs = await SharedPreferences.getInstance();
          // // final readerProv =
          // // ReaderProvider(book: widget.bookDetail, prefs: prefs);
          //
          // if (widget.bookDetail.chapters.isNotEmpty) {
          //   Navigator.push(
          //     context,
          //     MaterialPageRoute(
          //       builder: (_) => ChangeNotifierProvider.value(
          //         value: readerProv,
          //         child: ReaderScreen(),
          //       ),
          //     ),
          //   );
          // } else {
          //   ScaffoldMessenger.of(context).showSnackBar(
          //     const SnackBar(content: Text('Coming soon')),
          //   );
          // }
        },
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(AppColors.white),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon(
            //   Icons.play_arrow,
            //   color: Colors.white,
            //   size: 34,
            // ),
            // const SizedBox(width: 8),
            Text(
              l10n.continueWatching,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
