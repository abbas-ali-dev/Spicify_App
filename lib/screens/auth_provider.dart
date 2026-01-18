import 'dart:async';

import 'package:Spicify/utilities/navigator_helper_class.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../model/book_model.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  User? get currentUser => _auth.currentUser;

  bool _isSubscribed = false;
  bool get isSubscribed => _isSubscribed;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  // 🔥 NEW — Force refresh current user + subscription
  Future<void> refreshUser() async {
    await _auth.currentUser?.reload();
    final u = _auth.currentUser;

    if (u != null) {
      await loadUserStatus();
    }

    notifyListeners();
  }

  Future<Map<String, dynamic>> loadUserProfile() async {
    if (currentUser != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get();

      return doc.data()!;
    } else {
      return {};
    }
  }

  Future<void> registerUser({
    required String email,
    required String password,
    required String name,
    String? profileImage,
    bool isSubscriber = false,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;
      if (user == null)
        throw FirebaseAuthException(
            code: 'user-null', message: 'User not found after registration');

      await user.sendEmailVerification();

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'name': name,
        'profileImage': profileImage ?? "",
        'isSubscriber': isSubscriber,
      });
    } on FirebaseAuthException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError("Registration failed: $e");
    } finally {
      _setLoading(false);
    }
  }

  // ✅ FIXED — Email verification refresh
  Future<void> loginWithEmail(String email, String password) async {
    _setLoading(true);
    _setError(null);
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _auth.currentUser?.reload(); // 🔥 IMPORTANT
      final user = _auth.currentUser;

      if (user != null) {
        if (!user.emailVerified) {
          await _auth.signOut();
          _setError('Your account is not verified. Please contact support.');
          return;
        }

        // 🔥 Load subscription immediately
        await loadUserStatus();
      }
    } on FirebaseAuthException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError('An unexpected error occurred.');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loginWithGoogle(BuildContext context) async {
    _setLoading(true);
    _setError(null);

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email'],
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      // 🔥 After Google login load subscription
      await loadUserStatus();

      _setError(null);
    } catch (e) {
      print("Google sign-in failed: $e");
      _setError("Google sign-in failed: $e");
    } finally {
      _setLoading(false);
    }
  }

  Future<String> getPrivacyPolicy() async {
    return _getContent('privacyPolicy');
  }

  Future<String> getTerms() async {
    return _getContent('terms');
  }

  Future<String> getAbout() async {
    return _getContent('about');
  }

  Future<String> _getContent(String docId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('siteContent')
          .doc(docId)
          .get();

      if (doc.exists) {
        return doc['content'] ?? 'No content available';
      } else {
        const defaultContent = {
          'privacyPolicy':
              '<h1>Privacy Policy</h1><p>Your privacy policy here</p>',
          'terms': '<h1>Terms</h1><p>Your terms here</p>',
          'about': '<h1>About</h1><p>Your about content here</p>',
        };

        await FirebaseFirestore.instance
            .collection('siteContent')
            .doc(docId)
            .set({'content': defaultContent[docId] ?? 'Content not available'});

        return defaultContent[docId] ?? 'Content not available';
      }
    } catch (e) {
      print('Error getting content: $e');
      return 'Error loading content';
    }
  }

  Future<Map<String, String>> getSocialAccounts() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('siteContent')
          .doc('socialAccounts')
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
        return Map<String, String>.from(data ?? {});
      } else {
        const defaultAccounts = {
          'youtube': '',
          'tiktok': '',
          'instagram': '',
          'facebook': '',
          'twitter': '',
        };

        await FirebaseFirestore.instance
            .collection('siteContent')
            .doc('socialAccounts')
            .set(defaultAccounts);

        return defaultAccounts;
      }
    } catch (e) {
      print('Error getting social accounts: $e');
      return {};
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception("Failed to send reset link");
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    _isSubscribed = false; // 🔥 Reset subscription
    notifyListeners();
  }

  void updateUserSocialAccounts(Map<String, dynamic> socialAccounts) async {
    if (currentUser != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .update({
        'socialAccounts': {
          'instagram': socialAccounts['instagram'] ?? '',
          'youtube': socialAccounts['youtube'] ?? '',
          'tiktok': socialAccounts['tiktok'] ?? '',
        }
      });
      notifyListeners();
    }
  }

  // ✅ FIXED — Always refresh Firestore (no stale data)
  Future<void> loadUserStatus() async {
    final user = _auth.currentUser;
    if (user == null) {
      _isSubscribed = false;
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get(const GetOptions(source: Source.server)); // 🔥 FORCE SERVER

      if (doc.exists) {
        final data = doc.data()!;
        _isSubscribed = hasActiveSubscription(data);
      }
    } catch (e) {
      print("Failed loading subscription: $e");
    }

    notifyListeners();
  }

  Future<void> favouriteBook(Book book) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('favourites')
          .doc(user.uid)
          .collection('mybookmarks')
          .doc()
          .set(book.toMap());
    } catch (e) {
      print("Failed to save favourite: $e");
    }

    notifyListeners();
  }

  Future<void> toggleLike(String postId) async {
    if (currentUser == null) return;

    final postRef = FirebaseFirestore.instance
        .collection('subscriber_club')
        .doc('clubData')
        .collection('posts')
        .doc(postId);

    return FirebaseFirestore.instance.runTransaction((transaction) async {
      final postSnapshot = await transaction.get(postRef);
      if (!postSnapshot.exists) return;

      final data = postSnapshot.data()!;
      final likedBy = List<String>.from(data['likedBy'] ?? []);
      final isLiked = likedBy.contains(currentUser!.uid);

      if (isLiked) {
        likedBy.remove(currentUser!.uid);
        transaction.update(postRef, {
          'likes': FieldValue.increment(-1),
          'likedBy': likedBy,
        });
      } else {
        likedBy.add(currentUser!.uid);
        transaction.update(postRef, {
          'likes': FieldValue.increment(1),
          'likedBy': likedBy,
        });
      }
    });
  }

  Stream<List<Book>> getFavouriteBooksStream() {
    final user = _auth.currentUser;

    if (user == null) {
      return Stream.value([]);
    }

    return FirebaseFirestore.instance
        .collection('favourites')
        .doc(user.uid)
        .collection('mybookmarks')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();

        final List<Chapter> chapters =
            (data['chapters'] as List<dynamic>? ?? []).map((chapterData) {
          final c = Map<String, dynamic>.from(chapterData);

          final rawBlocks = (c['contentBlocks'] as List<dynamic>? ?? []);
          final contentBlocks = rawBlocks.map<ContentBlock>((b) {
            final m = Map<String, dynamic>.from(b);

            final type = (m['type'] ?? '').toString();

            if (type == "image") {
              return ContentBlock(
                type: "image",
                text: null,
                url: m['url']?.toString(),
              );
            }

            return ContentBlock(
              type: "text",
              text: (m['content'] ?? '').toString(),
              url: null,
            );
          }).toList();

          return Chapter(
            chapterId: c['chapterId'] ?? 0,
            chapterName: c['chapterName'] ?? '',
            chapterUrl: c['chapterUrl'] ?? '',
            chapterType: c['chapterType']?.toString(),
            isLocked: c['isLocked'] ?? false,
            isFree: c['isFree'] ?? false,
            order: c['order'] ?? 0,
            isDownloadable: c['isDownloadable'] ?? false,
            textContent: c['textContent'] ?? '',
            contentBlocks: contentBlocks,
          );
        }).toList();

        final hubButtonsData = data['hubButtons'] ?? {};
        final HubButtons hubButtons = HubButtons(
          listen: hubButtonsData['listen'] ?? false,
          read: hubButtonsData['read'] ?? false,
          watch: hubButtonsData['watch'] ?? false,
        );

        return Book(
          id: doc.id,
          poster: data['poster'] ?? '',
          bookCover: data['bookCover'] ?? '',
          title: data['title'] ?? '',
          authoer: data['author'] ?? '',
          rate: data['rate']?.toInt() ?? 0,
          tags: List<String>.from(data['tags'] ?? []),
          summary: data['summary'] ?? '',
          teaserQuote: data['teaserQuote'] ?? '',
          audioUrl: data['audioUrl'] ?? '',
          spiceLevel: data['spiceLevel'] ?? '',
          isRecommended: data['isRecommended'] ?? false,
          chapters: chapters,
          readingModeEnabled: data['readingModeEnabled'] ?? false,
          watchModeEnabled: data['watchModeEnabled'] ?? false,
          hubButtons: hubButtons,
        );
      }).toList();
    });
  }
}
