import 'dart:ui';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'i_locale_service.dart';

class LocaleService implements ILocaleService {
  final FlutterSecureStorage _storage;
  static const String _uiLanguageKey = 'ui_language';

  LocaleService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  @override
  List<Locale> get supportedLocales => const [
        Locale('de'),
        Locale('en'),
      ];

  @override
  Future<void> saveUiLanguage(String languageCode) async {
    if (!['de', 'en'].contains(languageCode)) {
      throw ArgumentError('Invalid UI language: $languageCode');
    }
    await _storage.write(key: _uiLanguageKey, value: languageCode);
  }

  @override
  Future<String> getUiLanguage() async {
    final saved = await _storage.read(key: _uiLanguageKey);
    if (saved != null && ['de', 'en'].contains(saved)) {
      return saved;
    }
    return getDefaultUiLanguage();
  }

  @override
  Future<String> getDefaultUiLanguage() async {
    final deviceLocale = PlatformDispatcher.instance.locale;
    final countryCode = deviceLocale.countryCode?.toUpperCase();

    // German-speaking countries: Germany, Austria, Switzerland
    if (countryCode == 'DE' || countryCode == 'AT' || countryCode == 'CH') {
      return 'de';
    }
    // Also check language code for cases without country
    if (deviceLocale.languageCode == 'de') {
      return 'de';
    }
    return 'en';
  }

  @override
  Locale? getLocaleFromCode(String code) {
    return code == 'de'
        ? const Locale('de')
        : code == 'en'
            ? const Locale('en')
            : null;
  }
}
