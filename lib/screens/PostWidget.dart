import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../utilities/app_typography.dart';
import '../utilities/navigator_helper_class.dart';
import 'comments_screen.dart';

class PostReactions extends StatefulWidget {
  final String postId;
  final String userId;
  final Map<String, dynamic> initialReactions;
  final Map<dynamic, dynamic> postData;

  const PostReactions({
    required this.postId,
    required this.userId,
    required this.initialReactions,
    required this.postData,
    Key? key,
  }) : super(key: key);

  @override
  _PostReactionsState createState() => _PostReactionsState();
}

class _PostReactionsState extends State<PostReactions> {
  late Map<String, dynamic> _reactions;
  String _userReaction = '';

  @override
  void initState() {
    super.initState();
    _reactions = Map<String, dynamic>.from(widget.initialReactions);
    _updateUserReaction();
  }

  void _updateUserReaction() {
    _userReaction = _reactions.entries
        .firstWhere(
          (entry) =>
              (entry.value['users'] as List?)?.contains(widget.userId) ?? false,
          orElse: () => MapEntry('', null),
        )
        .key;
  }

  Future<void> _toggleReaction(String emoji) async {
    final newReactions = Map<String, dynamic>.from(_reactions);
    final reactionData = newReactions[emoji] ?? {'count': 0, 'users': []};
    final users = List<String>.from(reactionData['users'] ?? []);

    // Remove from previous reaction if exists
    if (_userReaction.isNotEmpty) {
      final prevReaction = newReactions[_userReaction];
      if (prevReaction != null) {
        prevReaction['users'] = List<String>.from(prevReaction['users'])
          ..remove(widget.userId);
        prevReaction['count'] = (prevReaction['count'] as int) - 1;
        if (prevReaction['count'] <= 0) {
          newReactions.remove(_userReaction);
        }
      }
    }

    // Add to new reaction if different from current
    if (_userReaction != emoji) {
      reactionData['count'] = (reactionData['count'] as int) + 1;
      reactionData['users'] = [...users, widget.userId];
      newReactions[emoji] = reactionData;
    }

    // Update Firestore
    try {
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .update({'reactions': newReactions});

      setState(() {
        _reactions = newReactions;
        _userReaction = _userReaction == emoji ? '' : emoji;
      });
    } catch (e) {
      print('error ${e}');
      // Show error or revert UI
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update reaction: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          PopupMenuButton<String>(
            tooltip: 'React',
            icon: _userReaction.isNotEmpty
                ? RepaintBoundary(
                    child: Text(_userReaction,
                        style: const TextStyle(fontSize: 26)))
                : const Icon(Icons.emoji_emotions_outlined,
                    color: Colors.white70),
            onSelected: _toggleReaction,
            itemBuilder: (context) =>
                ['❤️', '😂', '😮', '😢', '👍', '👎', '🔥'].map((emoji) {
              return PopupMenuItem(
                value: emoji,
                child: RepaintBoundary(
                    child: Text(emoji, style: const TextStyle(fontSize: 24))),
              );
            }).toList(),
            color: Colors.black,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.comment, color: Colors.white70),
            onPressed: () => NavigationHelper.pushWithTransition(
              context: context,
              targetPage: CommentsScreen(postId: widget.postId),
            ),
          ),
          const SizedBox(width: 4),
          RepaintBoundary(
            child: Text('${widget.postData['comments'] ?? 0}',
                style: AppTypography.labelText),
          ),
        ],
      ),
    );
  }
}
