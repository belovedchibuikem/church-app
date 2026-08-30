import 'catalogs.g.dart';
import 'supported_locales.dart';

String lookupFhcMessage(
  String locale,
  String key, {
  Map<String, String>? args,
  String? fallback,
}) {
  final resolved = normalizeFhcLocale(locale);
  final fromLocale = kFhcMessageCatalogs[resolved]?[key];
  final fromEnglish =
      resolved == kFhcDefaultLocale
          ? null
          : kFhcMessageCatalogs[kFhcDefaultLocale]?[key];
  var template = fromLocale ?? fromEnglish ?? fallback ?? key;
  if (args != null) {
    args.forEach((name, value) {
      template = template.replaceAll('{$name}', value);
    });
  }
  return template;
}
