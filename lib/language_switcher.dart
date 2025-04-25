import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'language_provider.dart';

class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final currentLocale = languageProvider.locale;

    return PopupMenuButton<Locale>(
      icon: const Icon(Icons.language, color: Colors.green),
      onSelected: (Locale newLocale) {
        languageProvider.setLocale(newLocale);
      },
      itemBuilder: (BuildContext context) => [
        const PopupMenuItem(
          value: Locale('en'),
          child: Text('English'),
        ),
        const PopupMenuItem(
          value: Locale('fr'),
          child: Text('Français'),
        ),
        const PopupMenuItem(
          value: Locale('ar'),
          child: Text('العربية'),
        ),
        const PopupMenuItem(
          value: Locale('es'),
          child: Text('Español'),
        ),
      ],
    );
  }
}