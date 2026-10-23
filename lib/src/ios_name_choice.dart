import '../device_display_name.dart';
import 'apple_identifiers.g.dart';

/// Names an Apple device by its hardware identifier ("iPhone13,1").
///
/// iOS has no public API that returns the marketing name, and `UIDevice.name`
/// is just "iPhone" since iOS 16, so a table is the only way. A device newer
/// than the table is named by its identifier, which still tells two models
/// apart.
DisplayName chooseIosName(String machine, {String? idiom}) {
  final kind = iosKind(idiom);
  final name = appleIdentifiers[machine];
  if (name != null) {
    return DisplayName(
      name,
      NameSource.identifierTable,
      key: machine,
      kind: kind,
    );
  }
  return DisplayName(machine, NameSource.identifier, kind: kind);
}
