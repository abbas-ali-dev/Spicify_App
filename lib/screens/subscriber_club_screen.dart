import 'dart:ui';

import 'package:Spicify/screens/bonuce_scene.dart';
import 'package:Spicify/screens/comments_screen.dart';
import 'package:Spicify/screens/poll_widget.dart';
import 'package:Spicify/screens/sneakpeak.dart';
import 'package:Spicify/utilities/navigator_helper_class.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../gen_l10n/app_localizations.dart';
import '../utilities/app_colors.dart';
import '../utilities/app_typography.dart';
import 'HolidaySpecial.dart';
import 'audio_manager/audio_manager.dart';
import 'auth/login_screen.dart';
import 'package:rxdart/rxdart.dart';

class SubscriberClubScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return _SubscriberClubScreen();
  }
}

class _SubscriberClubScreen extends State<SubscriberClubScreen> {
  late final AudioManager _audioManager; // Create it once here

  @override
  void initState() {
    super.initState();
    _audioManager = AudioManager();
  }

  @override
  void dispose() {
    _audioManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return _buildAuthRequiredScreen(context, l10n);
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // ✅ Force-cast .data() to Map<String, dynamic>?
        final Map<String, dynamic>? userData =
            userSnapshot.data!.data() as Map<String, dynamic>?;

        print('User data XCF $userData');
        final isSubscribed = hasActiveSubscription(
            userData); //userSnapshot.data?['isSubscriber'] ?? false;

        print('XDRSubscribeer $isSubscribed');

        if (!isSubscribed) {
          return _buildSubscribeRequiredScreen(context, l10n);
        }

        return ClubContentScreen(user: user, audioManager: _audioManager);
      },
    );
  }

  Widget _buildAuthRequiredScreen(BuildContext context, AppLocalizations l10n) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RepaintBoundary(
                child: Text(l10n.loginRequiredMessage,
                    style: AppTypography.heading16Bold)),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonRed,
              ),
              onPressed: () {
                NavigationHelper.pushWithTransition(
                    context: context, targetPage: const LoginScreen());
              },
              child: RepaintBoundary(
                  child:
                      Text(l10n.loginTitle, style: AppTypography.buttonText)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscribeRequiredScreen(
      BuildContext context, AppLocalizations l10n) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RepaintBoundary(
              child: Text(l10n.subscribeRequiredMessage,
                  style: AppTypography.heading16Bold),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class ClubContentScreen extends StatefulWidget {
  final User user;
  final AudioManager audioManager; // Move AudioManager here

  ClubContentScreen({required this.user, required this.audioManager});

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return _ClubContentScreen(user: user);
  }
}

class _ClubContentScreen extends State<ClubContentScreen> {
  final User user;

  _ClubContentScreen({required this.user});

  // @override
  // void dispose() {
  //   _audioManager.dispose();
  //   super.dispose();
  // }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return RepaintBoundary(
      child: Scaffold(
        backgroundColor: AppColors.black,
        appBar: AppBar(
          backgroundColor: AppColors.black,
          elevation: 0,
          title: RepaintBoundary(
              child: Text(l10n.subscriberClubTitle,
                  style: AppTypography.heading16Bold)),
        ),
        body: SingleChildScrollView(
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('subscriber_club')
                .doc('clubData')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || !snapshot.data!.exists) {
                return Center(
                    child: RepaintBoundary(child: Text(l10n.noContentFound)));
              }

              final data = snapshot.data!.data() as Map<String, dynamic>;

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  //padding: const EdgeInsets.all(16),
                  children: [
                    const SizedBox(height: 16),
                    //Image.asset('asset/image/Group 5.png'),
                    buildNeonText(data['welcomeMessage'] as String),
                    const SizedBox(height: 24),
                    //buildNeonText(data['quoteOfWeek'] as String),
                    _buildQuoteCard(
                        data['quoteOfWeek'] ?? l10n.quoteMissing, l10n),
                    const SizedBox(height: 24),
                    buildHolidaySpecialWidget(data, widget.audioManager),
                    const SizedBox(height: 24),
                    _buildSectionTitle(l10n.bonusScenesTitle),
                    const SizedBox(height: 24),
                    StreamBuilder<List<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('subscriber_club')
                          .doc('clubData')
                          .collection('bonusScenes')
                          .snapshots()
                          .map((snapshot) {
                        final now = DateTime.now();
                        return snapshot.docs
                            .map((doc) => doc.data())
                            .where((data) {
                          final scheduledAt = data['scheduledAt'];
                          if (scheduledAt == null) return true;
                          return (scheduledAt as Timestamp)
                              .toDate()
                              .isBefore(now);
                        }).toList();
                      }),
                      builder: (context, bonusSnapshot) {
                        if (!bonusSnapshot.hasData) return const SizedBox();
                        final bonusList = bonusSnapshot.data!;
                        return Column(
                          children: bonusList
                              .map((scene) => BonusScenePlayer(
                                    scene: scene,
                                    audioManager: widget.audioManager,
                                  ))
                              .toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    PollWidget(),

                    const SizedBox(height: 24),

                    if (data['sneakPeek'] != null)
                      SneakPeekWidget(
                        sp: data['sneakPeek'],
                        l10n: l10n,
                        audioManager: widget.audioManager,
                      ),
                    const SizedBox(height: 24),
                    StreamBuilder<List<QueryDocumentSnapshot>>(
                      stream: getCombinedPosts(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError) {
                          return Center(
                              child: Text('Error: ${snapshot.error}'));
                        }

                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Center();
                        }

                        final posts = snapshot.data!;

                        return Column(
                          // Change this back to Column since we're inside SingleChildScrollView
                          children: posts.map((doc) {
                            return _buildPost(
                              doc.data() as Map<String, dynamic>,
                              doc.id,
                              user,
                              context,
                              key: Key('post_${doc.id}'),
                            );
                          }).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Stream<List<QueryDocumentSnapshot>> getCombinedPosts() {
    final scheduledPostsStream = FirebaseFirestore.instance
        .collection('subscriber_club')
        .doc('clubData')
        .collection('posts')
        .where('scheduledAt', isLessThanOrEqualTo: Timestamp.now())
        .orderBy('scheduledAt', descending: true)
        .snapshots();

    final unscheduledPostsStream = FirebaseFirestore.instance
        .collection('subscriber_club')
        .doc('clubData')
        .collection('posts')
        .where('scheduledAt', isNull: true)
        .snapshots();

    return Rx.combineLatest2<QuerySnapshot, QuerySnapshot,
        List<QueryDocumentSnapshot>>(
      scheduledPostsStream,
      unscheduledPostsStream,
      (scheduled, unscheduled) {
        final allDocs = [...scheduled.docs, ...unscheduled.docs];

        // Sort so scheduled posts come first, nulls at the bottom
        allDocs.sort((a, b) {
          final aTime = a.data().toString().contains('scheduledAt')
              ? a['scheduledAt']
              : null;
          final bTime = b.data().toString().contains('scheduledAt')
              ? b['scheduledAt']
              : null;

          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1; // null goes last
          if (bTime == null) return -1;
          return (bTime as Timestamp).compareTo(aTime as Timestamp);
        });

        return allDocs;
      },
    );
  }

  Widget buildHolidaySpecialWidget(
      Map<String, dynamic> data, AudioManager audioManager) {
    final holidaySpecial = data['holidaySpecial'];
    final scheduledAt = holidaySpecial?['scheduledAt'];

    DateTime? scheduledDate;
    if (scheduledAt is String) {
      scheduledDate = DateTime.tryParse(scheduledAt)?.toUtc();
    }

    final isHolidayActive = data['isHolidaySpecial'] == true &&
        holidaySpecial != null &&
        (scheduledDate == null ||
            scheduledDate.isBefore(DateTime.now().toUtc()));

    if (isHolidayActive) {
      return _buildHolidaySpecial(holidaySpecial, audioManager);
    }

    return Container();
  }

  Widget _buildSectionTitle(String text) => Align(
        alignment: Alignment.centerLeft,
        child: Text(text, style: AppTypography.heading16Bold),
      );

  Widget _buildQuoteCard(String quote, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      height: 180,
      padding: const EdgeInsets.all(20),
      // decoration: BoxDecoration(
      //     image: const DecorationImage(
      //       image: AssetImage('asset/image/quote_image.png'),
      //       fit: BoxFit.cover,
      //     ),
      //     borderRadius: BorderRadius.circular(12)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          RepaintBoundary(
            child: Text(l10n.quoteOfWeek,
                style: TextStyle(
                  fontSize: 24,
                  color: AppColors.buttonRed,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  shadows: [
                    Shadow(
                      blurRadius: 10,
                      color: AppColors.buttonRed,
                      offset: Offset(0, 0),
                    ),
                    Shadow(
                      blurRadius: 30,
                      color: AppColors.buttonRed.withOpacity(0.6),
                      offset: Offset(0, 0),
                    ),
                  ],
                )),
          ),
          RepaintBoundary(
            child: Text(quote,
                style: TextStyle(
                  fontSize: 20,
                  color: AppColors.buttonRed,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  fontStyle: FontStyle.italic,
                  shadows: [
                    Shadow(
                      blurRadius: 10,
                      color: AppColors.buttonRed,
                      offset: Offset(0, 0),
                    ),
                    Shadow(
                      blurRadius: 30,
                      color: AppColors.buttonRed.withOpacity(0.6),
                      offset: Offset(0, 0),
                    ),
                  ],
                ),
                textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }

  Widget _buildHolidaySpecial(Map m, AudioManager audioManager) {
    return HolidaySpecialWidget(m: m, audioManager: audioManager);

    // return GestureDetector(
    //   onTap: () {/* play audio */},
    //   child: Container(
    //     height: 120,
    //     decoration: BoxDecoration(
    //       color: Colors.redAccent,
    //       borderRadius: BorderRadius.circular(12),
    //       image: DecorationImage(
    //         image: NetworkImage(m['imageUrl']),
    //         fit: BoxFit.cover,
    //       ),
    //     ),
    //     child: Align(
    //       alignment: Alignment.bottomLeft,
    //       child: Padding(
    //         padding: const EdgeInsets.all(12),
    //         child: Text(m['title'], style: AppTypography.buttonText),
    //       ),
    //     ),
    //   ),
    // );
  }

  Widget _buildPost(Map post, String postId, User user, BuildContext context,
      {Key? key}) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(post['authorId'])
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const ListTile(
            leading: CircleAvatar(child: Icon(Icons.person)),
            title: Text("Unknown user"),
          );
        }

        final authorData = snapshot.data!.data() as Map<String, dynamic>;
        final authorName = authorData['displayName'] ?? 'No Name';
        final authorAvatarUrl = authorData['profileImage'] ?? '';

        return Container(
          key: key,
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Author info
              ListTile(
                leading: CircleAvatar(
                  backgroundImage: authorAvatarUrl.isNotEmpty
                      ? NetworkImage(authorAvatarUrl)
                      : null,
                  child:
                      authorAvatarUrl.isEmpty ? const Icon(Icons.person) : null,
                ),
                title: RepaintBoundary(
                    child: Text(authorName, style: AppTypography.labelText)),
              ),

              // Post image
              if (post['imageUrl'] != null)
                CachedNetworkImage(
                  imageUrl: post['imageUrl'],
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              // Image.network(
              //   post['imageUrl'],
              //   width: double.infinity,
              //   fit: BoxFit.cover,
              // ),

              // Description
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: RepaintBoundary(
                    child: Text(post['description'],
                        style: AppTypography.labelText)),
              ),

              // 🔄 Reactions section via StreamBuilder
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('subscriber_club')
                    .doc('clubData')
                    .collection('posts')
                    .doc(postId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data?.data() == null) {
                    return RepaintBoundary(
                      child: const Text(
                        'No Postsss',
                        style: AppTypography.appTitle,
                      ),
                    );
                  }

                  final data = snapshot.data!.data()! as Map<String, dynamic>;
                  final reactions =
                      Map<String, dynamic>.from(data['reactions'] ?? {});

                  final userReaction = reactions.entries
                      .firstWhere(
                        (entry) =>
                            (entry.value['users'] as List?)
                                ?.contains(user.uid) ??
                            false,
                        orElse: () => MapEntry('', null),
                      )
                      .key;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (reactions.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Wrap(
                            spacing: 8,
                            children: reactions.entries.map((entry) {
                              final emoji = entry.key;
                              final count = entry.value['count'] ?? 0;
                              return Chip(
                                label: RepaintBoundary(
                                    child: Text('$emoji $count')),
                                backgroundColor: Colors.grey.shade800,
                                labelStyle:
                                    const TextStyle(color: Colors.white),
                              );
                            }).toList(),
                          ),
                        ),

                      // Reaction and comment buttons
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            PopupMenuButton<String>(
                              tooltip: 'React',
                              icon: userReaction.isNotEmpty
                                  ? RepaintBoundary(
                                      child: Text(userReaction,
                                          style: const TextStyle(fontSize: 26)),
                                    )
                                  : const Icon(Icons.emoji_emotions_outlined,
                                      color: Colors.white70),
                              onSelected: (emoji) =>
                                  _toggleReaction(postId, user.uid, emoji),
                              itemBuilder: (context) => [
                                '❤️',
                                '😂',
                                '😮',
                                '😢',
                                '👍',
                                '👎',
                                '🔥'
                              ].map((emoji) {
                                return PopupMenuItem(
                                  value: emoji,
                                  child: RepaintBoundary(
                                    child: Text(emoji,
                                        style: const TextStyle(fontSize: 24)),
                                  ),
                                );
                              }).toList(),
                              color: Colors.black,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            const SizedBox(width: 16),
                            IconButton(
                              icon: const Icon(Icons.comment,
                                  color: Colors.white70),
                              onPressed: () =>
                                  NavigationHelper.pushWithTransition(
                                context: context,
                                targetPage: CommentsScreen(postId: postId),
                              ),
                            ),
                            const SizedBox(width: 4),
                            RepaintBoundary(
                              child: Text('${data['comments'] ?? 0}',
                                  style: AppTypography.labelText),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _toggleLike(String postId, String userId) async {
    final postRef = FirebaseFirestore.instance
        .collection('subscriber_club')
        .doc('clubData')
        .collection('posts')
        .doc(postId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final postSnapshot = await transaction.get(postRef);
      if (!postSnapshot.exists) return;

      final data = postSnapshot.data()!;
      final likedBy = List<String>.from(data['likedBy'] ?? []);
      final isLiked = likedBy.contains(userId);

      if (isLiked) {
        likedBy.remove(userId);
        transaction.update(postRef, {
          'likes': FieldValue.increment(-1),
          'likedBy': likedBy,
        });
      } else {
        likedBy.add(userId);
        transaction.update(postRef, {
          'likes': FieldValue.increment(1),
          'likedBy': likedBy,
        });
      }
    });
  }

  Future<void> _toggleReaction(
      String postId, String userId, String emoji) async {
    final postRef = FirebaseFirestore.instance
        .collection('subscriber_club')
        .doc('clubData')
        .collection('posts')
        .doc(postId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(postRef);
      if (!snapshot.exists) return;

      final data = snapshot.data()!;
      final reactions = Map<String, dynamic>.from(data['reactions'] ?? {});

      // Find existing emoji reacted by user
      String? previousEmoji;
      reactions.forEach((em, info) {
        final users = List<String>.from(info['users'] ?? []);
        if (users.contains(userId)) previousEmoji = em;
      });

      // Remove previous reaction
      if (previousEmoji != null) {
        final previous = Map<String, dynamic>.from(reactions[previousEmoji]!);
        final prevUsers = List<String>.from(previous['users']);
        prevUsers.remove(userId);
        previous['count'] = (previous['count'] ?? 1) - 1;

        if (previous['count'] <= 0) {
          reactions.remove(previousEmoji);
        } else {
          previous['users'] = prevUsers;
          reactions[previousEmoji!] = previous;
        }

        // If tapped the same emoji, just remove and return
        if (previousEmoji == emoji) {
          transaction.update(postRef, {'reactions': reactions});
          return;
        }
      }

      // Add new reaction
      final targetReaction = Map<String, dynamic>.from(
        reactions[emoji] ?? {'count': 0, 'users': []},
      );
      final users = List<String>.from(targetReaction['users']);
      users.add(userId);
      targetReaction['users'] = users;
      targetReaction['count'] = (targetReaction['count'] ?? 0) + 1;
      reactions[emoji] = targetReaction;

      transaction.update(postRef, {'reactions': reactions});
    });
  }

  Widget buildNeonText(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(32),
        //border: Border.all(color: Colors.yellow, width: 2),
        // boxShadow: [
        //   BoxShadow(
        //     color: Colors.yellow.withOpacity(0.6),
        //     blurRadius: 10,
        //     spreadRadius: 1,
        //   ),
        // ],
      ),
      child: RepaintBoundary(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            color: AppColors.buttonRed,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            shadows: [
              Shadow(
                blurRadius: 10,
                color: AppColors.buttonRed,
                offset: Offset(0, 0),
              ),
              Shadow(
                blurRadius: 30,
                color: AppColors.buttonRed.withOpacity(0.6),
                offset: Offset(0, 0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
