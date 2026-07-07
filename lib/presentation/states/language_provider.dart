import 'package:flutter/material.dart';

class LanguageProvider extends ChangeNotifier {
  String _selectedLanguage = 'Français';

  String get selectedLanguage => _selectedLanguage;

  String get languageCode {
    switch (_selectedLanguage) {
      case 'Anglais':
        return 'en';
      case 'Arabe':
        return 'ar';
      case 'Français':
      default:
        return 'fr';
    }
  }

  bool get isFr => languageCode == 'fr';
  bool get isEn => languageCode == 'en';
  bool get isAr => languageCode == 'ar';

  TextDirection get textDirection =>
      isAr ? TextDirection.rtl : TextDirection.ltr;

  void setLanguage(String lang) {
    _selectedLanguage = lang;
    notifyListeners(); // Informe l'app qu'il faut redessiner les textes
  }
}
