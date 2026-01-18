import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';

import '../utilities/app_colors.dart';
import '../utilities/app_typography.dart';

class PollWidget extends StatefulWidget {
  const PollWidget({super.key});

  @override
  State<PollWidget> createState() => _PollWidgetState();
}

class _PollWidgetState extends State<PollWidget> {
  final pollRef = FirebaseFirestore.instance
      .collection('subscriber_club')
      .doc('clubData')
      .collection('poll')
      .doc('active');

  final userId = FirebaseAuth.instance.currentUser?.uid;
  String? localVotedKey;

  void vote(
      String selectedKey, List<Map<String, dynamic>> currentOptions) async {
    if (userId == null) return;

    final previousVote = localVotedKey;

    if (previousVote == selectedKey)
      return; // Tapping the same option does nothing

    setState(() {
      localVotedKey = selectedKey; // Optimistic update
    });

    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final freshSnap = await tx.get(pollRef);
        final freshData = freshSnap.data() as Map<String, dynamic>;
        final updatedOptions =
            List<Map<String, dynamic>>.from(freshData['options']);
        final updatedVotes =
            Map<String, dynamic>.from(freshData['votes'] ?? {});

        // Decrement previous vote count if any
        if (previousVote != null) {
          final oldIndex =
              updatedOptions.indexWhere((o) => o['key'] == previousVote);
          if (oldIndex != -1) {
            updatedOptions[oldIndex]['votes'] =
                (updatedOptions[oldIndex]['votes'] as int) - 1;
          }
        }

        // Increment new vote count
        final newIndex =
            updatedOptions.indexWhere((o) => o['key'] == selectedKey);
        if (newIndex != -1) {
          updatedOptions[newIndex]['votes'] =
              (updatedOptions[newIndex]['votes'] as int) + 1;
          updatedVotes[userId!] = selectedKey;

          tx.update(pollRef, {
            'options': updatedOptions,
            'votes': updatedVotes,
          });
        }
      });
    } catch (e) {
      debugPrint('❌ Failed to change vote: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: pollRef.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox();
        }

        final pollData = snapshot.data!.data() as Map<String, dynamic>;
        final now = DateTime.now();
        final scheduledAt = pollData['scheduledAt'];

// Optional: allow a 1–2 minute grace period
        final gracePeriod = Duration(minutes: 2);

// Safely parse
        DateTime? scheduledTime;
        if (scheduledAt is Timestamp) {
          scheduledTime = scheduledAt.toDate();
        } else if (scheduledAt is String) {
          scheduledTime = DateTime.tryParse(scheduledAt);
        }

        if (scheduledTime != null &&
            scheduledTime.isAfter(now.add(gracePeriod))) {
          return Container();
        }

        final votes = Map<String, dynamic>.from(pollData['votes'] ?? {});
        final originalOptions =
            List<Map<String, dynamic>>.from(pollData['options']);
        final userVotedKey = votes[userId];
        final votedKeyToUse = localVotedKey ?? userVotedKey;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blueAccent),
            borderRadius: BorderRadius.circular(16),
            color: AppColors.textFieldGrey,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RepaintBoundary(
                child: RepaintBoundary(
                  child: Text((pollData['question']).toString(),
                      style: AppTypography.labelText),
                ),
              ),
              const SizedBox(height: 20),
              ...originalOptions.map((option) {
                final key = option['key'];
                final label = option['label'];
                final votesCount = option['votes'];
                final isSelected = votedKeyToUse == key;

                final int currentTotalVotes = originalOptions.fold<int>(
                    0, (sum, o) => sum + (o['votes'] as int));

                final double percent = currentTotalVotes == 0
                    ? 0.0
                    : (votesCount / currentTotalVotes).clamp(0.0, 1.0);

                return GestureDetector(
                  onTap: () => vote(key, originalOptions),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.buttonRed
                                    : Colors.transparent,
                                border: Border.all(color: Colors.white),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check,
                                      size: 16, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: RepaintBoundary(
                                child: Text(
                                  "$key. $label",
                                  style: AppTypography.labelText
                                      .copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                            RepaintBoundary(
                              child: Text(
                                "${(percent * 100).toStringAsFixed(0)}%",
                                style: AppTypography.labelText
                                    .copyWith(color: Colors.white54),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: percent,
                            backgroundColor: Colors.grey.shade800,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.buttonRed),
                            minHeight: 8,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList()
            ],
          ),
        );
      },
    );
  }
}
