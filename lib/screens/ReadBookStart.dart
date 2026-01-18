import 'package:Spicify/screens/reader_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/book_model.dart';
import '../provider_book/reader_provider.dart';

class Readbookstart extends StatelessWidget {
  final Book book;
  final SharedPreferences prefs;
  const Readbookstart({Key? key, required this.book, required this.prefs})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ReaderProvider>(
      create: (_) => ReaderProvider(book: book, prefs: prefs),
      child: const ReaderRoot(),
    );
  }
}

class ReaderRoot extends StatelessWidget {
  const ReaderRoot({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ReaderProvider>(context);
    final theme = provider.darkMode ? ThemeData.dark() : ThemeData.light();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Book Reader',
      theme: theme.copyWith(
        scaffoldBackgroundColor: provider.darkMode ? Colors.black : null,
      ),
      home: ReaderScreen(),
    );
  }
}
