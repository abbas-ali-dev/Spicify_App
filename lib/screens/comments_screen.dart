import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../utilities/app_typography.dart';

class CommentsScreen extends StatefulWidget {
  final String postId;
  const CommentsScreen({super.key, required this.postId});

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class Comment {
  final String id;
  final String uid;
  final String displayName;
  final String avatarUrl;
  final String text;
  final Timestamp timestamp;
  final bool reported;

  Comment({
    required this.id,
    required this.uid,
    required this.displayName,
    required this.avatarUrl,
    required this.text,
    required this.timestamp,
    required this.reported,
  });

  factory Comment.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Comment(
      id: doc.id,
      uid: data['uid'],
      displayName: data['displayName'] ?? '',
      avatarUrl: data['avatarUrl'] ?? '',
      text: data['text'],
      timestamp: data['timestamp'],
      reported: data['reported'] ?? false,
    );
  }
}

class _CommentsScreenState extends State<CommentsScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    //_ensureUser();
  }

  // Future<void> _ensureUser() async {
  //   if (_auth.currentUser == null) {
  //     await _auth.signInAnonymously();
  //   }
  // }

  Stream<List<Comment>> _commentStream() {
    return _firestore
        .collection('comments')
        .where('postId', isEqualTo: widget.postId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Comment.fromDoc(d)).toList());
  }

  Future<void> _addComment(String text) async {
    final user = _auth.currentUser!;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final data = doc.data();
    await _firestore.collection('comments').add({
      'postId': widget.postId,
      'uid': user.uid,
      'displayName': data?['displayName'] as String,
      'avatarUrl': data?['profileImage'] as String,
      'text': text,
      'timestamp': Timestamp.now(),
      'reported': false,
    });
// ✅ Increment comment count in the "posts" collection
    await _firestore
        .collection('subscriber_club')
        .doc('clubData')
        .collection('posts')
        .doc(widget.postId)
        .update({
      'comments': FieldValue.increment(1),
    });
    _controller.clear();
    FocusScope.of(context).unfocus();
  }

  Future<void> _deleteComment(String commentId) async {
    await _firestore.collection('comments').doc(commentId).delete();
    await _firestore
        .collection('subscriber_club')
        .doc('clubData')
        .collection('posts')
        .doc(widget.postId)
        .update({
      'comments': FieldValue.increment(-1),
    });
  }

  Future<void> _reportComment(String commentId) async {
    await _firestore
        .collection('comments')
        .doc(commentId)
        .update({'reported': true});
  }

  Widget _buildCommentBubble(Comment c) {
    final me = _auth.currentUser!;
    final isMine = me.uid == c.uid;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(backgroundImage: NetworkImage(c.avatarUrl)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RepaintBoundary(
                  child: Text(c.displayName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: RepaintBoundary(
                      child: Text(c.text,
                          style: const TextStyle(color: Colors.white))),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () {
                    if (isMine) {
                      _deleteComment(c.id);
                    } else {
                      _reportComment(c.id);
                    }
                  },
                  child: RepaintBoundary(
                    child: Text(
                      isMine
                          ? (c.reported ? 'Delete Reported' : 'Delete')
                          : (c.reported ? 'Reported' : 'Report'),
                      style: TextStyle(
                        color: c.reported ? Colors.red : Colors.blueAccent,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Scaffold(
        appBar: AppBar(
          title: RepaintBoundary(
            child: Text(
              'Comments',
              style: AppTypography.homeTitle,
            ),
          ),
          backgroundColor: Colors.black,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        backgroundColor: Colors.black,
        body: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<Comment>>(
                stream: _commentStream(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snap.hasError) {
                    print('Erorro snap ${snap.error}');

                    return const Center(
                      child: Text('Something went wrong',
                          style: TextStyle(color: Colors.white)),
                    );
                  }

                  final comments = snap.data ?? [];

                  if (comments.isEmpty) {
                    return const Center(
                      child: RepaintBoundary(
                        child: Text('No comments yet.',
                            style: TextStyle(color: Colors.white54)),
                      ),
                    );
                  }

                  return ListView.builder(
                    reverse: true,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: comments.length,
                    itemBuilder: (ctx, i) => _buildCommentBubble(comments[i]),
                  );
                },
              ),
            ),
            SafeArea(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.grey[900],
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Write Comment',
                          hintStyle: const TextStyle(color: Colors.white38),
                          filled: true,
                          fillColor: Colors.grey[800],
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: () {
                        final text = _controller.text.trim();
                        if (text.isNotEmpty) {
                          _addComment(text);
                        }
                      },
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
