import 'dart:ui';

/// Interface for locale/language preferences
/// Following Interface Segregation Principle (ISP)
abstract class ILocaleService {
  Future<void> saveUiLanguage(String languageCode);
  Future<String> getUiLanguage();
  Future<String> getDefaultUiLanguage();
  Locale? getLocaleFromCode(String code);
  List<Locale> get supportedLocales;
}
