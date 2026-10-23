import 'dart:convert';

/// The name as a token for a User-Agent header or a similar one-line field.
///
/// The characters a User-Agent comment is parsed by become harmless ones -
/// `;` to `,`, `(` and `)` to `[` and `]` - and anything outside printable
/// ASCII is percent-encoded as UTF-8 (`Ганна's` -> `%D0%93...'s`), since a
/// header value must be ASCII; the receiver gets the name back with a plain
/// percent-decode. Control characters and runs of spaces become one space.
String userAgentToken(String name) {
  final out = StringBuffer();
  for (final rune in name.replaceAll(RegExp(r'\s+'), ' ').trim().runes) {
    if (rune == 0x3B) {
      out.write(',');
    } else if (rune == 0x28) {
      out.write('[');
    } else if (rune == 0x29) {
      out.write(']');
    } else if (rune == 0x25) {
      // A literal % is encoded too, or the receiver's decode would misread it.
      out.write('%25');
    } else if (rune >= 0x20 && rune < 0x7F) {
      out.writeCharCode(rune);
    } else {
      for (final byte in utf8.encode(String.fromCharCode(rune))) {
        out.write('%${byte.toRadixString(16).toUpperCase().padLeft(2, '0')}');
      }
    }
  }
  return out.toString();
}

/// Labels for a list of devices in which two may share a name - two
/// "Galaxy S24" in one account.
///
/// Each item is a name and an optional [detail] that can tell it apart (the
/// OS version, a sign-in date, the name the user gave the device). A name
/// that occurs once is left as it is; repeated names get their detail in
/// brackets when the details differ, and a number otherwise:
///
///     [("Galaxy S24", "Android 15"), ("Galaxy S24", "Android 14"), ("Pixel 9", null)]
///     -> ["Galaxy S24 (Android 15)", "Galaxy S24 (Android 14)", "Pixel 9"]
List<String> distinctLabels(Iterable<({String name, String? detail})> items) {
  final list = items.toList();
  final byName = <String, List<int>>{};
  for (var i = 0; i < list.length; i++) {
    byName.putIfAbsent(list[i].name, () => []).add(i);
  }
  final labels = [for (final item in list) item.name];
  for (final MapEntry(key: name, value: indexes) in byName.entries) {
    if (indexes.length < 2) continue;
    final details = [for (final i in indexes) list[i].detail];
    final distinct =
        details.every((d) => d != null && d.trim().isNotEmpty) &&
        details.toSet().length == details.length;
    for (var n = 0; n < indexes.length; n++) {
      labels[indexes[n]] = distinct
          ? '$name (${details[n]!.trim()})'
          : '$name (${n + 1})';
    }
  }
  return labels;
}
