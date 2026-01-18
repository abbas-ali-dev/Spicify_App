// AudioPlayerScreen.dart
import 'dart:async';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import '../gen_l10n/app_localizations.dart';
import 'package:Spicify/modelSheet/chapters_bottom_sheet.dart';
import 'package:Spicify/screens/auth/login_screen.dart';
import 'package:Spicify/utilities/app_colors.dart';
import 'package:Spicify/utilities/navigator_helper_class.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../main.dart';
import '../model/book_model.dart';
import 'audio_manager/AudioHandler.dart';
import 'auth_provider.dart';
import 'package:rxdart/rxdart.dart';

class AudioPlayerScreen extends StatefulWidget {
  final Book bookDetail;
  const AudioPlayerScreen({super.key, required this.bookDetail});

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  bool isPlaying = false;
  Duration duration = Duration.zero;
  Duration position = Duration.zero;
  int currentChapter = 0;
  int maxChapters = 0;
  int minChapters = 0;
  int currentSpeed = 1;
  Timer? _saveProgressTimer;
  Map<int, Duration> _chapterProgress = {};
  bool _isLoading = false;
  bool _isDisposed = false;
  bool isFavourite = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  final ValueNotifier<Duration> _positionNotifier =
      ValueNotifier(Duration.zero);
  bool _isDragging = false;
  StreamSubscription<DocumentSnapshot>? _bookListener;
  late Book updatedBook;

  @override
  void initState() {
    super.initState();

    // ensure updatedBook has a sensible default (prevents late issues)
    updatedBook = widget.bookDetail;

    maxChapters = widget.bookDetail.chapters.length - 1;
    _initializePlayer();
    checkIfFavourite();

    print("book id ${widget.bookDetail.id}");

    audioHandler.playbackState.listen((state) {
      if (!_isDisposed && state.playing == false) {
        _saveProgressToFirestore(); // Save on pause
      }
    });

    _bookListener = _firestore
        .collection('audiobooks')
        .doc(widget.bookDetail.id)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && !_isDisposed) {
        final data = snapshot.data() as Map<String, dynamic>;
        setState(() {
          updatedBook = widget.bookDetail.copyWithUpdated(data);

          print('Updated Book ${updatedBook.title}');
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      auth.loadUserStatus();
    });
  }

  /// Returns list of original chapter indices that are audio (chapterUrl not empty).
  List<int> _audioIndices() {
    final List<int> indices = [];
    for (int i = 0; i < widget.bookDetail.chapters.length; i++) {
      final ch = widget.bookDetail.chapters[i];
      if (ch.chapterUrl.trim().isNotEmpty) {
        indices.add(i);
      }
    }
    return indices;
  }

  /// Ensure currentChapter points to a valid audio chapter (original index).
  /// If the saved currentChapter is not audio, pick the first audio chapter >= saved,
  /// otherwise fallback to first audio chapter or 0.
  void _ensureValidAudioChapterIndex() {
    final audioIdx = _audioIndices();
    if (audioIdx.isEmpty) {
      // No audio chapters at all — keep currentChapter 0
      return;
    }

    // If currentChapter is already an audio index, keep it.
    if (audioIdx.contains(currentChapter)) return;

    // Try to find first audio index >= currentChapter
    for (final idx in audioIdx) {
      if (idx >= currentChapter) {
        currentChapter = idx;
        return;
      }
    }

    // fallback: pick first available audio chapter
    currentChapter = audioIdx.first;
  }

  Future<void> _initializePlayer() async {
    await _loadProgressFromFirestore();

    //_startSavingProgressTimer();

    // Set up listeners
    audioHandler.playbackState.listen((state) {
      if (!_isDisposed) {
        setState(() {
          isPlaying = state.playing;
          _isLoading = state.processingState == AudioProcessingState.loading ||
              state.processingState == AudioProcessingState.buffering;
        });
      }
    });

    _positionSubscription?.cancel();
    _positionSubscription = audioHandler.positionStream.listen((pos) {
      if (!_isDisposed && mounted && !_isDragging) {
        _positionNotifier.value = pos;
        if (position != pos) {
          setState(() => position = pos);
        }
      }
    });

    _durationSubscription?.cancel();
    _durationSubscription = audioHandler.durationStream.listen((dur) {
      if (!_isDisposed && mounted && dur != null) {
        setState(() => duration = dur);
      }
    });

    _ensureValidAudioChapterIndex();

    // 🔥 IMPORTANT: Get saved position BEFORE playChapter
    final savedPosition = _chapterProgress[currentChapter] ?? Duration.zero;

    // 1️⃣ Load chapter but DO NOT play automatically
    await _playChapter(currentChapter, initialLoad: true);

    // 2️⃣ Seek BEFORE starting playback (CORRECT ORDER)
    if (savedPosition > Duration.zero) {
      await audioHandler.seek(savedPosition);
      setState(() => position = savedPosition);
    }

    // 3️⃣ NOW safely start playing
    await audioHandler.play();
  }

  void _startSavingProgressTimer() {
    _saveProgressTimer?.cancel();
    _saveProgressTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (audioHandler.playbackState.value.playing) {
        _saveProgressToFirestore();
      }
    });
  }

  Future<void> _saveProgressToFirestore() async {
    final userId =
        Provider.of<AuthProvider>(context, listen: false).currentUser?.uid;
    if (userId == null) return;

    // Always get the live position from just_audio
    final currentState = audioHandler.playbackState.value;

    final realPosition = currentState.position; // <-- KEY FIX

    // ❌ Skip saving 0ms or too small position
    if (realPosition.inMilliseconds < 1500) {
      print("❌ Skip save: position too small — would reset progress");
      return;
    }

    // Cache locally
    _chapterProgress[currentChapter] = realPosition;

    await _firestore
        .collection('userProgress')
        .doc(userId)
        .collection('audioProgress')
        .doc(widget.bookDetail.title)
        .set({
      'bookId': widget.bookDetail.title,
      'currentChapter': currentChapter,
      'lastUpdated': FieldValue.serverTimestamp(),
      'chapters': {
        currentChapter.toString(): realPosition.inMilliseconds,
      },
    }, SetOptions(merge: true));
  }

  Future<void> _loadProgressFromFirestore() async {
    try {
      if (_isDisposed) return;

      final auth = Provider.of<AuthProvider>(context, listen: false);
      final user = auth.currentUser;
      if (user == null) return;

      final doc = await _firestore
          .collection('userProgress')
          .doc(user.uid)
          .collection('audioProgress')
          .doc(widget.bookDetail.title)
          .get();

      if (!doc.exists) return;

      final data = doc.data();
      if (data == null) return;

      final savedChapter = data['currentChapter'] as int? ?? 0;
      final chaptersData = Map<String, dynamic>.from(data['chapters'] ?? {});

      final Map<int, Duration> loadedProgress = {};

      chaptersData.forEach((key, value) {
        final chapterIndex = int.tryParse(key) ?? -1;
        if (chapterIndex >= 0) {
          print("Chapter Valueeeee ${value}");
          loadedProgress[chapterIndex] =
              Duration(milliseconds: (value as num).toInt());
        }
      });

      if (_isDisposed) return;

      setState(() {
        currentChapter = savedChapter;
        _chapterProgress = loadedProgress; // <-- IMPORTANT FIX
      });

      debugPrint("Loaded chapter: $currentChapter");
      debugPrint("Loaded progress: $_chapterProgress");
    } catch (e) {
      debugPrint('Failed to load progress: $e');
    }
  }

  String formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    return duration.inHours > 0
        ? "${twoDigits(duration.inHours)}:$minutes:$seconds"
        : "$minutes:$seconds";
  }

  Future<void> _playChapter(int chapterIndex,
      {bool initialLoad = false}) async {
    if (_isDisposed ||
        chapterIndex < 0 ||
        chapterIndex >= widget.bookDetail.chapters.length) return;

    try {
      if (!initialLoad && currentChapter != chapterIndex) {
        // Get accurate current position from audioHandler
        final currentPosition = await audioHandler.playbackState.first
            .then((state) => state.position);

        setState(() {
          position = currentPosition;
        });

        // Update local progress cache before saving
        _chapterProgress[currentChapter] = currentPosition;

        await _saveProgressToFirestore();
      }

      setState(() {
        _isLoading = true;
        currentChapter = chapterIndex;
        duration = Duration.zero;

        // 🔥 Only reset position when switching chapters — NOT on initial load
        if (!initialLoad) {
          position = Duration.zero;
        }
      });

      final chapter = widget.bookDetail.chapters[chapterIndex];
      final savedPosition = _chapterProgress[chapterIndex] ?? Duration.zero;

      await audioHandler.updateMediaItem(MediaItem(
        id: widget.bookDetail.title,
        title: chapter.chapterName,
        artist: widget.bookDetail.authoer,
        album: widget.bookDetail.title,
        artUri: Uri.parse(widget.bookDetail.bookCover),
        duration: Duration.zero,
        extras: {
          'chapter': chapterIndex,
          'chapterName': chapter.chapterName,
        },
      ));

      await audioHandler.loadAudioSource(chapter.chapterUrl);

      // -------------------------------------------------------
      // 🔥 1. WAIT UNTIL PLAYER IS READY (MOST IMPORTANT STEP)
      // -------------------------------------------------------
      try {
        await audioHandler.playbackState
            .firstWhere(
                (state) => state.processingState == AudioProcessingState.ready)
            .timeout(const Duration(seconds: 4));
      } catch (_) {
        // if failed, continue — but seek may not work
      }

      // -------------------------------------------------------
      // 🔥 2. WAIT FOR DURATION (SECOND SAFEGUARD)
      // -------------------------------------------------------
      Duration? loadedDuration;
      try {
        loadedDuration = await audioHandler.durationStream
            .firstWhere((d) => d != null)
            .timeout(const Duration(seconds: 3));
      } catch (e) {
        loadedDuration = null;
      }

      // -------------------------------------------------------
      // 🔥 3. SEEK USING DOUBLE-RETRY (GUARANTEED)
      // -------------------------------------------------------
      if (savedPosition > Duration.zero) {
        try {
          await audioHandler.seek(savedPosition);
        } catch (_) {
          await Future.delayed(const Duration(milliseconds: 200));
          try {
            await audioHandler.seek(savedPosition);
          } catch (_) {}
        }
      }
      // -------------------------------------------------------

      if (!initialLoad) {
        await audioHandler.play();
      }
    } catch (e) {
      debugPrint('Error playing chapter: $e');
      if (!_isDisposed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to play chapter')),
        );
      }
    } finally {
      if (!_isDisposed) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> checkIfFavourite() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final user = auth.currentUser;
      if (user != null && !_isDisposed) {
        final doc = await _firestore
            .collection('favourites')
            .doc(user.uid)
            .collection('mybookmarks')
            .doc(widget.bookDetail.title)
            .get();
        if (doc.exists && !_isDisposed) {
          setState(() => isFavourite = true);
        }
      }
    } catch (e) {
      debugPrint('Failed to check favorite: $e');
    }
  }

  Future<void> toggleFavourite() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final user = auth.currentUser;
      if (user == null) {
        NavigationHelper.pushWithTransition(
            context: context, targetPage: LoginScreen());
        return;
      }

      final docRef = _firestore
          .collection('favourites')
          .doc(user.uid)
          .collection('mybookmarks')
          .doc(widget.bookDetail.title);

      if (isFavourite) {
        await docRef.delete();
      } else {
        await docRef.set(widget.bookDetail.toMap());
      }

      if (!_isDisposed) setState(() => isFavourite = !isFavourite);
    } catch (e) {
      debugPrint('Failed to toggle favorite: $e');
      if (!_isDisposed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update favorites')),
        );
      }
    }
  }

  Future<void> speedAudio() async {
    try {
      final targetSpeed = currentSpeed == 2 ? 1.0 : 2.0;
      await audioHandler.setSpeed(targetSpeed);
      if (!_isDisposed) setState(() => currentSpeed = targetSpeed.toInt());
    } catch (e) {
      debugPrint('Failed to change speed: $e');
      if (!_isDisposed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to change speed')),
        );
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _saveProgressTimer?.cancel();
    _saveProgressToFirestore();
    super.dispose();
  }

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
            onPressed: () async {
              await _saveProgressToFirestore();
              Navigator.of(context).pop();
            },
          ),
          title: Text(
            widget.bookDetail.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500),
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.black,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white,
          selectedFontSize: 10,
          unselectedFontSize: 10,
          elevation: 0,
          selectedLabelStyle: const TextStyle(
              fontSize: 10, fontFamily: 'Poppins', fontWeight: FontWeight.w500),
          unselectedLabelStyle: const TextStyle(
              fontSize: 10, fontFamily: 'Poppins', fontWeight: FontWeight.w500),
          onTap: (value) async {
            final auth = Provider.of<AuthProvider>(context, listen: false);
            if (value == 0) {
              await toggleFavourite();
            } else if (value == 1) {
              // The ChaptersBottomSheet shows audio-only chapters and returns an index
              // into that filtered list. We must map the returned index back to the
              // original chapter index in updatedBook.chapters.
              final selectedFromSheet = await ChaptersBottomSheet()
                  .buildBottomsheet(context, updatedBook.chapters);

              if (selectedFromSheet != null) {
                // Compute original indices of audio chapters
                final audioOriginalIndices = <int>[];
                for (int i = 0; i < updatedBook.chapters.length; i++) {
                  if (updatedBook.chapters[i].chapterUrl.trim().isNotEmpty) {
                    audioOriginalIndices.add(i);
                  }
                }

                // Guard: ensure the returned index maps into audioOriginalIndices
                if (selectedFromSheet < 0 ||
                    selectedFromSheet >= audioOriginalIndices.length) {
                  // out-of-range — ignore
                  return;
                }

                final actualChapterIndex =
                    audioOriginalIndices[selectedFromSheet];

                if (actualChapterIndex > 0) {
                  final chapter = updatedBook.chapters[actualChapterIndex];
                  debugPrint(
                      'Chapter $actualChapterIndex - isLocked: ${chapter.isLocked}');

                  if (!chapter.isLocked) {
                    // Chapter is free → always play
                    await _playChapter(actualChapterIndex);
                    return;
                  }

                  // Chapter is locked → check subscription
                  if (auth.currentUser == null || !auth.isSubscribed) {
                    if (!_isDisposed) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.pleaseSubscribe)),
                      );
                    }
                    return;
                  }

                  // Locked but subscribed → play
                  await _playChapter(actualChapterIndex);
                } else {
                  // Chapter 0 is always free
                  await _playChapter(actualChapterIndex);
                }
              }
            } else if (value == 2) {
              await speedAudio();
            }
          },
          items: [
            BottomNavigationBarItem(
              label: l10n.bookmark,
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: Icon(
                  isFavourite ? Icons.favorite : Icons.favorite_border,
                  key: ValueKey<bool>(isFavourite),
                  color: isFavourite ? Colors.red : Colors.white,
                  size: 24,
                ),
              ),
            ),
            BottomNavigationBarItem(
              label: l10n.chapters,
              icon: Column(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Image.asset("asset/image/Paper.png",
                        color: Colors.white),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.005),
                ],
              ),
            ),
            BottomNavigationBarItem(
              label: currentSpeed == 1 ? l10n.speed2x : l10n.speed1x,
              icon: Column(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Image.asset("asset/image/Time Square.png",
                        color: Colors.white),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.005),
                ],
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(9.0),
            child: Padding(
              padding:
                  const EdgeInsets.only(left: 20.0, right: 20.0, top: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 319,
                    height: 335,
                    child: Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          height: MediaQuery.of(context).size.height * 0.5,
                          decoration: ShapeDecoration(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CachedNetworkImage(
                                imageUrl:
                                    Uri.encodeFull(widget.bookDetail.bookCover),
                                fit: BoxFit.fill,
                                errorWidget: (context, url, error) => Container(
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.error),
                                ),
                              ),
                              BackdropFilter(
                                filter: ImageFilter.blur(
                                    sigmaX: 10.0, sigmaY: 10.0),
                                child: Container(color: Colors.transparent),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          left: 0,
                          top: 0,
                          child: Container(
                            width: 319,
                            height: 319,
                            decoration: ShapeDecoration(
                              image: DecorationImage(
                                image: CachedNetworkImageProvider(
                                    widget.bookDetail.bookCover),
                                fit: BoxFit.cover,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.045),
                  Text(
                    widget.bookDetail.title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.005),
                  Opacity(
                    opacity: 0.5,
                    child: Text(
                      widget.bookDetail.authoer,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w400),
                    ),
                  ),
                  ValueListenableBuilder<Duration>(
                    valueListenable: _positionNotifier,
                    builder: (context, currentPosition, _) {
                      // Ensure duration is at least 1 second to avoid division by zero
                      final safeDuration = duration.inSeconds > 0
                          ? duration
                          : Duration(seconds: 1);

                      return SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppColors.buttonRed,
                          inactiveTrackColor: AppColors.white,
                          thumbColor: AppColors.buttonRed,
                          overlayColor: AppColors.buttonRed.withOpacity(0.2),
                        ),
                        child: Slider(
                          min: 0,
                          max: safeDuration.inSeconds.toDouble(),
                          value: currentPosition.inSeconds
                              .clamp(0, safeDuration.inSeconds)
                              .toDouble(),
                          onChangeStart: (value) {
                            setState(() => _isDragging = true);
                          },
                          onChangeEnd: (value) async {
                            final newPos = Duration(seconds: value.toInt());
                            await audioHandler.seek(newPos);
                            setState(() {
                              position = newPos;
                              _isDragging = false;
                            });
                          },
                          onChanged: _isLoading
                              ? null
                              : (value) {
                                  _positionNotifier.value =
                                      Duration(seconds: value.toInt());
                                },
                        ),
                      );
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          formatTime(position),
                          style: const TextStyle(
                              color: Color(0xFF9292A2),
                              fontSize: 10,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w400),
                        ),
                        Text(
                          formatTime(duration),
                          style: const TextStyle(
                              color: Color(0xFF9292A2),
                              fontSize: 10,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w400),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: _isLoading
                              ? null
                              : () async {
                                  // Skip backward 10 seconds safely
                                  final skipSeconds = 10;
                                  Duration newPos =
                                      position - Duration(seconds: skipSeconds);

                                  // Ensure position doesn't go below 0
                                  if (newPos < Duration.zero) {
                                    newPos = Duration.zero;
                                  }

                                  // Optional: Also ensure it doesn't exceed duration
                                  if (newPos > duration) {
                                    newPos = duration;
                                  }

                                  try {
                                    await audioHandler.seek(newPos);
                                    setState(() {
                                      position = newPos;
                                    });
                                  } catch (e) {
                                    print('Error seeking: $e');
                                  }
                                },
                          child: Opacity(
                            opacity: 1,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                image: DecorationImage(
                                  image: AssetImage(
                                      "asset/image/Arrow - Left Circle.png"),
                                  fit: BoxFit.fill,
                                  colorFilter: ColorFilter.mode(
                                      Colors.white, BlendMode.srcIn),
                                ),
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: _isLoading
                              ? null
                              : () async {
                                  if (isPlaying) {
                                    await audioHandler.pause();
                                  } else {
                                    await audioHandler.play();
                                  }
                                },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 72,
                            height: 72,
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : Image.asset(
                                    isPlaying
                                        ? "asset/image/pause.png"
                                        : "asset/image/Play2.png",
                                    color: Colors.white,
                                  ),
                          ),
                        ),
                        GestureDetector(
                          onTap: _isLoading
                              ? null
                              : () async {
                                  final skipSeconds = 10;
                                  Duration newPos =
                                      position + Duration(seconds: skipSeconds);

                                  // Ensure position doesn't go below 0
                                  if (newPos < Duration.zero) {
                                    newPos = Duration.zero;
                                  }

                                  // Optional: Also ensure it doesn't exceed duration
                                  if (newPos > duration) {
                                    newPos = duration;
                                  }

                                  try {
                                    await audioHandler.seek(newPos);
                                    setState(() {
                                      position = newPos;
                                    });
                                  } catch (e) {
                                    print('Error seeking: $e');
                                  }
                                },
                          child: Opacity(
                            opacity: currentChapter < maxChapters ? 1 : 0.5,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                image: DecorationImage(
                                  image: AssetImage(
                                      "asset/image/Arrow - Right Circle.png"),
                                  fit: BoxFit.fill,
                                  colorFilter: ColorFilter.mode(
                                      Colors.white, BlendMode.srcIn),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5.0),
                    child: Text(
                      widget.bookDetail.chapters[currentChapter].chapterName,
                      overflow: TextOverflow.ellipsis,
                      softWrap: true,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w400),
                    ),
                  ),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 20),
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
