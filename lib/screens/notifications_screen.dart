import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../gen_l10n/app_localizations.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final loc = AppLocalizations.of(context)!;

    return RepaintBoundary(
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: RepaintBoundary(
            child: Text(loc.notifications,
                style: const TextStyle(color: Colors.white)),
          ),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 0,
        ),
        body: user == null
            ? Center(
                child: RepaintBoundary(
                  child: Text(
                    loc.loginToViewNotifications,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              )
            //FirebaseFirestore.instance
            //                   .collection('notifications')
            //                   .doc(user.uid)
            //                   .collection('user_notifications')
            //                   .orderBy('timestamp', descending: true)
            //                   .snapshots(),
            : StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('notifications')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: RepaintBoundary(
                        child: Text(
                          loc.noNotifications,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    );
                  }

                  final notifications = snapshot.data!.docs;

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: notifications.length,
                    separatorBuilder: (_, __) =>
                        const Divider(color: Colors.white10),
                    itemBuilder: (context, index) {
                      final message = notifications[index]['body'] ?? '';
                      final time = notifications[index]['createdAt']?.toDate();

                      return ListTile(
                        title: RepaintBoundary(
                          child: Text(message,
                              style: const TextStyle(color: Colors.white)),
                        ),
                        subtitle: time != null
                            ? RepaintBoundary(
                                child: Text(
                                  "${time.toLocal()}",
                                  style: const TextStyle(color: Colors.white54),
                                ),
                              )
                            : null,
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}
