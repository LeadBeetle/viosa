import 'package:flutter/widgets.dart';
import '../generated/app_localizations.dart';

export '../generated/app_localizations.dart';

extension LocalizedBuildContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
