/// Lightweight English / বাংলা translations. English text is the key; Bangla comes from [bn].
/// Placeholders use {name}: tr('Save {n}%', {'n': 40}).
library;

import 'i18n_bn.dart';

/// Current language code ('en' or 'bn'), set from Settings before the app builds.
String appLanguage = 'en';

bool get isBangla => appLanguage == 'bn';

String tr(String en, [Map<String, Object?>? args]) {
  var s = isBangla ? (bn[en] ?? en) : en;
  if (args != null) {
    for (final e in args.entries) {
      s = s.replaceAll('{${e.key}}', isBangla ? toBanglaDigits('${e.value}') : '${e.value}');
    }
  }
  return s;
}

const _digits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];

/// 1,234.50 → ১,২৩৪.৫০ (used for counts in Bangla mode; prices keep Latin digits for clarity).
String toBanglaDigits(String s) => s.replaceAllMapped(RegExp(r'\d'), (m) => _digits[int.parse(m[0]!)]);
