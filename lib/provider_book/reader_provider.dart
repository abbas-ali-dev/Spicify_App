// lib/provider_book/reader_provider.dart
import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/book_model.dart';
import '../screens/auth_provider.dart';

const String _kFavKey = 'favorites_set';
const String _kCachedChapterPrefix = 'cached_chapter_';
const String _kProgressPrefix = 'reading_progress_';
const String _kFontPrefix = 'font_size_';

final FirebaseFirestore _firestore = FirebaseFirestore.instance;

class ReaderProvider extends ChangeNotifier {
  Book book;
  final SharedPreferences prefs;

  int? initialOrderFromFirestore;
  double? initialOffsetFromFirestore;

  bool isFavorite = false;
  bool darkMode = false;
  bool _isLoadingFavorite = false;

  int? fireOrder;
  double? fireOffset;

  final Map<int, Chapter> loadedChapters = {};
  int currentOrder = 0;
  double currentScrollOffset = 0.0;

  ReaderProvider({
    required this.book,
    required this.prefs,
    this.initialOrderFromFirestore,
    this.initialOffsetFromFirestore,
  }) {
    fireOrder = initialOrderFromFirestore;
    fireOffset = initialOffsetFromFirestore;
    _init();
  }

  double _fontSize = 18;
  double get fontSize => _fontSize;

  void updateFontSize(double value) {
    _fontSize = value;
    prefs.setDouble(_kFontPrefix, value);
    notifyListeners();
  }

  StreamSubscription? _bookSubscription;

  void listenToBookUpdates() {
    _bookSubscription = FirebaseFirestore.instance
        .collection("audiobooks")
        .doc(book.id)
        .snapshots()
        .listen((snap) {
      if (!snap.exists) return;

      final updatedBook = Book.fromMap(snap.data()!, book.id);

      // Update chapters in memory
      book = updatedBook;

      // Clear loaded chapters so updated content loads fresh
      loadedChapters.clear();

      // Reload current chapter
      loadChapterIfNeeded(currentOrder);

      notifyListeners();
    });
  }

  Future<void> _init() async {
    _loadFavorite();
    _loadTheme();

    listenToBookUpdates();
    final fontSiz = prefs.getDouble(_kFontPrefix) ?? 18;
    _fontSize = fontSiz;

    // Sync with Firestore after loading local favorite
    _syncFavoriteWithFirestore();

    // load local progress if exists
    final prog = prefs.getString(_kProgressPrefix + book.id);

    int? savedOrder;
    double? savedOffset;

    if (prog != null) {
      try {
        final Map<String, dynamic> p = jsonDecode(prog);
        savedOrder = (p['order'] as num?)?.toInt();
        savedOffset = (p['offset'] as num?)?.toDouble();
      } catch (_) {}
    }

    // Determine first reading order available
    final readingOrders = _readingOrdersSorted();

    if (readingOrders.isEmpty) {
      // no reading chapters at all
      currentOrder = 0;
      currentScrollOffset = savedOffset ?? 0.0;
    } else {
      // --------------------------
      // FIX: PRIORITIZE FIRESTORE PROGRESS
      // --------------------------
      if (initialOrderFromFirestore != null &&
          readingOrders.contains(initialOrderFromFirestore)) {
        currentOrder = initialOrderFromFirestore!;
        currentScrollOffset = initialOffsetFromFirestore ?? 0.0;
      }

      // Then use local SharedPreferences if valid
      else if (savedOrder != null && readingOrders.contains(savedOrder)) {
        currentOrder = savedOrder;
        currentScrollOffset = savedOffset ?? 0.0;
      }

      // fallback to first chapter
      else {
        currentOrder = readingOrders.first;
        currentScrollOffset = 0.0;
      }

      // Preload the starting reading chapter
      await loadChapterIfNeeded(currentOrder);
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _bookSubscription?.cancel();
    super.dispose();
  }

  // load favorite from local preferences
  void _loadFavorite() {
    final favs = prefs.getStringList(_kFavKey) ?? [];
    isFavorite = favs.contains(book.id);
  }

  // Sync local favorite with Firestore
  Future<void> _syncFavoriteWithFirestore() async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) return;

      final doc = await _firestore
          .collection('favourites')
          .doc(userId)
          .collection('mybookmarks')
          .doc(book.title)
          .get();

      final firestoreFavorite = doc.exists;

      // If local and Firestore don't match, update local to match Firestore
      if (isFavorite != firestoreFavorite) {
        isFavorite = firestoreFavorite;
        _updateLocalFavorite(firestoreFavorite);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to sync favorite with Firestore: $e');
    }
  }

  // Modified toggleFavorite with Firestore integration
  Future<void> toggleFavorite() async {
    if (_isLoadingFavorite) return;

    _isLoadingFavorite = true;
    notifyListeners();

    try {
      final userId = await _getCurrentUserId();

      if (userId == null) {
        // User not logged in - just toggle local favorite
        _toggleLocalFavorite();
        _isLoadingFavorite = false;
        notifyListeners();
        return;
      }

      final docRef = _firestore
          .collection('favourites')
          .doc(userId)
          .collection('mybookmarks')
          .doc(book.title);

      if (isFavorite) {
        // Remove from favorites
        await docRef.delete();
        _toggleLocalFavorite();
      } else {
        // Add to favorites
        await docRef.set(book.toMap());
        _toggleLocalFavorite();
      }
    } catch (e) {
      debugPrint('Failed to toggle favorite: $e');
      // Revert UI state on error
      _toggleLocalFavorite();
    } finally {
      _isLoadingFavorite = false;
      notifyListeners();
    }
  }

  // Helper method to toggle local favorite
  void _toggleLocalFavorite() {
    final favs = prefs.getStringList(_kFavKey) ?? [];

    if (isFavorite) {
      favs.remove(book.id);
      isFavorite = false;
    } else {
      favs.add(book.id);
      isFavorite = true;
    }

    prefs.setStringList(_kFavKey, favs);
  }

  // Helper method to update local favorite
  void _updateLocalFavorite(bool isFav) {
    final favs = prefs.getStringList(_kFavKey) ?? [];

    if (isFav) {
      if (!favs.contains(book.id)) {
        favs.add(book.id);
      }
    } else {
      favs.remove(book.id);
    }

    prefs.setStringList(_kFavKey, favs);
  }

  // Get current user ID - you need to implement this based on your auth setup
  Future<String?> _getCurrentUserId() async {
    try {
      // TODO: Replace with your actual auth implementation
      // Example:

      return AuthProvider().currentUser?.uid;

      // For now, return null - you'll need to implement this
      return null;
    } catch (e) {
      debugPrint('Failed to get user ID: $e');
      return null;
    }
  }

  void _loadTheme() {
    darkMode = prefs.getBool('dark_mode') ?? false;
  }

  Future<void> toggleTheme() async {
    darkMode = !darkMode;
    await prefs.setBool('dark_mode', darkMode);
    notifyListeners();
  }

  // -------------------------
  // Helpers to work only with reading chapters
  // -------------------------
  // returns sorted list of orders that are reading chapters
  List<int> _readingOrdersSorted() {
    final orders = book.chapters
        .where((c) => _isReadingChapter(c))
        .map((c) => c.order)
        .toList();
    orders.sort();
    return orders;
  }

  bool _isReadingChapter(Chapter c) {
    // consider it reading if chapterType == 'text' OR has contentBlocks/textContent
    final hasTypeText = (c.chapterType?.toLowerCase() == 'text');
    final hasBlocks = c.contentBlocks.isNotEmpty;
    final hasTextContent = (c.textContent.trim().isNotEmpty);
    return hasTypeText || hasBlocks || hasTextContent;
  }

  // -------------------------
  // Progress
  // -------------------------
  Future<void> saveProgress(
      {required int order, required double offset}) async {
    currentOrder = order;
    currentScrollOffset = offset;
    final m = {'order': order, 'offset': offset};
    await prefs.setString(_kProgressPrefix + book.id, jsonEncode(m));
  }

  // // -------------------------
  // // Caching
  // // -------------------------
  // Instead of caching full chapter, cache only the order
  Set<int> _getCachedChapterOrders() {
    final key = _kCachedChapterPrefix + book.id;
    final strList = prefs.getStringList(key) ?? [];
    return strList.map((s) => int.tryParse(s)).whereType<int>().toSet();
  }

  Future<void> _cacheChapterOrder(int order) async {
    final key = _kCachedChapterPrefix + book.id;
    final cachedOrders = _getCachedChapterOrders();
    cachedOrders.add(order);
    await prefs.setStringList(
        key, cachedOrders.map((e) => e.toString()).toList());
  }

  Future<void> _removeCachedChapterOrder(int order) async {
    final key = _kCachedChapterPrefix + book.id;
    final cachedOrders = _getCachedChapterOrders();
    cachedOrders.remove(order);
    await prefs.setStringList(
        key, cachedOrders.map((e) => e.toString()).toList());
  }

  // -------------------------
  // Load chapter (reading-only)
  // -------------------------
  Future<void> loadChapterIfNeeded(int order) async {
    if (loadedChapters.containsKey(order)) return;

    try {
      // Always load latest from book.chapters
      final found = book.chapters
          .firstWhere((c) => c.order == order && _isReadingChapter(c));
      loadedChapters[order] = found;

      // mark this order as cached (just for tracking)
      await _cacheChapterOrder(order);

      notifyListeners();
    } catch (e) {
      // Chapter might have been deleted
      loadedChapters.remove(order);
      await _removeCachedChapterOrder(order);

      final reading = _readingOrdersSorted();
      final idx = reading.indexWhere((o) => o > order);
      if (idx != -1 && idx < reading.length) {
        final nextOrder = reading[idx];
        final nextChapter =
            book.chapters.firstWhere((c) => c.order == nextOrder);
        loadedChapters[nextOrder] = nextChapter;
        await _cacheChapterOrder(nextOrder);
        currentOrder = nextOrder;
        notifyListeners();
      } else {
        // nothing to load
        notifyListeners();
      }
    }
  }

  // -------------------------
  // Navigation helpers
  // -------------------------
  int? nextOrder(int order) {
    final orders = _readingOrdersSorted();
    final idx = orders.indexOf(order);
    if (idx == -1 || idx + 1 >= orders.length) return null;
    return orders[idx + 1];
  }

  // public API: returns reading chapters sorted (for the bottom sheet / list)
  List<Chapter> getAllChaptersSorted() {
    final list = book.chapters.where((c) => _isReadingChapter(c)).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    return list;
  }
}
