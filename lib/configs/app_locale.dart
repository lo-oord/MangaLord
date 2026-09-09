import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const englishLocale = Locale('en');
const arabicLocale = Locale('ar');
const languagePreferenceKey = 'mangalord.language';

final appLocale = ValueNotifier<Locale>(englishLocale);

bool isArabicLocale(Locale locale) => locale.languageCode == arabicLocale.languageCode;

String languageLabel(Locale locale) => isArabicLocale(locale) ? 'العربية' : 'English';

Locale localeFromPreference(String? value) {
  // Keep accepting the old display-value format used by previous builds.
  switch (value?.trim().toLowerCase()) {
    case 'ar':
    case 'arabic':
    case 'العربية':
      return arabicLocale;
    default:
      return englishLocale;
  }
}

Future<void> loadAppLocale() async {
  final prefs = await SharedPreferences.getInstance();
  appLocale.value = localeFromPreference(prefs.getString(languagePreferenceKey));
}

Future<void> setAppLocale(Locale locale) async {
  final normalized = isArabicLocale(locale) ? arabicLocale : englishLocale;
  if (appLocale.value != normalized) {
    appLocale.value = normalized;
  }
  final prefs = await SharedPreferences.getInstance();
  // Store a stable language code rather than a translated display label.
  await prefs.setString(languagePreferenceKey, normalized.languageCode);
}
