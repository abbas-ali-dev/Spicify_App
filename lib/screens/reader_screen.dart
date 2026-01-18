import 'dart:async';
import 'package:Spicify/screens/web_view_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../model/book_model.dart';
import '../provider_book/reader_provider.dart';
import '../utilities/app_colors.dart';
import '../gen_l10n/app_localizations.dart';
import '../utilities/navigator_helper_class.dart';
import './auth_provider.dart' as auth;

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({Key? key}) : super(key: key);

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  // Keep a ScrollController if you need it elsewhere; main paging uses PageController
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _chapterKeys = {};
  Timer? _saveTimer;
  bool _initialLoadDone = false;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    // We don't rely on a single global scroll controller for per-chapter scrolling.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prepareOnOpen();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preloadMoreChapters();
    });
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _scrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  bool _isChapterUnlocked(Chapter ch) {
    final authP = context.watch<auth.AuthProvider>();
    // Rule 1: First chapter always unlocked
    if (ch.order == 1) return true;

    // Rule 2: Chapter is marked "free"
    if (ch.isFree == true) return true;

    // Rule 3: User has subscription
    if (authP.isSubscribed == true) return true;

    // Otherwise locked
    return false;
  }

  void _showSubscriptionPopup() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: RepaintBoundary(child: const Text("Locked Chapter")),
        backgroundColor: Colors.white,
        content: RepaintBoundary(
          child: const Text(
            "This chapter is available to members",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: RepaintBoundary(child: const Text("Close")),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to your subscription screen
              NavigationHelper.pushWithTransition(
                  context: context,
                  targetPage: WebViewScreen(
                      url: "https://spicifyapp.com/auth/register"));
            },
            child: RepaintBoundary(child: const Text("Create An Account")),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to your subscription screen
              NavigationHelper.pushWithTransition(
                  context: context,
                  targetPage:
                      WebViewScreen(url: "https://spicifyapp.com/auth/login"));
            },
            child: RepaintBoundary(child: const Text("Sign in")),
          ),
        ],
      ),
    );
  }

  Future<void> _prepareOnOpen() async {
    final prov = context.read<ReaderProvider>();
    final current = prov.currentOrder;

    // Ensure the book reading list exists
    final allChapters = prov.getAllChaptersSorted();
    if (allChapters.isEmpty) {
      // nothing to show
      setState(() {
        _initialLoadDone = true;
      });
      return;
    }

    // Load current chapter if needed
    await prov.loadChapterIfNeeded(current);

    // Determine index in full chapter list (not loadedChapters)
    final orders = allChapters.map((c) => c.order).toList();
    final currentIndex = orders.indexOf(current);

    // Load previous (for back navigation)
    if (currentIndex > 0) {
      await prov.loadChapterIfNeeded(orders[currentIndex - 1]);
    }

    // Load next 2 chapters for smooth reading
    for (int i = 1; i <= 2; i++) {
      if (currentIndex + i < orders.length) {
        await prov.loadChapterIfNeeded(orders[currentIndex + i]);
      }
    }

    // If there are few chapters, load them all
    if (orders.length <= 5) {
      for (final order in orders) {
        if (!prov.loadedChapters.containsKey(order)) {
          await prov.loadChapterIfNeeded(order);
        }
      }
    }

    // Jump to the correct page index in full allChapters list
    final all = prov.getAllChaptersSorted();
    final idx = all.indexWhere((c) => c.order == current);
    if (idx != -1 && _pageController.hasClients) {
      // use jumpToPage if you want immediate positioning
      _pageController.jumpToPage(idx);
    } else if (idx != -1) {
      // if controller not ready yet, schedule a post-frame jump
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          _pageController.jumpToPage(idx);
        }
      });
    }

    setState(() {
      _initialLoadDone = true;
    });
  }

  Future<void> _tryLoadNextChapter() async {
    final prov = context.read<ReaderProvider>();
    final currentOrder = prov.currentOrder;
    final allChapters = prov.getAllChaptersSorted();
    final currentIndex =
        allChapters.indexWhere((ch) => ch.order == currentOrder);

    if (currentIndex == -1) return;

    for (int i = 1; i <= 3; i++) {
      if (currentIndex + i < allChapters.length) {
        final nextOrder = allChapters[currentIndex + i].order;
        if (!prov.loadedChapters.containsKey(nextOrder)) {
          await prov.loadChapterIfNeeded(nextOrder);
          if (mounted) setState(() {});
        }
      }
    }
  }

  Future<void> _preloadMoreChapters() async {
    final prov = context.read<ReaderProvider>();
    final allChapters = prov.getAllChaptersSorted();

    if (prov.loadedChapters.length < 5 &&
        allChapters.length > prov.loadedChapters.length) {
      final loadedOrders = prov.loadedChapters.keys.toList();

      for (final chapter in allChapters) {
        if (!loadedOrders.contains(chapter.order) && loadedOrders.length < 5) {
          await prov.loadChapterIfNeeded(chapter.order);
          if (mounted) setState(() {});
        }
      }
    }
  }

  Widget _buildLoadingChapter(bool dark) {
    return Container(
      color: dark ? AppColors.black : Colors.white,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: const CircularProgressIndicator(),
    );
  }

  Widget _buildChapter(Chapter ch, bool dark) {
    final prov = context.read<ReaderProvider>();
    final user = context.watch<auth.AuthProvider>();
    final hasSubscription = user.isSubscribed;
    final l10 = AppLocalizations.of(context);
    final textStyle = TextStyle(
        fontSize: prov.fontSize,
        height: 1.2,
        color: dark ? Colors.white70 : Colors.black87,
        fontFamily: "Poppins");

    final List<Widget> items = [];

    // Lock-check: order>1 (i.e., order>0 in user's scheme) means not first chapter
    // Always allow first chapter (order == 0)
    final bool isFirstChapter = ch.order == 0;

// If user has no subscription and chapter is locked and it's NOT first chapter → show lock UI
    if (!hasSubscription && ch.isLocked && !isFirstChapter) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock,
                size: 60, color: dark ? Colors.white70 : Colors.black54),
            const SizedBox(height: 20),
            RepaintBoundary(
              child: Text(
                "This chapter is available to members",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: dark ? Colors.white : Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 10),
            RepaintBoundary(
              child: Text(
                "Please sign or create an account",
                style: TextStyle(
                  fontSize: 16,
                  color: dark ? Colors.white70 : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                NavigationHelper.pushWithTransition(
                  context: context,
                  targetPage: WebViewScreen(
                    url: "https://spicifyapp.com/payment",
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                backgroundColor: AppColors.buttonRed,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: RepaintBoundary(
                child: Text(
                  l10.loginTitle,
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            )
          ],
        ),
      );
    }

    // Chapter title
    items.add(Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: RepaintBoundary(
        child: Text(
          ch.chapterName,
          style: TextStyle(
            fontSize: 22,
            height: 1.3,
            fontWeight: FontWeight.bold,
            color: dark ? Colors.white : Colors.black,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    ));

    if (ch.contentBlocks.isNotEmpty) {
      for (final block in ch.contentBlocks) {
        if (block.type == 'text' ||
            block.type == 'paragraph' ||
            block.type == 'paragraph_text') {
          final blockText = (block.text ?? '').trim();
          if (blockText.isNotEmpty) {
            items.add(Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: RepaintBoundary(child: Text(blockText, style: textStyle)),
            ));
          }
        } else if (block.type == 'image') {
          final url = (block.url ?? '').trim();
          if (url.isNotEmpty) {
            items.add(Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder: (_, __) => Container(
                    height: 200,
                    color: Colors.grey.shade200,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    height: 200,
                    color: Colors.grey.shade200,
                    child: const Center(child: Icon(Icons.broken_image)),
                  ),
                ),
              ),
            ));
          }
        } else {
          final fallback = (block.text ?? '').trim();
          if (fallback.isNotEmpty) {
            items.add(Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: RepaintBoundary(child: Text(fallback, style: textStyle)),
            ));
          }
        }
      }
    } else {
      final text = ch.textContent.trim();
      if (text.isNotEmpty) {
        final paragraphs = text.split('\n').where((p) => p.trim().isNotEmpty);
        for (final paragraph in paragraphs) {
          items.add(Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: RepaintBoundary(child: Text(paragraph, style: textStyle)),
          ));
        }
      } else {
        items.add(const SizedBox(height: 20));
      }
    }

    items.add(const SizedBox(height: 80));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items,
    );
  }

  Widget _chapterContainerWithKey(int order, Chapter ch, bool dark) {
    _chapterKeys.putIfAbsent(order, () => GlobalKey());
    return Container(
      key: _chapterKeys[order],
      child: _buildChapter(ch, dark),
    );
  }

  // Scroll-to-chapter for bottom-sheet selection: compute index from full list
  Future<void> _scrollToChapterOrder(int order) async {
    final prov = context.read<ReaderProvider>();
    final all = prov.getAllChaptersSorted();
    final pageIndex = all.indexWhere((c) => c.order == order);

    if (pageIndex == -1) return;

    if (!prov.loadedChapters.containsKey(order)) {
      // load the chapter first then jump
      await prov.loadChapterIfNeeded(order);
      if (mounted) setState(() {});
      // preload neighbors
      await _loadChapterNeighbors(order);
    }

    if (_pageController.hasClients) {
      _pageController.jumpToPage(pageIndex);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          _pageController.jumpToPage(pageIndex);
        }
      });
    }
  }

  void _openChapterList() {
    final prov = context.read<ReaderProvider>();
    final chapters = prov.getAllChaptersSorted();
    final l10n = AppLocalizations.of(context);
    final isDark = prov.darkMode;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final authProv = context.watch<auth.AuthProvider>();

        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[900] : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                child: RepaintBoundary(
                  child: Text(
                    l10n?.chapters ?? 'Chapters',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ),
              Divider(
                  height: 1,
                  color: isDark ? Colors.grey[700] : Colors.grey[300]),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: chapters.length,
                  itemBuilder: (_, i) {
                    final ch = chapters[i];
                    final isCurrentChapter = prov.currentOrder == ch.order;
                    final isChapterLoaded =
                        prov.loadedChapters.containsKey(ch.order);

                    // unlocked when NOT locked OR marked free OR user subscribed
                    final bool isUnlocked =
                        (!ch.isLocked) || ch.isFree || authProv.isSubscribed;

                    return Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: isCurrentChapter
                            ? (isDark
                                ? Colors.blue.withOpacity(0.2)
                                : Colors.blue.withOpacity(0.1))
                            : Colors.transparent,
                        border: isCurrentChapter
                            ? Border.all(
                                color: Colors.blue.withOpacity(0.3), width: 1)
                            : null,
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isCurrentChapter
                                ? Colors.blue
                                : (isDark
                                    ? Colors.grey[700]
                                    : Colors.grey[300]),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Center(
                            child: RepaintBoundary(
                              child: Text(
                                ch.order.toString(),
                                style: TextStyle(
                                  color: isCurrentChapter
                                      ? Colors.white
                                      : (isDark ? Colors.white : Colors.black),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: RepaintBoundary(
                                child: Text(
                                  ch.chapterName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: isCurrentChapter
                                        ? Colors.blue
                                        : (isDark
                                            ? Colors.white
                                            : Colors.black),
                                  ),
                                ),
                              ),
                            ),
                            if (ch.isLocked && !isUnlocked)
                              const Icon(Icons.lock,
                                  size: 18, color: Colors.red),
                          ],
                        ),
                        trailing: isChapterLoaded
                            ? const Icon(Icons.check_circle,
                                color: Colors.green, size: 20)
                            : Icon(Icons.download,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                                size: 20),
                        onTap: () {
                          Navigator.pop(context);
                          if (!isUnlocked) {
                            _showSubscriptionPopup();
                            return;
                          }
                          _handleChapterSelection(ch.order);
                        },
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        tileColor: Colors.transparent,
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        );
      },
    );
  }

  void _handleChapterSelection(int order) {
    final prov = context.read<ReaderProvider>();
    prov.currentOrder = order;

    // We will load the requested order if needed and jump to its index in full list
    _scrollToChapterOrder(order);
  }

  Future<void> _loadChapterNeighbors(int order) async {
    final prov = context.read<ReaderProvider>();
    final allChapters = prov.getAllChaptersSorted();
    final orders = allChapters.map((c) => c.order).toList();
    final currentIndex = orders.indexOf(order);

    if (currentIndex == -1) return;

    // Load next 2 chapters
    for (int i = 1; i <= 2; i++) {
      if (currentIndex + i < orders.length) {
        final nextOrder = orders[currentIndex + i];
        if (!prov.loadedChapters.containsKey(nextOrder)) {
          await prov.loadChapterIfNeeded(nextOrder);
        }
      }
    }

    // Load previous chapter
    if (currentIndex > 0) {
      final prevOrder = orders[currentIndex - 1];
      if (!prov.loadedChapters.containsKey(prevOrder)) {
        await prov.loadChapterIfNeeded(prevOrder);
      }
    }

    if (mounted) setState(() {});
  }

  void _openFontAdjust(BuildContext context) {
    final prov = context.read<ReaderProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      builder: (_) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RepaintBoundary(
                child: Text("Adjust Font Size",
                    style: TextStyle(
                        fontSize: 18,
                        color: isDark ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 24),
              StatefulBuilder(builder: (c, setState) {
                return Column(
                  children: [
                    Slider(
                      min: 12,
                      max: 30,
                      divisions: 18,
                      value: prov.fontSize,
                      onChanged: (v) {
                        prov.updateFontSize(v);
                        setState(() {});
                      },
                      activeColor: Colors.blue,
                      inactiveColor: Colors.grey[300],
                    ),
                    const SizedBox(height: 8),
                    RepaintBoundary(
                      child: Text("${prov.fontSize.toStringAsFixed(0)} px",
                          style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                              fontSize: 16)),
                    ),
                  ],
                );
              }),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  // Save per-chapter scroll offset when the inner scroll ends
  void _saveChapterScrollProgress(int order, double offset) {
    final prov = context.read<ReaderProvider>();
    prov.saveProgress(order: order, offset: offset);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReaderProvider>(builder: (_, prov, __) {
      final dark = prov.darkMode;

      if (prov.getAllChaptersSorted().isEmpty && !_initialLoadDone) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _prepareOnOpen();
        });
      }

      final allChapters = prov.getAllChaptersSorted();

      return RepaintBoundary(
        child: Scaffold(
          backgroundColor: dark ? AppColors.black : Colors.white,
          appBar: AppBar(
            elevation: 0,
            centerTitle: true,
            backgroundColor: dark ? AppColors.black : Colors.black,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, size: 20),
              color: Colors.white,
              onPressed: () async {
                final authP = context.read<auth.AuthProvider>();
                if (authP.currentUser != null) {
                  await FirebaseFirestore.instance
                      .collection("reading_progress")
                      .doc(authP.currentUser!.uid)
                      .set({
                    "book": prov.book.toMap(),
                    "chapter":
                        prov.loadedChapters[prov.currentOrder]?.chapterName ??
                            "",
                    "page": prov.currentOrder,
                    "updatedAt": DateTime.now(),
                  }, SetOptions(merge: true));
                }
                Navigator.pop(context);
              },
            ),
            title: RepaintBoundary(
              child: Text(
                prov.book.title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500),
              ),
            ),
            actions: [
              IconButton(
                  icon: const Icon(Icons.text_fields,
                      size: 22, color: Colors.white),
                  onPressed: () => _openFontAdjust(context)),
            ],
          ),
          body: PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            physics: const BouncingScrollPhysics(),
            itemCount: allChapters.length,
            onPageChanged: (index) {
              final chapter = allChapters[index];
              final order = chapter.order;
              prov.currentOrder = order;
              // At page change, save progress at top (offset 0)
              prov.saveProgress(order: order, offset: 0);
              // Preload neighbors
              _loadChapterNeighbors(order);
            },
            itemBuilder: (context, index) {
              final chapter = allChapters[index];
              final order = chapter.order;
              final isLoaded = prov.loadedChapters.containsKey(order);

              if (!isLoaded) {
                // Start loading asynchronously but show a loading placeholder immediately
                prov.loadChapterIfNeeded(order).then((_) {
                  if (mounted) setState(() {});
                });
                return _buildLoadingChapter(dark);
              }

              // Each page contains its own SingleChildScrollView
              return NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  // When inner scroll ends, save progress offset for current chapter
                  if (notification is ScrollEndNotification ||
                      notification is UserScrollNotification) {
                    // Save after a small delay to avoid excessive writes
                    _saveTimer?.cancel();
                    _saveTimer = Timer(const Duration(milliseconds: 300), () {
                      final metrics = notification.metrics;
                      _saveChapterScrollProgress(order, metrics.pixels);
                    });
                  }
                  // If the user reaches bottom, auto-move to next page
                  if (notification is ScrollEndNotification) {
                    final metrics = notification.metrics;
                    final isAtBottom =
                        metrics.pixels >= metrics.maxScrollExtent - 20;
                    if (isAtBottom && index < allChapters.length - 1) {
                      _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut);
                    }
                  }
                  return false;
                },
                child: SingleChildScrollView(
                  padding: EdgeInsets.zero,
                  child: _chapterContainerWithKey(
                      order, prov.loadedChapters[order]!, dark),
                ),
              );
            },
          ),
          bottomNavigationBar: _BottomBar(onChapters: _openChapterList),
        ),
      );
    });
  }
}

class _BottomBar extends StatelessWidget {
  final VoidCallback onChapters;
  const _BottomBar({required this.onChapters});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ReaderProvider>();
    final dark = prov.darkMode;
    final l10n = AppLocalizations.of(context);

    return SafeArea(
      minimum: const EdgeInsets.only(bottom: 12), // add extra spacing
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: dark ? Colors.grey[900] : Colors.white,
          border: Border(
            top: BorderSide(
                color: dark ? Colors.grey[800]! : Colors.grey[200]!, width: 1),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(
                  prov.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: prov.isFavorite
                      ? Colors.red
                      : (dark ? Colors.white : Colors.black),
                  size: 26),
              onPressed: prov.toggleFavorite,
            ),
            GestureDetector(
              onTap: onChapters,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                    color: AppColors.buttonRed,
                    borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [
                    const Icon(Icons.menu_book, size: 18, color: Colors.white),
                    const SizedBox(width: 6),
                    RepaintBoundary(
                      child: Text(l10n?.chapters ?? 'Chapters',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: Text(dark ? "☀️" : "🌙",
                  style: const TextStyle(fontSize: 20)),
              onPressed: prov.toggleTheme,
            ),
          ],
        ),
      ),
    );
  }
}
