import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/local_provider.dart';

class LanguageDialog extends StatelessWidget {
  final Map<String, String> languages = {
    'en': 'English',
    'nl': 'Dutch',
    'es': 'Spanish',
    'fr': 'French',
    'de': 'German',
  };

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<LocaleProvider>(context);
    final selectedCode = provider.locale.languageCode;

    return Dialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Change Language',
                style: TextStyle(color: Colors.white, fontSize: 16)),
            const Divider(color: Colors.grey),
            ...languages.entries.map((entry) {
              final isSelected = selectedCode == entry.key;
              return ListTile(
                leading: Icon(
                  Icons.radio_button_checked,
                  color: isSelected ? Colors.red : Colors.grey,
                  size: 20,
                ),
                title: Text(entry.value, style: TextStyle(color: Colors.white)),
                onTap: () {
                  provider.setLocale(entry.key);
                  Navigator.of(context).pop();
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}
